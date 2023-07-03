// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IAccountPermissionsSimple {
    /*///////////////////////////////////////////////////////////////
                                Types
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice The payload that must be signed by an authorized wallet to set permissions for a signer to use the smart wallet.
     *
     *  @param signer The addres of the signer to give permissions.
     *  @param approvedTargets The list of approved targets that a role holder can call using the smart wallet.
     *  @param nativeTokenLimitPerTransaction The maximum value that can be transferred by a role holder in a single transaction.
     *  @param permissionStartTimestamp The UNIX timestamp at and after which a signer has permission to use the smart wallet.
     *  @param permissionEndTimestamp The UNIX timestamp at and after which a signer no longer has permission to use the smart wallet.
     *  @param reqValidityStartTimestamp The UNIX timestamp at and after which a signature is valid.
     *  @param reqValidityEndTimestamp The UNIX timestamp at and after which a signature is invalid/expired.
     *  @param uid A unique non-repeatable ID for the payload.
     */
    struct SignerPermissionRequest {
        address signer;
        address[] approvedTargets;
        uint256 nativeTokenLimitPerTransaction;
        uint128 permissionStartTimestamp;
        uint128 permissionEndTimestamp;
        uint128 reqValidityStartTimestamp;
        uint128 reqValidityEndTimestamp;
        bytes32 uid;
    }

    /**
     *  @notice The permissions that a signer has to use the smart wallet.
     *
     *  @param approvedTargets The list of approved targets that a role holder can call using the smart wallet.
     *  @param nativeTokenLimitPerTransaction The maximum value that can be transferred by a role holder in a single transaction.
     *  @param permissionStartTimestamp The UNIX timestamp at and after which a signer has permission to use the smart wallet.
     *  @param permissionEndTimestamp The UNIX timestamp at and after which a signer no longer has permission to use the smart wallet.
     */
    struct SignerPermissions {
        address[] approvedTargets;
        uint256 nativeTokenLimitPerTransaction;
        uint128 permissionStartTimestamp;
        uint128 permissionEndTimestamp;
    }

    /**
     *  @notice Internal struct for storing permissions for a signer (without approved targets).
     *
     *  @param nativeTokenLimitPerTransaction The maximum value that can be transferred by a role holder in a single transaction.
     *  @param permissionStartTimestamp The UNIX timestamp at and after which a signer has permission to use the smart wallet.
     *  @param permissionEndTimestamp The UNIX timestamp at and after which a signer no longer has permission to use the smart wallet.
     */
    struct SignerPermissionsStatic {
        uint256 nativeTokenLimitPerTransaction;
        uint128 permissionStartTimestamp;
        uint128 permissionEndTimestamp;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when permissions for a signer are updated.
    event SignerPermissionsUpdated(
        address indexed authorizingSigner,
        address indexed targetSigner,
        SignerPermissionRequest permissions
    );

    /// @notice Emitted when an admin is set or removed.
    event AdminUpdated(address indexed signer, bool isAdmin);

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the given account is an admin.
    function isAdmin(address signer) external view returns (bool);

    /// @notice Returns whether the given account is an active signer on the account.
    function isActiveSigner(address signer) external view returns (bool);

    /// @notice Returns the restrictions under which a signer can use the smart wallet.
    function getPermissionsForSigner(address signer) external view returns (SignerPermissions memory permissions);

    /// @dev Verifies that a request is signed by an authorized account.
    function verifySignerPermissionRequest(SignerPermissionRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds / removes an account as an admin.
    function setAdmin(address account, bool isAdmin) external;

    /// @notice Sets the permissions for a given signer.
    function setPermissionsForSigner(SignerPermissionRequest calldata req, bytes calldata signature) external;
}