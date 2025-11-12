{{ config (
    materialized = 'incremental',
    cluster_by = ['record_time::DATE', 'migration_id','inserted_timestamp::DATE'],
    tags = ['bronze_core']
) }}

WITH max_record_time AS (

    SELECT
        GREATEST(MAX(record_time), '2025-10-21') max_record_time,
        to_varchar(
            max_record_time,
            'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"'
        ) AS max_time_string,
        MAX(migration_id) AS max_migration_id
    FROM

{% if is_incremental() %}
{{ this }}
WHERE
    record_time :: DATE <= '2025-10-26'
{% else %}
    (
        SELECT
            '2024-10-21' :: datetime AS record_time,
            3 AS migration_id
    )
{% endif %}
),
l1 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'max_record_time'
    ) }}
),
l1_flat AS ({{ canton_api_flatten_response('l1') }}),
l1_max AS ({{ canton_api_max_record_time('l1_flat') }}),
l2 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l1_max'
    ) }}
),
l2_flat AS ({{ canton_api_flatten_response('l2') }}),
l2_max AS ({{ canton_api_max_record_time('l2_flat') }}),
l3 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l2_max'
    ) }}
),
l3_flat AS ({{ canton_api_flatten_response('l3') }}),
l3_max AS ({{ canton_api_max_record_time('l3_flat') }}),
l4 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l3_max'
    ) }}
),
l4_flat AS ({{ canton_api_flatten_response('l4') }}),
l4_max AS ({{ canton_api_max_record_time('l4_flat') }}),
l5 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l4_max'
    ) }}
),
l5_flat AS ({{ canton_api_flatten_response('l5') }}),
l5_max AS ({{ canton_api_max_record_time('l5_flat') }}),
l6 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l5_max'
    ) }}
),
l6_flat AS ({{ canton_api_flatten_response('l6') }}),
l6_max AS ({{ canton_api_max_record_time('l6_flat') }}),
l7 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l6_max'
    ) }}
),
l7_flat AS ({{ canton_api_flatten_response('l7') }}),
l7_max AS ({{ canton_api_max_record_time('l7_flat') }}),
l8 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l7_max'
    ) }}
),
l8_flat AS ({{ canton_api_flatten_response('l8') }}),
l8_max AS ({{ canton_api_max_record_time('l8_flat') }}),
l9 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l8_max'
    ) }}
),
l9_flat AS ({{ canton_api_flatten_response('l9') }}),
l9_max AS ({{ canton_api_max_record_time('l9_flat') }}),
l10 AS (
    {{ canton_api_updates_call(
        migration_id = 'max_migration_id',
        after_record_time = 'max_time_string',
        from_table = 'l9_max'
    ) }}
),
l10_flat AS ({{ canton_api_flatten_response('l10') }}),
all_updates AS (
    SELECT
        update_json
    FROM
        l1_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l2_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l3_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l4_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l5_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l6_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l7_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l8_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l9_flat
    UNION ALL
    SELECT
        update_json
    FROM
        l10_flat
)
SELECT
    update_json :update_id :: STRING AS update_id,
    update_json :migration_id :: INT AS migration_id,
    update_json :record_time :: datetime AS record_time,
    update_json,
    SYSDATE() AS inserted_timestamp,
    '{{ invocation_id }}' AS _invocation_id
FROM
    all_updates
