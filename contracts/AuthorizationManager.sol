// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AuthorizationManager
 * @dev Manages withdrawal authorizations with replay protection
 * Each authorization can only be used once
 */
contract AuthorizationManager is Ownable {
    using ECDSA for bytes32;

    // Signer address for authorizations
    address public signer;

    // Track which authorizations have been consumed
    mapping(bytes32 => bool) public usedAuthorizations;

    // Events
    event SignerUpdated(address indexed newSigner);
    event AuthorizationConsumed(bytes32 indexed authId);

    constructor(address _signer) {
        require(_signer != address(0), "Invalid signer");
        signer = _signer;
    }

    /**
     * @dev Update the signer address (only owner)
     */
    function updateSigner(address _newSigner) external onlyOwner {
        require(_newSigner != address(0), "Invalid signer");
        signer = _newSigner;
        emit SignerUpdated(_newSigner);
    }

    /**
     * @dev Verify and consume an authorization
     * @param vault The vault contract address
     * @param recipient The withdrawal recipient
     * @param amount The withdrawal amount
     * @param authId Unique authorization identifier
     * @param signature The signature of the authorization data
     */
    function verifyAuthorization(
        address vault,
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes calldata signature
    ) external returns (bool) {
        // Check authorization hasn't been used
        require(!usedAuthorizations[authId], "Authorization already used");

        // Construct the message hash
        bytes32 messageHash = keccak256(abi.encodePacked(
            vault,
            recipient,
            amount,
            authId,
            block.chainid
        ));

        // Verify signature
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(signature);

        require(recoveredSigner == signer, "Invalid signature");

        // Mark as used
        usedAuthorizations[authId] = true;
        emit AuthorizationConsumed(authId);

        return true;
    }

    /**
     * @dev Check if an authorization has been used
     */
    function isAuthorizationUsed(bytes32 authId) external view returns (bool) {
        return usedAuthorizations[authId];
    }
}
