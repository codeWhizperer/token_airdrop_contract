
use starknet::ContractAddress;


#[starknet::contract]
mod ERC20 {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use core::option::OptionTrait;
    use core::integer::Zeroable;
    use core::integer::BoundedInt;
    use merkle::interface;


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        amount: u256
    }

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balance: LegacyMap::<ContractAddress, u256>,
        allowance: LegacyMap::<(ContractAddress, ContractAddress), u256>
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252, decimals: u8) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimals.write(decimals);
    }

    impl IERC20Impl of interface::IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }
        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance.read(account)
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn mint(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let prevBalance = self.balance.read(caller);
            let prevT = self.total_supply.read();
            self.balance.write(caller, prevBalance + amount);
            self.total_supply.write(prevT + amount);
            self
                .emit(
                    Event::Transfer(
                        Transfer { sender: Zeroable::zero(), recipient: caller, amount }
                    )
                );
        }

        fn allowances(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowance.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            self._spend_allowance(sender, caller, amount);
            self._transfer(caller, recipient, amount);
            true
        }
    }


    #[generate_trait]
    impl IERC20Internal of IERC20InternalTrait {
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            assert(!sender.is_zero(), 'sender_is_zero');
            assert(!recipient.is_zero(), 'sender_is_zero');
            let prev_sender_balance = self.balance.read(sender);
            let prev_recipient_balance = self.balance.read(recipient);
            self.balance.write(sender, self.balance.read(sender) - amount);
            self.balance.write(recipient, self.balance.read(recipient) + amount);
            self.emit(Event::Transfer(Transfer { sender, recipient, amount }));
        }
        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            self.allowance.write((owner, spender), amount);
            self.emit(Event::Approval(Approval { owner, spender, amount }))
        }

        fn _spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance = self.allowance.read((owner, spender));
            if current_allowance != BoundedInt::max() {
                self._approve(owner, spender, current_allowance - amount);
            }
        }
        fn _increase_allowance(
            ref self: ContractState,
            owner: ContractAddress,
            spender: ContractAddress,
            amount_to_add: u256
        ) {
            let caller = get_caller_address();
            let current_allowance = self.allowance.read((owner, spender));
            self._approve(caller, spender, current_allowance + amount_to_add);
        }

        fn _decrease_allowance(
            ref self: ContractState,
            owner: ContractAddress,
            spender: ContractAddress,
            amount_to_sub: u256
        ) {
            let caller = get_caller_address();
            let current_allowance = self.allowance.read((owner, spender));
            self._approve(caller, spender, current_allowance - amount_to_sub);
        }
    }
}


