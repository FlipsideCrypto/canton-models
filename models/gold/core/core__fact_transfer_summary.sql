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
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
)
{% endif %}
),
-- Calculate aggregates from outputs
output_aggregates AS (
    SELECT
        event_id,
        COUNT(1) AS num_outputs,
        SUM(output.value :receiverFeeRatio :: NUMBER(38, 10)) AS total_receiver_fee_ratio,
        SUM(
            t.event_json :exercise_result :summary :outputFees [output.index] :: NUMBER(
                38,
                10
            )
        ) AS total_output_fees,
        ARRAY_AGG(
            COALESCE(
                output.value :receiver :: STRING,
                t.event_json :choice_argument :transfer :sender :: STRING
            )
        ) within GROUP (
            ORDER BY
                output.index
        ) AS receivers
    FROM
        transfer_events t,
        LATERAL FLATTEN(
            input => t.event_json :choice_argument :transfer :outputs
        ) AS output
    GROUP BY
        1
)
SELECT
    -- Event identifiers
    t.update_id,
    t.migration_id,
    t.record_time,
    t.effective_at,
    t.event_id,
    t.event_index,
    t.choice,
    t.event_json :acting_parties AS acting_parties,
    -- Transfer parties
    t.event_json :choice_argument :transfer :sender :: STRING AS sender,
    t.event_json :choice_argument :transfer :provider :: STRING AS provider,
    A.receivers,
    -- Summary fees
    t.event_json :exercise_result :summary :senderChangeFee :: NUMBER(
        38,
        10
    ) AS sender_change_fee,
    t.event_json :exercise_result :summary :holdingFees :: NUMBER(
        38,
        10
    ) AS holding_fees,
    -- Output aggregates
    A.num_outputs,
    A.total_receiver_fee_ratio,
    A.total_output_fees,
    -- Summary amounts
    t.event_json :exercise_result :summary :amuletPrice :: NUMBER(
        38,
        10
    ) AS amulet_price,
    t.event_json :exercise_result :summary :inputAmuletAmount :: NUMBER(
        38,
        10
    ) AS input_amulet_amount,
    t.event_json :exercise_result :summary :senderChangeAmount :: NUMBER(
        38,
        10
    ) AS sender_change_amount,
    t.event_json :exercise_result :summary :balanceChanges AS balance_changes,
    -- Full arrays
    t.event_json :choice_argument :transfer :inputs AS inputs,
    t.event_json :choice_argument :transfer :outputs AS outputs,
    t.event_json :choice_argument :transfer :beneficiaries AS beneficiaries,
    -- Context
    t.event_json :choice_argument :expectedDso :: STRING AS expected_dso,
    t.event_json :choice_argument :context :featuredAppRight :: STRING AS featured_app_right,
    t.event_json :choice_argument :context :openMiningRound :: STRING AS open_mining_round,
    t.event_json :choice_argument :context :issuingMiningRounds AS issuing_mining_rounds,
    t.event_json :choice_argument :context :validatorRights AS validator_rights,
    -- Exercise result
    t.event_json :exercise_result :round :number :: NUMBER AS round_number,
    t.event_json :exercise_result :createdAmulets AS created_amulets,
    t.event_json :exercise_result :senderChangeAmulet :: STRING AS sender_change_amulet,
    t.event_json :exercise_result :meta :values AS transfer_meta,
    t.event_json :exercise_result :meta :values :"splice.lfdecentralizedtrust.org/tx-kind" :: STRING AS tx_kind,
    -- Contract details
    t.event_json :contract_id :: STRING AS contract_id,
    t.event_json :template_id :: STRING AS template_id,
    t.event_json :consuming :: BOOLEAN AS consuming,
    -- Metadata
    {{ dbt_utils.generate_surrogate_key(['t.event_id']) }} AS fact_transfer_summary_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    transfer_events t
    LEFT JOIN output_aggregates A
    ON t.event_id = A.event_id
