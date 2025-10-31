{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gov','non_core']
) }}

WITH validator_activity_events AS (
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
        choice IN (
            'ValidatorLicense_ReportActive', --sv
            'ValidatorLicense_RecordValidatorLivenessActivity' --normal
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
    event_index,
    choice,
    event_json:acting_parties[0] AS validator_party,
    case when choice = 'ValidatorLicense_ReportActive'  then 'super_validator' else 'validator' end as validator_type,

    -- Choice arguments
    event_json:choice_argument:openRoundCid::STRING AS open_round_cid,
    event_json:choice_argument:closedRoundCid::STRING AS closed_round_cid,

    -- Exercise results
    event_json:exercise_result:couponCid::STRING AS coupon_cid,
    event_json:exercise_result:licenseCid::STRING AS license_cid,

    -- Contract details
    event_json:contract_id::STRING AS contract_id,
    event_json:template_id::STRING AS template_id,
event_json,
    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_validator_activity_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    validator_activity_events
