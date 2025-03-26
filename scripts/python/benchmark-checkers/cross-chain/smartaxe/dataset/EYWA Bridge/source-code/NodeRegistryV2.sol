// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract NodeRegistryV2 is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    enum State {
        Registered,
        Ready,
        Disabled,
        Removed,
        Deleted,
        Penalized
    }

    enum Mode {
        Witness,
        Validator
    }

    struct Node {
        /// @dev absolute sequential number, starting from 1
        uint64 nodeId;
        /// @dev node owner address
        address owner;
        /// @dev node signer\worker address
        address signer;
        /// @dev protocol version number that this node supports
        uint64 version;
        /// @dev libp2p host ID
        string hostId;
        /// @dev BLS public key
        bytes blsPubKey;
        /// @dev owner's collateral
        uint256 collateral;
        /// @dev node state
        State state;
        /// @dev node mode
        Mode mode;
    }

    uint256 public constant MIN_COLLATERAL = 1 ether;
    /// @dev operator role id
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev utility POA token
    address public EPOA;
    /// @dev next available node id
    uint256 public nextNodeId;
    /// @dev nodes array
    Node[] public nodes;

    /// @dev nodes by owner, one owner -> many nodes
    mapping(address => uint256[]) private _nodesByOwner;
    /// @dev signer -> owner
    mapping(address => address) private _ownerBySigner;

    event NodeAdded(
        uint256 nodeId,
        address owner,
        address signer,
        uint64 version,
        string hostId,
        bytes blsPubKey,
        uint256 collateral,
        State state,
        Mode mode
    );
    event NodeVersionUpdated(uint256 nodeId, uint64 version);
    event NodeSignerUpdated(uint256 nodeId, address signer);
    event NodeStateChanged(uint256 nodeId, State state);
    event NodeRemoved(uint256 nodeId);
    event UtilityTokenSet(address token);
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Returns nodes.
     */
    function getNodes() external view returns (Node[] memory) {
        return nodes;
    }

    /**
     * @dev Returns node info by owner.
     *
     * @param owner node owner.
     */
    function getNodes(address owner) external view returns (Node[] memory) {
        return _getNodes(owner);
    }

    /**
     * @dev Can be used to get node by index, using nodes(index).
     * @return nodes count.
     */
    function getNodesCount() external view returns (uint256) {
        return nodes.length;
    }

    /**
     * @dev Returns node info by signer.
     *
     * @param signer node signer.
     */
    function getNode(address signer) external view returns (Node memory node) {
        address owner = _ownerBySigner[signer];
        Node[] memory nodes_ = _getNodes(owner);
        for (uint256 i = 0; i < nodes_.length; ++i) {
            if (nodes_[i].signer == signer) {
                node = nodes_[i];
                break;
            }
        }
    }

    /**
     * @dev Set utility token for which new node can be added.
     *
     * @param token token address.
     */
    function setUtilityToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(0), "NodeRegistry: zero address");
        EPOA = token;
        emit UtilityTokenSet(EPOA);
    }

    /**
     * @dev Adds new node.
     *
     * @param node Node struct. Collateral, nodeId and state field will be ignored;
     * @param deadline permit deadline;
     * @param v signature;
     * @param r hashed data;
     * @param v hashed data.
     */
    function addNode(
        Node memory node,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        address owner = node.owner;
        require(owner == msg.sender, "NodeRegistry: not owner");
        require(node.signer != address(0), "NodeRegistry: signer not set");
        require(bytes(node.hostId).length != 0, "NodeRegistry: zero host key");

        uint256 nodeBalance = IERC20(EPOA).balanceOf(owner);
        require(nodeBalance >= MIN_COLLATERAL, "NodeRegistry: not enough funds");

        // Check if signer is not used in other nodes
        require(_ownerBySigner[node.signer] == address(0), "NodeRegistry: signer already used");
        _ownerBySigner[node.signer] = owner;

        nextNodeId++;

        node.collateral = nodeBalance;
        _nodesByOwner[owner].push(nextNodeId);
        node.nodeId = uint64(nextNodeId);
        node.state = State.Registered;
        nodes.push(node);

        emit NodeAdded(
            node.nodeId,
            owner,
            node.signer,
            node.version,
            node.hostId,
            node.blsPubKey,
            node.collateral,
            node.state,
            node.mode
        );

        if (deadline > block.timestamp) {
            IERC20Permit(EPOA).permit(owner, address(this), nodeBalance, deadline, v, r, s);
        }
        IERC20(EPOA).safeTransferFrom(owner, address(this), nodeBalance);
    }

    /**
     * @dev Deactivates node.
     *
     * @notice To get collateral back call twice: on first call node will be marked as removed.
     * Then, after approve, make the second call to get collateral.
     *
     * @param id node id.
     */
    function removeNode(uint64 id) external {
        require(id > 0 && id <= nextNodeId, "NodeRegistry: wrong id");
        uint256 index = id - 1;
        require(nodes[index].owner == msg.sender, "NodeRegistry: not owner");
        if (nodes[index].state == State.Registered || nodes[index].state == State.Ready || nodes[index].state == State.Disabled) {
            nodes[index].state = State.Removed;
            emit NodeStateChanged(id, nodes[index].state);
        } else if (nodes[index].state == State.Deleted) {
            uint256 collateral = nodes[index].collateral;
            nodes[index].collateral = 0;
            emit NodeRemoved(id);
            ERC20Burnable(EPOA).burn(collateral);
        } else {
            revert("NodeRegistry: forbidden state");
        }
    }

    /**
     * @dev Set new state.
     *
     * @notice Contract owner have to set Deleted to make collateral releasable (only from Removed state).
     * Node owner may set state to Ready again (only from Removed state).
     *
     * @param id node id;
     * @param state new state.
     */
    function setState(uint64 id, State state) external {
        require(id > 0 && id <= nextNodeId, "NodeRegistry: wrong id");

        uint256 index = id - 1;
        require(nodes[index].state != state, "NodeRegistry: state already set");

        string memory forbiddenState = "NodeRegistry: forbidden state";

        if (nodes[index].mode == Mode.Validator) {
            if (hasRole(OPERATOR_ROLE, msg.sender)) {
                // all states accepted
                // TODO states check disabled in PoA
                // if (nodes[index].state == State.Registered) {
                //     revert(forbiddenState);
                // } else if (nodes[index].state == State.Ready) {
                //     require(state == State.Penalized, forbiddenState);
                // } else if (nodes[index].state == State.Disabled) {
                //     require(state == State.Penalized, forbiddenState);
                // } else if (nodes[index].state == State.Removed) {
                //     require(state == State.Deleted || state == State.Penalized, forbiddenState);
                // } else if (nodes[index].state == State.Deleted) {
                //     if (nodes[index].collateral == 0) {
                //         revert(forbiddenState);
                //     }
                //     require(state == State.Ready || state == State.Disabled, forbiddenState);
                // } else if (nodes[index].state == State.Penalized) {
                //     require(state == State.Ready || state == State.Disabled, forbiddenState);
                // }
            } else {
                require(nodes[index].owner == msg.sender, "NodeRegistry: not owner");

                if (nodes[index].state == State.Registered) {
                    require(state == State.Ready || state == State.Disabled, forbiddenState);
                } else if (nodes[index].state == State.Ready) {
                    require(state == State.Disabled || state == State.Removed, forbiddenState);
                } else if (nodes[index].state == State.Disabled) {
                    require(state == State.Ready || state == State.Removed, forbiddenState);
                } else if (nodes[index].state == State.Removed) {
                    require(state == State.Ready || state == State.Disabled, forbiddenState);
                } else if (nodes[index].state == State.Deleted) {
                    revert(forbiddenState);
                } else {
                    revert(forbiddenState);
                }
            }
        } else { // node.mode == Mode.Witness
            if (hasRole(OPERATOR_ROLE, msg.sender)) {
                require(state == State.Ready || state == State.Disabled || state == State.Penalized, forbiddenState);
            } else {
                require(nodes[index].owner == msg.sender, "NodeRegistry: not owner");
                if (nodes[index].state == State.Registered) {
                    require(state == State.Ready || state == State.Disabled, forbiddenState);
                } else if (nodes[index].state == State.Ready) {
                    require(state == State.Disabled, forbiddenState);
                } else if (nodes[index].state == State.Disabled) {
                    require(state == State.Ready, forbiddenState);
                } else {
                    revert(forbiddenState);
                }
            }
        }

        nodes[index].state = state;
        emit NodeStateChanged(id, state);
    }

    /**
     * @dev Updates node signer.
     *
     * @param signer new signer.
     */
    function updateNodeSigner(uint64 id, address signer) external {
        require(id > 0 && id <= nextNodeId, "NodeRegistry: wrong id");
        require(signer != address(0), "NodeRegistry: zero address");
        uint256 index = id - 1;
        Node storage node = nodes[index];
        require(node.owner == msg.sender, "NodeRegistry: not owner");
        require(node.signer != signer, "NodeRegistry: signer already assigned");
        require(_ownerBySigner[signer] == address(0), "NodeRegistry: signer already used");
        _ownerBySigner[node.signer] = address(0);
        _ownerBySigner[signer] = node.owner;
        node.signer = signer;
        emit NodeSignerUpdated(id, signer);
    }

    /**
     * @dev Updates node version.
     *
     * @param version new node version.
     */
    function updateNodeVersion(uint64 id, uint64 version) external {
        require(id > 0 && id <= nextNodeId, "NodeRegistry: wrong id");
        uint256 index = id - 1;
        Node storage node = nodes[index];
        require(node.signer == msg.sender, "NodeRegistry: not owner");
        node.version = version;
        emit NodeVersionUpdated(node.nodeId, version);
    }

    function _getNodes(address owner) private view returns (Node[] memory) {
        uint256[] memory ownedIds = _nodesByOwner[owner];
        Node[] memory nodes_ = new Node[](ownedIds.length);
        for (uint256 i = 0; i < ownedIds.length; i++) {
            nodes_[i] = nodes[ownedIds[i] - 1];
        }
        return nodes_;
    }
}
