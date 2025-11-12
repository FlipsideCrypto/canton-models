{{ config (
    materialized = 'view',
    tags = ['core']
) }}

SELECT
    *
FROM
    {{ source(
        'crosschain_silver',
        'complete_native_asset_metadata'
    ) }}
WHERE
    blockchain = 'canton'
