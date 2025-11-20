{{ config(
    materialized = 'incremental',
    unique_key = ['effective_at', 'migration_id','update_id'],
    cluster_by = ['effective_at::DATE', 'migration_id'],
    incremental_strategy = 'merge',
    tags = ['core']
) }}

WITH base_updates AS (

    SELECT
        update_id,
        migration_id,
        record_time,
        update_json,
        inserted_timestamp AS _inserted_timestamp
    FROM
        {{ ref('bronze__updates') }}

{% if is_incremental() %}
WHERE
    inserted_timestamp >= DATEADD(
        'minute',
        -5,(
            SELECT
                MAX(modified_timestamp)
            FROM
                {{ this }}
        )
    )
{% endif %}
)
SELECT
    update_id,
    migration_id,
    record_time,
    update_json :effective_at :: datetime AS effective_at,
    update_json :synchronizer_id :: STRING AS synchronizer_id,
    update_json :workflow_id :: STRING AS workflow_id,
    update_json :root_event_ids AS root_event_ids,
    object_keys(
        update_json :events_by_id
    ) event_ids,
    ARRAY_SIZE(event_ids) AS event_count,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base_updates qualify ROW_NUMBER() over (
        PARTITION BY update_id,
        migration_id
        ORDER BY
            _inserted_timestamp DESC
    ) = 1
