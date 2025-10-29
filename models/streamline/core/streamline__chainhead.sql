{{ config (
    materialized = "view",
    tags = ['streamline_view']
) }}

SELECT
    {{ target.database }}.live.udf_api_v2(
        'GET',
        'https://api.cantonnodes.com/v0/round-of-latest-data',
        OBJECT_CONSTRUCT(
            'Content-Type',
            'application/json',
            'fsc-compression-mode',
            'always'
        ),
        OBJECT_CONSTRUCT(
            'daml_value_encoding',
            'compact_json'
        ),
        FALSE -- use async for large content payloads
    ) :data :round :: INT AS ROUND
