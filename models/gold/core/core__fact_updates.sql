{{ config(
    materialized = 'view',
    tags = ['core']
) }}

SELECT
    update_id,
    migration_id,
    record_time,
    effective_at,
    -- Update structure
    synchronizer_id,
    workflow_id,
    -- Event information
    root_event_ids,
    event_count,
    {{ dbt_utils.generate_surrogate_key(['update_id']) }} AS fact_update_id,
    inserted_timestamp,
    modified_timestamp
FROM
    {{ ref('silver__updates') }}
