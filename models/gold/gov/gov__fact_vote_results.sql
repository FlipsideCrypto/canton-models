{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    incremental_strategy = 'merge',
    tags = ['gov', 'non_core']
) }}

-- Tracks DSO governance vote results/outcomes
-- Shows final outcomes of vote requests including acceptance/rejection and vote counts
WITH vote_result_events AS (
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
        choice = 'DsoRules_CloseVoteRequest'

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
    event_json:acting_parties AS acting_parties,

    -- Choice arguments
    event_json:choice_argument:requestCid::STRING AS request_cid,
    event_json:choice_argument:amuletRulesCid::STRING AS amulet_rules_cid,
    event_json:choice_argument:sv::STRING AS closing_sv,

    -- Vote outcome
    event_json:exercise_result:outcome:tag::STRING AS outcome,
    event_json:exercise_result:outcome:value:effectiveAt::TIMESTAMP_NTZ AS outcome_effective_at,
    event_json:exercise_result:completedAt::TIMESTAMP_NTZ AS completed_at,
    ARRAY_AGG(
            CASE
                WHEN v.value[1]:accept::BOOLEAN = TRUE
                THEN v.value[0]::STRING
            END
        ) WITHIN GROUP (ORDER BY v.index) AS accepted_svs,
    ARRAY_AGG(
            CASE
                WHEN v.value[1]:accept::BOOLEAN = FALSE
                THEN v.value[0]::STRING
            END
        ) WITHIN GROUP (ORDER BY v.index) as rejected_svs,
    event_json:exercise_result:abstainingSvs AS abstaining_svs,
    event_json:exercise_result:offboardedVoters AS offboarded_voters,

    -- Original request details (embedded in result)
    event_json:exercise_result:request:trackingCid::STRING AS tracking_cid,
    event_json:exercise_result:request:requester::STRING AS requester,
    event_json:exercise_result:request:targetEffectiveAt::TIMESTAMP_NTZ AS target_effective_at,
    event_json:exercise_result:request:voteBefore::TIMESTAMP_NTZ AS vote_before,

    -- Action details
    event_json:exercise_result:request:action:tag::STRING AS action,
    event_json:exercise_result:request:action:value:dsoAction:tag::STRING AS dso_action,
    event_json:exercise_result:request:action:value:amuletRulesAction:tag::STRING AS amulet_rules_action,
    event_json:exercise_result:request:action:value:dsoAction:value AS dso_action_value,
    event_json:exercise_result:request:action:value:amuletRulesAction:value AS amulet_rules_value,

    -- Reason
    event_json:exercise_result:request:reason:body::STRING AS reason_body,
    event_json:exercise_result:request:reason:url::STRING AS reason_url,

    -- Vote statistics
    ARRAY_SIZE(event_json:exercise_result:request:votes) AS total_votes_cast,
    ARRAY_SIZE(event_json:exercise_result:abstainingSvs) AS abstaining_count,
    ARRAY_SIZE(event_json:exercise_result:offboardedVoters) AS offboarded_count,

    -- Vote tallies (calculated from votes array)
    ARRAY_SIZE(
        ARRAY_AGG(
            CASE
                WHEN v.value[1]:accept::BOOLEAN = TRUE
                THEN v.value[0]::STRING
            END
        ) WITHIN GROUP (ORDER BY v.index)
    ) AS accept_votes,
    ARRAY_SIZE(
        ARRAY_AGG(
            CASE
                WHEN v.value[1]:accept::BOOLEAN = FALSE
                THEN v.value[0]::STRING
            END
        ) WITHIN GROUP (ORDER BY v.index)
    ) AS reject_votes,

    -- Contract details
    event_json:contract_id::STRING AS contract_id,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_vote_result_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    event_json
FROM
    vote_result_events,
    LATERAL FLATTEN(input => event_json:exercise_result:request:votes, outer => true) v
GROUP BY
    update_id,
    migration_id,
    record_time,
    effective_at,
    event_id,
    event_index,
    choice,
    event_json
 
