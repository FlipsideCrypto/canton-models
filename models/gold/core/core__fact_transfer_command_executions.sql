{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    tags = ['core', 'transfers']
) }}

-- Tracks execution of transfer commands
-- Shows success/failure of transfers initiated through ExternalPartyAmuletRules
WITH transfer_command_executions AS (
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
        event_json:choice::STRING = 'TransferCommand_Send'

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

    -- Execution context
    event_json:choice_argument:context:amuletRules::STRING AS amulet_rules_cid,
    event_json:choice_argument:inputs AS transfer_inputs,
    event_json:choice_argument:transferCounterCid::STRING AS transfer_counter_cid,
    event_json:choice_argument:transferPreapprovalCidO::STRING AS transfer_preapproval_cid,

    -- Execution result
    event_json:exercise_result:nonce::STRING AS nonce,
    event_json:exercise_result:sender::STRING AS sender,
    event_json:exercise_result:result:tag::STRING AS result_status,

    -- Success details (when status = TransferCommandResultSuccess)
    event_json:exercise_result:result:value:result:round:number::NUMBER AS round_number,
    event_json:exercise_result:result:value:result:senderChangeAmulet::STRING AS sender_change_amulet_cid,
    event_json:exercise_result:result:value:result:createdAmulets AS created_amulets,
    ARRAY_SIZE(event_json:exercise_result:result:value:result:createdAmulets) AS created_amulets_count,
    event_json:exercise_result:result:value:result:meta AS transfer_meta,

    -- Contract details
    event_json:event_type::STRING AS event_type,
    event_json:contract_id::STRING AS contract_id,
    event_json:package_name::STRING AS package_name,
    event_json:template_id::STRING AS template_id,
    event_json:consuming::BOOLEAN AS consuming,

    -- Derived fields
    CASE
        WHEN event_json:exercise_result:result:tag::STRING = 'TransferCommandResultSuccess' THEN TRUE
        ELSE FALSE
    END AS is_successful,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_transfer_execution_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    transfer_command_executions
