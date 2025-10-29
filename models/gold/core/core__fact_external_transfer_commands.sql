{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    tags = ['core', 'transfers']
) }}

-- Tracks external party transfer commands
-- These are transfers initiated by external parties through a validator delegate
WITH external_transfer_commands AS (
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
        event_json:choice::STRING = 'ExternalPartyAmuletRules_CreateTransferCommand'

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

    -- Transfer command details
    event_json:choice_argument:amount::NUMBER(38,10) AS transfer_amount,
    event_json:choice_argument:sender::STRING AS sender,
    event_json:choice_argument:receiver::STRING AS receiver,
    event_json:choice_argument:delegate::STRING AS validator_delegate,
    event_json:choice_argument:nonce::STRING AS nonce,
    event_json:choice_argument:expiresAt::TIMESTAMP_NTZ AS expires_at,
    event_json:choice_argument:description::STRING AS description,
    event_json:choice_argument:expectedDso::STRING AS expected_dso,

    -- Exercise result
    event_json:exercise_result:transferCommandCid::STRING AS transfer_command_cid,

    -- Contract details
    event_json:event_type::STRING AS event_type,
    event_json:contract_id::STRING AS contract_id,
    event_json:package_name::STRING AS package_name,
    event_json:template_id::STRING AS template_id,
    event_json:consuming::BOOLEAN AS consuming,

    -- Derived fields
    DATEDIFF('second', effective_at, expires_at) AS expiration_seconds,
    CASE
        WHEN expires_at < CURRENT_TIMESTAMP() THEN TRUE
        ELSE FALSE
    END AS is_expired,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_external_transfer_command_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    external_transfer_commands
