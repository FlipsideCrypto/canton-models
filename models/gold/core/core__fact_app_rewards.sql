{{ config(
    materialized = 'incremental',
    unique_key = [ 'event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['core']
) }}
WITH app_reward_events AS (

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
        choice = 'AppRewardCoupon_DsoExpire'

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
    choice,
    event_json :acting_parties AS acting_parties,
    event_json :choice_argument :closedRoundCid :: STRING AS closed_round_cid,
     event_json:exercise_result:amount::NUMBER(38,10) AS reward_amount,
    event_json :exercise_result :featured :: BOOLEAN AS is_featured_app,
    event_json :contract_id :: STRING AS contract_id,
    event_json :template_id :: STRING AS template_id,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_app_reward_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    app_reward_events
