{{ config(
    materialized = 'incremental',
    unique_key = ['event_id', 'output_index'],
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
        choice = 'AmuletRules_Transfer'

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
    -- Event identifiers
    t.update_id,
    t.migration_id,
    t.record_time,
    t.effective_at,
    t.event_id,
    t.event_index,
    t.choice,
    -- Output identification
    output.index :: INTEGER AS output_index,
    -- Transfer parties
    t.event_json :choice_argument :transfer :sender :: STRING AS sender,
    t.event_json :choice_argument :transfer :provider :: STRING AS provider,
    COALESCE(
        output.value :receiver :: STRING,
        t.event_json :choice_argument :transfer :sender :: STRING
    ) AS receiver,
    -- Output details
    COALESCE(output.value :amount :: NUMBER(38, 10), 0) AS amount,
    output.value :receiverFeeRatio :: NUMBER(
        38,
        10
    ) AS receiver_fee_ratio,
    output.value :lock AS LOCK,
    -- Transfer metadata
    t.event_json :exercise_result :meta :values :"splice.lfdecentralizedtrust.org/tx-kind" :: STRING AS tx_kind,
    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['t.event_id', 'output.index']) }} AS fact_transfer_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    transfer_events t,
    LATERAL FLATTEN(
        input => t.event_json :choice_argument :transfer :outputs
    ) AS output
