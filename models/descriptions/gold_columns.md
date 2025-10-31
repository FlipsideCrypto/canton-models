{% docs col_update_id %}
Unique identifier for the Canton update/transaction. An update contains one or more events and represents an atomic change to the blockchain state.
{% enddocs %}

{% docs col_migration_id %}
Canton migration identifier. Used to track different phases or migrations in the Canton network's evolution.
{% enddocs %}

{% docs col_record_time %}
Timestamp when the update was recorded in the system.
{% enddocs %}

{% docs col_effective_at %}
Timestamp when the event or update became effective on the blockchain. This is the canonical time for ordering and analyzing blockchain events.
{% enddocs %}

{% docs col_event_id %}
Unique identifier for the event within the Canton blockchain.
{% enddocs %}

{% docs col_event_index %}
Ordering index of events within an update. Events within the same update are sequentially numbered starting from 0.
{% enddocs %}

{% docs col_choice %}
The choice/action/method being executed on a contract. Examples include 'DsoRules_RequestVote', 'AmuletRules_Transfer', 'LockedAmulet_Unlock', etc.
{% enddocs %}

{% docs col_event_type %}
Type of event: 'created_event' for contract creation or 'exercised_event' for method execution on existing contracts.
{% enddocs %}

{% docs col_contract_id %}
Unique identifier for the contract being created or exercised in this event.
{% enddocs %}

{% docs col_template_id %}
The template/type of the contract, including package information. Format: 'package_id:ModuleName:ContractType'
{% enddocs %}

{% docs col_package_name %}
The Canton package name containing the contract template.
{% enddocs %}

{% docs col_acting_parties %}
Array of party identifiers who are executing this action/choice.
{% enddocs %}

{% docs col_signatories %}
Array of party identifiers who are signatories to the contract.
{% enddocs %}

{% docs col_observers %}
Array of party identifiers who can observe the contract but are not signatories.
{% enddocs %}

{% docs col_created_at %}
Timestamp when the contract was created.
{% enddocs %}

{% docs col_consuming %}
Boolean indicating whether this action consumes/archives the contract.
{% enddocs %}

{% docs col_is_root_event %}
Boolean indicating whether this is a top-level event in the update (as opposed to a child event triggered by a parent event).
{% enddocs %}

{% docs col_child_event_ids %}
Array of event IDs for events that were triggered by this event.
{% enddocs %}

{% docs col_inserted_timestamp %}
Timestamp when the record was inserted into this table (Snowflake SYSDATE).
{% enddocs %}

{% docs col_modified_timestamp %}
Timestamp when the record was last modified in this table (Snowflake SYSDATE).
{% enddocs %}

{% docs col_event_json %}
Full JSON object containing all event data. Useful for detailed analysis and accessing fields not explicitly extracted.
{% enddocs %}

{% docs col_synchronizer_id %}
Identifier for the Canton synchronizer that processed this update.
{% enddocs %}

{% docs col_workflow_id %}
Identifier for the workflow associated with this update.
{% enddocs %}

{% docs col_root_event_ids %}
Array of event IDs that are root-level events in this update.
{% enddocs %}

{% docs col_event_count %}
Number of events contained in this update.
{% enddocs %}

{% docs col_party %}
Party identifier representing a participant in the Canton network. Can be a validator, user, app provider, or other entity.
{% enddocs %}

{% docs col_change_to_initial_amount %}
Numeric change to a party's initial amulet amount from a balance change operation.
{% enddocs %}

{% docs col_change_to_holding_fees_rate %}
Numeric change to the holding fees rate for a party.
{% enddocs %}

{% docs col_amulet_price %}
USD price of one amulet at the time of the event.
{% enddocs %}

{% docs col_reward_amount %}
Amount of reward (in amulets) being distributed or processed.
{% enddocs %}

{% docs col_is_featured_app %}
Boolean indicating whether an application has featured status, which typically grants higher reward rates.
{% enddocs %}

{% docs col_closed_round_cid %}
Contract ID reference to a closed mining round.
{% enddocs %}

{% docs col_coupon_amount %}
Amount (in amulets) represented by a reward coupon.
{% enddocs %}

