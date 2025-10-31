{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gov','non_core']
) }}

WITH sv_onboarding_expiration_events AS (

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
            'DsoRules_ExpireSvOnboardingRequest',
            'SvOnboardingRequest_Expire'
        )

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
    update_id,
    migration_id,
    record_time,
    effective_at,
    event_id,
    event_index,
    -- Choice details
    choice,
    CASE
        WHEN choice = 'DsoRules_ExpireSvOnboardingRequest' THEN 'dso_initiated'
        WHEN choice = 'SvOnboardingRequest_Expire' THEN 'contract_consumed'
    END AS expiration_type,
    event_json :acting_parties AS acting_parties,
    event_json :child_event_ids AS child_event_ids,
    event_json :consuming :: BOOLEAN AS consuming,
    -- Choice arguments (from DsoRules_ExpireSvOnboardingRequest)
    event_json :choice_argument :cid :: STRING AS expired_request_cid,
    event_json :choice_argument :sv :: STRING AS sv_party,
    -- Expired request contract ID (for SvOnboardingRequest_Expire, it's the contract_id itself)
    COALESCE(
        event_json :choice_argument :cid :: STRING,
        event_json :contract_id :: STRING
    ) AS onboarding_request_contract_id,
    -- Exercise result
    event_json :exercise_result :: STRING AS exercise_result,
    -- Contract details
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :interface_id :: STRING AS interface_id,
    -- Metadata
    event_json,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_sv_onboarding_expiration_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    sv_onboarding_expiration_events
