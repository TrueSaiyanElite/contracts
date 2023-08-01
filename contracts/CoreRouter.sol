// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "lib/dynamic-contracts/src/interface/IBaseRouter.sol";

// Core
import "lib/dynamic-contracts/src/core/Router.sol";

// Utils
import "lib/dynamic-contracts/src/presets/utils/StringSet.sol";
import "lib/dynamic-contracts/src/presets/utils/ExtensionState.sol";
import "./extension/PermissionOverride.sol";
import "./eip/ERC165.sol";

// Fixed extensions
import "./extension/Ownable.sol";
import "./extension/ContractMetadata.sol";

contract CoreRouter is IBaseRouter, Router, ExtensionState, ContractMetadata, Ownable, ERC165 {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        _setupOwner(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                            ERC 165 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IBaseRouter).interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(Extension memory _extension) external {
        require(_canSetExtension(), "CoreRouter: caller not authorized.");

        _addExtension(_extension);
    }

    /// @dev Updates an existing extension in the router, or overrides a default extension.
    function updateExtension(Extension memory _extension) external {
        require(_canSetExtension(), "CoreRouter: caller not authorized.");

        _updateExtension(_extension);
    }

    /// @dev Removes an existing extension from the router.
    function removeExtension(string memory _extensionName) external {
        require(_canSetExtension(), "CoreRouter: caller not authorized.");

        _removeExtension(_extensionName);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions stored. Override default lugins stored in router are
     *          given precedence over default extensions in DefaultExtensionSet.
     */
    function getAllExtensions() external view returns (Extension[] memory allExtensions) {
        string[] memory names = _extensionStateStorage().extensionNames.values();
        uint256 len = names.length;

        allExtensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allExtensions[i] = _extensionStateStorage().extensions[names[i]];
        }
    }

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory _extensionName) public view returns (Extension memory) {
        return _extensionStateStorage().extensions[_extensionName];
    }

    /// @dev Returns the extension's implementation smart contract address.
    function getExtensionImplementation(string memory _extensionName) external view returns (address) {
        return getExtension(_extensionName).metadata.implementation;
    }

    /// @dev Returns all functions that belong to the given extension contract.
    function getAllFunctionsOfExtension(string memory _extensionName)
        external
        view
        returns (ExtensionFunction[] memory)
    {
        return getExtension(_extensionName).functions;
    }

    /// @dev Returns the extension metadata for a given function.
    function getExtensionForFunction(bytes4 _functionSelector) public view returns (ExtensionMetadata memory) {
        return _extensionStateStorage().extensionMetadata[_functionSelector];
    }

    /// @dev Returns the extension implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        return getExtensionForFunction(_functionSelector).implementation;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the storage of this contract.
    function _extensionStateStorage() internal pure returns (ExtensionStateStorage.Data storage data) {
        data = ExtensionStateStorage.extensionStateStorage();
    }

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}