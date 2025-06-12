// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "./IEverscale.sol";


interface IMultiVault is IEverscale {
    enum Fee { Deposit, Withdraw }
    enum TokenType { Native, Alien }

    struct TokenPrefix {
        uint activation;
        string name;
        string symbol;
    }

    struct TokenMeta {
        string name;
        string symbol;
        uint8 decimals;
    }

    struct Token {
        uint activation;
        bool blacklisted;
        uint depositFee;
        uint withdrawFee;
        bool isNative;
    }

    struct NativeWithdrawalParams {
        EverscaleAddress native;
        TokenMeta meta;
        uint256 amount;
        address recipient;
        uint256 chainId;
    }

    struct AlienWithdrawalParams {
        address token;
        uint256 amount;
        address recipient;
        uint256 chainId;
    }

    struct PendingWithdrawalParams {
        address token;
        uint256 amount;
        uint256 bounty;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    function defaultNativeDepositFee() external view returns (uint);
    function defaultNativeWithdrawFee() external view returns (uint);
    function defaultAlienDepositFee() external view returns (uint);
    function defaultAlienWithdrawFee() external view returns (uint);

    function apiVersion() external view returns (string memory api_version);

    function initialize(
        address _bridge,
        address _governance
    ) external;

    function fees(address token) external view returns (uint);
    function prefixes(address _token) external view returns (TokenPrefix memory);
    function tokens(address _token) external view returns (Token memory);
    function natives(address _token) external view returns (EverscaleAddress memory);

    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external;
    function blacklistAddToken(address token) external;
    function blacklistRemoveToken(address token) external;

    function setTokenDepositFee(address token, uint _depositFee) external;
    function setTokenWithdrawFee(address token, uint _withdrawFee) external;

    function setDefaultNativeDepositFee(uint fee) external;
    function setDefaultNativeWithdrawFee(uint fee) external;
    function setDefaultAlienDepositFee(uint fee) external;
    function setDefaultAlienWithdrawFee(uint fee) external;

    function rewards() external view returns (EverscaleAddress memory);

    function configurationAlien() external view returns (EverscaleAddress memory);
    function configurationNative() external view returns (EverscaleAddress memory);

    function withdrawalIds(bytes32) external view returns (bool);
    function bridge() external view returns(address);

    function governance() external view returns (address);
    function guardian() external view returns (address);
    function management() external view returns (address);

    function emergencyShutdown() external view returns (bool);
    function setEmergencyShutdown(bool active) external;

    function setConfigurationAlien(EverscaleAddress memory _configuration) external;
    function setConfigurationNative(EverscaleAddress memory _configuration) external;

    function setGovernance(address _governance) external;
    function acceptGovernance() external;
    function setGuardian(address _guardian) external;
    function setManagement(address _management) external;
    function setRewards(EverscaleAddress memory _rewards) external;

    function pendingWithdrawalsPerUser(address user) external view returns (uint);

    function pendingWithdrawalsTotal(address token) external view returns (uint);

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view returns (PendingWithdrawalParams memory);

    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        EverscaleAddress memory recipient,
        uint bounty
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external;

    function deposit(
        EverscaleAddress memory recipient,
        address token,
        uint amount
    ) external;

    function deposit(
        EverscaleAddress memory recipient,
        address token,
        uint256 amount,
        uint256 expectedMinBounty,
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external;

    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;

    function skim(
        address token,
        bool skim_to_everscale
    ) external;

    function migrateAlienTokenToVault(
        address token,
        address vault
    ) external;

    event PendingWithdrawalCancel(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalUpdateBounty(
        address recipient,
        uint256 id,
        uint256 bounty
    );

    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        address token,
        uint256 amount,
        bytes32 payloadId
    );

    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 amount
    );

    event PendingWithdrawalFill(
        address recipient,
        uint256 id
    );

    event PendingWithdrawalForce(
        address recipient,
        uint256 id
    );

    event BlacklistTokenAdded(address token);
    event BlacklistTokenRemoved(address token);

    event UpdateDefaultNativeDepositFee(uint fee);
    event UpdateDefaultNativeWithdrawFee(uint fee);
    event UpdateDefaultAlienDepositFee(uint fee);
    event UpdateDefaultAlienWithdrawFee(uint fee);

    event UpdateBridge(address bridge);
    event UpdateConfiguration(TokenType _type, int128 wid, uint256 addr);
    event UpdateRewards(int128 wid, uint256 addr);

    event UpdateTokenDepositFee(address token, uint256 fee);
    event UpdateTokenWithdrawFee(address token, uint256 fee);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);

    event EmergencyShutdown(bool active);

    event TokenMigrated(address token, address vault);

    event TokenActivated(
        address token,
        uint activation,
        bool isNative,
        uint depositFee,
        uint withdrawFee
    );

    event TokenCreated(
        address token,
        int8 native_wid,
        uint256 native_addr,
        string name_prefix,
        string symbol_prefix,
        string name,
        string symbol,
        uint8 decimals
    );

    event AlienTransfer(
        uint256 base_chainId,
        uint160 base_token,
        string name,
        string symbol,
        uint8 decimals,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr
    );

    event NativeTransfer(
        int8 native_wid,
        uint256 native_addr,
        uint128 amount,
        int8 recipient_wid,
        uint256 recipient_addr
    );

    event Deposit(
        TokenType _type,
        address sender,
        address token,
        int8 recipient_wid,
        uint256 recipient_addr,
        uint256 amount,
        uint256 fee
    );

    event Withdraw(
        TokenType _type,
        bytes32 payloadId,
        address token,
        address recipient,
        uint256 amount,
        uint256 fee
    );

    event UpdateTokenPrefix(
        address token,
        string name_prefix,
        string symbol_prefix
    );

    event SkimFee(
        address token,
        bool skim_to_everscale,
        uint256 amount
    );
}