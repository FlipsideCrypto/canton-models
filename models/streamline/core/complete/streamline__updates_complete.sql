-- depends_on: {{ ref('bronze__updates') }}
{{ config (
    materialized = "incremental",
    unique_key = ['effective_at', 'migration_id'],
    merge_exclude_columns = ["inserted_timestamp"],
    cluster_by = ['effective_at::DATE', 'migration_id'],
    tags = ['streamline_realtime'],
    enabled = false
) }}

SELECT
    DATA: effective_at :: datetime AS effective_at,
    DATA :migration_id :: INT AS migration_id,
    DATA: record_time :: datetime AS record_time,
    DATA :update_id :: STRING AS update_id,
    partition_key,
    _inserted_timestamp,
    SYSDATE() AS inserted_timestamp,
    SYSDATE() AS modified_timestamp,
    file_name,
    '{{ invocation_id }}' AS _invocation_id,
FROM

{% if is_incremental() %}
{{ ref('bronze__updates') }}
{% else %}
    {{ ref('bronze__updates_history') }}
{% endif %}
WHERE
    DATA :error IS NULL

{% if is_incremental() %}
AND _inserted_timestamp >= (
    SELECT
        COALESCE(MAX(_INSERTED_TIMESTAMP), '1970-01-01' :: DATE) max_INSERTED_TIMESTAMP
    FROM
        {{ this }})
    {% endif %}

    qualify ROW_NUMBER() over (
        PARTITION BY effective_at,
        migration_id
        ORDER BY
            _inserted_timestamp DESC
    ) = 1
