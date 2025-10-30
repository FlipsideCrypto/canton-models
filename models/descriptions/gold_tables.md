{% docs core__fact_events %}

## Description
Core fact table exposing all Canton events from the blockchain with pre-extracted fields for easy analysis. This is the most granular event-level table and serves as the foundation for understanding all Canton blockchain activity.

## Key Use Cases
- Analyzing complete event history and patterns
- Joining to specialized fact tables for detailed analysis
- Exploring contract lifecycle (creation, exercise, archival)
- Understanding party interactions through acting_parties, signatories, and observers

## Important Relationships
- Source for all other event-based fact tables
- Joins to `core__fact_updates` via `update_id`
- Can be filtered by `choice` to find specific action types
- Can be filtered by `template_id` to find specific contract types

## Commonly-used Fields
- `event_id`: Unique identifier for the event
- `event_index`: Ordering of events within an update
- `choice`: The action/method being executed (for exercised events)
- `event_type`: created_event or exercised_event
- `effective_at`: When the event occurred
- `contract_id`: The contract being created or exercised
- `template_id`: The contract template type

{% enddocs %}

{% docs core__fact_updates %}

## Description
Tracks Canton update-level information. An update is a transaction that contains one or more events and represents an atomic change to the blockchain state.

## Key Use Cases
- Understanding transaction-level activity
- Analyzing update throughput and patterns
- Joining to events to see all changes in a single transaction
- Tracking workflow and synchronizer information

## Important Relationships
- Parent table to `core__fact_events` (one update has many events)
- Links to events via `update_id`

## Commonly-used Fields
- `update_id`: Unique identifier for the update
- `migration_id`: Canton migration identifier
- `effective_at`: When the update occurred
- `synchronizer_id`: The synchronizer that processed the update
- `workflow_id`: Workflow identifier
- `root_event_ids`: The top-level events in this update
- `event_count`: Number of events in this update

{% enddocs %}

{% docs core__fact_balance_changes %}

## Description
Tracks balance changes for parties resulting from transfer operations. Uses LATERAL FLATTEN to extract individual balance changes from the balanceChanges array in transfer event results.

## Key Use Cases
- Analyzing balance movements for specific parties
- Understanding holding fee impacts
- Tracking initial amount changes per party
- Monitoring amulet price at time of balance changes

## Important Relationships
- Derived from `silver__events` where exercise_result contains balanceChanges
- Links to transfer events via `event_id`

## Commonly-used Fields
- `party`: The party whose balance changed
- `change_to_initial_amount`: Change to the party's initial amount
- `change_to_holding_fees_rate`: Change to holding fees rate
- `amulet_price`: USD price of amulet at time of change
- `effective_at`: When the balance change occurred

{% enddocs %}

{% docs core__fact_app_rewards %}

## Description
Tracks app reward coupon expirations when the DSO expires app reward coupons. These events occur when reward coupons reach their expiration and are processed by the DSO.

## Key Use Cases
- Monitoring app reward expiration patterns
- Analyzing reward amounts being expired
- Tracking which closed rounds trigger expirations
- Understanding featured vs unfeatured app reward differences

## Important Relationships
- Links to closed rounds via `closed_round_cid`
- Related to `core__fact_app_reward_coupons` (creation of coupons)

## Commonly-used Fields
- `reward_amount`: Amount of the expired reward
- `is_featured_app`: Whether this was for a featured app
- `closed_round_cid`: Reference to the closed mining round
- `contract_id`: The app reward coupon contract being expired

{% enddocs %}

{% docs core__fact_app_reward_coupons %}

## Description
Tracks the creation of app reward coupons for application providers. These coupons are created during mining rounds and represent rewards earned by app providers.

## Key Use Cases
- Analyzing app provider reward distribution
- Tracking featured vs unfeatured app rewards
- Understanding per-round reward allocation
- Monitoring app provider incentive economics

## Important Relationships
- Links to rounds via `round_number`
- Can be joined to `core__fact_round_opens` or `core__fact_round_closes`
- Related to `core__fact_app_rewards` (expiration of coupons)

