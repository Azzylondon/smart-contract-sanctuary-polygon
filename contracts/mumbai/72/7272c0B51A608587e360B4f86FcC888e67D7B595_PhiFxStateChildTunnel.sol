// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.3;

import { FxBaseChildTunnel } from "@polymarket/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";
import { IPhiMap } from "./interfaces/IPhiMap.sol";

/**
 * @title FxStateChildTunnel
 */
contract PhiFxStateChildTunnel is FxBaseChildTunnel {
    uint256 public latestStateId;
    address public latestRootMessageSender;
    bytes public latestData;

    IPhiMap private _map;
    bytes32 public constant CERATE = keccak256("CERATE");
    bytes32 public constant CHANGE = keccak256("CHANGE");

    event MessageFromRoot(bytes32 syncType, bytes syncData);

    constructor(address _fxChild, IPhiMap map) FxBaseChildTunnel(_fxChild) {
        _map = map;
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        latestStateId = stateId;
        latestRootMessageSender = sender;
        latestData = data;
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));
        emit MessageFromRoot(syncType, syncData);
        if (syncType == CERATE) {
            _mapCreate(syncData);
        } else if (syncType == CHANGE) {
            _ownerChange(syncData);
        } else {
            revert("FxChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _mapCreate(bytes memory syncData) internal {
        (string memory name, address sender) = abi.decode(syncData, (string, address));
        _map.create(name, msg.sender);
    }

    function _ownerChange(bytes memory syncData) internal {
        (string memory name, address sender) = abi.decode(syncData, (string, address));
        _map.changePhilandOwner(name, msg.sender);
    }

    function sendMessageToRoot(bytes memory message) public {
        _sendMessageToRoot(message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) public {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) public override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.3;

interface IPhiMap {
    function create(string calldata name, address caller) external;

    function changePhilandOwner(string calldata name, address caller) external;
}