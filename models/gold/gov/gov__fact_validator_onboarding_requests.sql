{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gov','non_core']
) }}

WITH sv_onboarding_request_events AS (

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
        choice = 'DsoRules_StartSvOnboarding'

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
    event_json :acting_parties AS acting_parties,
    event_json :child_event_ids AS child_event_ids,
    event_json :consuming :: BOOLEAN AS consuming,
    -- Candidate information
    event_json :choice_argument :candidateName :: STRING AS candidate_name,
    event_json :choice_argument :candidateParticipantId :: STRING AS candidate_participant_id,
    event_json :choice_argument :candidateParty :: STRING AS candidate_party,
    -- Sponsorship
    event_json :choice_argument :sponsor :: STRING AS sponsor,
    -- Onboarding token (JWT)
    event_json :choice_argument :token :: STRING AS onboarding_token,
    -- Exercise result
    event_json :exercise_result :onboardingRequest :: STRING AS onboarding_request_contract_id,
    -- Contract details
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :interface_id :: STRING AS interface_id,
    -- Metadata
    event_json,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_sv_onboarding_request_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    sv_onboarding_request_events
