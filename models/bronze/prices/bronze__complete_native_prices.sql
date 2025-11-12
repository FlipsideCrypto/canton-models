{{ config (
    materialized = 'view',
    tags = ['core']
) }}

SELECT
    *
FROM
    {{ source(
        'crosschain_silver',
        'complete_native_prices'
    ) }}
WHERE
    blockchain = 'canton'
