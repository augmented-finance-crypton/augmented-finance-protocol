// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../../../tools/Errors.sol';
import '../../../interfaces/ICreditDelegationToken.sol';
import '../../../dependencies/openzeppelin/contracts/SafeMath.sol';
import '../../../dependencies/openzeppelin/contracts/ERC20Events.sol';
import './PoolTokenBase.sol';

/// @dev Base contract for a non-transferrable debt tokens: StableDebtToken and VariableDebtToken
abstract contract DebtTokenBase is PoolTokenBase('', '', 0), ERC20Events, ICreditDelegationToken {
  using SafeMath for uint256;

  mapping(address => mapping(address => uint256)) internal _borrowAllowances;

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external override {
    _borrowAllowances[msg.sender][delegatee] = amount;
    emit BorrowAllowanceDelegated(msg.sender, delegatee, _underlyingAsset, amount);
  }

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser)
    external
    view
    override
    returns (uint256)
  {
    return _borrowAllowances[fromUser][toUser];
  }

  function transfer(address, uint256) public override returns (bool) {
    notSupported();
    _mutable();
  }

  function allowance(address, address) public view override returns (uint256) {
    this;
    return 0;
  }

  function approve(address, uint256) public override returns (bool) {
    notSupported();
    _mutable();
  }

  function transferFrom(
    address,
    address,
    uint256
  ) public override returns (bool) {
    notSupported();
    _mutable();
  }

  function notSupported() private pure {
    revert('NOT_SUPPORTED');
  }

  function _mutable() private {}

  function _decreaseBorrowAllowance(
    address delegator,
    address delegatee,
    uint256 amount
  ) internal {
    uint256 newAllowance =
      _borrowAllowances[delegator][delegatee].sub(amount, Errors.BORROW_ALLOWANCE_NOT_ENOUGH);

    _borrowAllowances[delegator][delegatee] = newAllowance;

    emit BorrowAllowanceDelegated(delegator, delegatee, _underlyingAsset, newAllowance);
  }
}
