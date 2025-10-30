{{ config(
    materialized = 'incremental',
    unique_key = ['event_id', 'party'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['core']
) }}

WITH transfer_events AS (

    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_index,
        choice,
        event_json
    FROM
        {{ ref('silver__events') }}
    WHERE
        event_json :exercise_result :summary :balanceChanges IS NOT NULL

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
),
flattened_balance_changes AS (
    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_index,
        choice,
        event_json,
        bc.value AS balance_change_array
    FROM
        transfer_events,
        LATERAL FLATTEN(
            input => event_json :exercise_result :summary :balanceChanges
        ) bc
)
SELECT
    update_id,
    migration_id,
    record_time,
    effective_at,
    event_id,
    event_index,
    choice,
    event_json :acting_parties AS acting_parties,
    balance_change_array [0] :: STRING AS party,
    balance_change_array [1] :changeToHoldingFeesRate :: NUMBER(
        38,
        10
    ) AS change_to_holding_fees_rate,
    balance_change_array [1] :changeToInitialAmountAsOfRoundZero :: NUMBER(
        38,
        10
    ) AS change_to_initial_amount,
    event_json :exercise_result :summary :amuletPrice :: NUMBER(
        38,
        10
    ) AS amulet_price,
    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id', 'party']) }} AS fact_balance_change_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    flattened_balance_changes
