# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a dbt (data build tool) project for modeling Canton blockchain data on Snowflake. The project follows Flipside Crypto's data modeling standards and uses a layered architecture (bronze → silver → gold) to transform raw blockchain data into analytics-ready tables.

**Key characteristics:**
- Target database: Snowflake
- dbt version: >=1.8.0
- Profile name: `canton`
- Dependencies: `fsc-utils`, `dbt_snowflake_query_tags`, `dbt_utils`

## Development Commands

### Core dbt Commands

```bash
# Install dependencies
dbt deps

# Run models (dev environment by default)
dbt run

# Run specific model
dbt run --select model_name

# Run with incremental refresh
dbt run --full-refresh

# Run tests
dbt test

# Run tests for specific model
dbt test --select model_name

# Build (run + test)
dbt build

# Generate documentation
dbt docs generate
dbt docs serve

# Clean compiled files
dbt clean
```

### Running with Variables

```bash
# Update Snowflake tags for a model
dbt run --var '{"UPDATE_SNOWFLAKE_TAGS":True}' -s models/core/core__fact_swaps.sql

# Update UDFs and stored procedures
dbt run --var '{"UPDATE_UDFS_AND_SPS":True}'

# Run streamline models
dbt run --var '{"STREAMLINE_INVOKE_STREAMS":True}'
```

### Environment-Specific Runs

The project uses target-specific configuration for dev vs prod environments, controlled in `dbt_project.yml`:
- `dev`: Uses staging API integration and `canton_DEV` database
- `prod`: Uses production API integration and `CANTON` database

## Architecture

### Data Flow Layers

1. **Bronze**: Raw data ingestion from Canton API via external functions (`models/bronze/`)
   - Uses `canton.live.udf_api()` to fetch updates from Canton nodes API
   - Implements paginated API calls with 10 layers (l1-l10) to retrieve updates
2. **Silver**: Cleaned and transformed data with JSON parsing (`models/silver/`)
   - Flattens JSON structures from bronze layer
   - Extracts event data from update objects
3. **Gold**: Analytics-ready models (`models/gold/`) - **Currently being built**
   - Core schema directory exists but models are in development
4. **Streamline**: Real-time data pipeline models (`models/streamline/`)
   - Contains migration tracking and completion status models

### Model Naming Convention

Models use double-underscore notation to separate schema from table name:
- `{schema}__{table_name}.sql` → `{database}.{schema}.{table_name}`
- Example: `core__fact_blocks.sql` → `CANTON.CORE.FACT_BLOCKS`

Model prefixes indicate type:
- `fact_`: Fact tables (transactions, events, etc.)
- `dim_`: Dimension tables (reference data)
- `ez_`: Easy views (simplified analytics tables)
- `udf_`: User-defined functions
- `udtf_`: User-defined table functions

### Key Macros

**Canton API Integration** (`macros/canton_api_updates.sql`):
- `canton_api_updates_call()`: Makes POST requests to Canton nodes API to fetch updates
- `canton_api_flatten_response()`: Flattens API response arrays into individual update records
- `canton_api_max_record_time()`: Extracts max record_time and migration_id for pagination

**Streamline Processing** (`macros/streamline/models.sql`):
- `streamline_external_table_query()`: Queries external tables with metadata (for future use)
- `streamline_external_table_query_fr()`: Alternative using file registration

**Snowflake Tagging** (`macros/tags/snowflake_tagging.sql`):
- `apply_meta_as_tags()`: Applies metadata tags to Snowflake objects (runs on-run-end)
- `set_database_tag_value()`: Sets database-level tags
- `set_schema_tag_value()`: Sets schema-level tags

**UDFs/SPs** (`macros/create_udfs.sql`, `macros/create_sps.sql`):
- `create_udfs()`: Creates external functions for API calls (runs on-run-start)
  - Controlled by `UPDATE_UDFS_AND_SPS` variable (default: False)
- `create_sps()`: Creates stored procedures including `sp_create_prod_clone()` for production cloning (runs on-run-start)
  - Only runs when `target.database == 'CANTON'` (production)
- `create_udf_bulk_rest_api_v2()`: External function for bulk REST API calls to Streamline
- `enable_search_optimization()`: Helper to add search optimization to production tables

**Custom Query Tagging** (`macros/custom_query_tag.sql`):
- Integrates with `dbt_snowflake_query_tags` package for query tracking

### External Integrations

**Canton Nodes API**:
- API endpoint: `https://api.cantonnodes.com/v2/updates`
- Used by `canton.live.udf_api()` function in bronze layer models
- Fetches blockchain update data with pagination support
- Parameters: `after_migration_id`, `after_record_time`, `page_size` (1000), `daml_value_encoding` (compact_json)

**AWS Lambda External Functions** (for Streamline integration):
- Dev: `AWS_CANTON_API_STG_V2` → `owx5z51jzf.execute-api.us-east-1.amazonaws.com/stg/`
- Prod: `AWS_CANTON_API_PROD_V2` → `niz48dl8gb.execute-api.us-east-1.amazonaws.com/prod/`
- Used by `streamline.udf_bulk_rest_api_v2()` function (created only when `UPDATE_UDFS_AND_SPS=True`)

## Modeling Standards

### Incremental Models
- Always prioritize incremental processing for performance
- Use appropriate `unique_key` for merge strategy
- Include incremental predicates: `{% if is_incremental() %} WHERE ... {% endif %}`
- Use `cluster_by` for frequently queried columns

### Column Naming
- Use `snake_case` for all columns
- Maintain naming consistency through the pipeline
- Capitalize column names in YAML files

### Gold Layer Requirements
- Implement search optimization for production tables
- Apply appropriate clustering keys
- Add comprehensive tests (unique, not_null, recency, relationships)

