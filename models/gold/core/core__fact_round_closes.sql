{{ config(
    materialized = 'incremental',
    unique_key = ['round_number'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['core']
) }}

WITH mining_round_created_events AS (

    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_index,
        event_json
    FROM
        {{ ref('silver__events') }}
    WHERE
        event_json :template_id :: STRING LIKE '%SummarizingMiningRound'
        AND event_json :event_type :: STRING = 'created_event'

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
)
SELECT
    update_id,
    migration_id,
    record_time,
    effective_at,
    event_id,
    event_index,
    -- Round identification
    event_json :create_arguments :round :number :: NUMBER AS round_number,
    -- Issuance configuration
    event_json :create_arguments :issuanceConfig :amuletToIssuePerYear :: NUMBER(
        38,
        10
    ) AS amulet_to_issue_per_year,
    event_json :create_arguments :issuanceConfig :validatorRewardPercentage :: NUMBER(
        38,
        10
    ) AS validator_reward_percentage,
    event_json :create_arguments :issuanceConfig :appRewardPercentage :: NUMBER(
        38,
        10
    ) AS app_reward_percentage,
    event_json :create_arguments :issuanceConfig :validatorRewardCap :: NUMBER(
        38,
        10
    ) AS validator_reward_cap,
    event_json :create_arguments :issuanceConfig :featuredAppRewardCap :: NUMBER(
        38,
        10
    ) AS featured_app_reward_cap,
    event_json :create_arguments :issuanceConfig :unfeaturedAppRewardCap :: NUMBER(
        38,
        10
    ) AS unfeatured_app_reward_cap,
    event_json :create_arguments :issuanceConfig :optValidatorFaucetCap :: NUMBER(
        38,
        10
    ) AS validator_faucet_cap,
    -- Amulet price
    event_json :create_arguments :amuletPrice :: NUMBER(
        38,
        10
    ) AS amulet_price_usd,
    -- Tick duration
    event_json :create_arguments :tickDuration :microseconds :: NUMBER AS tick_duration_microseconds,
    -- DSO party
    event_json :create_arguments :dso :: STRING AS dso_party,
    -- Contract details
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :created_at :: timestamp_ntz AS created_at,
    -- Signatories and observers
    event_json :signatories AS signatories,
    event_json :observers AS observers,
    -- Full configuration for reference
    event_json :create_arguments :issuanceConfig AS issuance_config,
    -- Metadata
    event_json,
    {{ dbt_utils.generate_surrogate_key(['round_number']) }} AS fact_mining_round_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    mining_round_created_events
