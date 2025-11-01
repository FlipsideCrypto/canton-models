{% macro canton_api_updates_call(
        migration_id,
        after_record_time,
        from_table
    ) %}
SELECT
    canton.live.udf_api_v2(
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
                {{ migration_id }},
                'after_record_time',
                {{ after_record_time }}
            ),
            'page_size',
            500,
            'daml_value_encoding',
            'compact_json'
        ),
        TRUE -- use async for large content payloads
    ) :data AS response
FROM
    {{ from_table }}
{% endmacro %}

{% macro canton_api_flatten_response(from_cte) %}
SELECT
    VALUE AS update_json
FROM
    {{ from_cte }},
    LATERAL FLATTEN(
        response :transactions
    )
WHERE
    len(response) > 10
{% endmacro %}

{% macro canton_api_max_record_time(from_cte) %}
SELECT
    to_varchar(MAX(update_json :record_time) :: datetime, 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"') AS max_time_string,
    MAX(
        update_json :migration_id
    ) :: INT AS max_migration_id
FROM
    {{ from_cte }}
{% endmacro %}
