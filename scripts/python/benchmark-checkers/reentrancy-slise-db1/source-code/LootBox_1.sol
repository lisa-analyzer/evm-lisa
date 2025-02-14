pragma solidity ^0.6.12;
// IGNORE_LICENSE-Identifier: MIT

pragma experimental ABIEncoderV2;

// IGNORE_LICENSE-Identifier: MIT


// IGNORE_LICENSE-Identifier: MIT


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// IGNORE_LICENSE-Identifier: MIT


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// IGNORE_LICENSE-Identifier: MIT



/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/// @title Allows anyone to "loot" an address
/// @author Brendan Asselstine
/// @notice A LootBox allows anyone to withdraw all tokens or execute calls on behalf of the contract.
/// @dev This contract is intended to be counterfactually instantiated via CREATE2.
contract LootBox {

  /// @notice A structure to define arbitrary contract calls
  struct Call {
    address to;
    uint256 value;
    bytes data;
  }

  /// @notice A structure to define ERC721 transfer contents
  struct WithdrawERC721 {
    IERC721 token;
    uint256[] tokenIds;
  }

  /// @notice A structure to define ERC1155 transfer contents
  struct WithdrawERC1155 {
    IERC1155 token;
    uint256[] ids;
    uint256[] amounts;
    bytes data;
  }

  /// @notice Emitted when an ERC20 token is withdrawn
  event WithdrewERC20(address indexed token, uint256 amount);

  /// @notice Emitted when an ERC721 token is withdrawn
  event WithdrewERC721(address indexed token, uint256[] tokenIds);

  /// @notice Emitted when an ERC1155 token is withdrawn
  event WithdrewERC1155(address indexed token, uint256[] ids, uint256[] amounts, bytes data);

  /// @notice Emitted when the contract transfer ether
  event TransferredEther(address indexed to, uint256 amount);

  /// @notice Executes calls on behalf of this contract.
  /// @param calls The array of calls to be executed.
  /// @return An array of the return values for each of the calls
  function executeCalls(Call[] calldata calls) external returns (bytes[] memory) {
    bytes[] memory response = new bytes[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
      response[i] = _executeCall(calls[i].to, calls[i].value, calls[i].data);
    }
    return response;
  }

  /// @notice Transfers ether held by the contract to another account
  /// @param to The account to transfer Ether to
  /// @param amount The amount of Ether to transfer
  // SWC-Function Default Visibility: L64-L68
  function transferEther(address payable to, uint256 amount) public {
    to.transfer(amount);

    emit TransferredEther(to, amount);
  }

  /// @notice Transfers tokens to another account
  /// @param erc20 Array of ERC20 token addresses whose entire balance should be transferred
  /// @param erc721 Array of WithdrawERC721 structs whose tokens should be transferred
  /// @param erc1155 Array of WithdrawERC1155 structs whose tokens should be transferred
  /// @param to The address receiving all tokens
  function plunder(
    IERC20[] memory erc20,
    WithdrawERC721[] memory erc721,
    WithdrawERC1155[] memory erc1155,
    address payable to
  ) external {
    _withdrawERC20(erc20, to);
    _withdrawERC721(erc721, to);
    _withdrawERC1155(erc1155, to);
    transferEther(to, address(this).balance);
  }

  /// @notice Destroys this contract using `selfdestruct`
  /// @param to The address to send remaining Ether to
  function destroy(address payable to) external {
    selfdestruct(to);
  }

  /// @notice Executes a call to another contract
  /// @param to The address to call
  /// @param value The Ether to pass along with the call
  /// @param data The call data
  /// @return The return data from the call
  function _executeCall(address to, uint256 value, bytes memory data) internal returns (bytes memory) {
    (bool succeeded, bytes memory returnValue) = to.call{value: value}(data);
    require(succeeded, string(returnValue));
    return returnValue;
  }

  /// @notice Transfers the entire balance of ERC20s to an account
  /// @param tokens An array of ERC20 tokens to transfer out.  The balance of each will be transferred.
  /// @param to The recipient of the transfers
  function _withdrawERC20(IERC20[] memory tokens, address to) internal {
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 balance = tokens[i].balanceOf(address(this));
      tokens[i].transfer(to, balance);

      emit WithdrewERC20(address(tokens[i]), balance);
    }
  }

  /// @notice Transfers ERC721 tokens to an account
  /// @param withdrawals An array of WithdrawERC721 structs that each include the ERC721 token to transfer and the corresponding token ids.
  /// @param to The recipient of the transfers
  function _withdrawERC721(WithdrawERC721[] memory withdrawals, address to) internal {
    for (uint256 i = 0; i < withdrawals.length; i++) {
      for (uint256 tokenIndex = 0; tokenIndex < withdrawals[i].tokenIds.length; tokenIndex++) {
        withdrawals[i].token.transferFrom(address(this), to, withdrawals[i].tokenIds[tokenIndex]);
      }

      emit WithdrewERC721(address(withdrawals[i].token), withdrawals[i].tokenIds);
    }
  }

  /// @notice Transfers ERC1155 tokens to an account
  /// @param withdrawals An array of WithdrawERC1155 structs that each include the ERC1155 to transfer and it's corresponding token ids and amounts.
  /// @param to The recipient of the transfers
  function _withdrawERC1155(WithdrawERC1155[] memory withdrawals, address to) internal {
    for (uint256 i = 0; i < withdrawals.length; i++) {
      withdrawals[i].token.safeBatchTransferFrom(address(this), to, withdrawals[i].ids, withdrawals[i].amounts, withdrawals[i].data);

      emit WithdrewERC1155(address(withdrawals[i].token), withdrawals[i].ids, withdrawals[i].amounts, withdrawals[i].data);
    }
  }

}
