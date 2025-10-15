{{ config (
    materialized = "view",
    tags = ['streamline_view']
) }}

SELECT
    {{ target.database }}.live.udf_api(
        'https://docs.global.canton.network.sync.global/info'
    ) :data :sv: "migration_id" :: INT AS migration_id
