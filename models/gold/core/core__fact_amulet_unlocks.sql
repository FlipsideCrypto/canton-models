{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['core']
) }}

-- Tracks unlocking/unstaking of locked amulets
-- When unlocked, creates a regular Amulet as child event
WITH unlock_events AS (
    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_index,
        choice,
        event_json,
        is_root_event
    FROM
        {{ ref('silver__events') }}
    WHERE
        choice IN (
            'LockedAmulet_OwnerExpireLock',
            'LockedAmulet_Unlock'
        )

    {% if is_incremental() %}
    AND modified_timestamp >= (
        SELECT MAX(modified_timestamp)
        FROM {{ this }}
    )
    {% endif %}
),

child_amulet_events AS (
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
        event_json:event_type::STRING = 'created_event'
        AND event_json:template_id::STRING LIKE '%:Amulet'
        AND NOT event_json:template_id::STRING LIKE '%LockedAmulet'

    {% if is_incremental() %}
    AND modified_timestamp >= (
        SELECT MAX(modified_timestamp)
        FROM {{ this }}
    )
    {% endif %}
)

SELECT
    a.update_id,
    a.migration_id,
    a.record_time,
    a.effective_at,
    a.event_id,
    a.event_index,
    a.choice,
    a.event_json:acting_parties AS acting_parties,

    -- Derived unlock action
    CASE
        WHEN a.choice = 'LockedAmulet_Unlock' THEN 'unlock'
        WHEN a.choice = 'LockedAmulet_OwnerExpireLock' THEN 'expire_lock'
    END AS unlock_action,

    -- Choice arguments
    a.event_json:choice_argument:openRoundCid::STRING AS open_round_cid,

    -- Exercise results from unlock
    a.event_json:exercise_result:amuletSum:amulet::STRING AS unlocked_amulet_cid,
    a.event_json:exercise_result:amuletSum:amuletPrice::NUMBER(38,10) AS amulet_price,
    a.event_json:exercise_result:amuletSum:round:number::NUMBER AS round_number,
    a.event_json:exercise_result:meta:values['splice.lfdecentralizedtrust.org/reason']::STRING AS unlock_reason,
    a.event_json:exercise_result:meta:values['splice.lfdecentralizedtrust.org/tx-kind']::STRING AS tx_kind,

    -- Details from child Amulet created event
    b.event_json:create_arguments:amount:initialAmount::NUMBER(38,10) AS unlocked_amount,
    b.event_json:create_arguments:amount:createdAt:number::NUMBER AS created_at_round,
    b.event_json:create_arguments:amount:ratePerRound:rate::NUMBER(38,10) AS rate_per_round,
    b.event_json:create_arguments:owner::STRING AS owner,
    b.event_json:created_at::TIMESTAMP_NTZ AS amulet_created_at,

    -- Contract details
    a.event_json:event_type::STRING AS event_type,
    a.event_json:contract_id::STRING AS locked_amulet_contract_id,
    a.event_json:consuming::BOOLEAN AS consuming,
    b.event_json:contract_id::STRING AS created_amulet_contract_id,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['a.event_id']) }} AS fact_amulet_unlocks_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    unlock_events a
LEFT JOIN child_amulet_events b
    ON a.update_id = b.update_id
    AND b.event_json:contract_id::STRING = a.event_json:exercise_result:amuletSum:amulet::STRING
WHERE
    a.is_root_event
