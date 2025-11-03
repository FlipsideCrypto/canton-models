{{ config(
    materialized = 'incremental',
    unique_key = ['event_id'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['core']
) }}

WITH transfer_events AS (
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

    -- Transfer details from choice_argument
    event_json:choice_argument:transfer:sender::STRING AS sender,
    event_json:choice_argument:transfer:provider::STRING AS provider,
    COALESCE(event_json:choice_argument:transfer:outputs[0]:receiver::STRING,sender) AS receiver,
    COALESCE(event_json:choice_argument:transfer:outputs[0]:amount::NUMBER(38,10),0) AS amount,
    event_json:choice_argument:transfer:outputs[0]:receiverFeeRatio::NUMBER(38,10) AS receiver_fee_ratio,
    event_json:choice_argument:transfer:outputs[0]:lock AS lock,
    event_json:choice_argument:transfer:inputs AS inputs,
    event_json:choice_argument:transfer:beneficiaries AS beneficiaries,
    event_json:choice_argument:expectedDso::STRING AS expected_dso,

    -- Context from choice_argument
    event_json:choice_argument:context:featuredAppRight::STRING AS featured_app_right,
    event_json:choice_argument:context:openMiningRound::STRING AS open_mining_round,
    event_json:choice_argument:context:issuingMiningRounds AS issuing_mining_rounds,
    event_json:choice_argument:context:validatorRights AS validator_rights,

    -- Exercise result - round and summary
    event_json:exercise_result:round:number::NUMBER AS round_number,
    event_json:exercise_result:summary:amuletPrice::NUMBER(38,10) AS amulet_price,
    event_json:exercise_result:summary:inputAmuletAmount::NUMBER(38,10) AS input_amulet_amount,
    event_json:exercise_result:summary:senderChangeAmount::NUMBER(38,10) AS sender_change_amount,
    event_json:exercise_result:summary:senderChangeFee::NUMBER(38,10) AS sender_change_fee,
    event_json:exercise_result:summary:holdingFees::NUMBER(38,10) AS holding_fees,
    event_json:exercise_result:summary:balanceChanges AS balance_changes,

    -- Exercise result - created amulets and metadata
    event_json:exercise_result:createdAmulets AS created_amulets,
    event_json:exercise_result:senderChangeAmulet::STRING AS sender_change_amulet,
    event_json:exercise_result:meta:values AS transfer_meta,

    -- Contract details
    event_json:contract_id::STRING AS contract_id,
    event_json:template_id::STRING AS template_id,
     event_json:consuming::BOOLEAN AS consuming,

    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_transfer_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    transfer_events