{% docs col_app_provider %}
Party identifier for an application provider receiving rewards.
{% enddocs %}

{% docs col_beneficiary %}
Party identifier for the beneficiary of a reward or coupon.
{% enddocs %}

{% docs col_round_number %}
Sequential number identifying a mining round in the Canton network.
{% enddocs %}

{% docs col_dso_party %}
Party identifier for the DSO (Digital Synchronizer Operator) that manages network governance and operations.
{% enddocs %}

{% docs col_locked_amount %}
Initial amount of amulet being locked/staked.
{% enddocs %}

{% docs col_amulet_owner %}
Party identifier for the owner of an amulet (locked or unlocked).
{% enddocs %}

{% docs col_lock_expires_at %}
Timestamp when a lock expires and the amulet can be unlocked.
{% enddocs %}

{% docs col_lock_holders %}
Array of party identifiers who hold rights to a locked amulet.
{% enddocs %}

{% docs col_rate_per_round %}
Rate at which fees or rewards accrue per mining round.
{% enddocs %}

{% docs col_amount_created_at_round %}
Round number when an amulet amount was originally created.
{% enddocs %}

{% docs col_unlock_action %}
Type of unlock action: 'unlock' for normal unlock or 'expire_lock' for lock expiration.
{% enddocs %}

{% docs col_unlocked_amount %}
Amount of amulet being unlocked from a locked state.
{% enddocs %}

{% docs col_owner %}
Generic party identifier for an owner. Specific context determines what is owned.
{% enddocs %}

{% docs col_open_round_cid %}
Contract ID reference to an open mining round.
{% enddocs %}

{% docs col_unlock_reason %}
Metadata describing the reason for an unlock operation.
{% enddocs %}

{% docs col_tx_kind %}
Transaction kind metadata describing the type of transaction.
{% enddocs %}

{% docs col_locked_amulet_contract_id %}
Contract ID for a LockedAmulet contract.
{% enddocs %}

{% docs col_created_amulet_contract_id %}
Contract ID for a newly created Amulet contract (typically after unlock).
{% enddocs %}

{% docs col_amount %}
Generic numeric amount field. Context determines what is being measured (transfer amount, reward amount, etc.).
{% enddocs %}

{% docs col_sender %}
Party identifier for the sender in a transfer operation.
{% enddocs %}

{% docs col_receiver %}
Party identifier for the receiver in a transfer operation.
{% enddocs %}

{% docs col_provider %}
Party identifier for a service provider facilitating an operation (often transfers).
{% enddocs %}

{% docs col_delegate %}
Party identifier for a delegate who can act on behalf of another party.
{% enddocs %}

{% docs col_description %}
Text description providing context for an operation.
{% enddocs %}

{% docs col_nonce %}
Unique nonce value for ensuring transaction uniqueness.
{% enddocs %}

{% docs col_expires_at %}
Timestamp when something expires (transfer preapproval, lock, etc.).
{% enddocs %}

{% docs col_expected_dso %}
Expected DSO party identifier for validation purposes.
{% enddocs %}

{% docs col_context %}
JSON object containing contextual information for an operation.
{% enddocs %}

{% docs col_transfer_object %}
JSON object containing full transfer details.
{% enddocs %}

{% docs col_transfer_command_cid %}
Contract ID for a TransferCommand contract.
{% enddocs %}

{% docs col_transfer_preapproval_cid %}
Contract ID for a TransferPreapproval contract.
{% enddocs %}

{% docs col_amulet_amount %}
Specific amount of amulets paid or transferred.
{% enddocs %}

{% docs col_transfer_summary %}
JSON object summarizing transfer results including fees and amounts.
{% enddocs %}

{% docs col_transfer_meta %}
JSON object containing transfer metadata.
{% enddocs %}

{% docs col_opens_at %}
Timestamp when a mining round opens.
{% enddocs %}

{% docs col_target_closes_at %}
Target timestamp for when a mining round should close.
{% enddocs %}

{% docs col_issuance_per_featured_app_coupon %}
Amount of amulets to issue per featured app reward coupon in this round.
{% enddocs %}

