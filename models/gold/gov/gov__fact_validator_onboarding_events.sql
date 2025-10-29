{{ config(
    materialized = 'table'
) }}
{# {{ config(
materialized = 'incremental',
unique_key = ['effective_at', 'migration_id', 'event_id'],
cluster_by = ['effective_at::DATE', 'migration_id'],
incremental_strategy = 'merge',
tags = ['core']
) }}
#}

SELECT
    update_id,
    migration_id,
    record_time,
    effective_at event_id,
    event_json :acting_parties AS acting_parties,
    event_json :choice_argument :contactPoint :: STRING AS contact,
    event_json :choice_argument :sponsor :: STRING AS sponsor,
    event_json :choice_argument :validator :: STRING AS validator,
    event_json :choice_argument :version :: STRING AS version,
    event_json :event_type :: STRING AS event_type,
    event_json :contract_id :: STRING AS contract_id,
    event_json :package_name :: STRING AS package_name,
    event_json :template_id :: STRING AS template_id,
    event_json :exercise_result :validatorLicense :: STRING AS validator_license,
    {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS fact_validator_onboarding_event_id,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
FROM
    {{ ref('silver__events') }}

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            MAX(modified_timestamp)
        FROM
            {{ this }}
    )
{% endif %}
