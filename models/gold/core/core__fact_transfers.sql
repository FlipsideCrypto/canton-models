{{ config(
    materialized = 'incremental',
    unique_key = ['effective_at', 'migration_id', 'event_id'],
    cluster_by = ['effective_at::DATE', 'migration_id'],
    incremental_strategy = 'merge',
    tags = ['core']
) }}

WITH transfer_events AS (
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
            'AmuletRules_Transfer',
            'TransferCommand_Send',
            'TransferFactory_Transfer',
            'TransferPreapproval_Send'
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

    -- Choice arguments (extracted from various nested levels depending on choice)
    COALESCE(
        event_json:choice_argument:amount::NUMBER(38,10),
        event_json:choice_argument:transfer:inputs[0]:value:amount::NUMBER(38,10)
    ) AS amount,

    COALESCE(
        event_json:choice_argument:sender::STRING,
        event_json:choice_argument:transfer:sender::STRING,
        event_json:exercise_result:sender::STRING
    ) AS sender,

    COALESCE(
        event_json:choice_argument:receiver::STRING,
        event_json:choice_argument:transfer:outputs[0]:receiver::STRING
    ) AS receiver,

    COALESCE(
        event_json:choice_argument:provider::STRING,
        event_json:choice_argument:transfer:provider::STRING
    ) AS provider,

    event_json:choice_argument:delegate::STRING AS delegate,
    event_json:choice_argument:description::STRING AS description,
    event_json:choice_argument:nonce::STRING AS nonce,
    event_json:choice_argument:expiresAt::TIMESTAMP_NTZ AS expires_at,
    event_json:choice_argument:expectedDso::STRING AS expected_dso,

    -- Full context and transfer objects for detailed analysis
    event_json:choice_argument:context AS context,
    event_json:choice_argument:transfer AS transfer_object,

    -- Exercise results
    event_json:exercise_result:transferCommandCid::STRING AS transfer_command_cid,
    event_json:exercise_result:transferPreapprovalCid::STRING AS transfer_preapproval_cid,
    COALESCE(
        event_json:exercise_result:amuletPaid::NUMBER(38,10),
        event_json:exercise_result:summary:inputAmuletAmount::NUMBER(38,10)
    ) AS amulet_amount,
    event_json:exercise_result:summary AS transfer_summary,
    event_json:exercise_result:meta AS transfer_meta,

    -- Contract details
    event_json:event_type::STRING AS event_type,
    event_json:contract_id::STRING AS contract_id,
    event_json:package_name::STRING AS package_name,
    event_json:template_id::STRING AS template_id,
    event_json:consuming::BOOLEAN AS consuming,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_transfer_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    transfer_events
