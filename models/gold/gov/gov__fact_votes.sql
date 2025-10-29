{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    tags = ['gov']
) }}

WITH vote_events AS (

    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_json,
        is_root_event,
        _inserted_timestamp
    FROM
        {{ ref('silver__events') }}
    WHERE
        (
            event_json :create_arguments :trackingCid IS NOT NULL
            OR event_json :choice :: STRING IN (
                'DsoRules_CastVote',
                'DsoRules_RequestVote'
            )
        )

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
) --Votes
SELECT
    A.update_id,
    A.migration_id,
    A.record_time,
    A.effective_at,
    A.event_id,
    A.event_json :choice :: STRING AS choice,
    A.event_json :choice_argument :requestCid :: STRING AS request_cid,
    b.event_json :create_arguments :trackingCid :: STRING AS tracking_cid,
    -- Vote count from VoteRequest
    A.event_json :choice_argument :vote :sv :: STRING AS sv,
    A.event_json :choice_argument :vote :accept :: BOOLEAN AS accept,
    A.event_json :choice_argument :vote :optCastAt :: timestamp_ntz AS opt_cast_at,
    A.event_json :choice_argument :vote :reason AS reason,
    A.event_json :contract_id :: STRING AS contract_id,
    A.event_json :exercise_result :voteRequest :: STRING AS vote_request_cid,
    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['a.event_id']) }} AS fact_vote_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    vote_events A
    LEFT JOIN vote_events b
    ON A.update_id = b.update_id
    AND NOT b.is_root_event
WHERE
    A.is_root_event
    AND A.event_json :choice :: STRING = 'DsoRules_CastVote'
UNION ALL
    --Vote Requests (contains the initial vote)
SELECT
    A.update_id,
    A.migration_id,
    A.record_time,
    A.effective_at,
    A.event_id,
    A.event_json :choice :: STRING AS choice,
    A.event_json :exercise_result :voteRequest :: STRING AS request_cid,
    A.event_json :exercise_result :voteRequest :: STRING AS tracking_cid,
    b.event_json :create_arguments :votes [0] [1] :sv :: STRING AS sv,
    b.event_json :create_arguments :votes [0] [1] :accept :: BOOLEAN AS accept,
    b.event_json :create_arguments :votes [0] [1] :optCastAt :: timestamp_ntz AS opt_cast_at,
    b.event_json :create_arguments :votes [0] [1] :reason AS reason,
    A.event_json :contract_id :: STRING AS contract_id,
    A.event_json :exercise_result :voteRequest :: STRING AS vote_request_cid,
    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['a.event_id']) }} AS fact_vote_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    vote_events A
    LEFT JOIN vote_events b
    ON A.update_id = b.update_id
    AND NOT b.is_root_event
WHERE
    A.is_root_event
    AND A.event_json :choice :: STRING = 'DsoRules_RequestVote'
