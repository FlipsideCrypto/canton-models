{% docs __overview__ %}

# Welcome to the Flipside Crypto CANTON Models Documentation

## **What does this documentation cover?**
The documentation included here details the design of the CANTON blockchain tables and views available via [Flipside Crypto.](https://flipsidecrypto.xyz/) For more information on how these models are built, please see [the github repository.](https://github.com/FlipsideCrypto/canton-models)

## **How do I use these docs?**
The easiest way to navigate this documentation is to use the Quick Links below. These links will take you to the documentation for each table, which contains a description, a list of the columns, and other helpful information.

If you are experienced with dbt docs, feel free to use the sidebar to navigate the documentation, as well as explore the relationships between tables and the logic building them.

There is more information on how to use dbt docs in the last section of this document.

## **Quick Links to Table Documentation**

**Click on the links below to jump to the documentation for each schema.**

### Core Schema

**Event & Transaction Tables:**
- [core__fact_events](#!/model/model.canton_models.core__fact_events) - All Canton events with pre-extracted fields
- [core__fact_updates](#!/model/model.canton_models.core__fact_updates) - Update-level transaction information

**Transfer & Balance Tables:**
- [core__fact_transfers](#!/model/model.canton_models.core__fact_transfers) - All amulet transfer operations
- [core__fact_balance_changes](#!/model/model.canton_models.core__fact_balance_changes) - Balance changes from transfers

**Amulet Lock/Stake Tables:**
- [core__fact_amulet_locks](#!/model/model.canton_models.core__fact_amulet_locks) - Amulet locking/staking events
- [core__fact_amulet_unlocks](#!/model/model.canton_models.core__fact_amulet_unlocks) - Amulet unlocking/unstaking events
- [core__ez_amulet_lock_lifecycle](#!/model/model.canton_models.core__ez_amulet_lock_lifecycle) - Complete lock lifecycle view

**Reward Tables:**
- [core__fact_app_reward_coupons](#!/model/model.canton_models.core__fact_app_reward_coupons) - App reward coupon creation
- [core__fact_app_rewards](#!/model/model.canton_models.core__fact_app_rewards) - App reward coupon expirations

**Mining Round Tables:**
- [core__fact_round_opens](#!/model/model.canton_models.core__fact_round_opens) - Mining round opening events
- [core__fact_round_closes](#!/model/model.canton_models.core__fact_round_closes) - Mining round closing events

### Governance Schema

**Validator Lifecycle Tables:**
- [gov__fact_validator_onboarding_requests](#!/model/model.canton_models.gov__fact_validator_onboarding_requests) - Validator onboarding requests
- [gov__fact_validator_onboarding_events](#!/model/model.canton_models.gov__fact_validator_onboarding_events) - Successful validator onboardings
- [gov__fact_validator_offboarding_events](#!/model/model.canton_models.gov__fact_validator_offboarding_events) - Validator offboarding events
- [gov__fact_validator_onboarding_request_expirations](#!/model/model.canton_models.gov__fact_validator_onboarding_request_expirations) - Expired onboarding requests
- [gov__ez_validator_onboarding_lifecycle](#!/model/model.canton_models.gov__ez_validator_onboarding_lifecycle) - Complete validator lifecycle view

**Validator Activity & Rewards:**
- [gov__fact_validator_activity](#!/model/model.canton_models.gov__fact_validator_activity) - Validator liveness and activity reporting
- [gov__fact_validator_rewards](#!/model/model.canton_models.gov__fact_validator_rewards) - Validator reward claims

**Voting & Governance Tables:**
- [gov__fact_vote_requests](#!/model/model.canton_models.gov__fact_vote_requests) - DSO governance vote proposals
- [gov__fact_votes](#!/model/model.canton_models.gov__fact_votes) - Individual vote casting events
- [gov__fact_vote_results](#!/model/model.canton_models.gov__fact_vote_results) - Final vote outcomes and tallies

---

The CANTON models are built using three layers of SQL models: **bronze, silver, and gold (core/gov).**

- Bronze: Data is loaded in from the source as a view
- Silver: All necessary parsing, filtering, de-duping, and other transformations are done here
- Gold (core/gov): Final views and tables that are available publicly

Convenience views (denoted ez_) are a combination of different fact tables. These views are built to make it easier to query the data by providing complete lifecycle tracking and pre-joined relationships.

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
- [Github](https://github.com/FlipsideCrypto/canton-models)
- [What is dbt?](https://docs.getdbt.com/docs/introduction)
- [Canton Network](https://www.canton.network/)

<!--
LLM-specific metadata below (hidden from rendered docs but available in source)

<llm>
  <blockchain>Canton</blockchain>
  <aliases>CANTON, Canton Network</aliases>
  <ecosystem>Privacy-Enabled Blockchain Network, Decentralized Synchronization</ecosystem>
  <description>
    Canton is a privacy-enabled blockchain network designed for institutional and enterprise
    financial applications. Built by Digital Asset, Canton uses the Daml smart contract language
    and implements a unique synchronization protocol that enables confidential, interoperable
    transactions across multiple network participants. The network supports both public and
    private data domains, allowing participants to maintain data privacy while still achieving
    settlement finality. Canton's architecture is built around "updates" (atomic transactions)
    that contain one or more "events" (contract creations and exercises). The network includes
    a Digital Super Organization (DSO) that governs the network through decentralized voting,
    manages validator onboarding/offboarding, and controls the Amulet native token economics
    including mining rounds, rewards, and transfer operations.
  </description>
  <external_resources>
    <block_scanner>https://explorer.canton.network/</block_scanner>
    <developer_documentation>https://docs.canton.network/</developer_documentation>
    <main_website>https://www.canton.network/</main_website>
  </external_resources>
  <expert>
    <constraints>
      <table_availability>
        Ensure that your queries use only available tables for Canton blockchain. The gold
        layer contains core tables (transfers, balance changes, amulet locks/unlocks, mining
        rounds, app rewards) and governance tables (validator lifecycle, voting, rewards).
        Use the quick links above to navigate to specific table documentation.
      </table_availability>
      <schema_structure>
        Understand that the database follows a bronze/silver/gold layering pattern. Bronze
        models contain raw API data from Canton nodes, silver models parse JSON and flatten
        events, and gold models provide analytics-ready fact tables. The gold layer includes
        core tables (transaction/transfer data) and governance tables (validator and voting
        data), plus ez_ tables that provide lifecycle views.
      </schema_structure>
    </constraints>
    <optimization>
      <performance_filters>
        Use filters like effective_at over the last N days to improve query performance. Most
        tables are clustered by effective_at::DATE for efficient time-based queries. For
        party-specific analysis, filter by party, validator_party, sender, or receiver fields.
      </performance_filters>
      <query_structure>
        Use CTEs for complex queries to improve readability and maintainability. Join tables
        on event_id, update_id, contract_id, or round_number for efficient lookups. Use the
        ez_ lifecycle views for simplified analysis across multiple related events.
      </query_structure>
      <implementation_guidance>
        Be aware of Canton's event model: updates contain events, events have parent-child
        relationships via root_event_ids and child_event_ids. Use effective_at for temporal
        queries, event_id for unique event identification, and contract_id for tracking
        contract lifecycle.
      </implementation_guidance>
    </optimization>
    <domain_mapping>
      <token_operations>
        For amulet transfers, use core__fact_transfers. For balance changes resulting from
        transfers, use core__fact_balance_changes. For locked/staked amulets, use
        core__fact_amulet_locks, core__fact_amulet_unlocks, or core__ez_amulet_lock_lifecycle
        for complete lifecycle.
      </token_operations>
      <governance_analysis>
        For validator analysis, use gov__fact_validator_onboarding_requests,
        gov__fact_validator_onboarding_events, gov__fact_validator_offboarding_events, or
        gov__ez_validator_onboarding_lifecycle for complete lifecycle. For validator activity
        and rewards, use gov__fact_validator_activity and gov__fact_validator_rewards.
      </governance_analysis>
      <voting_analysis>
        For DSO governance voting, use gov__fact_vote_requests (proposals), gov__fact_votes
        (individual votes), and gov__fact_vote_results (outcomes). Vote results include
        accepted/rejected SV lists and abstentions.
      </voting_analysis>
      <mining_rounds>
        For mining round data, use core__fact_round_opens (IssuingMiningRound with issuance
        rates) and core__fact_round_closes (SummarizingMiningRound with reward caps and
        amulet price). Round numbers link to app rewards and validator rewards.
      </mining_rounds>
      <specialized_features>
        Canton uses a Daml-based contract model with created_events (contract creation) and
        exercised_events (contract method execution). Events within an update may have
        parent-child relationships. The DSO governs through voting, validators report
        activity, and mining rounds drive reward distribution.
      </specialized_features>
    </domain_mapping>
    <interaction_modes>
      <direct_user>
        Ask clarifying questions when dealing with complex Canton data structures, especially
        around event relationships, contract lifecycles, and governance processes. Provide
        specific examples using Canton party IDs, contract IDs, and template IDs.
      </direct_user>
      <agent_invocation>
        When invoked by another AI agent, respond with relevant query text and explain
        Canton-specific considerations like the update/event model, Daml contract patterns,
        and DSO governance mechanisms.
      </agent_invocation>
    </interaction_modes>
    <engagement>
      <exploration_tone>
        Have fun exploring the Canton ecosystem through data! The privacy-enabled architecture,
        DSO governance model, and mining round economics make for fascinating analytics
        patterns unique to Canton Network.
      </exploration_tone>
    </engagement>
  </expert>
</llm>
-->

{% enddocs %}