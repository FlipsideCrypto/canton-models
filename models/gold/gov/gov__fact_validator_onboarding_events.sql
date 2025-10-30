{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gov','non_core']
) }}

WITH validator_onboarding_events AS (

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
            'DsoRules_OnboardValidator',
            'DsoRules_ConfirmSvOnboarding'
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
        WHEN choice = 'DsoRules_OnboardValidator' THEN 'validator'
        WHEN choice = 'DsoRules_ConfirmSvOnboarding' THEN 'super_validator'
    END AS onboarding_type,
    event_json :acting_parties AS acting_parties,
    event_json :child_event_ids AS child_event_ids,
    event_json :consuming :: BOOLEAN AS consuming,
    -- Common fields (unified across both types)
    COALESCE(
        event_json :choice_argument :validator :: STRING,
        event_json :choice_argument :newSvParty :: STRING
    ) AS validator_party,
    COALESCE(
        event_json :choice_argument :validator :: STRING,
        event_json :choice_argument :newSvName :: STRING
    ) AS validator_name,
    -- Validator-specific fields
    event_json :choice_argument :contactPoint :: STRING AS contact_point,
    event_json :choice_argument :sponsor :: STRING AS sponsor,
    event_json :choice_argument :version :: STRING AS version,
    event_json :exercise_result :validatorLicense :: STRING AS validator_license,
    -- Super Validator-specific fields
    event_json :choice_argument :newParticipantId :: STRING AS sv_participant_id,
    event_json :choice_argument :newSvParty :: STRING AS sv_party,
    event_json :choice_argument :newSvName :: STRING AS sv_name,
    event_json :choice_argument :newSvRewardWeight :: NUMBER(38, 10) AS sv_reward_weight,
    event_json :choice_argument :reason :: STRING AS sv_onboarding_reason,
    event_json :exercise_result :onboardingConfirmed :: STRING AS sv_onboarding_confirmed,
    -- Contract details
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :interface_id :: STRING AS interface_id,
    -- Metadata
    event_json,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_validator_onboarding_event_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    validator_onboarding_events