### Configuration Patterns

Standard model config:
```sql
{{ config(
    materialized = 'incremental',
    unique_key = ['id'],
    cluster_by = ['block_timestamp::DATE', 'id'],
    incremental_strategy = 'merge',
    on_schema_change = 'append_new_columns'
) }}
```

## Documentation Standards

### Current State
**Note**: Documentation is in early stages as gold models are being developed.

Existing documentation files:
- `models/descriptions/__overview__.md`: Project overview with LLM-friendly XML tags
- `models/descriptions/tables.md`: Table documentation (minimal content currently)
- `models/descriptions/columns.md`: Column documentation (minimal content currently)

### Target Documentation Standards
When building out gold models, every model should have an accompanying `.yml` file with:
- Model description using `{{ doc('table_name') }}` references
- All columns documented with `{{ doc('column_name') }}` references
- Appropriate tests for data quality

Descriptions should be stored in markdown files in `models/descriptions/` with these required sections:
1. **Description**: What the model represents
2. **Key Use Cases**: When to use this table
3. **Important Relationships**: How it relates to other gold models
4. **Commonly-used Fields**: Most important columns for analytics

See `.cursor/rules/dbt-documentation-standards.mdc` for complete documentation requirements.

### Overview Documentation
The `models/descriptions/__overview__.md` file contains:
- Rich project description wrapped in `{% docs __overview__ %}` tags
- "Quick Links to Table Documentation" section (currently empty as gold models are being built)
- Structured `<llm>` XML tags for AI consumption describing Canton blockchain

**Important**: The overview references Sui blockchain in some places (likely copied from template). As Canton models are developed, this should be updated to accurately reflect Canton's architecture and data model.

## Snowflake Tags

Tags are managed through dbt model metadata and applied automatically.

**Setting tags on a model**:
```sql
{{ config(
    meta={
        'database_tags':{
            'table': {
                'PURPOSE': 'ANALYTICS'
            }
        }
    }
) }}
```

**Updating tags** (by default tags are not pushed on every run):
```bash
dbt run --var '{"UPDATE_SNOWFLAKE_TAGS":True}' -s model_name
```

**Querying existing tags**:
```sql
SELECT * FROM TABLE(
    canton.information_schema.tag_references('canton.core.fact_blocks', 'table')
);
```

## Testing

Tests are configured to:
- Store failures: `+store_failures: true`
- Run on recent data: `+where: "modified_timestamp::DATE > dateadd(hour, -36, sysdate())"`
- Adjust threshold with: `--var 'TEST_HOURS_THRESHOLD=48'`

Required tests:
- `unique` for primary keys
- `not_null` for required columns
- `relationships` for foreign keys
- Recency tests for frequently updated tables

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `dbt_run_adhoc.yml`: Manual/scheduled dbt runs
- `dbt_run_dev_refresh.yml`: Development environment refresh
- `dbt_docs_update.yml`: Documentation generation
- `slack_notify.yml`: Failure notifications

Slack notifications use `python/slack_alert.py` and require `SLACK_WEBHOOK_URL` environment variable.

## Python Utilities

**Slack Alerts** (`python/slack_alert.py`):
- Sends formatted failure notifications to Slack
- Integrates with GitHub Actions environment variables
- Usage: `python python/slack_alert.py`

## Performance Optimization

- Use partition pruning with `block_timestamp` filters
- Implement appropriate clustering keys for query patterns
- Enable search optimization for gold tables in production
- Monitor incremental model performance with `dbt run --full-refresh` periodically
- Consider impact on downstream consumers when modifying models

## Important Project Variables

Key variables in `dbt_project.yml`:
- `UPDATE_SNOWFLAKE_TAGS`: Control tag updates (default: True)
- `UPDATE_UDFS_AND_SPS`: Control UDF/SP creation (default: False)
- `STREAMLINE_INVOKE_STREAMS`: Enable streamline processing (default: TRUE)
- `STREAMLINE_USE_DEV_FOR_EXTERNAL_TABLES`: Use dev external tables (default: FALSE)
- `TEST_HOURS_THRESHOLD`: Hours of data to test (default: 36)

## Bronze Layer Implementation Details

### Data Ingestion Pattern
The `bronze__updates` model implements a sophisticated multi-layer API pagination pattern:
1. Starts with max migration_id and record_time from previous run (or seed date '2024-10-01')
2. Makes 10 sequential API calls (l1 through l10), each using the max from the previous layer
3. Each layer fetches up to 1000 updates via the Canton nodes API
4. All results are unioned together and parsed into the bronze table

Key columns in bronze layer:
- `update_id`: Unique identifier for the update
- `migration_id`: Canton migration identifier
- `record_time`: Timestamp of the update
- `update_json`: Full JSON payload containing events and metadata
- `_invocation_id`: dbt invocation tracking

### Silver Layer Transformations
**silver__updates**: Extracts update-level metadata
- Parses `effective_at`, `synchronizer_id`, `workflow_id` from JSON
- Extracts `root_event_ids` and counts events per update
- Uses incremental merge strategy on `['effective_at', 'migration_id']`

**silver__events**: Flattens events from updates
- Uses `LATERAL FLATTEN` to explode `events_by_id` JSON object
- Identifies root events via `ARRAY_CONTAINS` check
- Creates one row per event with full event JSON
- Uses incremental merge strategy on `['update_id', 'event_id']`

## Cross-Database References

The project references external databases:
- `streamline`: For Canton blockchain data (environment-specific: `canton` or `canton_dev`)
- `crosschain` / `crosschain_dev`: Shared reference data (address_tags, dim_dates, token metadata, prices)

Source definitions in `models/sources.yml` handle environment-specific database names.
