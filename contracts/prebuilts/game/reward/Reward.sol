// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IReward } from "./IReward.sol";
import { GameLibrary } from "../core/LibGame.sol";
import { RewardStorage } from "./RewardStorage.sol";

contract Reward is IReward, GameLibrary {
    using RewardStorage for RewardStorage.Data;

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Register a reward.
    function registerReward(string memory identifier, RewardInfo calldata rewardInfo) external onlyManager {
        _registerReward(identifier, rewardInfo);
    }

    /// @dev Unregister a reward.
    function unregisterReward(string memory identifier) external onlyManager {
        _unregisterReward(identifier);
    }

    /// @dev Claim a reward.
    function claimReward(address receiver, string memory identifier) external onlyManager {
        _claimReward(receiver, identifier);
    }

    /*///////////////////////////////////////////////////////////////
                        Signature-based external functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Register a reward with a signature.
    function registerRewardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (string memory identifier, RewardInfo memory rewardInfo) = abi.decode(req.data, (string, RewardInfo));
        _registerReward(identifier, rewardInfo);
    }

    /// @dev Unregister a reward with a signature.
    function unregisterRewardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        string memory identifier = abi.decode(req.data, (string));
        _unregisterReward(identifier);
    }

    /// @dev Claim a reward with a signature.
    function claimRewardWithSignature(GameRequest calldata req, bytes calldata signature)
        external
        onlyManagerApproved(req, signature)
    {
        (address receiver, string memory identifier) = abi.decode(req.data, (address, string));
        _claimReward(receiver, identifier);
    }

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Get reward information by identifier.
    function getRewardInfo(string calldata identifier) external view returns (RewardInfo memory rewardInfo) {
        rewardInfo = RewardStorage.rewardStorage().rewardInfo[_getRewardBytes32(identifier)];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Register a reward with signature.
    function _registerReward(string memory identifier, RewardInfo memory rewardInfo) internal {
        RewardStorage.Data storage rs = RewardStorage.rewardStorage();
        rs.rewardInfo[_getRewardBytes32(identifier)] = rewardInfo;
        emit RegisterReward(identifier, rewardInfo);
    }

    /// @dev Unregister a reward with signature.
    function _unregisterReward(string memory identifier) internal {
        RewardStorage.Data storage rs = RewardStorage.rewardStorage();
        delete rs.rewardInfo[_getRewardBytes32(identifier)];
        emit UnregisterReward(identifier);
    }

    /// @dev Claim a reward with signature.
    function _claimReward(address receiver, string memory identifier) internal {
        IReward.RewardInfo memory rewardInfo = RewardStorage.rewardStorage().rewardInfo[_getRewardBytes32(identifier)];
        if (rewardInfo.rewardAddress == address(0)) revert("Reward: Reward not registered");
        if (receiver == address(0)) revert("Reward: Receiver cannot be zero address");
        if (rewardInfo.rewardType == RewardType.ERC20) {
            _transferERC20(receiver, rewardInfo.rewardAddress, rewardInfo.rewardAmount);
        } else if (rewardInfo.rewardType == RewardType.ERC721) {
            _transferERC721(receiver, rewardInfo.rewardAddress, rewardInfo.rewardTokenId);
        } else if (rewardInfo.rewardType == RewardType.ERC1155) {
            _transferERC1155(receiver, rewardInfo.rewardAddress, rewardInfo.rewardTokenId, rewardInfo.rewardAmount);
        } else {
            revert("Reward: Invalid reward type");
        }
        emit ClaimReward(receiver, identifier, rewardInfo);
    }

    /*///////////////////////////////////////////////////////////////
                        Private functions
    //////////////////////////////////////////////////////////////*/

    function _getRewardBytes32(string memory identifier) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(identifier));
    }

    function _transferERC20(
        address receiver,
        address rewardAddress,
        uint256 rewardAmount
    ) private {
        (bool success, bytes memory data) = rewardAddress.call(
            abi.encodeWithSelector(0xa9059cbb, receiver, rewardAmount)
        );
        if (!success) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            } else {
                revert("Reward: Transfer ERC20 failed");
            }
        }
    }

    function _transferERC721(
        address receiver,
        address rewardAddress,
        uint256 rewardTokenId
    ) private {
        (bool success, bytes memory data) = rewardAddress.call(
            abi.encodeWithSelector(0x40c10f19, receiver, rewardTokenId)
        );
        if (!success) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            } else {
                revert("Reward: Transfer ERC721 failed");
            }
        }
    }

    function _transferERC1155(
        address receiver,
        address rewardAddress,
        uint256 rewardTokenId,
        uint256 rewardAmount
    ) private {
        (bool success, bytes memory data) = rewardAddress.call(
            abi.encodeWithSelector(0xa22cb465, receiver, rewardTokenId, rewardAmount, "")
        );
        if (!success) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            } else {
                revert("Reward: Transfer ERC1155 failed");
            }
        }
    }
}