## Commonly-used Fields
- `coupon_amount`: The reward amount in this coupon
- `app_provider`: The party receiving the reward
- `beneficiary`: The beneficiary of the coupon
- `is_featured_app`: Whether this is for a featured application
- `round_number`: Which mining round this coupon was created in

{% enddocs %}

{% docs core__fact_amulet_locks %}

## Description
Tracks when amulets are locked/staked by creating LockedAmulet contracts. Locking amulets allows holders to stake their tokens, typically for validator operations or other protocol functions.

## Key Use Cases
- Monitoring staking activity and locked amounts
- Tracking lock expiration times
- Analyzing lock holder patterns
- Understanding rate per round for locked amulets

## Important Relationships
- Links to `core__fact_amulet_unlocks` via amulet_owner and contract_id patterns
- Related to validator operations through lock_holders

## Commonly-used Fields
- `locked_amount`: Initial amount of amulet being locked
- `amulet_owner`: The party who owns the locked amulet
- `lock_expires_at`: When the lock expires
- `lock_holders`: Parties who hold the lock
- `rate_per_round`: Rate of fee accrual per round
- `amount_created_at_round`: Round when the amount was created

{% enddocs %}

{% docs core__ez_amulet_lock_lifecycle %}

## Description
Comprehensive EZ view showing the complete lifecycle of locked amulets from initial lock through unlock or expiration. Joins lock and unlock events to provide a full picture of staking activity including durations, status, and outcomes.

## Key Use Cases
- Analyzing complete amulet locking/staking patterns
- Calculating average lock durations
- Identifying locks that expired vs were actively unlocked
- Tracking which locks were unlocked after expiry
- Understanding staking behavior and timing
- Monitoring currently active locks

## Important Relationships
- Combines `core__fact_amulet_locks` and `core__fact_amulet_unlocks` via locked_amulet_contract_id
- Links to validators and staking through amulet_owner and lock_holders

## Commonly-used Fields
- `locked_amulet_contract_id`: Unique identifier for the locked amulet
- `amulet_owner`: Party who owns the locked amulet
- `lock_status`: Current status (locked, unlocked, or expired)
- `locked_at`: When the lock was created
- `unlocked_at`: When it was unlocked (NULL if still locked)
- `locked_amount`: Amount locked
- `days_locked_before_unlock`: Duration for completed locks
- `days_locked_current`: Duration for active locks
- `was_unlocked_after_expiry`: Whether unlock happened after expiration time

{% enddocs %}

{% docs core__fact_amulet_unlocks %}

## Description
Tracks unlocking/unstaking of locked amulets through exercise events. Joins to child Amulet created events to capture details of the newly created unlocked amulet.

## Key Use Cases
- Monitoring unstaking activity
- Tracking unlock reasons and transaction types
- Analyzing unlocked amounts and their destinations
- Understanding validator unstaking patterns

## Important Relationships
- Counterpart to `core__fact_amulet_locks`
- Joins parent unlock event to child Amulet creation event
- Links to rounds via `round_number` and `open_round_cid`

## Commonly-used Fields
- `unlock_action`: Either 'unlock' or 'expire_lock'
- `unlocked_amount`: Amount being unlocked
- `owner`: Party receiving the unlocked amulet
- `amulet_price`: USD price at time of unlock
- `round_number`: Round in which unlock occurred
- `unlock_reason`: Metadata describing why unlock happened
- `locked_amulet_contract_id`: Original locked contract
- `created_amulet_contract_id`: New unlocked amulet contract

{% enddocs %}

{% docs core__fact_transfers %}

## Description
Comprehensive fact table tracking all amulet transfer operations across multiple transfer-related choices. Handles various transfer types including direct transfers, transfer commands, factory transfers, and preapproved transfers.

## Key Use Cases
- Analyzing transfer volume and patterns
- Tracking sender/receiver relationships
- Understanding transfer amounts and fees
- Monitoring different transfer mechanisms (direct, command, preapproval, factory)

## Important Relationships
- Links to balance changes through `event_id`
- References rounds and amulet rules through context
- Provider field links to service providers facilitating transfers

