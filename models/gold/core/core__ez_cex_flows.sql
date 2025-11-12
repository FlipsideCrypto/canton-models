{{ config(
    materialized = 'view',
    tags = ['scheduled_non_core']
) }}

WITH labels AS (

    SELECT
        address,
        label_subtype,
        label AS exchange_name
    FROM
        {{ ref('core__dim_labels') }}
    WHERE
        label_type = 'cex'
)
SELECT
    A.*,
    COALESCE(
        sender_label.exchange_name,
        receiver_label.exchange_name
    ) AS exchange_name,
    CASE
        WHEN sender_label.address IS NOT NULL
        AND receiver_label.address IS NULL THEN 'withdrawal'
        WHEN receiver_label.address IS NOT NULL
        AND sender_label.address IS NULL THEN 'deposit'
        WHEN sender_label.address IS NOT NULL
        AND receiver_label.address IS NOT NULL
        AND sender_label.exchange_name = receiver_label.exchange_name THEN 'internal_transfer'
        WHEN sender_label.address IS NOT NULL
        AND receiver_label.address IS NOT NULL
        AND sender_label.exchange_name <> receiver_label.exchange_name THEN 'inter_exchange_transfer'
    END AS direction,
     CASE WHEN sender_label.address IS NOT NULL
        AND receiver_label.address IS NOT NULL
        AND sender_label.exchange_name <> receiver_label.exchange_name THEN receiver_label.exchange_name 
        END AS inter_exchange_transfer_receiving_exchange
FROM
    {{ ref('core__ez_token_transfers') }} A
    LEFT JOIN labels sender_label
    ON A.sender = sender_label.address
    LEFT JOIN labels receiver_label
    ON A.receiver = receiver_label.address
WHERE
    COALESCE(
        receiver_label.address,
        sender_label.address
    ) IS NOT NULL
