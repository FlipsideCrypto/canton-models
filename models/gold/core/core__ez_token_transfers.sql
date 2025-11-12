{{ config(
    materialized = 'incremental',
    unique_key = ['event_id', 'output_index'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::DATE"],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = ['effective_at::DATE'],
    post_hook = "ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(event_id, sender, receiver);",
    tags = ['core']
) }}

SELECT
    t.update_id,
    t.migration_id,
    t.record_time,
    t.effective_at,
    t.event_id,
    t.event_index,
    t.choice,
    t.output_index,
    t.sender,
    t.provider,
    t.receiver,
    t.amount AS amount_raw,
    -- Amount calculations with decimals
    CASE
        WHEN COALESCE(p.decimals, 0) <> 0
        THEN t.amount / POWER(10, p.decimals)
        ELSE t.amount / POWER(10, 10) -- Default to 10 decimals for Amulet if price data unavailable
    END AS amount,
    ROUND(
        amount * p.price,
        2
    ) AS amount_usd,
    -- Price and token metadata
    p.price,
    p.symbol,
    p.decimals,
    COALESCE(p.token_is_verified, TRUE) AS token_is_verified,
    -- Other transfer details
    t.receiver_fee_ratio,
    t.lock,
    t.tx_kind,
    -- IDs and timestamps
    t.fact_transfer_id AS ez_token_transfers_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    {{ ref('core__fact_transfers') }} t
    LEFT JOIN {{ ref('price__ez_prices_hourly') }} p
        ON DATE_TRUNC('HOUR', t.effective_at) = p.hour
        AND p.is_native = TRUE -- Canton native token (Amulet)
WHERE
    amount IS NOT NULL

{% if is_incremental() %}
    AND t.modified_timestamp >= (
        SELECT
            MAX(modified_timestamp)
        FROM
            {{ this }}
    )
{% endif %}