## Commonly-used Fields
- `choice`: Type of transfer (AmuletRules_Transfer, TransferCommand_Send, etc.)
- `amount`: Transfer amount (from choice_argument)
- `sender`: Sending party
- `receiver`: Receiving party
- `provider`: Service provider facilitating the transfer
- `amulet_amount`: Actual amulet paid (from exercise_result)
- `transfer_summary`: Summary of transfer including fees and amounts

{% enddocs %}

{% docs core__fact_round_opens %}

## Description
Tracks IssuingMiningRound contract creation events, representing when new mining rounds are opened and become active. Contains detailed per-coupon-type issuance rates and round timing information.

## Key Use Cases
- Monitoring mining round lifecycle (opening phase)
- Understanding issuance rates for different reward types
- Tracking round timing (opens_at, target_closes_at)
- Analyzing reward distribution economics per round

## Important Relationships
- Counterpart to `core__fact_round_closes` (same round_number, different phases)
- Links to reward coupon creation events via round_number
- DSO party references governance

## Commonly-used Fields
- `round_number`: Sequential round identifier
- `opens_at`: When the round opens
- `target_closes_at`: Target closing time
- `issuance_per_featured_app_coupon`: Issuance rate for featured apps
- `issuance_per_unfeatured_app_coupon`: Issuance rate for unfeatured apps
- `issuance_per_validator_coupon`: Issuance rate for validators
- `issuance_per_sv_coupon`: Issuance rate for super validators
- `dso_party`: The DSO party managing the round

{% enddocs %}

{% docs core__fact_round_closes %}

## Description
Tracks SummarizingMiningRound contract creation events, representing when mining rounds close and summarize their results. Contains issuance configuration, reward caps, and amulet price information.

## Key Use Cases
- Monitoring mining round lifecycle (closing/summary phase)
- Analyzing issuance configuration per round
- Understanding reward percentage allocations
- Tracking amulet price at round close
- Monitoring reward caps for different participant types

## Important Relationships
- Counterpart to `core__fact_round_opens` (same round_number, different phases)
- Amulet price links to various reward calculations
- Issuance config drives reward distribution

## Commonly-used Fields
- `round_number`: Sequential round identifier
- `amulet_to_issue_per_year`: Annual issuance target
- `validator_reward_percentage`: Percentage allocated to validators
- `app_reward_percentage`: Percentage allocated to apps
- `validator_reward_cap`: Maximum validator rewards
- `featured_app_reward_cap`: Maximum featured app rewards
- `unfeatured_app_reward_cap`: Maximum unfeatured app rewards
- `amulet_price_usd`: USD price of amulet at round close
- `tick_duration_microseconds`: Duration of each tick in the round

{% enddocs %}

{% docs gov__fact_validator_onboarding_requests %}

## Description
Tracks when super validators initiate the onboarding process by executing DsoRules_StartSvOnboarding. Captures the initial request with candidate information and onboarding tokens.

## Key Use Cases
- Monitoring new validator onboarding requests
- Tracking onboarding request timing and actors
- Analyzing candidate information and reasons
- Linking requests to eventual onboarding events

## Important Relationships
- First step in validator lifecycle, links to `gov__fact_validator_onboarding_events`
- Can link to `gov__fact_validator_onboarding_request_expirations` for expired requests
- Part of `gov__ez_validator_onboarding_lifecycle` comprehensive view

## Commonly-used Fields
- `candidate_name`: Name of the validator candidate
- `candidate_party`: Party ID of the candidate
- `reason_url`: URL with reason for onboarding
- `reason_body`: Text description of reason
- `onboarding_token`: Token for the onboarding process
- `onboarding_request_contract_id`: Contract ID of the created request

{% enddocs %}

{% docs gov__fact_validator_onboarding_events %}

## Description
Tracks successful validator onboarding events for both regular validators (DsoRules_OnboardValidator) and super validators (DsoRules_ConfirmSvOnboarding). Represents the final confirmation step in validator onboarding.

## Key Use Cases
- Monitoring successful validator onboardings
- Distinguishing between validator and super validator onboardings
- Tracking validator party identifiers and names
- Analyzing onboarding timing and actors

## Important Relationships
- Final step after `gov__fact_validator_onboarding_requests`
- Links to `gov__fact_validator_offboarding_events` for complete lifecycle
- Core table in `gov__ez_validator_onboarding_lifecycle` comprehensive view

