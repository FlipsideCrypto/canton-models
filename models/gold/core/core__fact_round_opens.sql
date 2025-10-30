{{ config(
    materialized = 'incremental',
    unique_key = ['round_number'],
    cluster_by = ['effective_at::DATE'],
    incremental_strategy = 'merge',
    incremental_predicates = ["dynamic_range_predicate", "effective_at::date"],
    merge_exclude_columns = ["inserted_timestamp"],
    tags = ['core']
) }}

WITH open_round_created_events AS (

    SELECT
        update_id,
        migration_id,
        record_time,
        effective_at,
        event_id,
        event_index,
        event_json
    FROM
        {{ ref('silver__events') }}
    WHERE
        event_json :template_id :: STRING LIKE '%IssuingMiningRound'

{% if is_incremental() %}
AND modified_timestamp >= (
    SELECT
        MAX(modified_timestamp)
    FROM
        {{ this }}
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
    -- Round identification
    event_json :create_arguments :round :number :: NUMBER AS round_number,
    -- Round timing
    event_json :create_arguments :opensAt :: TIMESTAMP_NTZ AS opens_at,
    event_json :create_arguments :targetClosesAt :: TIMESTAMP_NTZ AS target_closes_at,
    -- Issuance per coupon type
    event_json :create_arguments :issuancePerFeaturedAppRewardCoupon :: NUMBER(38, 10) AS issuance_per_featured_app_coupon,
    event_json :create_arguments :issuancePerUnfeaturedAppRewardCoupon :: NUMBER(38, 10) AS issuance_per_unfeatured_app_coupon,
    event_json :create_arguments :issuancePerValidatorRewardCoupon :: NUMBER(38, 10) AS issuance_per_validator_coupon,
    event_json :create_arguments :issuancePerSvRewardCoupon :: NUMBER(38, 10) AS issuance_per_sv_coupon,
    event_json :create_arguments :optIssuancePerValidatorFaucetCoupon :: NUMBER(38, 10) AS issuance_per_validator_faucet_coupon,
    -- DSO party
    event_json :create_arguments :dso :: STRING AS dso_party,
    -- Contract details
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :created_at :: TIMESTAMP_NTZ AS created_at,
    -- Signatories and observers
    event_json :signatories AS signatories,
    event_json :observers AS observers,
    -- Metadata
    event_json,
    {{ dbt_utils.generate_surrogate_key(['round_number']) }} AS fact_open_round_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp
FROM
    open_round_created_events