{% docs col_issuance_per_unfeatured_app_coupon %}
Amount of amulets to issue per unfeatured app reward coupon in this round.
{% enddocs %}

{% docs col_issuance_per_validator_coupon %}
Amount of amulets to issue per validator reward coupon in this round.
{% enddocs %}

{% docs col_issuance_per_sv_coupon %}
Amount of amulets to issue per super validator reward coupon in this round.
{% enddocs %}

{% docs col_issuance_per_validator_faucet_coupon %}
Amount of amulets to issue per validator faucet coupon in this round (optional/may be NULL).
{% enddocs %}

{% docs col_amulet_to_issue_per_year %}
Target annual issuance rate of amulets in the issuance configuration.
{% enddocs %}

{% docs col_validator_reward_percentage %}
Percentage of issuance allocated to validator rewards.
{% enddocs %}

{% docs col_app_reward_percentage %}
Percentage of issuance allocated to application rewards.
{% enddocs %}

{% docs col_validator_reward_cap %}
Maximum amulet amount for validator rewards.
{% enddocs %}

{% docs col_featured_app_reward_cap %}
Maximum amulet amount for featured app rewards.
{% enddocs %}

{% docs col_unfeatured_app_reward_cap %}
Maximum amulet amount for unfeatured app rewards.
{% enddocs %}

{% docs col_validator_faucet_cap %}
Maximum amulet amount for validator faucet (optional/may be NULL).
{% enddocs %}

{% docs col_amulet_price_usd %}
USD price of one amulet.
{% enddocs %}

{% docs col_tick_duration_microseconds %}
Duration of each tick in microseconds.
{% enddocs %}

{% docs col_issuance_config %}
JSON object containing full issuance configuration.
{% enddocs %}

{% docs col_candidate_name %}
Name of a validator candidate in an onboarding request.
{% enddocs %}

{% docs col_candidate_party %}
Party identifier for a validator candidate.
{% enddocs %}

{% docs col_reason_url %}
URL providing additional information or justification for an action.
{% enddocs %}

{% docs col_reason_body %}
Text body explaining the reason for an action.
{% enddocs %}

{% docs col_onboarding_token %}
Token used in the validator onboarding process.
{% enddocs %}

{% docs col_onboarding_request_contract_id %}
Contract ID for a validator onboarding request.
{% enddocs %}

{% docs col_onboarding_type %}
Type of onboarding: 'validator' for regular validators or 'super_validator' for super validators.
{% enddocs %}

{% docs col_validator_party %}
Party identifier for a validator.
{% enddocs %}

{% docs col_validator_name %}
Human-readable name for a validator.
{% enddocs %}

{% docs col_sv_party %}
Party identifier specifically for a super validator.
{% enddocs %}

{% docs col_sv_onboarding_confirmed %}
Contract ID confirming super validator onboarding.
{% enddocs %}

{% docs col_new_dso_rules_contract_id %}
Contract ID for updated DSO rules after a governance action.
{% enddocs %}

{% docs col_offboarded_sv_party %}
Party identifier for a super validator being offboarded.
{% enddocs %}

{% docs col_expiration_type %}
Type of expiration: 'dso_initiated' for DSO-triggered expiration or 'contract_consumed' for automatic contract expiration.
{% enddocs %}

{% docs col_expired_request_cid %}
Contract ID of an expired onboarding request.
{% enddocs %}

{% docs col_is_current %}
Boolean flag indicating whether this is the current/active record for an entity (used in lifecycle/timeline views).
{% enddocs %}

{% docs col_requested_at %}
Timestamp when something was requested (e.g., validator onboarding).
{% enddocs %}

{% docs col_onboarded_at %}
Timestamp when onboarding was completed.
{% enddocs %}

{% docs col_offboarded_at %}
Timestamp when offboarding occurred.
{% enddocs %}

{% docs col_expired_at %}
Timestamp when expiration occurred.
{% enddocs %}

{% docs col_most_recent_timestamp %}
Most recent timestamp across multiple possible event types for an entity.
{% enddocs %}