## Commonly-used Fields
- `onboarding_type`: 'validator' or 'super_validator'
- `validator_party`: Party ID of the onboarded validator
- `validator_name`: Name of the validator
- `sv_party`: Party ID if onboarding as super validator
- `sv_onboarding_confirmed`: Contract ID from SV onboarding
- `new_dso_rules_contract_id`: Updated DSO rules contract

{% enddocs %}

{% docs gov__fact_validator_offboarding_events %}

## Description
Tracks when validators are removed from the network through DsoRules_OffboardSv events. Captures the offboarding decision and resulting state changes.

## Key Use Cases
- Monitoring validator exits from the network
- Understanding offboarding reasons and actors
- Tracking DSO rule updates from offboardings
- Analyzing validator lifecycle completion

## Important Relationships
- Final step in validator lifecycle from `gov__fact_validator_onboarding_events`
- Part of `gov__ez_validator_onboarding_lifecycle` comprehensive view
- Links to validator activity tables via offboarded_sv_party

## Commonly-used Fields
- `offboarded_sv_party`: Party ID of the offboarded validator
- `reason_url`: URL explaining offboarding reason
- `reason_body`: Text description of offboarding reason
- `new_dso_rules_contract_id`: Updated DSO rules after offboarding
- `effective_at`: When offboarding occurred

{% enddocs %}

{% docs gov__fact_validator_onboarding_request_expirations %}

## Description
Tracks onboarding request expirations through both DSO-initiated expiration (DsoRules_ExpireSvOnboardingRequest) and contract consumption (SvOnboardingRequest_Expire). Handles parent-child event relationships.

## Key Use Cases
- Monitoring expired onboarding requests
- Understanding expiration types (DSO-initiated vs contract-consumed)
- Tracking which requests didn't complete onboarding
- Analyzing expiration timing and patterns

## Important Relationships
- Links to `gov__fact_validator_onboarding_requests` via contract IDs
- Part of `gov__ez_validator_onboarding_lifecycle` for incomplete onboardings

## Commonly-used Fields
- `expiration_type`: 'dso_initiated' or 'contract_consumed'
- `expired_request_cid`: Contract ID of the expired request
- `reason_url`: URL explaining expiration (DSO-initiated only)
- `reason_body`: Text description of expiration (DSO-initiated only)
- `effective_at`: When expiration occurred

{% enddocs %}

{% docs gov__ez_validator_onboarding_lifecycle %}

## Description
Comprehensive EZ view providing a complete picture of validator lifecycle from request through onboarding and potential offboarding. Uses FULL OUTER JOIN to capture all validators regardless of request status, and includes an is_current flag for active validators.

## Key Use Cases
- Understanding complete validator journey
- Analyzing active vs inactive validators
- Tracking onboarding success rates and timing
- Monitoring validator status changes over time
- Reporting on current validator set

## Important Relationships
- Joins `gov__fact_validator_onboarding_requests`, `gov__fact_validator_onboarding_events`, `gov__fact_validator_offboarding_events`, and `gov__fact_validator_onboarding_request_expirations`
- Comprehensive view suitable for dashboards and reporting

## Commonly-used Fields
- `is_current`: Boolean flag indicating if this is the current record for the validator
- `validator_party`: Party ID of the validator
- `validator_name`: Name of the validator
- `onboarding_type`: 'validator' or 'super_validator'
- `requested_at`: When onboarding was requested
- `onboarded_at`: When onboarding was confirmed
- `offboarded_at`: When validator was offboarded (if applicable)
- `most_recent_timestamp`: Most recent activity timestamp for this validator

{% enddocs %}

{% docs gov__fact_validator_activity %}

## Description
Tracks validator liveness and activity reporting events. Captures both super validator activity reports (ValidatorLicense_ReportActive) and regular validator liveness activity (ValidatorLicense_RecordValidatorLivenessActivity).

## Key Use Cases
- Monitoring validator liveness and activity
- Distinguishing between super validator and regular validator activity
- Tracking activity patterns and frequency
- Analyzing validator performance and participation

## Important Relationships
- Links to validator onboarding tables via validator parties
- Activity data used for reward calculations
- Related to validator reward distribution

