{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    tags = ['core', 'staking']
) }}

-- Tracks locking/staking of amulets
-- Captures when LockedAmulet contracts are created
WITH locked_amulet_creations AS (
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
        event_json:event_type::STRING = 'created_event'
        AND event_json:template_id::STRING LIKE '%LockedAmulet'

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

    -- Lock details from create_arguments
    event_json:create_arguments:amulet:amount:initialAmount::NUMBER(38,10) AS locked_amount,
    event_json:create_arguments:amulet:amount:createdAt:number::NUMBER AS amount_created_at_round,
    event_json:create_arguments:amulet:amount:ratePerRound:rate::NUMBER(38,10) AS rate_per_round,
    event_json:create_arguments:amulet:owner::STRING AS amulet_owner,
    event_json:create_arguments:lock AS lock_details,
    event_json:create_arguments:lock:expiresAt::TIMESTAMP_NTZ AS lock_expires_at,
    event_json:create_arguments:lock:holders AS lock_holders,

    -- Contract details
    event_json:contract_id::STRING AS locked_amulet_contract_id,
    event_json:created_at::TIMESTAMP_NTZ AS created_at,
    event_json:signatories AS signatories,
    event_json:observers AS observers,
    event_json:package_name::STRING AS package_name,
    event_json:template_id::STRING AS template_id,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_lock_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    locked_amulet_creations
