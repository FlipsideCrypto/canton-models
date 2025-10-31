{{ config(
    materialized = 'view',
    tags = ['core']
) }}

SELECT
    update_id,
    migration_id,
    record_time,
    effective_at,
    event_id,
    event_index,
    is_root_event,
    -- Event type and structure
    event_json :event_type :: STRING AS event_type,
    choice,
    event_json :consuming :: BOOLEAN AS consuming,
    -- Contract identification
    event_json :contract_id :: STRING AS contract_id,
    event_json :template_id :: STRING AS template_id,
    event_json :package_name :: STRING AS package_name,
    event_json :interface_id :: STRING AS interface_id,
    -- Parties
    event_json :acting_parties AS acting_parties,
    event_json :signatories AS signatories,
    event_json :observers AS observers,
    -- Event relationships
    event_json :child_event_ids AS child_event_ids,
    -- Timestamps
    event_json :created_at :: TIMESTAMP_NTZ AS created_at,
    -- Full JSON for detailed analysis
    event_json :choice_argument AS choice_argument,
    event_json :exercise_result AS exercise_result,
    event_json :create_arguments AS create_arguments,
    event_json,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_event_id,
   inserted_timestamp,
   modified_timestamp
FROM
    {{ ref('silver__events') }} 