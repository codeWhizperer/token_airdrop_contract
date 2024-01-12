use starknet::ContractAddress;
#[starknet::interface]
trait IAirdrop<TContractState> {
    fn claim(
        ref self: TContractState, claimee: ContractAddress, amount: u128, proof: Array::<felt252>
    );
}


#[starknet::contract]
mod Airdrop {
    use merkle::interface::IERC20DispatcherTrait;
use merkle::merkle_tree::{MerkleTreeTrait, MerkleTree};
    use starknet::ContractAddress;
    use core::array::ArrayTrait;
    use core::hash::LegacyHash;
    use core::traits::Into;
    use starknet::ContractAddressIntoFelt252;
    use core::traits::TryInto;
    use core::option::OptionTrait;
    use merkle::erc20::ERC20;
    use merkle::interface::IERC20Dispatcher;

    #[derive(starknet::Event, Drop)]
    #[event]
    enum Event {
        Claimed: Claimed
    }

    #[derive(starknet::Event, Drop)]
    struct Claimed {
        address: ContractAddress,
        received: u128
    }

    #[storage]
    struct Storage {
        token_contract_address: ContractAddress,
        airdrop_claimed: LegacyMap<ContractAddress, u128>,
        has_claimed: LegacyMap<ContractAddress,bool>,
        merkle_root: felt252
    }

    #[constructor]
    fn constructor(ref self: ContractState, _merkle_root:felt252, _token_contract:ContractAddress) {
        self.merkle_root.write(_merkle_root);
        self.token_contract_address.write(_token_contract);
    }

    #[external(v0)]
    impl Airdrop of super::IAirdrop<ContractState> {
        fn claim(
            ref self: ContractState, claimee: ContractAddress, amount: u128, proof: Array::<felt252>
        ) {
            let status:bool = self.has_claimed.read(claimee);
            assert(!status, 'already claimed');
            let mut merkle_tree = MerkleTreeTrait::new();
            let amount_felt: felt252 = amount.into();
            let leaf = LegacyHash::hash(claimee.into(), amount_felt);

            let root = merkle_tree.compute_root(leaf, proof.span());
            let state = ERC20::unsafe_new_contract_state();
            let stored_root = self.merkle_root.read();
            assert(root == stored_root, 'invalid proof');
            let token_addr = self.token_contract_address.read();
            IERC20Dispatcher { contract_address: token_addr }.transfer(claimee, u256 { high: 0, low: amount });
            self.emit(Claimed { address: claimee, received: amount });
        }
    }
}
