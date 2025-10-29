{{ config(
    materialized = 'table',
    tags = ['core', 'staking', 'ez']
) }}

-- Summary of staking activity by owner
-- Combines locks and unlocks to show net staking positions
WITH locks AS (
    SELECT
        amulet_owner AS owner,
        COUNT(*) AS total_locks,
        SUM(locked_amount) AS total_locked_amount,
        MIN(created_at) AS first_lock_at,
        MAX(created_at) AS last_lock_at,
        COUNT(DISTINCT DATE_TRUNC('day', created_at)) AS days_with_locks
    FROM
        {{ ref('core__fact_amulet_locks') }}
    GROUP BY
        amulet_owner
),

unlocks AS (
    SELECT
        owner,
        COUNT(*) AS total_unlocks,
        SUM(unlocked_amount) AS total_unlocked_amount,
        MIN(effective_at) AS first_unlock_at,
        MAX(effective_at) AS last_unlock_at,
        SUM(CASE WHEN unlock_action = 'expire_lock' THEN 1 ELSE 0 END) AS expired_locks,
        SUM(CASE WHEN unlock_action = 'unlock' THEN 1 ELSE 0 END) AS manual_unlocks
    FROM
        {{ ref('core__fact_locked_amulets') }}
    WHERE
        owner IS NOT NULL
    GROUP BY
        owner
)

SELECT
    COALESCE(l.owner, u.owner) AS owner,

    -- Lock metrics
    COALESCE(l.total_locks, 0) AS total_locks,
    COALESCE(l.total_locked_amount, 0) AS total_locked_amount,
    l.first_lock_at,
    l.last_lock_at,
    l.days_with_locks,

    -- Unlock metrics
    COALESCE(u.total_unlocks, 0) AS total_unlocks,
    COALESCE(u.total_unlocked_amount, 0) AS total_unlocked_amount,
    u.first_unlock_at,
    u.last_unlock_at,
    COALESCE(u.expired_locks, 0) AS expired_locks,
    COALESCE(u.manual_unlocks, 0) AS manual_unlocks,

    -- Net position (may be negative if unlocks recorded but locks not in data)
    COALESCE(l.total_locked_amount, 0) - COALESCE(u.total_unlocked_amount, 0) AS net_locked_amount,

    -- Activity indicators
    CASE
        WHEN l.total_locks IS NULL THEN 'unlock_only'
        WHEN u.total_unlocks IS NULL THEN 'lock_only'
        ELSE 'both'
    END AS activity_type,

    -- Metadata
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    locks l
FULL OUTER JOIN unlocks u
    ON l.owner = u.owner
