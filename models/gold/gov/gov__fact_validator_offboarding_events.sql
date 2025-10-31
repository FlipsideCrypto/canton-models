{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gov','non_core']
) }}

WITH validator_offboarding_events AS (

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
        choice = 'DsoRules_OffboardSv'

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
    -- Choice argument
    event_json :choice_argument :sv :: STRING AS offboarded_sv_party,
    -- Exercise result
    event_json :exercise_result :newDsoRules :: STRING AS new_dso_rules_contract_id,
    -- Contract details
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :interface_id :: STRING AS interface_id,
    -- Metadata
    event_json,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_validator_offboarding_event_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    validator_offboarding_events
