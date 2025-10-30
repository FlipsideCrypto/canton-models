{{ config(
    materialized = 'view',
    tags = ['core']
) }}

WITH locks AS (
    SELECT
        event_id AS lock_event_id,
        effective_at AS locked_at,
        amulet_owner,
        locked_amount,
        amount_created_at_round,
        rate_per_round,
        lock_expires_at,
        lock_holders,
        locked_amulet_contract_id,
        created_at,
        signatories,
        observers
    FROM
        {{ ref('core__fact_amulet_locks') }}
),
unlocks AS (
    SELECT
        event_id AS unlock_event_id,
        effective_at AS unlocked_at,
        locked_amulet_contract_id,
        unlock_action,
        unlocked_amount,
        owner AS unlock_owner,
        amulet_price AS unlock_amulet_price,
        round_number AS unlock_round_number,
        unlock_reason,
        tx_kind,
        created_amulet_contract_id
    FROM
        {{ ref('core__fact_amulet_unlocks') }}
)
SELECT
    -- Lock identification and ownership
    l.locked_amulet_contract_id,
    l.amulet_owner,
    l.lock_holders,

    -- Lock timing
    l.locked_at,
    l.lock_expires_at,
    u.unlocked_at,

    -- Lock amounts
    l.locked_amount,
    u.unlocked_amount,
    l.amount_created_at_round,
    l.rate_per_round,

    -- Unlock details
    u.unlock_action,
    u.unlock_reason,
    u.tx_kind,
    u.unlock_amulet_price,
    u.unlock_round_number,
    u.created_amulet_contract_id,

    -- Event IDs
    l.lock_event_id,
    u.unlock_event_id,

    -- Status
    CASE
        WHEN u.unlocked_at IS NOT NULL THEN 'unlocked'
        WHEN l.lock_expires_at < CURRENT_TIMESTAMP() THEN 'expired'
        ELSE 'locked'
    END AS lock_status,

    -- Duration calculations
    CASE
        WHEN u.unlocked_at IS NOT NULL
        THEN DATEDIFF('day', l.locked_at, u.unlocked_at)
    END AS days_locked_before_unlock,

    CASE
        WHEN u.unlocked_at IS NULL AND l.lock_expires_at >= CURRENT_TIMESTAMP()
        THEN DATEDIFF('day', l.locked_at, CURRENT_TIMESTAMP())
    END AS days_locked_current,

    CASE
        WHEN l.lock_expires_at < u.unlocked_at THEN TRUE
        WHEN l.lock_expires_at < CURRENT_TIMESTAMP() AND u.unlocked_at IS NULL THEN TRUE
        ELSE FALSE
    END AS was_unlocked_after_expiry,

    -- Most recent activity
    COALESCE(u.unlocked_at, l.locked_at) AS most_recent_activity,

    -- Contract metadata
    l.created_at,
    l.signatories,
    l.observers
FROM
    locks l
    LEFT JOIN unlocks u ON l.locked_amulet_contract_id = u.locked_amulet_contract_id
