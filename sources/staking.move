


module contract_addr::staking {
    use std::signer;
    use std::error;
    use std::string::String;
    use std::vector;

    use aptos_token::token::{Self, TokenId};

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    use aptos_std::table::{Self, Table};

    // ERRORS
    const ERROR_ACCOUNT_IS_NOT_AN_OWNER: u64 = 0;
    const ERROR_ACCOUNT_IS_NOT_COLLECTION_CREATOR: u64 = 1;
    const ERROR_STAKING_POOL_IS_ALREADY_INITIALIZED: u64 = 2;
    const ERROR_STAKING_POOL_IS_NOT_INITIALIZED: u64 = 3;
    const ERROR_COLLECTION_DATA_IS_NOT_CORRECT: u64 = 4;
    const ERROR_TOKEN_ALREADY_STAKED: u64 = 5;

    // STRUCTS

    struct StakingPool<phantom CollectionType> has key {
        collection: String,
        creator: String,
        amount_staked: u64,
        stake_events: EventHandle<StakeEvent>,
        unstake_events: EventHandle<UnstakeEvent>,
        claim_events: EventHandle<ClaimEvent>
    }

    struct ResourceStakingData<phantom CollectionType> has key {
        staker: address,
        staking_capability: account::SignerCapability
    }

    struct StakingData<phantom CollectionType> has key {
        token_staking_datas: Table<TokenId, TokenStakingData>,
        amount_staked: u64,
        claimed: u64,
    }

    struct TokenStakingData has store {
        start_timestamp: u64,
        staking_address: address,
    }

    struct StakeEvent has drop, store {
        token_name: String,
        account_address: adderss,
    }

    struct UnstakeEvent has drop, store {
        token_name: String,
        account_address: adderss,
    }

    struct ClaimEvent has drop, store {
        token_name: String,
        account_address: address,
        amount: u64
    }

    
    // ASSERTS
    
    fun assert_address_is_owner(account_address: address) {
        assert!(
            account_address == @contract_addr,
            error::invalid_argument(ERROR_ACCOUNT_IS_NOT_AN_OWNER)
        );
    }

    fun assert_account_is_collection_creator(account_address: address, collection_name: String)  {
        assert!(
            token::check_collection_exists(account_address, collection_name),
            error::invalid_state(ERROR_ACCOUNT_IS_NOT_COLLECTION_CREATOR)
        );
    }

    fun assert_staking_pool_is_not_initialized() {
        assert!(
            !exists<StakingPool>(@contract_addr),
            error::invalid_state(ERROR_STAKING_POOL_IS_ALREADY_INITIALIZED)
        );
    }

    fun assert_staking_pool_is_initialized() {
        assert!(
            exists<StakingPool<CollectionType>>(@contract_addr),
            error::invalid_state(ERROR_STAKING_POOL_IS_NOT_INITIALIZED)
        );
    }

    fun assert_collection_data_is_correct<CollectionType>(collection: String, creator: address) acquires StakingPool {
        let staking_pool = borrow_global<StakingPool<CollectionType>>(@contract_addr);

        assert!(
            staking_pool.collection == collection && staking_pool.creator == creator,
            error::invalid_state(ERROR_COLLECTION_DATA_IS_NOT_CORRECT)
        );
    }

    fun assert_token_is_not_staked<CollectionType>(account_address: address, token_id: TokenId) acquires StakingData {
        let staking_data = borrow_global<StakingData<CollectionType>>(account_address);
        
        assert!(
            table::contains(&staking_data.token_staking_datas, token_id),
            error::invalid_state(ERROR_TOKEN_ALREADY_STAKED)
        );
    }


    public fun init_pool<CollectionType>(
        account: &signer,
        collection: String,
        creator: address
    ) {
        let account_address = signer::address_of(account);
        
        assert_address_is_owner(account_address);

        assert_account_is_collection_creator(creator, collection);

        assert_staking_pool_is_not_initialized<CollectionType>();


        move_to(account, StakingPbirthday_giftsool<CollectionType> {
            collection,
            creator,
            amount_staked: 0,
            stake_events: account::new_event_handle<StakeEvent>(account),
            unstake_events: account::new_event_handle<UnstakeEvent>(account),
            claim_events: account::new_event_handle<UnstakeEvent>(account)
        });
    }

    public fun stake<CollectionType>(
        account: &signer,
        creator: address,
        collection: String,
        token_name: String,
        property_version: u64
    ) {
        let account_address = signer::address_of(account);

        assert_staking_pool_is_initialized<CollectionType>();

        assert_collection_data_is_correct<CollectionType>();
        

        // initializing StakingData
        if (!exists<StakingData<CollectionType>>) {
            move_to(account, StakingData<CollectionType> {
                token_staking_datas: table::new(),
                amount_staked: 0,
                claimed: 0
            });
        }

        let staking_data = borrow_global_mut<StakingData<CollectionType>>(account_address);

        let token_id = token::create_token_id_raw(creator, collection, token_name, property_version);

        assert_token_is_not_staked(account_address, token_id);

        let seed = vector::empty<u8>();
        vector::append<u8>(&mut seed, collection.bytes);
        vector::append<u8>(&mut seed, token_name.bytes);

        // creating resource account
        let (resource, signer_cap) = account::create_resource_account(account, seed);

        // enable opt-in 

        // transfer token to the resource account

        // store data inside the resource account
    }

}