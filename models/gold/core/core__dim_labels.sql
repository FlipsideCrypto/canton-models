{{ config(
    materialized = 'incremental',
    unique_key = ['address'],
    incremental_strategy = 'merge',
    merge_exclude_columns = ["inserted_timestamp"],
    post_hook = ["ALTER TABLE {{ this }} ADD SEARCH OPTIMIZATION ON EQUALITY(address)", "DELETE FROM {{ this }} WHERE address in (select address from {{ ref('silver__crosschain_labels') }} where _is_deleted = TRUE);",],
    tags = ['gold','core']
) }}

SELECT
    blockchain,
    creator,
    address,
    label_type,
    label_subtype,
    project_name AS label,
    address_name,
    labels_combined_id AS dim_labels_id,
    inserted_timestamp,
    modified_timestamp
FROM
    {{ ref('silver__crosschain_labels') }}

{% if is_incremental() %}
WHERE
    modified_timestamp >= (
        SELECT
            MAX(
                modified_timestamp
            )
        FROM
            {{ this }}
    )
{% endif %}
