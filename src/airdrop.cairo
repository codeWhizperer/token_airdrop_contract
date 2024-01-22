// Example of Airdrop contract
// Coded with Cairo 2.4.0 
// token_contract_address: 0x53cdac997da00f8e113a8b2078d3797d9ce6cde4879d3d36726decdbba8050
// merkle_airdrop_address:0x79f31526432c6b9e92b1412312a1a449deed9586a44fe7dd6396819d3ec5276
use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn totalSupply(self: @TContractState) -> u256;
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256);
    fn increaseAllowance(ref self: TContractState, spender: ContractAddress, added_value: u256);
    fn decreaseAllowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    );
}

#[starknet::interface]
trait IMerkleVerify<TContractState> {
    fn get_root(self: @TContractState) -> felt252;
    fn verify_from_leaf_hash(
        self: @TContractState, leaf_hash: felt252, proof: Array<felt252>
    ) -> bool;
    fn verify_from_leaf_array(
        self: @TContractState, leaf_array: Array<felt252>, proof: Array<felt252>
    ) -> bool;
    fn verify_from_leaf_airdrop(
        self: @TContractState, address: ContractAddress, amount: u256, proof: Array<felt252>
    ) -> bool;
    fn hash_leaf_array(self: @TContractState, leaf: Array<felt252>) -> felt252;
}

#[starknet::interface]
trait IAirdrop<TContractState> {
    fn get_merkle_address(self: @TContractState) -> ContractAddress;
    // fn get_time(self: @TContractState) -> u64;
    fn is_address_airdropped(self: @TContractState, address: ContractAddress) -> bool;
    fn request_airdrop(
        ref self: TContractState, address: ContractAddress, amount: u256, proof: Array<felt252>
    );
}

#[starknet::contract]
mod AirdropT {
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::{IMerkleVerifyDispatcher, IMerkleVerifyDispatcherTrait};
    use super::IAirdrop;
    use core::option::OptionTrait;
    use starknet::{ContractAddress, SyscallResultTrait, contract_address_const};
    // use starknet::get_block_timestamp;
    use core::hash::HashStateExTrait;
    use core::hash::{HashStateTrait, Hash};
    use core::array::{ArrayTrait, SpanTrait};

    #[storage]
    struct Storage {
        erc20_address: ContractAddress,
        start_time: u64,
        merkle_address: ContractAddress,
        erc20_owner: ContractAddress,
        merkle_root: felt252,
        airdrop_performed: LegacyMap::<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Claimed: Claimed
    }

    #[derive(Drop, starknet::Event)]
    struct Claimed {
        address: ContractAddress,
        amount: u256
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        erc20_address: ContractAddress,
        merkle_address: ContractAddress,
        erc20_owner: ContractAddress,
    ) {
        self.erc20_address.write(erc20_address);
        self.merkle_address.write(merkle_address);
        self.erc20_owner.write(erc20_owner);
        // self.start_time.write(start_time);
    }

    #[external(v0)]
    impl MerkleVerifyContract of super::IAirdrop<ContractState> {
        // returns the address of the merkle verify contract for this airdrop
        fn get_merkle_address(self: @ContractState) -> ContractAddress {
            self.merkle_address.read()
        }

        // returns the time of start of the airdrop
        // fn get_time(self: @ContractState) -> u64 {
        //     get_block_timestamp()
        // }

        fn is_address_airdropped(self: @ContractState, address: ContractAddress) -> bool {
            self.airdrop_performed.read(address)
        }

      fn request_airdrop(
            ref self: ContractState, address: ContractAddress, amount: u256, proof: Array<felt252>
        ) {
            let already_airdropped: bool = self.airdrop_performed.read(address);
            assert(!already_airdropped, 'Address already airdropped');
            // let current_time: u64 = get_block_timestamp();
            let airdrop_start_time: u64 = self.start_time.read();
            // assert(current_time >= airdrop_start_time, 'Airdrop has not started yet.');
        
            let is_request_valid: bool = IMerkleVerifyDispatcher {
                contract_address: self.merkle_address.read()
            }
                .verify_from_leaf_airdrop( address, amount, proof);
            assert(is_request_valid, 'Proof not valid.'); // revert if not valid

            // Airdrop
            // Register the address as already airdropped
            self.airdrop_performed.write(address, true);
            // to be sure to perform the airdrop only once per address.

            // Perform here your transfer of token.
            IERC20Dispatcher { contract_address: self.erc20_address.read() }
                .transfer_from(self.erc20_owner.read(), address, amount);
            // if needed, create some events.
            self.emit(Claimed { address: address, amount: amount });
            return ();
        }
    }
}


//RPC: starknet_estimateFee with params {"request":[{"type":"INVOKE","sender_address":"0x143255712596fe3b1ebb6a4309230d2592034e6fe544e33acf2848fe7cf5fa7","calldata":["0x1","0x9d1c5b3d0882dfaf6d8ed591d8ab7fcab3ea4a189179b66a9b925bbebc59c2","0x3d05b7bc194a1006aecda433c763ca000b3382f88e41ceeb3e7f636bc582473","0x0","0x7","0x7","0x143255712596fe3b1ebb6a4309230d2592034e6fe544e33acf2848fe7cf5fa7","0xfa","0x0","0x3","0x40a6dba21b22596e979a1555a278ca58c11b5cd5e46f5801c1af8c4ab518845","0x1cb465ce3f2e1671e0b4efd009d7d24a35002d545f35149c118dc999f87b160","0x51c01d843798398dfdd4b6b23138b19a8ffe74b5e1c27ccd8b175b05a50cb75"],"version":"0x100000000000000000000000000000001","signature":["0x0","0x0","0x0"],"nonce":"0x7","max_fee":"0x0"}],"block_id":"pending"}
 //40: Contract error: {"revert_error":"reverted: Error in the called contract (0x0143255712596fe3b1ebb6a4309230d2592034e6fe544e33acf2848fe7cf5fa7):\nError at pc=0:10:\nGot an exception while executing a hint.\nCairo traceback (most recent call last):\nUnknown location (pc=0:228)\nUnknown location (pc=0:214)\n\nError in the called contract (0x0143255712596fe3b1ebb6a4309230d2592034e6fe544e33acf2848fe7cf5fa7):\nError at pc=0:37:\nGot an exception while executing a hint.\nCairo traceback (most recent call last):\nUnknown location (pc=0:8783)\nUnknown location (pc=0:8731)\nUnknown location (pc=0:6218)\nUnknown location (pc=0:6239)\n\nError in the called contract (0x009d1c5b3d0882dfaf6d8ed591d8ab7fcab3ea4a189179b66a9b925bbebc59c2):\nError at pc=0:1864:\nGot an exception while executing a hint: Custom Hint Error: Entry point EntryPointSelector(StarkFelt(\"0x0041b033f4a31df8067c24d1e9b550a2ce75fd4a29e1147af9752174f0e6cb20\")) not found in contract.\nCairo traceback (most recent call last):\nUnknown location (pc=0:343)\nUnknown location (pc=0:1023)\n"}