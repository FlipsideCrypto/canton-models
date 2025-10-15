{% macro create_udf_bulk_rest_api_v2() %}
    CREATE
    OR REPLACE EXTERNAL FUNCTION streamline.udf_bulk_rest_api_v2(
        json OBJECT
    ) returns ARRAY {% if target.database == 'CANTON' -%}
        api_integration = aws_canton_api_prod_v2 AS 'https://niz48dl8gb.execute-api.us-east-1.amazonaws.com/prod/udf_bulk_rest_api'
    {% else %}
        api_integration = aws_canton_api_stg_v2 AS 'https://owx5z51jzf.execute-api.us-east-1.amazonaws.com/stg/udf_bulk_rest_api'
    {%- endif %}
{% endmacro %}
