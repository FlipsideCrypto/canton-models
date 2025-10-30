{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['rewards']
) }}

WITH app_reward_coupon_events AS (

    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_index,
        event_json
    FROM
        {{ ref('silver__events') }}
    WHERE
        event_json :event_type :: STRING = 'created_event'
        AND event_json :template_id :: STRING LIKE '%AppRewardCoupon'

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
    -- Reward details
    event_json :create_arguments :amount :: NUMBER(38, 10) AS coupon_amount,
    event_json :create_arguments :provider :: STRING AS app_provider,
    event_json :create_arguments :beneficiary :: STRING AS beneficiary,
    event_json :create_arguments :featured :: BOOLEAN AS is_featured_app,
    event_json :create_arguments :round :number :: NUMBER AS round_number,
    event_json :create_arguments :dso :: STRING AS dso_party,
    -- Contract details
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS coupon_contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :created_at :: TIMESTAMP_NTZ AS created_at,
    -- Signatories and observers
    event_json :signatories AS signatories,
    event_json :observers AS observers,
    -- Metadata
    event_json,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_app_reward_coupon_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    app_reward_coupon_events