## Commonly-used Fields
- `validator_type`: 'super_validator' or 'validator'
- `round_number`: Mining round when activity occurred
- `validator_party`: Party reporting activity
- `effective_at`: When activity was reported

{% enddocs %}

{% docs gov__fact_validator_rewards %}

## Description
Tracks validator reward claims via AmuletRules_Transfer events where metadata contains validator-rewards information. Captures reward amounts, burned amounts, and net rewards.

## Key Use Cases
- Analyzing validator reward distribution
- Calculating net rewards after burns
- Tracking reward timing by mining round
- Monitoring validator economics and incentives

## Important Relationships
- Links to mining rounds via round_number
- Links to validators via validator_party
- Related to `gov__fact_validator_activity` (activity enables rewards)

## Commonly-used Fields
- `validator_party`: Party receiving the reward
- `reward_amount`: Gross reward amount from metadata
- `burned_amount`: Amount burned in the process
- `net_reward_amount`: Calculated field (reward_amount - burned_amount)
- `mining_round`: Round number associated with reward
- `round_number`: Round from exercise result

{% enddocs %}

{% docs gov__fact_vote_requests %}

## Description
Tracks DSO governance vote requests/proposals through DsoRules_RequestVote events. Captures proposals for various DSO actions including granting featured app rights, updating rules, and other governance decisions.

## Key Use Cases
- Monitoring governance proposals and voting activity
- Analyzing proposal types and actions being requested
- Tracking requester patterns and proposal timing
- Understanding governance participation

## Important Relationships
- Parent table to `gov__fact_votes` (proposals receive votes)
- Links to `gov__fact_vote_results` via vote_request_cid
- Action details drive governance changes

## Commonly-used Fields
- `requester`: Party proposing the vote
- `target_effective_at`: When proposal should take effect
- `vote_timeout_microseconds`: How long voting is open
- `action`: High-level action tag
- `dso_action`: Specific DSO action if applicable
- `amulet_rules_action`: Specific amulet rules action if applicable
- `reason_body`: Explanation of the proposal
- `reason_url`: URL with more details
- `vote_request_cid`: Contract ID of the vote request

{% enddocs %}

{% docs gov__fact_votes %}

## Description
Tracks individual vote casting events (DsoRules_CastVote) in response to vote requests. Captures who voted, what they voted for, and timing of votes.

## Key Use Cases
- Analyzing voting patterns and participation
- Tracking individual super validator votes
- Understanding vote timing relative to requests
- Monitoring governance engagement

## Important Relationships
- Child events to `gov__fact_vote_requests`
- Links to vote requests via vote_request_cid
- Aggregated in `gov__fact_vote_results`

## Commonly-used Fields
- `voter`: Party casting the vote
- `vote_accept`: Boolean indicating accept/reject vote
- `vote_request_cid`: Reference to the vote request
- `effective_at`: When vote was cast

{% enddocs %}

{% docs gov__fact_vote_results %}

## Description
Tracks DSO governance vote results/outcomes through DsoRules_CloseVoteRequest events. Shows final outcomes including acceptance/rejection, vote counts, accepted/rejected SVs, and abstentions. Uses LATERAL FLATTEN to parse votes array.

## Key Use Cases
- Analyzing governance decision outcomes
- Understanding vote tallies and participation
- Tracking which SVs voted for/against proposals
- Monitoring abstention and offboarded voter patterns
- Analyzing proposal success/failure rates

## Important Relationships
- Final step after `gov__fact_vote_requests` and `gov__fact_votes`
- Aggregates individual votes into final result
- Includes embedded original request details

## Commonly-used Fields
- `outcome`: Result tag (typically 'VRO_Accepted' or 'VRO_Rejected')
- `accept_votes`: Count of accept votes
- `reject_votes`: Count of reject votes
- `accepted_svs`: Array of SV parties who voted to accept
- `rejected_svs`: Array of SV parties who voted to reject
- `abstaining_svs`: Array of SVs who abstained
- `total_votes_cast`: Total number of votes
- `completed_at`: When voting concluded
- `requester`: Original proposal requester
- `action`: Original proposal action
- `reason_body`: Original proposal reason

{% enddocs %}
