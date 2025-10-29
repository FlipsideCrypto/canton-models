{{ config(
    materialized = 'incremental',
    unique_key = ['reward_date', 'reward_type'],
    cluster_by = ['reward_date'],
    incremental_strategy = 'merge',
    tags = ['ez', 'rewards'],
    enabled = false
) }}

WITH validator_rewards AS (

    SELECT
        effective_at :: DATE AS reward_date,
        'validator' AS reward_type,
        reward_action,
        acting_parties [0] :: STRING AS recipient,
        reward_amount
    FROM
        {{ ref('rewards__fact_validator_rewards') }}
    WHERE
        reward_amount IS NOT NULL

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
),
app_rewards AS (
    SELECT
        effective_at :: DATE AS reward_date,
        CASE
            WHEN is_featured_app THEN 'featured_app'
            ELSE 'unfeatured_app'
        END AS reward_type,
        reward_action,
        acting_parties [0] :: STRING AS recipient,
        reward_amount
    FROM
        {{ ref('rewards__fact_app_rewards') }}
    WHERE
        reward_amount IS NOT NULL

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
),
all_rewards AS (
    SELECT
        *
    FROM
        validator_rewards
    UNION ALL
    SELECT
        *
    FROM
        app_rewards
    -- Note: SV rewards track weight changes, not amounts, so excluded from this summary
)
SELECT
    reward_date,
    reward_type,
    -- Volume metrics
    COUNT(*) AS total_reward_events,
    SUM(reward_amount) AS total_rewards_distributed,
    AVG(reward_amount) AS avg_reward_amount,
    MEDIAN(reward_amount) AS median_reward_amount,
    MIN(reward_amount) AS min_reward_amount,
    MAX(reward_amount) AS max_reward_amount,
    -- Unique recipients
    COUNT(
        DISTINCT recipient
    ) AS unique_recipients,
    -- Action breakdown
    SUM(
        CASE
            WHEN reward_action = 'archived' THEN 1
            ELSE 0
        END
    ) AS archived_rewards,
    SUM(
        CASE
            WHEN reward_action = 'expired' THEN 1
            ELSE 0
        END
    ) AS expired_rewards,
    SUM(
        CASE
            WHEN reward_action = 'received' THEN 1
            ELSE 0
        END
    ) AS received_rewards,
    -- Metadata
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    all_rewards
GROUP BY
    reward_date,
    reward_type
