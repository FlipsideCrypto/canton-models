{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    merge_exclude_columns = ["inserted_timestamp"],
    incremental_predicates = ["dynamic_range_predicate", "HOUR::date"],
    unique_key = 'ez_prices_hourly_id',
    cluster_by = ['hour::DATE'],
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(token_address, symbol)",
    tags = ['gold_prices','core']
) }}

WITH base AS (

    SELECT
        *
    FROM
        {{ ref('silver__complete_native_prices') }}

{% if is_incremental() %}
WHERE
    modified_timestamp > (
        SELECT
            COALESCE(MAX(modified_timestamp), '1970-01-01' :: TIMESTAMP) AS modified_timestamp
        FROM
            {{ this }})
        {% endif %}
    )
SELECT
    HOUR,
    NULL AS token_address,
    symbol,
    NAME,
    decimals,
    price,
    blockchain,
    TRUE is_native,
    is_deprecated,
    is_imputed,
    TRUE AS token_is_verified,
    {{ dbt_utils.generate_surrogate_key(['token_address','hour']) }} AS ez_prices_hourly_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    base qualify ROW_NUMBER() over (
        PARTITION BY HOUR,
        token_address
        ORDER BY
            modified_timestamp DESC
    ) = 1
