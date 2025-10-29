{{ config(
    materialized = 'incremental',
    unique_key = ['effective_at', 'migration_id', 'event_id'],
    cluster_by = ['effective_at::DATE', 'migration_id'],
    incremental_strategy = 'merge',
    tags = ['core']
) }}

WITH transfer_instruction_events AS (
    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_json,
        _inserted_timestamp
    FROM
        {{ ref('silver__events') }}
    WHERE
        event_json:choice::STRING IN (
            'TransferInstruction_Accept',
            'TransferInstruction_Reject',
            'TransferInstruction_Withdraw'
        )

    {% if is_incremental() %}
    AND modified_timestamp >= (
        SELECT MAX(modified_timestamp)
        FROM {{ this }}
    )
    {% endif %}
)

SELECT
    update_id,
    migration_id,
    record_time,
    effective_at,
    event_id,
    event_json:choice::STRING AS choice,
    event_json:acting_parties AS acting_parties,

    -- Derived instruction status
    CASE
        WHEN event_json:choice::STRING = 'TransferInstruction_Accept' THEN 'accepted'
        WHEN event_json:choice::STRING = 'TransferInstruction_Reject' THEN 'rejected'
        WHEN event_json:choice::STRING = 'TransferInstruction_Withdraw' THEN 'withdrawn'
    END AS instruction_status,

    -- Choice arguments
    event_json:choice_argument AS choice_argument,

    -- Exercise results
    event_json:exercise_result AS exercise_result,
    event_json:exercise_result:transferResult AS transfer_result,

    -- Contract details
    event_json:event_type::STRING AS event_type,
    event_json:contract_id::STRING AS contract_id,
    event_json:package_name::STRING AS package_name,
    event_json:template_id::STRING AS template_id,
    event_json:consuming::BOOLEAN AS consuming,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_transfer_instruction_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    transfer_instruction_events
