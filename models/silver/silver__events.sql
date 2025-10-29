{{ config(
    materialized = 'incremental',
    unique_key = ['effective_at', 'migration_id', 'event_id'],
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
    inserted_timestamp >= (
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
    update_json :effective_at :: datetime AS effective_at,
    update_json :root_event_ids AS root_event_ids,
    CASE
        WHEN ARRAY_CONTAINS(
            f.key :: variant,
            root_event_ids
        ) THEN TRUE
        ELSE FALSE
    END AS is_root_event,
    f.key :: STRING AS event_id,
    REPLACE(REPLACE(f.key, update_id), ':') :: INT AS event_index,
    f.value AS event_json,
    f.value :choice :: STRING AS choice,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    base_updates,
    LATERAL FLATTEN(
        input => update_json :events_by_id
    ) f
