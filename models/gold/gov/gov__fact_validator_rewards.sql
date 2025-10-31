{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['gov', 'non_core']
) }}

-- Tracks validator reward claims via AmuletRules_Transfer
-- Rewards are in exercise_result.meta.values['amulet.splice.lfdecentralizedtrust.org/validator-rewards']
WITH validator_reward_events AS (
    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_index,
        choice,
        event_json
    FROM
        {{ ref('silver__events') }}
    WHERE
        choice = 'AmuletRules_Transfer'
        AND event_json:exercise_result:meta:values['amulet.splice.lfdecentralizedtrust.org/validator-rewards'] IS NOT NULL

    {% if is_incremental() %}
    AND modified_timestamp >= (
        SELECT MAX(modified_timestamp)
        FROM {{ this }}
    )
    {% endif %}
)

SELECT
    update_id,
    migration_id,
    record_time,
    effective_at,
    event_id,
    event_index,
    choice,
    event_json:acting_parties AS acting_parties,

    -- Transfer context
    event_json:choice_argument:context:validatorRights AS validator_rights,
    event_json:choice_argument:context:issuingMiningRounds AS issuing_mining_rounds,
    event_json:choice_argument:context:issuingMiningRounds[0][0]:number AS mining_round,
    event_json:choice_argument:transfer:sender::STRING AS validator_party,

    -- Exercise results with validator reward amount from metadata
    event_json:exercise_result AS exercise_result,
    event_json:exercise_result:meta:values['amulet.splice.lfdecentralizedtrust.org/validator-rewards']::NUMBER(38,10) AS reward_amount,
    event_json:exercise_result:meta:values['splice.lfdecentralizedtrust.org/burned']::NUMBER(38,10) AS burned_amount,
    reward_amount - burned_amount AS net_reward_amount,
    event_json:exercise_result:meta:values AS all_meta_values,
    event_json:exercise_result:summary AS transfer_summary,
    event_json:exercise_result:round:number::NUMBER AS round_number,
    event_json:contract_id::STRING AS contract_id,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_validator_reward_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    validator_reward_events
