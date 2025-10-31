{{ config(
    materialized = 'view',
    tags = ['gov', 'non_core']
) }}

{{ config(
    tests={
        "where": "most_recent_timestamp::DATE > dateadd(hour, -{{ var('TEST_HOURS_THRESHOLD', 36) }}, sysdate())"
    }
) }}

WITH requests AS (
    SELECT
        onboarding_request_contract_id,
        effective_at AS request_created_at,
        candidate_name,
        candidate_party,
        candidate_participant_id,
        sponsor AS request_sponsor,
        onboarding_token,
        event_id AS request_event_id,
        contract_id,
        ROW_NUMBER() OVER (
            PARTITION BY candidate_party
            ORDER BY effective_at ASC
        ) AS request_index,
        inserted_timestamp,
        modified_timestamp
    FROM
        {{ ref('gov__fact_validator_onboarding_requests') }}
),
onboarding_events AS (
    SELECT
        effective_at AS onboarded_at,
        validator_party,
        validator_name,
        onboarding_type,
        contact_point,
        sponsor,
        version,
        validator_license,
        sv_onboarding_confirmed,
        sv_party,
        sv_name,
        sv_participant_id,
        sv_reward_weight,
        event_id AS onboarding_event_id,
        contract_id,
        inserted_timestamp,
        modified_timestamp
    FROM
        {{ ref('gov__fact_validator_onboarding_events') }}
),
base AS (
    SELECT
        COALESCE(r.onboarding_request_contract_id, onb.sv_onboarding_confirmed) AS onboarding_request_contract_id,
        COALESCE(onb.sv_party, onb.validator_party, r.candidate_party) AS validator_party,
        r.request_created_at,
        r.candidate_name,
        r.candidate_party,
        r.candidate_participant_id,
        r.request_sponsor,
        r.onboarding_token,
        r.request_event_id,
        onb.onboarded_at,
        onb.validator_name,
        onb.onboarding_type,
        onb.contact_point,
        onb.sponsor AS onboarding_sponsor,
        onb.version,
        onb.validator_license,
        onb.sv_party,
        onb.sv_name,
        onb.sv_participant_id,
        onb.sv_reward_weight,
        onb.onboarding_event_id,
        greatest(r.inserted_timestamp,onb.inserted_timestamp) AS inserted_timestamp,
        greatest(r.modified_timestamp,onb.modified_timestamp) AS modified_timestamp
        
    FROM
        requests r
        FULL OUTER JOIN onboarding_events onb ON r.candidate_party = onb.validator_party and r.contract_id = onb.contract_id
        WHERE r.candidate_party is null or r.request_index = 1
),
expirations AS (
    SELECT
        onboarding_request_contract_id,
        effective_at AS expired_at,
        expiration_type,
        choice AS expiration_choice,
        event_id AS expiration_event_id
    FROM
        {{ ref('gov__fact_validator_onboarding_request_expirations') }}
    WHERE
        expiration_type = 'dso_initiated' -- Only get the parent event, not the consumed contract
),
offboarding AS (
    SELECT
        offboarded_sv_party,
        effective_at AS offboarded_at,
        event_id AS offboarding_event_id
    FROM
        {{ ref('gov__fact_validator_offboarding_events') }}
),
combined AS (
    SELECT
        -- Validator identification
        b.validator_party,
        COALESCE(b.validator_name, b.candidate_name) AS validator_name,
        COALESCE(b.onboarding_type,'super_validator') as validator_type,
        -- Request details
        b.onboarding_request_contract_id,
        b.request_created_at,
        {# b.candidate_name,
        b.candidate_party, #}
        {# b.candidate_participant_id, #}
        b.request_sponsor,
        {# b.onboarding_token, #}
        b.request_event_id,
        -- Onboarding details
        b.onboarded_at,
        b.contact_point,
        b.onboarding_sponsor,
        b.version,
        b.validator_license,
        {# b.sv_party,
        b.sv_name, #}
        {# b.sv_participant_id, #}
        b.sv_reward_weight,
        b.onboarding_event_id,
        -- Expiration details
        e.expired_at,
        e.expiration_type,
        e.expiration_choice,
        e.expiration_event_id,
        -- Offboarding details
        o.offboarded_at,
        o.offboarding_event_id,
        -- Status and timing
        CASE
            WHEN o.offboarded_at IS NOT NULL THEN 'offboarded'
            WHEN b.onboarded_at IS NOT NULL THEN 'active'
            WHEN e.expired_at IS NOT NULL THEN 'request_expired'
            WHEN b.request_created_at IS NOT NULL THEN 'request_pending'
            ELSE 'unknown'
        END AS validator_status,
        CASE
            WHEN b.request_created_at IS NOT NULL AND b.onboarded_at IS NOT NULL
            THEN DATEDIFF('day', b.request_created_at, b.onboarded_at)
        END AS days_from_request_to_onboarding,
        CASE
            WHEN o.offboarded_at IS NOT NULL AND b.onboarded_at IS NOT NULL
            THEN DATEDIFF('day', b.onboarded_at, o.offboarded_at)
        END AS days_active_before_offboarding,
        CASE
            WHEN o.offboarded_at IS NULL AND b.onboarded_at IS NOT NULL
            THEN DATEDIFF('day', b.onboarded_at, CURRENT_TIMESTAMP())
        END AS days_active_current,
        -- Most recent timestamp for this record
        GREATEST(
            COALESCE(b.request_created_at, '1900-01-01'::TIMESTAMP_NTZ),
            COALESCE(b.onboarded_at, '1900-01-01'::TIMESTAMP_NTZ),
            COALESCE(e.expired_at, '1900-01-01'::TIMESTAMP_NTZ),
            COALESCE(o.offboarded_at, '1900-01-01'::TIMESTAMP_NTZ)
        ) AS most_recent_timestamp
        b.inserted_timestamp,
        b.modified_timestamp
    FROM
        base b
        LEFT JOIN expirations e ON e.onboarding_request_contract_id = b.onboarding_request_contract_id
        LEFT JOIN offboarding o ON o.offboarded_sv_party = b.validator_party
)
SELECT
    *,
    CASE
        -- If onboarded and not offboarded, this is the current active validator
        WHEN onboarded_at IS NOT NULL AND offboarded_at IS NULL THEN TRUE
        -- Otherwise, check if this is the most recent record for this validator
        WHEN most_recent_timestamp = MAX(most_recent_timestamp) OVER (
            PARTITION BY validator_party, validator_name
        ) THEN TRUE
        ELSE FALSE
    END AS is_current,
    {{ dbt_utils.generate_surrogate_key(['validator_party']) }} AS ez_validator_onboarding_lifecycle_id
FROM
    combined
