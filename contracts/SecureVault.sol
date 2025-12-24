// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthorizationManager {
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes calldata signature
    ) external returns (bool);
}

/**
 * @title SecureVault
 * @dev Vault contract that holds funds and executes withdrawals
 * only when authorized by the AuthorizationManager
 */
contract SecureVault {
    // Authorization manager reference
    IAuthorizationManager public authManager;

    // Track total deposits
    uint256 public totalDeposited;

    // Track balance
    mapping(address => uint256) public balances;

    // Events
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount, bytes32 authId);

    constructor(address _authManager) {
        require(_authManager != address(0), "Invalid auth manager");
        authManager = _authManager;
    }

    /**
     * @dev Accept deposits
     */
    receive() external payable {
        totalDeposited += msg.value;
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw funds with authorization
     * @param recipient The withdrawal recipient
     * @param amount The withdrawal amount
     * @param authId Unique authorization identifier
     * @param signature The signature of the authorization
     */
    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes calldata signature
    ) external {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient vault balance");

        // Verify authorization before updating state
        bool isAuthorized = authManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            authId,
            signature
        );

        require(isAuthorized, "Authorization failed");

        // Update state after verification
        totalDeposited -= amount;

        // Transfer funds
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        // Emit event
        emit Withdrawn(recipient, amount, authId);
    }

    /**
     * @dev Get vault balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