{% docs col_validator_type %}
Type of validator: 'super_validator' or 'validator'.
{% enddocs %}

{% docs col_burned_amount %}
Amount of amulets burned in a transaction.
{% enddocs %}

{% docs col_net_reward_amount %}
Net reward amount after subtracting burns (reward_amount - burned_amount).
{% enddocs %}

{% docs col_mining_round %}
Mining round number from context or choice arguments.
{% enddocs %}

{% docs col_validator_rights %}
JSON object describing validator rights and capabilities.
{% enddocs %}

{% docs col_issuing_mining_rounds %}
JSON array of issuing mining rounds from context.
{% enddocs %}

{% docs col_exercise_result %}
JSON object containing the full result of exercising a choice on a contract.
{% enddocs %}

{% docs col_all_meta_values %}
JSON object containing all metadata key-value pairs.
{% enddocs %}

{% docs col_requester %}
Party identifier for the party requesting a governance action or vote.
{% enddocs %}

{% docs col_target_effective_at %}
Target timestamp for when a governance action should become effective.
{% enddocs %}

{% docs col_vote_timeout_microseconds %}
Duration in microseconds for how long voting remains open.
{% enddocs %}

{% docs col_action %}
High-level action tag for a governance proposal.
{% enddocs %}

{% docs col_dso_action %}
Specific DSO-related action being proposed.
{% enddocs %}

{% docs col_dso_action_value %}
JSON value containing details of the DSO action.
{% enddocs %}

{% docs col_amulet_rules_action %}
Specific amulet rules action being proposed.
{% enddocs %}

{% docs col_amulet_rules_value %}
JSON value containing details of the amulet rules action.
{% enddocs %}

{% docs col_vote_request_cid %}
Contract ID for a vote request.
{% enddocs %}

{% docs col_voter %}
Party identifier for a party casting a vote.
{% enddocs %}

{% docs col_vote_accept %}
Boolean indicating whether a vote is to accept (TRUE) or reject (FALSE) a proposal.
{% enddocs %}

{% docs col_request_cid %}
Generic contract ID for a request.
{% enddocs %}

{% docs col_amulet_rules_cid %}
Contract ID for an AmuletRules contract.
{% enddocs %}

{% docs col_closing_sv %}
Party identifier for the super validator closing a vote.
{% enddocs %}

{% docs col_outcome %}
Result of a vote: typically 'VRO_Accepted' or 'VRO_Rejected'.
{% enddocs %}

{% docs col_outcome_effective_at %}
Timestamp when a vote outcome becomes effective.
{% enddocs %}

{% docs col_completed_at %}
Timestamp when voting was completed and closed.
{% enddocs %}

{% docs col_accepted_svs %}
Array of super validator party IDs who voted to accept a proposal.
{% enddocs %}

{% docs col_rejected_svs %}
Array of super validator party IDs who voted to reject a proposal.
{% enddocs %}

{% docs col_abstaining_svs %}
Array of super validator party IDs who abstained from voting.
{% enddocs %}

{% docs col_offboarded_voters %}
Array of voter party IDs who were offboarded before voting completed.
{% enddocs %}

{% docs col_tracking_cid %}
Contract ID used for tracking a request through its lifecycle.
{% enddocs %}

{% docs col_vote_before %}
Timestamp by which votes must be cast.
{% enddocs %}

{% docs col_total_votes_cast %}
Total number of votes cast on a proposal.
{% enddocs %}

{% docs col_abstaining_count %}
Count of validators who abstained from voting.
{% enddocs %}

{% docs col_offboarded_count %}
Count of validators who were offboarded before voting completed.
{% enddocs %}

{% docs col_accept_votes %}
Count of votes to accept a proposal.
{% enddocs %}

{% docs col_reject_votes %}
Count of votes to reject a proposal.
{% enddocs %}

{% docs col_choice_argument %}
JSON object containing the arguments passed to a choice/action.
{% enddocs %}

{% docs col_create_arguments %}
JSON object containing the arguments used to create a contract.
{% enddocs %}

{% docs col_interface_id %}
Identifier for a Canton interface implemented by a contract.
{% enddocs %}
