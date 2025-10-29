{{ config(
    materialized = 'incremental',
    unique_key = [ 'event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    incremental_strategy = 'merge',
    tags = ['gov','non_core']
) }}

-- Tracks DSO governance vote requests/proposals
-- Captures proposals for various DSO actions like granting featured app rights, updating rules, etc.
WITH vote_request_events AS (
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
        event_json:choice::STRING = 'DsoRules_RequestVote'

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

    -- Requester and timing
    event_json:choice_argument:requester::STRING AS requester,
    event_json:choice_argument:targetEffectiveAt::TIMESTAMP_NTZ AS target_effective_at,
    event_json:choice_argument:voteRequestTimeout:microseconds::NUMBER AS vote_timeout_microseconds,

    -- Action details
    event_json:choice_argument:action:tag::STRING AS action,
 
    event_json:choice_argument:action:value:dsoAction:tag::STRING AS dso_action,
    event_json:choice_argument:action:value:dsoAction:value AS dso_action_value,
        event_json:choice_argument:action:value:amuletRulesAction:tag::STRING AS amulet_rules_action,
    event_json:choice_argument:action:value:amuletRulesAction:value AS amulet_rules_value,

    -- Reason for the proposal
    event_json:choice_argument:reason:body::STRING AS reason_body,
    event_json:choice_argument:reason:url::STRING AS reason_url,

    -- Exercise result
    event_json:exercise_result:voteRequest::STRING AS vote_request_cid,

    -- Contract details
     event_json:contract_id::STRING AS contract_id,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_vote_request_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    vote_request_events
