use starknet::ContractAddress;
#[starknet::interface]
trait IERC20<TState> {
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;
    fn mint(ref self: TState, amount: u256);
     fn allowances(
            self: @TState, owner: ContractAddress, spender: ContractAddress
        ) -> u256;
}