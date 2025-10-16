{{ config (
    materialized = "view",
    post_hook = fsc_utils.if_data_call_function_v2(
        func = 'streamline.udf_bulk_rest_api_v2',
        target = "{{this.schema}}.{{this.identifier}}",
        params ={ "external_table" :"updates",
        "sql_limit" :"1",
        "producer_batch_size" :"1",
        "worker_batch_size" :"1",
        "async_concurrent_requests" :"1",
        "sql_source" :"{{this.identifier}}",
        'exploded_key': '["transactions"]',
        "order_by_column": "partition_key" }
    ),
    tags = ['streamline_realtime'],
    enabled = false
) }}

WITH curr_mig AS (

    SELECT
        migration_id -1 AS migration_id
    FROM
        {{ ref('streamline__current_migration') }}
),
max_record_time AS (
    SELECT
        MAX(record_time) max_record_time,
        to_varchar(
            max_record_time,
            'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"'
        ) AS max_time_string
    FROM
        {{ ref('streamline__updates_complete') }}
)
SELECT
    max_time_string,
    to_char(
        max_record_time,
        'YYYYMMDD'
    ) AS partition_key,
    {{ target.database }}.live.udf_api(
        'POST',
        'https://api.cantonnodes.com/v2/updates',
        OBJECT_CONSTRUCT(
            'Content-Type',
            'application/json',
            'fsc-compression-mode',
            'always'
        ),
        OBJECT_CONSTRUCT(
            'after',
            OBJECT_CONSTRUCT(
                'after_migration_id',
                migration_id,
                'after_record_time',
                max_time_string
            ),
            'page_size',
            1000,
            'daml_value_encoding',
            'compact_json',
            'method',
            'nothing'
        )
    ) AS request
FROM
    max_record_time
    CROSS JOIN curr_mig
