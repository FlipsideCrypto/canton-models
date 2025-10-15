{% docs __overview__ %}

# Welcome to the Flipside Crypto CANTON Models Documentation

## **What does this documentation cover?**
The documentation included here details the design of the CANTON blockchain tables and views available via [Flipside Crypto.](https://flipsidecrypto.xyz/) For more information on how these models are built, please see [the github repository.](https://github.com/flipsideCrypto/sui-models/)

## **How do I use these docs?**
The easiest way to navigate this documentation is to use the Quick Links below. These links will take you to the documentation for each table, which contains a description, a list of the columns, and other helpful information.

If you are experienced with dbt docs, feel free to use the sidebar to navigate the documentation, as well as explore the relationships between tables and the logic building them.

There is more information on how to use dbt docs in the last section of this document.

## **Quick Links to Table Documentation**

**Click on the links below to jump to the documentation for each schema.**

### Core Tables
**Dimension Tables:**
 

**Fact Tables:**
 

The CANTON models are built using three layers of SQL models: **bronze, silver, and gold (or core/defi/nft).**

- Bronze: Data is loaded in from the source as a view
- Silver: All necessary parsing, filtering, de-duping, and other transformations are done here
- Gold (or core/defi/nft): Final views and tables that are available publicly

The dimension tables are sourced from a variety of on-chain and off-chain sources.

Convenience views (denoted ez_) are a combination of different fact and dimension tables. These views are built to make it easier to query the data.

## **Using dbt docs**
### Navigation

You can use the ```Project``` and ```Database``` navigation tabs on the left side of the window to explore the models in the project.

### Database Tab

This view shows relations (tables and views) grouped into database schemas. Note that ephemeral models are *not* shown in this interface, as they do not exist in the database.

### Graph Exploration

You can click the blue icon on the bottom-right corner of the page to view the lineage graph of your models.

On model pages, you'll see the immediate parents and children of the model you're exploring. By clicking the Expand button at the top-right of this lineage pane, you'll be able to see all of the models that are used to build, or are built from, the model you're exploring.

Once expanded, you'll be able to use the ```--models``` and ```--exclude``` model selection syntax to filter the models in the graph. For more information on model selection, check out the [dbt docs](https://docs.getdbt.com/docs/model-selection-syntax).

Note that you can also right-click on models to interactively filter and explore the graph.

### **More information**
- [Flipside](https://flipsidecrypto.xyz/)
- [Github](https://github.com/FlipsideCrypto/sui-models)
- [What is dbt?](https://docs.getdbt.com/docs/introduction)

<llm>
<blockchain>Canton</blockchain>
<aliases>CANTON, Canton Network</aliases>
<ecosystem>Layer 1, Object-Centric Parallel Execution</ecosystem>
<description>Canton is a high-performance Layer 1 blockchain designed for instant settlement and infinite scalability. Built on the Move programming language with an object-centric data model, Canton enables parallel execution of transactions that don't conflict, achieving unprecedented throughput and low latency. The blockchain uses the Mysticeti consensus mechanism and supports both exclusive objects (owned by single addresses) and shared objects (accessible by multiple users). Canton was specifically designed for high-volume decentralized applications including gaming, NFTs, and DeFi, offering developers a secure and scalable platform for building next-generation Web3 applications.</description>
<external_resources>
    <block_scanner>https://suiexplorer.com/</block_scanner>
    <developer_documentation>https://docs.sui.io/</developer_documentation>
</external_resources>
<expert>
  <constraints>
    <table_availability>
      Ensure that your queries use only available tables for Canton blockchain. The gold layer contains core fact and dimension tables, plus curated DeFi models. Use the quick links above to navigate to specific table documentation.
    </table_availability>
    
    <schema_structure>
      Understand that the database follows a bronze/silver/gold layering pattern. Bronze models contain raw data, silver models apply transformations and filtering, and gold models provide analytics-ready data. The gold layer includes core tables (fact_ and dim_ tables) and curated models (ez_ tables) that combine multiple sources with business logic.
    </schema_structure>
  </constraints>

  <optimization>
    <performance_filters>
      Use filters like block_timestamp over the last N days to improve query performance. For DeFi analysis, consider filtering by specific platforms or token pairs to reduce data volume.
    </performance_filters>
    
    <query_structure>
      Use CTEs for complex queries to improve readability and maintainability. Leverage the object-centric nature of Canton data by joining on object IDs and transaction digests for efficient lookups.
    </query_structure>
    
    <implementation_guidance>
      Be smart with aggregations and window functions when analyzing high-throughput Canton data. Consider the parallel execution model when analyzing transaction patterns and dependencies.
    </implementation_guidance>
  </optimization>

  <domain_mapping>
    <token_operations>
      For token transfers and balance changes, use core__fact_balance_changes and core__fact_changes tables. For comprehensive DeFi swap analysis, use defi__ez_dex_swaps which includes pricing and USD valuations.
    </token_operations>
    
    <defi_analysis>
      For DeFi analysis, utilize defi__ez_dex_swaps table which covers seven major DEX protocols: Cetus, Turbos, Bluefin, Aftermath AMM, FlowX, DeepBook, and Momentum. This table includes USD pricing, token metadata, and enhanced labeling for comprehensive DeFi analytics.
    </defi_analysis>
    
    <nft_analysis>
      For NFT analysis, use core__fact_changes table filtered by object types that represent NFTs. Canton's object-centric model makes NFT tracking particularly efficient through object ID lookups.
    </nft_analysis>
    
    <specialized_features>
      Canton's object-centric data model is complex, so ensure you ask clarifying questions when dealing with object relationships and ownership patterns. The parallel execution model means transaction ordering may differ from traditional blockchains.
    </specialized_features>
  </domain_mapping>

  <interaction_modes>
    <direct_user>
      Ask clarifying questions when dealing with complex Canton data structures, especially around object ownership and transaction dependencies. Provide specific examples using Canton's Move type format and address conventions.
    </direct_user>
    
    <agent_invocation>
      When invoked by another AI agent, respond with relevant query text and explain Canton-specific considerations like object-centric data model and parallel execution patterns.
    </agent_invocation>
  </interaction_modes>

  <engagement>
    <exploration_tone>
      Have fun exploring the Canton ecosystem through data! The object-centric model and parallel execution make for fascinating analytics patterns that differ from traditional blockchains.
    </exploration_tone>
  </engagement>
</expert>
</llm>

{% enddocs %}