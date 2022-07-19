%lang starknet

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.math import assert_le, assert_le_felt, assert_nn_le, assert_ge
from starkware.cairo.common.pow import pow

from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address, get_block_timestamp)


from contracts.oracle_controller.IEmpiricOracle import IEmpiricOracle

from openzeppelin.token.erc20.library import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_initializer,
    ERC20_approve,
    ERC20_increaseAllowance,
    ERC20_decreaseAllowance,
    ERC20_transfer,
    ERC20_transferFrom,
    ERC20_mint
)

const EMPIRIC_ORACLE_ADDRESS = 0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4
const KEY = 28556963469423460  # str_to_felt("eth/usd")
const AGGREGATION_MODE = 0  # default

@storage_var
func bets_for(address:felt) -> (num:felt):
end

@storage_var
func bets_against(address:felt) -> (num:felt):
end

@storage_var
func total_for_amount() -> (num:felt):
end

@storage_var
func total_against_amount() -> (num:felt):
end

@storage_var
func total_amount() -> (num:felt):
end

@storage_var
func end_date() -> (num:felt):
end

@storage_var
func result() -> (num:felt):
end

@external
func place_bet_for{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(amount: felt):
    let (timestamp) = get_block_timestamp()
    let (final_timestamp) = end_date.read()
    assert_le(timestamp, final_timestamp)
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    ERC20_transferFrom(caller_address, contract_address, amount)
    let (num) = bets_for.read(address = caller_address)
    bets_for.write(caller_address, num + amount)
    let (total_for) = total_for_amount.read()
    total_for_amount.write(total_for + amount)
    let (total_amount) = total_amount.read()
    total_amount.write(total_amount + amount)
end

@external
func place_bet_against{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(amount: felt):
    let (timestamp) = get_block_timestamp()
    let (final_timestamp) = end_date.read()
    assert_le(timestamp, final_timestamp)
    let (caller_address) = get_caller_address()
    let (contract_address) = get_contract_address()
    ERC20_transferFrom(caller_address, contract_address, amount)
    let (num) = bets_against.read(address = caller_address)
    bets_against.write(caller_address, num + amount)
    let (total_against) = total_against_amount.read()
    total_against_amount.write(total_against + amount)
    let (total_amount) = total_amount.read()
    total_amount.write(total_amount + amount)
end

@external
func fetch_truth{syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*}(amount: felt):
    let (timestamp) = get_block_timestamp()
    let (final_timestamp) = end_date.read()
    assert_ge(timestamp, final_timestamp)
    let (is_above_threshold) = check_eth_usd_threshold(2000)
    result.write(is_above_threshold)
end



@view
func check_eth_usd_threshold{syscall_ptr : felt*, range_check_ptr}(threshold : felt) -> (
    is_above_threshold : felt
):
    alloc_locals

    let (eth_price, decimals, timestamp, num_sources_aggregated) = IEmpiricOracle.get_value(
        EMPIRIC_ORACLE_ADDRESS, KEY, AGGREGATION_MODE
    )
    let (multiplier) = pow(10, decimals)

    let shifted_threshold = threshold * multiplier
    let (is_above_threshold) = is_le(shifted_threshold, eth_price)
    return (is_above_threshold)
end