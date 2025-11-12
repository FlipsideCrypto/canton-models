{{ config(
    materialized = 'view',
    tags = ['silver','core']
) }}

SELECT
    *
FROM
    {{ ref(
        'bronze__complete_native_prices'
    ) }}
    p
