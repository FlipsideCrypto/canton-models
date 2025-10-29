{{ config(
    materialized = 'incremental',
    unique_key = ['effective_at', 'migration_id', 'event_id'],
    cluster_by = ['effective_at::DATE', 'migration_id'],
    incremental_strategy = 'merge',
    tags = ['gov']
) }}

WITH validator_activity_events AS (
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
            'ValidatorLicense_ReportActive',
            'ValidatorLicense_RecordValidatorLivenessActivity',
            'ValidatorLivenessActivityRecord_DsoExpire'
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

    -- Derived activity type
    CASE
        WHEN event_json:choice::STRING = 'ValidatorLicense_ReportActive' THEN 'report_active'
        WHEN event_json:choice::STRING = 'ValidatorLicense_RecordValidatorLivenessActivity' THEN 'record_activity'
        WHEN event_json:choice::STRING = 'ValidatorLivenessActivityRecord_DsoExpire' THEN 'activity_expired'
    END AS activity_type,

    -- Choice arguments
    event_json:choice_argument AS choice_argument,
    event_json:choice_argument:closedRoundCid::STRING AS closed_round_cid,

    -- Exercise results
    event_json:exercise_result AS exercise_result,
    event_json:exercise_result:livenessRecordCid::STRING AS liveness_record_cid,

    -- Contract details
    event_json:event_type::STRING AS event_type,
    event_json:contract_id::STRING AS contract_id,
    event_json:package_name::STRING AS package_name,
    event_json:template_id::STRING AS template_id,
    event_json:consuming::BOOLEAN AS consuming,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_validator_activity_id,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    validator_activity_events
