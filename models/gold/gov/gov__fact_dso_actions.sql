{{ config(
    materialized = 'incremental',
    unique_key = ['effective_at', 'migration_id', 'event_id'],
    cluster_by = ['effective_at::DATE', 'migration_id'],
    incremental_strategy = 'merge',
    tags = ['gov']
) }}

WITH dso_action_events AS (
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
            'DsoRules_ConfirmAction',
            'DsoRules_ExecuteConfirmedAction',
            'DsoRules_ExpireStaleConfirmation'
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

    -- Derived action status
    CASE
        WHEN event_json:choice::STRING = 'DsoRules_ConfirmAction' THEN 'confirmed'
        WHEN event_json:choice::STRING = 'DsoRules_ExecuteConfirmedAction' THEN 'executed'
        WHEN event_json:choice::STRING = 'DsoRules_ExpireStaleConfirmation' THEN 'expired'
    END AS action_status,

    -- Choice arguments
    event_json:choice_argument AS choice_argument,
    event_json:choice_argument:action AS action,

    -- Exercise results
    event_json:exercise_result AS exercise_result,
    event_json:exercise_result:confirmationCid::STRING AS confirmation_cid,

    -- Contract details
    event_json:event_type::STRING AS event_type,
    event_json:contract_id::STRING AS contract_id,
    event_json:package_name::STRING AS package_name,
    event_json:template_id::STRING AS template_id,
    event_json:consuming::BOOLEAN AS consuming,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_dso_action_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    dso_action_events
