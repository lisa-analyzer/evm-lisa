// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;



/**
 * @title ConsiderationEventsAndErrors
 * @author 0age
 * @notice ConsiderationEventsAndErrors contains all events and errors.
 */
interface ConsiderationEventsAndErrors {
    /**
     * @dev Emit an event whenever an order is successfully fulfilled.
     *
     * @param orderHash     The hash of the fulfilled order.
     * @param offerer       The offerer of the fulfilled order.
     * @param zone          The zone of the fulfilled order.
     * @param fulfiller     The fulfiller of the order, or the null address if
     *                      there is no specific fulfiller (i.e. the order is
     *                      part of a group of orders).
     * @param offer         The offer items spent as part of the order.
     * @param consideration The consideration items received as part of the
     *                      order along with the recipients of each item.
     */
    event OrderFulfilled(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone,
        address fulfiller,
        SpentItem[] offer,
        ReceivedItem[] consideration
    );

    /**
     * @dev Emit an event whenever an order is successfully cancelled.
     *
     * @param orderHash The hash of the cancelled order.
     * @param offerer   The offerer of the cancelled order.
     * @param zone      The zone of the cancelled order.
     */
    event OrderCancelled(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone
    );

    /**
     * @dev Emit an event whenever an order is explicitly validated. Note that
     *      this event will not be emitted on partial fills even though they do
     *      validate the order as part of partial fulfillment.
     *
     * @param orderHash The hash of the validated order.
     * @param offerer   The offerer of the validated order.
     * @param zone      The zone of the validated order.
     */
    event OrderValidated(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone
    );

    /**
     * @dev Emit an event whenever a nonce for a given offerer is incremented.
     *
     * @param newNonce The new nonce for the offerer.
     * @param offerer  The offerer in question.
     */
    event NonceIncremented(uint256 newNonce, address indexed offerer);

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      already been fully filled.
     *
     * @param orderHash The order hash on which a fill was attempted.
     */
    error OrderAlreadyFilled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to fill an order outside the
     *      specified start time and end time .
     */
    error InvalidTime();

    /**
     * @dev Revert with an error when attempting to fill an order that specifies
     *      a restricted submitter as its order type when not submitted by
     *      either the offerrer or the order's zone or approved as valid by the
     *      zone in question via a staticcall to `isValidOrder`.
     *
     * @param orderHash The order hash for the invalid restricted order.
     */
    error InvalidRestrictedOrder(bytes32 orderHash);

    /**
     * @dev Revert with an error when an order is supplied for fulfillment with
     *      a consideration array that is shorter than the original array.
     */
    error MissingOriginalConsiderationItems();

    /**
     * @dev Revert with an error when a fulfillment is provided as part of an
     *      call to fulfill available orders that does not declare at least one
     *      component.
     */
    error MissingFulfillmentComponentOnAggregation(Side side);

    /**
     * @dev Revert with an error when a fulfillment is provided that does not
     *      declare at least one offer component and at least one consideration
     *      component.
     */
    error OfferAndConsiderationRequiredOnFulfillment();

    /**
     * @dev Revert with an error when a fulfillment is provided with an index
     *      that references an order or item that has not been supplied.
     */
    error FulfilledOrderIndexOutOfRange();

    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();

    /**
     * @dev Revert with an error when the initial offer item named by a
     *      fulfillment component does not match the type, token, identifier,
     *      or conduit preference of the initial consideration item.
     */
    error MismatchedFulfillmentOfferAndConsiderationComponents();

    /**
     * @dev Revert with an error when an order or item index are out of range
     *      or a fulfillment component does not match the type, token,
     *      identifier, or conduit preference of the initial consideration item.
     */
    error InvalidFulfillmentComponentData();

    /**
     * @dev Revert with an error if a consideration amount has not been fully
     *      zeroed out after applying all fulfillments.
     *
     * @param orderIndex         The index of the order with the consideration
     *                           item with a shortfall.
     * @param considerationIndex The index of the consideration item on the
     *                           order.
     * @param shortfallAmount    The unfulfilled consideration amount.
     */
    error ConsiderationNotMet(
        uint256 orderIndex,
        uint256 considerationIndex,
        uint256 shortfallAmount
    );

    /**
     * @dev Revert with an error when insufficient ether is supplied as part of
     *      msg.value when fulfilling orders.
     */
    error InsufficientEtherSupplied();

    /**
     * @dev Revert with an error when an ether transfer reverts.
     */
    error EtherTransferGenericFailure(address account, uint256 amount);

    /**
     * @dev Revert with an error when an ERC721 transfer with amount other than
     *      one is attempted.
     */
    error InvalidERC721TransferAmount();

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param from       The source of the attempted transfer.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    );

    /**
     * @dev Revert with an error when a batch ERC1155 token transfer reverts.
     *
     * @param token       The token for which the transfer was attempted.
     * @param from        The source of the attempted transfer.
     * @param to          The recipient of the attempted transfer.
     * @param identifiers The identifiers for the attempted transfer.
     * @param amounts     The amounts for the attempted transfer.
     */
    error ERC1155BatchTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256[] identifiers,
        uint256[] amounts
    );

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param from       The source of the attempted ERC20 transfer.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    /**
     * @dev Revert with an error when an account being called as an assumed
     *      contract does not have code and returns no data.
     *
     * @param account The account that should contain code.
     */
    error NoContract(address account);

    /**
     * @dev Revert with an error when a partial fill is attempted on an order
     *      that does not specify partial fill support in its order type.
     */
    error PartialFillsNotEnabledForOrder();

    /**
     * @dev Revert with an error when attempting to fill an order that has been
     *      cancelled.
     *
     * @param orderHash The hash of the cancelled order.
     */
    error OrderIsCancelled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to fill a basic order that has
     *      been partially filled.
     *
     * @param orderHash The hash of the partially used order.
     */
    error OrderPartiallyFilled(bytes32 orderHash);

    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order that has not been supplied.
     */
    error OrderCriteriaResolverOutOfRange();

    /**
     * @dev Revert with an error if an offer item still has unresolved criteria
     *      after applying all criteria resolvers.
     */
    error UnresolvedOfferCriteria();

    /**
     * @dev Revert with an error if a consideration item still has unresolved
     *      criteria after applying all criteria resolvers.
     */
    error UnresolvedConsiderationCriteria();

    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order with an offer item that has not been supplied.
     */
    error OfferCriteriaResolverOutOfRange();

    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order with a consideration item that has not been supplied.
     */
    error ConsiderationCriteriaResolverOutOfRange();

    /**
     * @dev Revert with an error when providing a criteria resolver that refers
     *      to an order with an item that does not expect a criteria to be
     *      resolved.
     */
    error CriteriaNotEnabledForItem();

    /**
     * @dev Revert with an error when providing a criteria resolver that
     *      contains an invalid proof with respect to the given item and
     *      chosen identifier.
     */
    error InvalidProof();

    /**
     * @dev Revert with an error when attempting to cancel an order as a caller
     *      other than the indicated offerer or zone.
     */
    error InvalidCanceller();

    /**
     * @dev Revert with an error when supplying a fraction with a value of zero
     *      for the numerator or denominator, or one where the numerator exceeds
     *      the denominator.
     */
    error BadFraction();

    /**
     * @dev Revert with an error when attempting to apply a fraction as part of
     *      a partial fill that does not divide the target amount cleanly.
     */
    error InexactFraction();

    /**
     * @dev Revert with an error when a caller attempts to reenter a protected
     *      function.
     */
    error NoReentrantCalls();

    /**
     * @dev Revert with an error when a caller attempts to supply callvalue to a
     *      non-payable basic order route or does not supply any callvalue to a
     *      payable basic order route.
     */
    error InvalidMsgValue(uint256 value);

    /**
     * @dev Revert with an error when the implementation of the respective
     *      legacy user proxy does not match the expected proxy implementation.
     */
    error InvalidProxyImplementation();

    /**
     * @dev Revert with an error when attempting to fill a basic order using
     *      calldata not produced by default ABI encoding.
     */
    error InvalidBasicOrderParameterEncoding();

    /**
     * @dev Revert with an error when attempting to fulfill any number of
     *      available orders when none are fulfillable.
     */
    error NoSpecifiedOrdersAvailable();

    /**
     * @dev Revert with an error when attempting to fulfill an order where an
     *      item has an amount of zero.
     */
    error MissingItemAmount();
}


// prettier-ignore
    ProxyRegistryInterface,
    TokenTransferProxyInterface
} from "../interfaces/AbridgedProxyInterfaces.sol";

// prettier-ignore
    ConsiderationEventsAndErrors
} from "../interfaces/ConsiderationEventsAndErrors.sol";


/**
 * @title ConsiderationBase
 * @author 0age
 * @notice ConsiderationBase contains all storage, constants, and constructor
 *         logic.
 */
contract ConsiderationBase is ConsiderationEventsAndErrors {
    // Declare constants for name, version, and reentrancy sentinel values.
    string internal constant _NAME = "Consideration";
    string internal constant _VERSION = "rc.1";
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    // Precompute hashes, original chainId, and domain separator on deployment.
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 internal immutable _OFFER_ITEM_TYPEHASH;
    bytes32 internal immutable _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal immutable _ORDER_TYPEHASH;
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    // Allow for interaction with user proxies on the legacy proxy registry.
    ProxyRegistryInterface internal immutable _LEGACY_PROXY_REGISTRY;

    // Allow for interaction with the legacy token transfer proxy.
    TokenTransferProxyInterface internal immutable _LEGACY_TOKEN_TRANSFER_PROXY;

    // Ensure that user proxies adhere to the required proxy implementation.
    address internal immutable _REQUIRED_PROXY_IMPLEMENTATION;

    // Prevent reentrant calls on protected functions.
    uint256 internal _reentrancyGuard;

    // Track status of each order (validated, cancelled, and fraction filled).
    mapping(bytes32 => OrderStatus) internal _orderStatus;

    // Cancel all of a given offerer's orders signed with their current nonce.
    mapping(address => uint256) internal _nonces;

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param legacyProxyRegistry         A proxy registry that stores per-user
     *                                    proxies that may optionally be used to
     *                                    transfer approved ERC721+1155 tokens.
     * @param legacyTokenTransferProxy    A shared proxy contract that may
     *                                    optionally be used to transfer
     *                                    approved ERC20 tokens.
     * @param requiredProxyImplementation The implementation that must be set on
     *                                    each proxy in order to utilize it.
     */
    constructor(
        address legacyProxyRegistry,
        address legacyTokenTransferProxy,
        address requiredProxyImplementation
    ) {
        // Derive hashes, reference chainId, and associated domain separator.
        _NAME_HASH = keccak256(bytes(_NAME));
        _VERSION_HASH = keccak256(bytes(_VERSION));

        // prettier-ignore
        bytes memory offerItemTypeString = abi.encodePacked(
            "OfferItem(",
                "uint8 itemType,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 startAmount,",
                "uint256 endAmount",
            ")"
        );
        // prettier-ignore
        bytes memory considerationItemTypeString = abi.encodePacked(
            "ConsiderationItem(",
                "uint8 itemType,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 startAmount,",
                "uint256 endAmount,",
                "address recipient",
            ")"
        );
        // prettier-ignore
        bytes memory orderComponentsPartialTypeString = abi.encodePacked(
            "OrderComponents(",
                "address offerer,",
                "address zone,",
                "OfferItem[] offer,",
                "ConsiderationItem[] consideration,",
                "uint8 orderType,",
                "uint256 startTime,",
                "uint256 endTime,",
                "bytes32 zoneHash,",
                "uint256 salt,",
                "address conduit,",
                "uint256 nonce",
            ")"
        );

        // prettier-ignore
        _EIP_712_DOMAIN_TYPEHASH = keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                    "string name,",
                    "string version,",
                    "uint256 chainId,",
                    "address verifyingContract",
                ")"
            )
        );
        _OFFER_ITEM_TYPEHASH = keccak256(offerItemTypeString);
        _CONSIDERATION_ITEM_TYPEHASH = keccak256(considerationItemTypeString);
        _ORDER_TYPEHASH = keccak256(
            abi.encodePacked(
                orderComponentsPartialTypeString,
                considerationItemTypeString,
                offerItemTypeString
            )
        );
        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _deriveInitialDomainSeparator();

        _LEGACY_PROXY_REGISTRY = ProxyRegistryInterface(legacyProxyRegistry);
        _LEGACY_TOKEN_TRANSFER_PROXY = TokenTransferProxyInterface(
            legacyTokenTransferProxy
        );
        _REQUIRED_PROXY_IMPLEMENTATION = requiredProxyImplementation;

        // Initialize the reentrancy guard in a cleared state.
        _reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal view function to derive the initial EIP-712 domain
     *      separator.
     *
     * @return The derived domain separator.
     */
    function _deriveInitialDomainSeparator()
        internal
        view
        virtual
        returns (bytes32)
    {
        return _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator() internal view virtual returns (bytes32) {
        // prettier-ignore
        return keccak256(
            abi.encode(
                _EIP_712_DOMAIN_TYPEHASH,
                _NAME_HASH,
                _VERSION_HASH,
                block.chainid,
                address(this)
            )
        );
    }
}


interface EIP1271Interface {
    function isValidSignature(bytes32 digest, bytes calldata signature)
        external
        view
        returns (bytes4);
}



interface ZoneInterface {
    // Called by Consideration whenever extraData is not provided by the caller.
    function isValidOrder(
        bytes32 orderHash,
        address caller,
        address offerer,
        bytes32 zoneHash
    ) external view returns (bytes4 validOrderMagicValue);

    // Called by Consideration whenever any extraData is provided by the caller.
    function isValidOrderIncludingExtraData(
        bytes32 orderHash,
        address caller,
        AdvancedOrder calldata order,
        bytes32[] calldata priorOrderHashes
    ) external view returns (bytes4 validOrderMagicValue);
}



// prettier-ignore
    OfferItem,
    ConsiderationItem,
    SpentItem,
    ReceivedItem,
    OrderParameters,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver,
    Batch,
    BatchExecution
} from "./ConsiderationStructs.sol";




/**
 * @title ConsiderationPure
 * @author 0age
 * @notice ConsiderationPure contains all pure functions.
 */
contract ConsiderationPure is ConsiderationBase {
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param legacyProxyRegistry         A proxy registry that stores per-user
     *                                    proxies that may optionally be used to
     *                                    transfer approved ERC721+1155 tokens.
     * @param legacyTokenTransferProxy    A shared proxy contract that may
     *                                    optionally be used to transfer
     *                                    approved ERC20 tokens.
     * @param requiredProxyImplementation The implementation that must be set on
     *                                    each proxy in order to utilize it.
     */
    constructor(
        address legacyProxyRegistry,
        address legacyTokenTransferProxy,
        address requiredProxyImplementation
    )
        ConsiderationBase(
            legacyProxyRegistry,
            legacyTokenTransferProxy,
            requiredProxyImplementation
        )
    {}

    /**
     * @dev Internal pure function to apply criteria resolvers containing
     *      specific token identifiers and associated proofs to order items.
     *
     * @param advancedOrders     The orders to apply criteria resolvers to.
     * @param criteriaResolvers  An array where each element contains a
     *                           reference to a specific order as well as that
     *                           order's offer or consideration, a token
     *                           identifier, and a proof that the supplied token
     *                           identifier is contained in the order's merkle
     *                           root. Note that a root of zero indicates that
     *                           any transferrable token identifier is valid and
     *                           that no proof needs to be supplied.
     */
    function _applyCriteriaResolvers(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers
    ) internal pure {
        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Iterate over each criteria resolver.
            for (uint256 i = 0; i < criteriaResolvers.length; ++i) {
                // Retrieve the criteria resolver.
                CriteriaResolver memory criteriaResolver = criteriaResolvers[i];

                // Read the order index from memory and place it on the stack.
                uint256 orderIndex = criteriaResolver.orderIndex;

                // Ensure that the order index is in range.
                if (orderIndex >= advancedOrders.length) {
                    revert OrderCriteriaResolverOutOfRange();
                }

                // Skip criteria resolution for order if not fulfilled.
                if (advancedOrders[orderIndex].numerator == 0) {
                    continue;
                }

                // Retrieve the parameters for the order.
                OrderParameters memory orderParameters = (
                    advancedOrders[orderIndex].parameters
                );

                // Read component index from memory and place it on the stack.
                uint256 componentIndex = criteriaResolver.index;

                // Declare values for item's type and criteria.
                ItemType itemType;
                uint256 identifierOrCriteria;

                // If the criteria resolver refers to an offer item...
                if (criteriaResolver.side == Side.OFFER) {
                    // Ensure that the component index is in range.
                    if (componentIndex >= orderParameters.offer.length) {
                        revert OfferCriteriaResolverOutOfRange();
                    }

                    // Retrieve relevant item using order and component index.
                    OfferItem memory offer = (
                        orderParameters.offer[componentIndex]
                    );

                    // Read item type and criteria from memory & place on stack.
                    itemType = offer.itemType;
                    identifierOrCriteria = offer.identifierOrCriteria;

                    // Optimistically update item type to remove criteria usage.
                    ItemType newItemType;
                    assembly {
                        newItemType := sub(3, eq(itemType, 4))
                    }
                    offer.itemType = newItemType;

                    // Optimistically update identifier w/ supplied identifier.
                    offer.identifierOrCriteria = criteriaResolver.identifier;
                } else {
                    // Otherwise, the resolver refers to a consideration item.
                    // Ensure that the component index is in range.
                    if (
                        componentIndex >= orderParameters.consideration.length
                    ) {
                        revert ConsiderationCriteriaResolverOutOfRange();
                    }

                    // Retrieve relevant item using order and component index.
                    ConsiderationItem memory consideration = (
                        orderParameters.consideration[componentIndex]
                    );

                    // Read item type and criteria from memory & place on stack.
                    itemType = consideration.itemType;
                    identifierOrCriteria = consideration.identifierOrCriteria;

                    // Optimistically update item type to remove criteria usage.
                    ItemType newItemType;
                    assembly {
                        newItemType := sub(3, eq(itemType, 4))
                    }
                    consideration.itemType = newItemType;

                    // Optimistically update identifier w/ supplied identifier.
                    consideration.identifierOrCriteria = (
                        criteriaResolver.identifier
                    );
                }

                // Ensure the specified item type indicates criteria usage.
                if (!_isItemWithCriteria(itemType)) {
                    revert CriteriaNotEnabledForItem();
                }

                // If criteria is not 0 (i.e. a collection-wide offer)...
                if (identifierOrCriteria != uint256(0)) {
                    // Verify identifier inclusion in criteria root using proof.
                    _verifyProof(
                        criteriaResolver.identifier,
                        identifierOrCriteria,
                        criteriaResolver.criteriaProof
                    );
                }
            }

            // Iterate over each order.
            for (uint256 i = 0; i < advancedOrders.length; ++i) {
                // Retrieve the order.
                AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Skip criteria resolution for order if not fulfilled.
                if (advancedOrder.numerator == 0) {
                    continue;
                }

                // Read consideration length from memory and place on stack.
                uint256 totalItems = (
                    advancedOrder.parameters.consideration.length
                );

                // Iterate over each consideration item on the order.
                for (uint256 j = 0; j < totalItems; ++j) {
                    // Ensure item type no longer indicates criteria usage.
                    if (
                        _isItemWithCriteria(
                            advancedOrder.parameters.consideration[j].itemType
                        )
                    ) {
                        revert UnresolvedConsiderationCriteria();
                    }
                }

                // Read offer length from memory and place on stack.
                totalItems = advancedOrder.parameters.offer.length;

                // Iterate over each offer item on the order.
                for (uint256 j = 0; j < totalItems; ++j) {
                    // Ensure item type no longer indicates criteria usage.
                    if (
                        _isItemWithCriteria(
                            advancedOrder.parameters.offer[j].itemType
                        )
                    ) {
                        revert UnresolvedOfferCriteria();
                    }
                }
            }
        }
    }

    /**
     * @dev Internal pure function to derive the current amount of a given item
     *      based on the current price, the starting price, and the ending
     *      price. If the start and end prices differ, the current price will be
     *      extrapolated on a linear basis.
     *
     * @param startAmount The starting amount of the item.
     * @param endAmount   The ending amount of the item.
     * @param elapsed     The time elapsed since the order's start time.
     * @param remaining   The time left until the order's end time.
     * @param duration    The total duration of the order.
     * @param roundUp     A boolean indicating whether the resultant amount
     *                    should be rounded up or down.
     *
     * @return The current amount.
     */
    function _locateCurrentAmount(
        uint256 startAmount,
        uint256 endAmount,
        uint256 elapsed,
        uint256 remaining,
        uint256 duration,
        bool roundUp
    ) internal pure returns (uint256) {
        // Only modify end amount if it doesn't already equal start amount.
        if (startAmount != endAmount) {
            // Leave extra amount to add for rounding at zero (i.e. round down).
            uint256 extraCeiling = 0;

            // If rounding up, set rounding factor to one less than denominator.
            if (roundUp) {
                // Skip underflow check: duration cannot be zero.
                unchecked {
                    extraCeiling = duration - 1;
                }
            }

            // Aggregate new amounts weighted by time with rounding factor
            uint256 totalBeforeDivision = ((startAmount * remaining) +
                (endAmount * elapsed) +
                extraCeiling);

            // Division is performed without zero check as it cannot be zero.
            uint256 newAmount;
            assembly {
                newAmount := div(totalBeforeDivision, duration)
            }

            // Return the current amount (expressed as endAmount internally).
            return newAmount;
        }

        // Return the original amount (now expressed as endAmount internally).
        return endAmount;
    }

    /**
     * @dev Internal pure function to return a fraction of a given value and to
     *      ensure the resultant value does not have any fractional component.
     *
     * @param numerator   A value indicating the portion of the order that
     *                    should be filled.
     * @param denominator A value indicating the total size of the order.
     * @param value       The value for which to compute the fraction.
     *
     * @return newValue The value after applying the fraction.
     */
    function _getFraction(
        uint256 numerator,
        uint256 denominator,
        uint256 value
    ) internal pure returns (uint256 newValue) {
        // Return value early in cases where the fraction resolves to 1.
        if (numerator == denominator) {
            return value;
        }

        // Multiply the numerator by the value and ensure no overflow occurs.
        uint256 valueTimesNumerator = value * numerator;

        // Divide (Note: denominator must not be zero!) and check for remainder.
        bool exact;
        assembly {
            newValue := div(valueTimesNumerator, denominator)
            exact := iszero(mulmod(value, numerator, denominator))
        }

        // Ensure that division gave a final result with no remainder.
        if (!exact) {
            revert InexactFraction();
        }
    }

    /**
     * @dev Internal pure function to "compress" executions, splitting them into
     *      "standard" (or unbatched) executions and "batch" executions. Note
     *      that there may be additional compression that could be performed,
     *      such as allowing contrarian orders to cancel one another.
     *
     * @param executions An array of uncompressed executions.
     *
     * @return standardExecutions An array of executions that were not able to
     *                            be compressed.
     * @return batchExecutions    An array of executions (all ERC1155 transfers)
     *                            that have been compressed into batches.
     */
    function _compressExecutions(Execution[] memory executions)
        internal
        pure
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {
        // Skip overflow checks as all incremented values start at low amounts.
        unchecked {
            // Read executions array length from memory and place on the stack.
            uint256 totalExecutions = executions.length;

            // Return early if less than two executions are provided.
            if (totalExecutions <= 1) {
                return (executions, new BatchExecution[](0));
            }

            // Determine the toal number of ERC1155 executions in the array.
            uint256 total1155Executions = 0;

            // Allocate array in memory for indices of each ERC1155 execution.
            uint256[] memory indexBy1155 = new uint256[](totalExecutions);

            // Iterate over each execution.
            for (uint256 i = 0; i < executions.length; ++i) {
                // If the item specified by the execution is an ERC1155 item...
                if (executions[i].item.itemType == ItemType.ERC1155) {
                    // Set index of 1155 execution in memory, then increment it.
                    indexBy1155[total1155Executions++] = i;
                }
            }

            // Return early if less than two ERC1155 executions are located.
            if (total1155Executions <= 1) {
                return (executions, new BatchExecution[](0));
            }

            // Allocate array to track potential ERC1155 batch executions.
            Batch[] memory batches = new Batch[](total1155Executions);

            // Read initial execution index from memory and place on the stack.
            uint256 initialExecutionIndex = indexBy1155[0];

            // Get hash from initial token, offerer, recipient, & proxy usage.
            bytes32 hash = _getHashByExecutionIndex(
                executions,
                initialExecutionIndex
            );

            // Allocate an array of length 1 in memory for the execution index.
            uint256[] memory executionIndices = new uint256[](1);

            // Populate the memory region with the initial execution index.
            executionIndices[0] = initialExecutionIndex;

            // Set hash and array with execution index as first batch element.
            batches[0].hash = hash;
            batches[0].executionIndices = executionIndices;

            // Track total number of unique hashes (starts at one).
            uint256 uniqueHashes = 1;

            // Iterate over each additional 1155 execution.
            for (uint256 i = 1; i < total1155Executions; ++i) {
                // Read execution index from memory and place on the stack.
                uint256 executionIndex = indexBy1155[i];

                // Derive hash based on the same parameters as the initial hash.
                hash = _getHashByExecutionIndex(executions, executionIndex);

                // Assume no matching hash exists unless proven otherwise.
                bool foundMatchingHash = false;

                // Iterate over all known unique hashes.
                for (uint256 j = 0; j < uniqueHashes; ++j) {
                    // If the hash matches the known unique hash in question...
                    if (hash == batches[j].hash) {
                        // Retrieve execution index of the original execution.
                        uint256[] memory oldExecutionIndices = (
                            batches[j].executionIndices
                        );

                        // Place old execution indices array length on stack.
                        uint256 originalLength = oldExecutionIndices.length;

                        // Allocate execution indices array w/ an extra element.
                        uint256[] memory newExecutionIndices = (
                            new uint256[](originalLength + 1)
                        );

                        // Iterate over existing execution indices.
                        for (uint256 k = 0; k < originalLength; ++k) {
                            // Add them to the new execution indices array.
                            newExecutionIndices[k] = oldExecutionIndices[k];
                        }

                        // Add new execution index to the end of the array.
                        newExecutionIndices[originalLength] = executionIndex;

                        // Update the batch with the extended array.
                        batches[j].executionIndices = newExecutionIndices;

                        // Mark that new hash matches one already in a batch.
                        foundMatchingHash = true;

                        // Stop scanning for a match as one has now been found.
                        break;
                    }
                }

                // If no matching hash was located, create a new batch element.
                if (!foundMatchingHash) {
                    // Reuse existing array & update w/ current execution index.
                    executionIndices[0] = executionIndex;

                    // Set next batch element and increment total unique hashes.
                    batches[uniqueHashes].hash = hash;
                    batches[uniqueHashes++].executionIndices = executionIndices;
                }
            }

            // Return early if every hash is unique.
            if (uniqueHashes == total1155Executions) {
                return (executions, new BatchExecution[](0));
            }

            // Allocate an array to track the batch each execution is used in.
            // Values of zero indicate that it is not used in a batch, whereas
            // non-zero values indicate the execution index *plus one*.
            uint256[] memory usedInBatch = new uint256[](totalExecutions);

            // Stack elements have been exhausted, so utilize memory to track
            // total elements used as part of a batch as well as total batches.
            uint256[] memory totals = new uint256[](2);

            // Iterate over each potential batch (determined via unique hashes).
            for (uint256 i = 0; i < uniqueHashes; ++i) {
                // Retrieve the indices for the batch in question.
                uint256[] memory indices = batches[i].executionIndices;

                // Read total number of indices from memory and place on stack.
                uint256 indicesLength = indices.length;

                // if more than one execution applies to a potential batch...
                if (indicesLength >= 2) {
                    // Increment the total number of batches.
                    ++totals[1];

                    // Increment total executions used as part of a batch.
                    totals[0] += indicesLength;

                    // Iterate over each execution index for the batch.
                    for (uint256 j = 0; j < indicesLength; ++j) {
                        // Update array tracking batch the execution applies to.
                        usedInBatch[indices[j]] = i + 1;
                    }
                }
            }

            // Split executions into standard and batched executions and return.
            // prettier-ignore
            return _splitExecution(
                    executions,
                    batches,
                    usedInBatch,
                    totals[0],
                    totals[1]
                );
        }
    }

    /**
     * @dev Internal pure function to complete the process of "compressing"
     *      executions and return both unbatched and batched execution arrays.
     *
     * @param executions             An array of uncompressed executions.
     * @param batches                An array of elements indicating which
     *                               executions form the "baseline" for a batch.
     * @param batchExecutionPointers An array of indices, incremented by one (as
     *                               zero indicates no batching), that each
     *                               point to a respective batch per execution.
     * @param totalUsedInBatch       The total execution elements to batch.
     * @param totalBatches           The total number of batch executions.
     *
     * @return An array of executions that could not be compressed.
     * @return An array of executions (all ERC1155 transfers) that have been
     *         compressed into batches.
     */
    function _splitExecution(
        Execution[] memory executions,
        Batch[] memory batches,
        uint256[] memory batchExecutionPointers,
        uint256 totalUsedInBatch,
        uint256 totalBatches
    ) internal pure returns (Execution[] memory, BatchExecution[] memory) {
        // Skip overflow checks as all incremented values start at low amounts.
        unchecked {
            // Read executions array length from memory and place on the stack.
            uint256 totalExecutions = executions.length;

            // Allocate standard executions array (exclude ones used in batch).
            Execution[] memory standardExecutions = new Execution[](
                totalExecutions - totalUsedInBatch
            );

            // Allocate batch executions array (length equal to total batches).
            BatchExecution[] memory batchExecutions = new BatchExecution[](
                totalBatches
            );

            // Track the index of the next available standard execution element.
            uint256 nextStandardExecutionIndex = 0;

            // Allocate array in memory to track next element index per batch.
            uint256[] memory batchElementIndices = new uint256[](totalBatches);

            // Iterate over each execution.
            for (uint256 i = 0; i < totalExecutions; ++i) {
                // Check if execution is standard (0) or part of a batch (1+).
                uint256 batchExecutionPointer = batchExecutionPointers[i];

                // Retrieve the execution element.
                Execution memory execution = executions[i];

                // If the execution is a standard execution...
                if (batchExecutionPointer == 0) {
                    // Copy it to next standard index, then increment the index.
                    standardExecutions[nextStandardExecutionIndex++] = (
                        execution
                    );
                    // Otherwise, it is a batch execution.
                } else {
                    // Decrement pointer to derive the batch execution index.
                    uint256 batchIndex = batchExecutionPointer - 1;

                    // If it is the first item applied to the batch execution...
                    if (batchExecutions[batchIndex].token == address(0)) {
                        // Determine total elements in batch and place on stack.
                        uint256 totalElements = (
                            batches[batchIndex].executionIndices.length
                        );

                        // Populate all other fields using execution parameters.
                        batchExecutions[batchIndex] = BatchExecution(
                            execution.item.token, // token
                            execution.offerer, // from
                            execution.item.recipient, // to
                            new uint256[](totalElements), // tokenIds
                            new uint256[](totalElements), // amounts
                            execution.conduit // conduit
                        );
                    }

                    // Put next batch element index on stack, then increment it.
                    uint256 batchElementIndex = (
                        batchElementIndices[batchIndex]++
                    );

                    // Update current element's batch with respective tokenId.
                    batchExecutions[batchIndex].tokenIds[batchElementIndex] = (
                        execution.item.identifier
                    );

                    // Retrieve execution item amount and place on the stack.
                    uint256 amount = execution.item.amount;

                    // Ensure that the amount is non-zero.
                    _assertNonZeroAmount(amount);

                    // Update current element's batch with respective amount.
                    batchExecutions[batchIndex].amounts[batchElementIndex] = (
                        amount
                    );
                }
            }

            // Return both the standard and batch execution arrays.
            return (standardExecutions, batchExecutions);
        }
    }

    /**
     * @dev Internal pure function to apply a fraction to a consideration
     * or offer item.
     *
     * @param startAmount     The starting amount of the item.
     * @param endAmount       The ending amount of the item.
     * @param numerator       A value indicating the portion of the order that
     *                        should be filled.
     * @param denominator     A value indicating the total size of the order.
     * @param elapsed         The time elapsed since the order's start time.
     * @param remaining       The time left until the order's end time.
     * @param duration        The total duration of the order.
     *
     * @return amount The received item to transfer with the final amount.
     */
    function _applyFraction(
        uint256 startAmount,
        uint256 endAmount,
        uint256 numerator,
        uint256 denominator,
        uint256 elapsed,
        uint256 remaining,
        uint256 duration,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // If start amount equals end amount, apply fraction to end amount.
        if (startAmount == endAmount) {
            amount = _getFraction(numerator, denominator, endAmount);
        } else {
            // Otherwise, apply fraction to both to extrapolate final amount.
            amount = _locateCurrentAmount(
                _getFraction(numerator, denominator, startAmount),
                _getFraction(numerator, denominator, endAmount),
                elapsed,
                remaining,
                duration,
                roundUp
            );
        }
    }

    /**
     * @dev Internal pure function to aggregate a group of consideration items
     *      using supplied directives on which component items are candidates
     *      for aggregation, skipping items on orders that are not available.
     *
     * @param advancedOrders          The orders to aggregate consideration
     *                                items from.
     * @param considerationComponents An array of FulfillmentComponent structs
     *                                indicating the order index and item index
     *                                of each candidate consideration item for
     *                                aggregation.
     * @param startIndex              The initial order index to begin iteration
     *                                on when searching for consideration items
     *                                to aggregate.
     *
     * @return receivedItem The aggregated consideration items.
     */
    function _aggregateValidFulfillmentConsiderationItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory considerationComponents,
        uint256 startIndex
    ) internal pure returns (ReceivedItem memory receivedItem) {
        // Declare a variable indicating whether the aggregation is invalid.
        bool invalidFulfillment;

        // Utilize assembly in order to efficiently aggregate the items.
        assembly {
            // Retrieve the length of the orders array.
            let totalOrders := mload(advancedOrders)

            // Begin iteration at the indicated start index.
            let i := startIndex

            // Get fulfillment ptr from consideration component & start index.
            let fulfillmentPtr := mload(
                add(add(considerationComponents, 0x20), mul(i, 0x20))
            )

            // Retrieve the order index using the fulfillment pointer.
            let orderIndex := mload(fulfillmentPtr)

            // Retrieve item index using an offset of the fulfillment pointer.
            let itemIndex := mload(add(fulfillmentPtr, 0x20))

            // Ensure that the order index is not out of range.
            invalidFulfillment := iszero(lt(orderIndex, totalOrders))

            // Only continue if the fulfillment is not invalid.
            if iszero(invalidFulfillment) {
                // Calculate pointer to AdvancedOrder element at
                // advancedOrders[orderIndex].OrderParameters pointer is first
                // word of AdvancedOrder struct, so we mload twice.
                let orderPtr := mload(
                    // Read the pointer to advancedOrders[orderIndex] from its
                    // head in the array.
                    mload(
                        // Calculate head position of advancedOrders[orderIndex]
                        add(add(advancedOrders, 0x20), mul(orderIndex, 0x20))
                    )
                )

                // Load consideration array pointer.
                let considerationArrPtr := mload(
                    add(orderPtr, OrderParameters_consideration_head_offset)
                )

                // Check if itemIndex is within the range of the array.
                invalidFulfillment := iszero(
                    lt(itemIndex, mload(considerationArrPtr))
                )

                // Only continue if the fulfillment is not invalid.
                if iszero(invalidFulfillment) {
                    // Retrieve consideration item pointer using the item index.
                    let considerationItemPtr := mload(
                        add(
                            // Get pointer to beginning of receivedItem.
                            add(considerationArrPtr, 0x20),
                            // Calculate offset to pointer for desired order.
                            mul(itemIndex, 0x20)
                        )
                    )

                    // Set the item type on the received item.
                    mstore(receivedItem, mload(considerationItemPtr))

                    // Set the token on the received item.
                    mstore(
                        add(receivedItem, Common_token_offset),
                        mload(add(considerationItemPtr, Common_token_offset))
                    )

                    // Set the identifier on the received item.
                    mstore(
                        add(receivedItem, Common_identifier_offset),
                        mload(
                            add(considerationItemPtr, Common_identifier_offset)
                        )
                    )

                    // Retrieve amount pointer using consideration item pointer.
                    let amountPtr := add(
                        considerationItemPtr,
                        Common_amount_offset
                    )
                    // Set the amount.
                    mstore(
                        add(receivedItem, Common_amount_offset),
                        mload(amountPtr)
                    )

                    // Zero out amount on item to indicate it is credited.
                    mstore(amountPtr, 0)

                    // Set the recipient.
                    mstore(
                        add(receivedItem, ReceivedItem_recipient_offset),
                        mload(
                            add(
                                considerationItemPtr,
                                ConsiderationItem_recipient_offset
                            )
                        )
                    )

                    // Increment the iterator.
                    i := add(i, 1)

                    // Iterate over remaining consideration components.
                    // prettier-ignore
                    for {} lt(i, mload(considerationComponents)) {
                        i := add(i, 1)
                    } {
                        // Retrieve the fulfillment pointer.
                        fulfillmentPtr := mload(
                            add(
                                add(considerationComponents, 0x20),
                                mul(i, 0x20)
                            )
                        )

                        // Get the order index using the fulfillment pointer.
                        orderIndex := mload(fulfillmentPtr)

                        // Get the item index using the fulfillment pointer.
                        itemIndex := mload(add(fulfillmentPtr, 0x20))

                        // Ensure the order index is in range.
                        invalidFulfillment := iszero(
                            lt(orderIndex, totalOrders)
                        )

                        // Exit iteration if order index is not in range.
                        if invalidFulfillment {
                            break
                        }
                        // Get pointer to AdvancedOrder element. The pointer
                        // will be reused as the pointer to OrderParameters.
                        orderPtr := mload(
                            add(
                                add(advancedOrders, 0x20),
                                mul(orderIndex, 0x20)
                            )
                        )

                        // Only continue if numerator is not zero.
                        if mload(
                            add(orderPtr, AdvancedOrder_numerator_offset)
                        ) {
                            // First word of AdvancedOrder is pointer to
                            // OrderParameters.
                            orderPtr := mload(orderPtr)

                            // Load consideration array pointer.
                            considerationArrPtr := mload(
                                add(
                                    orderPtr,
                                    OrderParameters_consideration_head_offset
                                )
                            )

                            // Check if itemIndex is within the range of array.
                            invalidFulfillment := iszero(
                                lt(itemIndex, mload(considerationArrPtr))
                            )

                            // Exit iteration if item index is not in range.
                            if invalidFulfillment {
                                break
                            }

                            // Retrieve consideration item pointer using index.
                            considerationItemPtr := mload(
                                add(
                                    // Get pointer to beginning of receivedItem.
                                    add(considerationArrPtr, 0x20),
                                    // Use offset to pointer for desired order.
                                    mul(itemIndex, 0x20)
                                )
                            )

                            // Retrieve amount pointer using consideration item
                            // pointer.
                            amountPtr := add(
                                considerationItemPtr,
                                Common_amount_offset
                            )

                            // Increment the amount on the received item.
                            mstore(
                                add(receivedItem, Common_amount_offset),
                                add(
                                    mload(
                                        add(receivedItem, Common_amount_offset)
                                    ),
                                    mload(amountPtr)
                                )
                            )

                            // Zero out amount on original item to indicate it
                            // is credited.
                            mstore(amountPtr, 0)

                            // Ensure the indicated item matches original item.
                            invalidFulfillment := iszero(
                                and(
                                    // Item recipients must match.
                                    eq(
                                        mload(
                                            add(
                                                considerationItemPtr,
                                                ConsiderItem_recipient_offset
                                            )
                                        ),
                                        mload(
                                            add(
                                                receivedItem,
                                                ReceivedItem_recipient_offset
                                            )
                                        )
                                    ),
                                    and(
                                        // Item types must match.
                                        eq(
                                            mload(considerationItemPtr),
                                            mload(receivedItem)
                                        ),
                                        and(
                                            // Item tokens must match.
                                            eq(
                                                mload(
                                                    add(
                                                        considerationItemPtr,
                                                        Common_token_offset
                                                    )
                                                ),
                                                mload(
                                                    add(
                                                        receivedItem,
                                                        Common_token_offset
                                                    )
                                                )
                                            ),
                                            // Item identifiers must match.
                                            eq(
                                                mload(
                                                    add(
                                                        considerationItemPtr,
                                                        Common_identifier_offset
                                                    )
                                                ),
                                                mload(
                                                    add(
                                                        receivedItem,
                                                        Common_identifier_offset
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )

                            // Exit iteration if items do not match.
                            if invalidFulfillment {
                                break
                            }
                        }
                    }
                }
            }
        }

        // Revert if an order/item was out of range or was not aggregatable.
        if (invalidFulfillment) {
            revert InvalidFulfillmentComponentData();
        }
    }

    /**
     * @dev Internal pure function to ensure that a staticcall to `isValidOrder`
     *      or `isValidOrderIncludingExtraData` as part of validating a
     *      restricted order that was not submitted by the named offerer or zone
     *      was successful and returned the required magic value.
     *
     * @param success   A boolean indicating the status of the staticcall.
     * @param orderHash The order hash of the order in question.
     */
    function _assertIsValidOrderStaticcallSuccess(
        bool success,
        bytes32 orderHash
    ) internal pure {
        // If the call failed...
        if (!success) {
            // Revert and pass reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error message.
            revert InvalidRestrictedOrder(orderHash);
        }

        // Extract result from returndata buffer in case of memory overflow.
        bytes4 result;
        assembly {
            // Only put result on stack if return data is exactly 32 bytes.
            if eq(returndatasize(), 0x20) {
                // Copy directly from return data into scratch space.
                returndatacopy(0, 0, 0x20)

                // Take value from scratch space and place it on the stack.
                result := mload(0)
            }
        }

        // Ensure result was extracted and matches isValidOrder magic value.
        if (result != ZoneInterface.isValidOrder.selector) {
            revert InvalidRestrictedOrder(orderHash);
        }
    }

    /**
     * @dev Internal pure function to validate that a given order is fillable
     *      and not cancelled based on the order status.
     *
     * @param orderHash       The order hash.
     * @param orderStatus     The status of the order, including whether it has
     *                        been cancelled and the fraction filled.
     * @param onlyAllowUnused A boolean flag indicating whether partial fills
     *                        are supported by the calling function.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order has been cancelled or filled beyond the
     *                        allowable amount.
     *
     * @return valid A boolean indicating whether the order is valid.
     */
    function _verifyOrderStatus(
        bytes32 orderHash,
        OrderStatus memory orderStatus,
        bool onlyAllowUnused,
        bool revertOnInvalid
    ) internal pure returns (bool valid) {
        // Ensure that the order has not been cancelled.
        if (orderStatus.isCancelled) {
            // Only revert if revertOnInvalid has been supplied as true.
            if (revertOnInvalid) {
                revert OrderIsCancelled(orderHash);
            }

            // Return false as the order status is invalid.
            return false;
        }

        // If the order is not entirely unused...
        if (orderStatus.numerator != 0) {
            // ensure the order has not been partially filled when not allowed.
            if (onlyAllowUnused) {
                // Always revert on partial fills when onlyAllowUnused is true.
                revert OrderPartiallyFilled(orderHash);
                // Otherwise, ensure that order has not been entirely filled.
            } else if (orderStatus.numerator >= orderStatus.denominator) {
                // Only revert if revertOnInvalid has been supplied as true.
                if (revertOnInvalid) {
                    revert OrderAlreadyFilled(orderHash);
                }

                // Return false as the order status is invalid.
                return false;
            }
        }

        // Return true as the order status is valid.
        valid = true;
    }

    /**
     * @dev Internal pure function to hash key parameters of a given execution
     *      from an array of execution elements by index.
     *
     * @param executions     An array of execution elements.
     * @param executionIndex An index designating which execution element from
     *                       the array to hash.
     *
     * @return A hash of the key parameters of the execution.
     */
    function _getHashByExecutionIndex(
        Execution[] memory executions,
        uint256 executionIndex
    ) internal pure returns (bytes32) {
        // Retrieve ERC1155 execution element.
        Execution memory execution = executions[executionIndex];

        // Retrieve the received item for the given execution element.
        ReceivedItem memory item = execution.item;

        // Derive hash based on token, offerer, recipient, and proxy usage.
        // prettier-ignore
        return _hashBatchableItemIdentifier(
            item.token,
            execution.offerer,
            item.recipient,
            execution.conduit
        );
    }

    /**
     * @dev Internal pure function to derive a hash for comparing transfers to
     *      see if they can be batched. Only applies to ERC1155 tokens.
     *
     * @param token    The token to transfer.
     * @param from     The originator of the transfer.
     * @param to       The recipient of the transfer.
     * @param conduit A boolean indicating whether to utilize a proxy when
     *                 performing the transfer.
     *
     * @return value The hash.
     */
    function _hashBatchableItemIdentifier(
        address token,
        address from,
        address to,
        address conduit
    ) internal pure returns (bytes32 value) {
        // Leverage scratch space to perform an efficient hash.
        assembly {
            mstore(0x20, conduit) // Place proxy bool at end of scratch space.
            mstore(0x1c, to) // Place to address just before bool.
            mstore(0x08, from) // Place from address just before to.

            // Place combined token + start of from at start of scratch space.
            mstore(0x00, or(shl(0x60, token), shr(0x40, from)))

            value := keccak256(0x00, 0x40) // Hash scratch space region.
        }
    }

    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param domainSeparator The domain separator.
     * @param orderHash       The order hash.
     *
     * @return value The hash.
     */
    function _hashDigest(bytes32 domainSeparator, bytes32 orderHash)
        internal
        pure
        returns (bytes32 value)
    {
        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(
                0x00,
                0x1901000000000000000000000000000000000000000000000000000000000000 // solhint-disable-line max-line-length
            )

            // Place the domain separator in the next region of scratch space.
            mstore(0x02, domainSeparator)

            // Place the order hash in scratch space, spilling into the first
            // two bytes of the free memory pointer — this should never be set
            // as memory cannot be expanded to that size, and will be zeroed out
            // after the hash is performed.
            mstore(0x22, orderHash)

            value := keccak256(0x00, 0x42) // Hash the relevant region.

            mstore(0x22, 0) // Clear out the dirtied bits in the memory pointer.
        }
    }

    /**
     * @dev Internal pure function to check whether a given item type represents
     *      a criteria-based ERC721 or ERC1155 item (e.g. an item that can be
     *      resolved to one of a number of different identifiers at the time of
     *      order fulfillment).
     *
     * @param itemType The item type in question.
     *
     * @return withCriteria A boolean indicating that the item type in question
     *                      represents a criteria-based item.
     */
    function _isItemWithCriteria(ItemType itemType)
        internal
        pure
        returns (bool withCriteria)
    {
        // ERC721WithCriteria is item type 4. ERC1155WithCriteria is item type
        // 5.
        assembly {
            withCriteria := gt(itemType, 3)
        }
    }

    /**
     * @dev Internal pure function to check whether a given order type indicates
     *      that partial fills are not supported (e.g. only "full fills" are
     *      allowed for the order in question).
     *
     * @param orderType The order type in question.
     *
     * @return isFullOrder A boolean indicating whether the order type only
     *                     supports full fills.
     */
    function _doesNotSupportPartialFills(OrderType orderType)
        internal
        pure
        returns (bool isFullOrder)
    {
        // The "full" order types are even, while "partial" order types are odd.
        // Bitwise and by 1 is equivalent to modulo by 2, but 2 gas cheaper.
        assembly {
            // Same thing as uint256(orderType) & 1 == 0
            isFullOrder := iszero(and(orderType, 1))
        }
    }

    /**
     * @dev Internal pure function to convert an order to an advanced order with
     *      numerator and denominator of 1 and empty extraData.
     *
     * @param order The order to convert.
     *
     * @return advancedOrder The new advanced order.
     */
    function _convertOrderToAdvanced(Order calldata order)
        internal
        pure
        returns (AdvancedOrder memory advancedOrder)
    {
        // Convert to partial order (1/1 or full fill) and return new value.
        advancedOrder = AdvancedOrder(
            order.parameters,
            1,
            1,
            order.signature,
            ""
        );
    }

    /**
     * @dev Internal pure function to convert an array of orders to an array of
     *      advanced orders with numerator and denominator of 1.
     *
     * @param orders The orders to convert.
     *
     * @return advancedOrders The new array of partial orders.
     */
    function _convertOrdersToAdvanced(Order[] calldata orders)
        internal
        pure
        returns (AdvancedOrder[] memory advancedOrders)
    {
        // Read the number of orders from calldata and place on the stack.
        uint256 totalOrders = orders.length;

        // Allocate new empty array for each partial order in memory.
        advancedOrders = new AdvancedOrder[](totalOrders);

        // Skip overflow check as the index for the loop starts at zero.
        unchecked {
            // Iterate over the given orders.
            for (uint256 i = 0; i < totalOrders; ++i) {
                // Convert to partial order (1/1 or full fill) and update array.
                advancedOrders[i] = _convertOrderToAdvanced(orders[i]);
            }
        }

        // Return the array of advanced orders.
        return advancedOrders;
    }

    /**
     * @dev Internal pure function to revert and pass along the revert reason if
     *      data was returned by the last call.
     */
    //  SWC-DoS With Block Gas Limit: L1255 - L1266
    function _revertWithReasonIfOneIsReturned() internal pure {
        assembly {
            // If data was returned...
            if returndatasize() {
                // Copy returndata to memory, overwriting existing memory.
                returndatacopy(0, 0, returndatasize())

                // Revert, specifying memory region with copied returndata.
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Internal pure function to ensure that a given element is contained
     *      in a merkle root via a supplied proof.
     *
     * @param leaf  The element for which to prove inclusion.
     * @param root  The merkle root that inclusion will be proved against.
     * @param proof The merkle proof.
     */
    function _verifyProof(
        uint256 leaf,
        uint256 root,
        bytes32[] memory proof
    ) internal pure {
        // Convert the supplied leaf element from uint256 to bytes32.
        bytes32 computedHash = bytes32(leaf);

        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Iterate over each proof element.
            for (uint256 i = 0; i < proof.length; ++i) {
                // Retrieve the proof element.
                bytes32 proofElement = proof[i];

                if (computedHash <= proofElement) {
                    // Hash(current computed hash + current element of proof)
                    computedHash = _efficientHash(computedHash, proofElement);
                } else {
                    // Hash(current element of proof + current computed hash)
                    computedHash = _efficientHash(proofElement, computedHash);
                }
            }
        }

        // Ensure that the final derived hash matches the expected root.
        if (computedHash != bytes32(root)) {
            revert InvalidProof();
        }
    }

    /**
     * @dev Internal pure function to efficiently hash two bytes32 values.
     *
     * @param a The first component of the hash.
     * @param b The second component of the hash.
     *
     * @return value The hash.
     */
    function _efficientHash(bytes32 a, bytes32 b)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a) // Place element a in first word of scratch space.
            mstore(0x20, b) // Place element b in second word of scratch space.
            value := keccak256(0x00, 0x40) // Hash scratch space region.
        }
    }

    /**
     * @dev Internal pure function to ensure that the supplied consideration
     *      array length for an order to be fulfilled is not less than the
     *      original consideration array length for that order.
     *
     * @param suppliedConsiderationItemTotal The number of consideration items
     *                                       supplied when fulfilling the order.
     * @param originalConsiderationItemTotal The number of consideration items
     *                                       supplied on initial order creation.
     */
    function _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
        uint256 suppliedConsiderationItemTotal,
        uint256 originalConsiderationItemTotal
    ) internal pure {
        // Ensure supplied consideration array length is not less than original.
        if (suppliedConsiderationItemTotal < originalConsiderationItemTotal) {
            revert MissingOriginalConsiderationItems();
        }
    }

    /**
     * @dev Internal pure function to ensure that a given item amount in not
     *      zero.
     *
     * @param amount The amount to check.
     */
    function _assertNonZeroAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert MissingItemAmount();
        }
    }

    /**
     * @dev Internal pure function to validate calldata offsets for dynamic
     *      types in BasicOrderParameters. This ensures that functions using the
     *      calldata object normally will be using the same data as the assembly
     *      functions. Note that no parameters are supplied as all basic order
     *      functions use the same calldata encoding.
     */
    function _assertValidBasicOrderParameterOffsets() internal pure {
        // Declare a boolean designating basic order parameter offset validity.
        bool validOffsets;

        // Utilize assembly in order to read offset data directly from calldata.
        assembly {
            /*
             * Checks:
             * 1. Order parameters struct offset == 0x20
             * 2. Additional recipients arr offset == 0x200
             * 3. Signature offset == 0x240 + (recipients.length * 0x40)
             */
            validOffsets := and(
                // Order parameters have offset of 0x20
                eq(calldataload(0x04), 0x20),
                // Additional recipients have offset of 0x200
                eq(calldataload(0x224), 0x240)
            )
            validOffsets := and(
                validOffsets,
                eq(
                    // Load signature offset from calldata
                    calldataload(0x244),
                    // Calculate expected offset: start of recipients + len * 64
                    add(0x260, mul(calldataload(0x264), 0x40))
                )
            )
        }

        // Revert with an error if basic order parameter offsets are invalid.
        if (!validOffsets) {
            revert InvalidBasicOrderParameterEncoding();
        }
    }
}


interface ERC20Interface {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

interface ERC721Interface {
    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

interface ERC1155Interface {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


interface ProxyRegistryInterface {
    function proxies(address user) external view returns (address proxy);
}

interface ProxyInterface {
    function proxyAssert(
        address dest,
        uint8 howToCall,
        bytes calldata callData
    ) external;

    function implementation() external view returns (address);
}

interface TokenTransferProxyInterface {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}





// prettier-ignore
    OfferItem,
    ConsiderationItem,
    SpentItem,
    ReceivedItem,
    OrderParameters,
    Order,
    AdvancedOrder,
    OrderStatus,
    Execution,
    FulfillmentComponent
} from "./ConsiderationStructs.sol";



/**
 * @title ConsiderationInternalView
 * @author 0age
 * @notice ConsiderationInternal contains all internal view functions.
 */
contract ConsiderationInternalView is ConsiderationPure {
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param legacyProxyRegistry         A proxy registry that stores per-user
     *                                    proxies that may optionally be used to
     *                                    transfer approved ERC721+1155 tokens.
     * @param legacyTokenTransferProxy    A shared proxy contract that may
     *                                    optionally be used to transfer
     *                                    approved ERC20 tokens.
     * @param requiredProxyImplementation The implementation that must be set on
     *                                    each proxy in order to utilize it.
     */
    constructor(
        address legacyProxyRegistry,
        address legacyTokenTransferProxy,
        address requiredProxyImplementation
    )
        ConsiderationPure(
            legacyProxyRegistry,
            legacyTokenTransferProxy,
            requiredProxyImplementation
        )
    {}

    /**
     * @dev Internal view function to ensure that the sentinel value for the
            reentrancy guard is not currently set.
     */
    function _assertNonReentrant() internal view {
        // Ensure that the reentrancy guard is not currently set.
        if (_reentrancyGuard != _NOT_ENTERED) {
            revert NoReentrantCalls();
        }
    }

    /**
     * @dev Internal view function to ensure that the current time falls within
     *      an order's valid timespan.
     *
     * @param startTime       The time at which the order becomes active.
     * @param endTime         The time at which the order becomes inactive.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order is not active.
     *
     * @return valid A boolean indicating whether the order is active.
     */
    function _verifyTime(
        uint256 startTime,
        uint256 endTime,
        bool revertOnInvalid
    ) internal view returns (bool valid) {
        // Revert if order's timespan hasn't started yet or has already ended.
        if (startTime > block.timestamp || endTime <= block.timestamp) {
            // Only revert if revertOnInvalid has been supplied as true.
            if (revertOnInvalid) {
                revert InvalidTime();
            }

            // Return false as the order is invalid.
            return false;
        }

        // Return true as the order time is valid.
        valid = true;
    }

    /**
     * @dev Internal view function to validate whether a token transfer was
     *      successful based on the returned status and data. Note that
     *      malicious or non-compliant tokens (like fee-on-transfer tokens) may
     *      still return improper data — consider checking token balances before
     *      and after for more comprehensive transfer validation. Also note that
     *      this function must be called after the account in question has been
     *      called and before any other contracts have been called.
     *
     * @param success The status of the call to transfer. Note that contract
     *                size must be checked on status of true and no returned
     *                data to rule out undeployed contracts.
     * @param token   The token to transfer.
     * @param from    The originator of the transfer.
     * @param to      The recipient of the transfer.
     * @param tokenId The tokenId to transfer (if applicable).
     * @param amount  The amount to transfer (if applicable).
     */
    function _assertValidTokenTransfer(
        bool success,
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal view {
        // If the call failed...
        if (!success) {
            // Revert and pass reason along if one was returned from the token.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error.
            revert TokenTransferGenericFailure(
                token,
                from,
                to,
                tokenId,
                amount
            );
        }

        // Ensure that the token contract has code.
        _assertContractIsDeployed(token);
    }

    /**
     * @dev Internal view function to item that a contract is deployed to a
     *      given account. Note that this function must be called after the
     *      account in question has been called and before any other contracts
     *      have been called.
     *
     * @param account The account to check.
     */
    function _assertContractIsDeployed(address account) internal view {
        // Find out whether data was returned by inspecting returndata buffer.
        uint256 returnDataSize;
        assembly {
            returnDataSize := returndatasize()
        }

        // If no data was returned, ensure that the account has code.
        if (returnDataSize == 0 && account.code.length == 0) {
            revert NoContract(account);
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 32 or 33 bytes or if the recovered signer does not match the
     *      supplied offerer. Note that in cases where a 32 or 33 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param offerer   The offerer for the order.
     * @param orderHash The order hash.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _verifySignature(
        address offerer,
        bytes32 orderHash,
        bytes memory signature
    ) internal view {
        // Skip signature verification if the offerer is the caller.
        if (offerer == msg.sender) {
            return;
        }

        // Derive EIP-712 digest using the domain separator and the order hash.
        bytes32 digest = _hashDigest(_domainSeparator(), orderHash);

        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        // If signature contains 64 bytes, parse as EIP-2098 signature. (r+s&v)
        if (signature.length == 64) {
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            // Read each parameter directly from the signature's memory region.
            assembly {
                // Put the first word from the signature onto the stack as r.
                r := mload(add(signature, 0x20))

                // Put the second word from the signature onto the stack as vs.
                vs := mload(add(signature, 0x40))

                // Extract canonical s from vs (all but the highest bit).
                s := and(vs, EIP2098_allButHighestBitMask)

                // Extract yParity from highest bit of vs and add 27 to get v.
                v := add(shr(255, vs), 27)
            }
            // If signature is 65 bytes, parse as a standard signature. (r+s+v)
        } else if (signature.length == 65) {
            // Read each parameter directly from the signature's memory region.
            assembly {
                r := mload(add(signature, 0x20)) // Put first word on stack at r
                s := mload(add(signature, 0x40)) // Put next word on stack at s
                v := byte(0, mload(add(signature, 0x60))) // Put last byte at v
            }

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
            // For all other signature lengths, try verification via EIP-1271.
        } else {
            // Attempt EIP-1271 static call to offerer in case it's a contract.
            _verifySignatureViaERC1271(offerer, digest, signature);

            // Return early if the ERC-1271 signature check succeeded.
            return;
        }

        // Attempt to recover signer using the digest and signature parameters.
        address signer = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (signer == address(0)) {
            revert InvalidSignature();
            // Should a signer be recovered, but it doesn't match the offerer...
        } else if (signer != offerer) {
            // Attempt EIP-1271 static call to offerer in case it's a contract.
            _verifySignatureViaERC1271(offerer, digest, signature);
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order using
     *      ERC-1271 (i.e. contract signatures via `isValidSignature`).
     *
     * @param offerer   The offerer for the order.
     * @param digest    The signature digest, derived from the domain separator
     *                  and the order hash.
     * @param signature A signature (or other data) used to validate the digest.
     */
    function _verifySignatureViaERC1271(
        address offerer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        // Attempt an EIP-1271 staticcall to the offerer.
        bool success = _staticcall(
            offerer,
            abi.encodeWithSelector(
                EIP1271Interface.isValidSignature.selector,
                digest,
                signature
            )
        );

        // If the call fails...
        if (!success) {
            // Revert and pass reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error message.
            revert BadContractSignature();
        }

        // Extract result from returndata buffer in case of memory overflow.
        bytes4 result;
        assembly {
            // Only put result on stack if return data is exactly 32 bytes.
            if eq(returndatasize(), 0x20) {
                // Copy directly from return data into scratch space.
                returndatacopy(0, 0, 0x20)

                // Take value from scratch space and place it on the stack.
                result := mload(0)
            }
        }

        // Ensure result was extracted and matches EIP-1271 magic value.
        if (result != EIP1271Interface.isValidSignature.selector) {
            revert InvalidSigner();
        }
    }

    /**
     * @dev Internal view function to staticcall an arbitrary target with given
     *      calldata. Note that no data is written to memory and no contract
     *      size check is performed.
     *
     * @param target   The account to staticcall.
     * @param callData The calldata to supply when staticcalling the target.
     *
     * @return success The status of the staticcall to the target.
     */
    function _staticcall(address target, bytes memory callData)
        internal
        view
        returns (bool success)
    {
        (success, ) = target.staticcall(callData);
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     */
    function _domainSeparator() internal view returns (bytes32) {
        // prettier-ignore
        return block.chainid == _CHAIN_ID
            ? _DOMAIN_SEPARATOR
            : _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to derive the order hash for a given order.
     *      Note that only the original consideration items are included in the
     *      order hash, as additional consideration items may be supplied by the
     *      caller.
     *
     * @param orderParameters The parameters of the order to hash.
     * @param nonce           The nonce of the order to hash.
     *
     * @return orderHash The hash.
     */
    function _getOrderHash(
        OrderParameters memory orderParameters,
        uint256 nonce
    ) internal view returns (bytes32 orderHash) {
        // Get length of original consideration array and place it on the stack.
        uint256 originalConsiderationLength = (
            orderParameters.totalOriginalConsiderationItems
        );

        /*
         * Memory layout for an array of structs (dynamic or not) is similar
         * to ABI encoding of dynamic types, with a head segment followed by
         * a data segment. The main difference is that the head of an element
         * is a memory pointer rather than an offset.
         */

        // Declare a variable for the derived hash of the offer array.
        bytes32 offerHash;

        // Read offer item EIP-712 typehash from runtime code & place on stack.
        bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
        assembly {
            // Retrieve the free memory pointer and place on the stack.
            let hashArrPtr := mload(FreeMemoryPointerSlot)

            // Get the pointer to the offers array.
            let offerArrPtr := mload(add(orderParameters, 0x40))

            // Load the length.
            let offerLength := mload(offerArrPtr)

            // Set the pointer to the first offer's head.
            offerArrPtr := add(offerArrPtr, 0x20)

            // Iterate over the offer items.
            // prettier-ignore
            for { let i := 0 } lt(i, offerLength) {
                i := add(i, 1)
            } {
                // Read the pointer to the offer data and subtract 32
                // to get typeHash pointer.
                let ptr := sub(mload(offerArrPtr), 0x20)

                // Read the current value before the offer data.
                let value := mload(ptr)

                // Write the type hash to the previous word.
                mstore(ptr, typeHash)

                // Take the EIP712 hash and store it in the hash array.
                mstore(hashArrPtr, keccak256(ptr, 0xc0))

                // Restore the previous word.
                mstore(ptr, value)

                // Increment the array pointers.
                offerArrPtr := add(offerArrPtr, 0x20)
                hashArrPtr := add(hashArrPtr, 0x20)
            }

            // Derive the offer hash.
            offerHash := keccak256(
                mload(FreeMemoryPointerSlot),
                mul(offerLength, 0x20)
            )
        }

        // Declare a variable for the derived hash of the consideration array.
        bytes32 considerationHash;

        // Read consideration item typehash from runtime code & place on stack.
        typeHash = _CONSIDERATION_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
        assembly {
            // Retrieve the free memory pointer and place on the stack.
            let hashArrPtr := mload(FreeMemoryPointerSlot)

            // Get the pointer to the consideration array.
            let considerationArrPtr := add(
                mload(add(orderParameters, 0x60)),
                0x20
            )

            // Iterate over the offer items.
            // prettier-ignore
            for { let i := 0 } lt(i, originalConsiderationLength) {
                i := add(i, 1)
            } {
                // Read the pointer to the consideration data and subtract 32
                // to get typeHash pointer.
                let ptr := sub(mload(considerationArrPtr), 0x20)

                // Read the current value before the consideration data.
                let value := mload(ptr)

                // Write the type hash to the previous word.
                mstore(ptr, typeHash)

                // Take the EIP712 hash and store it in the hash array.
                mstore(hashArrPtr, keccak256(ptr, 0xe0))

                // Restore the previous word.
                mstore(ptr, value)

                // Increment the array pointers.
                considerationArrPtr := add(considerationArrPtr, 0x20)
                hashArrPtr := add(hashArrPtr, 0x20)
            }

            // Derive the offer hash.
            considerationHash := keccak256(
                mload(FreeMemoryPointerSlot),
                mul(originalConsiderationLength, 0x20)
            )
        }

        // Read order item EIP-712 typehash from runtime code & place on stack.
        typeHash = _ORDER_TYPEHASH;

        // Utilize assembly to access derived hashes & other arguments directly.
        assembly {
            let typeHashPtr := sub(orderParameters, 0x20)
            let previousValue := mload(typeHashPtr)
            mstore(typeHashPtr, typeHash)

            let offerHeadPtr := add(orderParameters, 0x40)
            let offerDataPtr := mload(offerHeadPtr)
            mstore(offerHeadPtr, offerHash)

            let considerationHeadPtr := add(orderParameters, 0x60)
            let considerationDataPtr := mload(considerationHeadPtr)
            mstore(considerationHeadPtr, considerationHash)

            let noncePtr := add(orderParameters, 0x140)
            mstore(noncePtr, nonce)

            orderHash := keccak256(typeHashPtr, 0x180)
            mstore(typeHashPtr, previousValue)
            mstore(offerHeadPtr, offerDataPtr)
            mstore(considerationHeadPtr, considerationDataPtr)
            mstore(noncePtr, originalConsiderationLength)
        }
    }

    /**
     * @dev Internal view function to to ensure that the supplied consideration
     *      array length on a given set of order parameters is not less than the
     *      original consideration array length for that order and to retrieve
     *      the current nonce for a given order's offerer and zone and use it to
     *      derive the order hash.
     *
     * @param orderParameters The parameters of the order to hash.
     *
     * @return The hash.
     */
    function _assertConsiderationLengthAndGetNoncedOrderHash(
        OrderParameters memory orderParameters
    ) internal view returns (bytes32) {
        // Ensure supplied consideration array length is not less than original.
        _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            orderParameters.consideration.length,
            orderParameters.totalOriginalConsiderationItems
        );

        // Derive and return order hash using current nonce for the offerer.
        return _getOrderHash(orderParameters, _nonces[orderParameters.offerer]);
    }

    /**
     * @dev Internal view function to determine if an order has a restricted
     *      order type and, if so, to ensure that either the offerer or the zone
     *      are the fulfiller or that a staticcall to `isValidOrder` on the zone
     *      returns a magic value indicating that the order is currently valid.
     *
     * @param orderHash The hash of the order.
     * @param zoneHash  The hash to provide upon calling the zone.
     * @param orderType The type of the order.
     * @param offerer   The offerer in question.
     * @param zone      The zone in question.
     */
    function _assertRestrictedBasicOrderValidity(
        bytes32 orderHash,
        bytes32 zoneHash,
        OrderType orderType,
        address offerer,
        address zone
    ) internal view {
        // Order type 2-3 require zone or offerer be caller or zone to approve.
        if (
            uint256(orderType) > 1 &&
            msg.sender != zone &&
            msg.sender != offerer
        ) {
            // Perform minimal staticcall to the zone.
            bool success = _staticcall(
                zone,
                abi.encodeWithSelector(
                    ZoneInterface.isValidOrder.selector,
                    orderHash,
                    msg.sender,
                    offerer,
                    zoneHash
                )
            );

            // Ensure call was successful and returned the correct magic value.
            _assertIsValidOrderStaticcallSuccess(success, orderHash);
        }
    }

    /**
     * @dev Internal view function to determine if a proxy should be utilized
     *      for a given order and to ensure that the submitter is allowed by the
     *      order type.
     *
     * @param advancedOrder    The order in question.
     * @param priorOrderHashes The order hashes of each order supplied prior to
     *                         the current order as part of a "match" variety of
     *                         order fulfillment (e.g. this array will be empty
     *                         for single or "fulfill available").
     * @param orderHash        The hash of the order.
     * @param zoneHash         The hash to provide upon calling the zone.
     * @param orderType        The type of the order.
     * @param offerer          The offerer in question.
     * @param zone             The zone in question.

     */
    function _assertRestrictedAdvancedOrderValidity(
        AdvancedOrder memory advancedOrder,
        bytes32[] memory priorOrderHashes,
        bytes32 orderHash,
        bytes32 zoneHash,
        OrderType orderType,
        address offerer,
        address zone
    ) internal view {
        // Order type 2-3 require zone or offerer be caller or zone to approve.
        if (
            uint256(orderType) > 1 &&
            msg.sender != zone &&
            msg.sender != offerer
        ) {
            // Declare a variable for the status of the staticcall to the zone.
            bool success;

            // If no extraData is supplied...
            if (advancedOrder.extraData.length == 0) {
                // Perform minimal staticcall to the zone.
                success = _staticcall(
                    zone,
                    abi.encodeWithSelector(
                        ZoneInterface.isValidOrder.selector,
                        orderHash,
                        msg.sender,
                        offerer,
                        zoneHash
                    )
                );
            } else {
                // Otherwise, extraData was supplied; in that event, perform a
                // more verbose staticcall to the zone.
                success = _staticcall(
                    zone,
                    abi.encodeWithSelector(
                        ZoneInterface.isValidOrderIncludingExtraData.selector,
                        orderHash,
                        msg.sender,
                        advancedOrder,
                        priorOrderHashes
                    )
                );
            }

            // Ensure call was successful and returned the correct magic value.
            _assertIsValidOrderStaticcallSuccess(success, orderHash);
        }
    }

    /**
     * @dev Internal view function to match offer items to consideration items
     *      on a group of orders via a supplied fulfillment.
     *
     * @param advancedOrders          The orders to match.
     * @param offerComponents         An array designating offer components to
     *                                match to consideration components.
     * @param considerationComponents An array designating consideration
     *                                components to match to offer components.
     *                                Note that each consideration amount must
     *                                be zero in order for the match operation
     *                                to be valid.
     *
     * @return execution The transfer performed as a result of the fulfillment.
     */
    function _applyFulfillment(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory offerComponents,
        FulfillmentComponent[] memory considerationComponents
    ) internal view returns (Execution memory execution) {
        // Ensure 1+ of both offer and consideration components are supplied.
        if (
            offerComponents.length == 0 || considerationComponents.length == 0
        ) {
            revert OfferAndConsiderationRequiredOnFulfillment();
        }

        // Validate and aggregate consideration items and store the result as a
        // ReceivedItem.
        ReceivedItem memory considerationItem = (
            _aggregateValidFulfillmentConsiderationItems(
                advancedOrders,
                considerationComponents,
                0
            )
        );

        // Validate & aggregate offer items and store result as an Execution.
        (
            execution
            /**
             * ItemType itemType,
             * address token,
             * uint256 identifier,
             * address offerer,
             * address conduit,
             * uint256 offerAmount
             */
        ) = _aggregateValidFulfillmentOfferItems(
            advancedOrders,
            offerComponents,
            0
        );

        // Ensure offer and consideration share types, tokens and identifiers.
        if (
            execution.item.itemType != considerationItem.itemType ||
            execution.item.token != considerationItem.token ||
            execution.item.identifier != considerationItem.identifier
        ) {
            revert MismatchedFulfillmentOfferAndConsiderationComponents();
        }

        // If total consideration amount exceeds the offer amount...
        if (considerationItem.amount > execution.item.amount) {
            // Retrieve the first consideration component from the fulfillment.
            FulfillmentComponent memory targetComponent = (
                considerationComponents[0]
            );

            // Add excess consideration item amount to original array of orders.
            advancedOrders[targetComponent.orderIndex]
                .parameters
                .consideration[targetComponent.itemIndex]
                .startAmount = considerationItem.amount - execution.item.amount;

            // Reduce total consideration amount to equal the offer amount.
            considerationItem.amount = execution.item.amount;
        } else {
            // Retrieve the first offer component from the fulfillment.
            FulfillmentComponent memory targetComponent = (offerComponents[0]);

            // Add excess offer item amount to the original array of orders.
            advancedOrders[targetComponent.orderIndex]
                .parameters
                .offer[targetComponent.itemIndex]
                .startAmount = execution.item.amount - considerationItem.amount;
        }

        // Reuse execution struct with consideration amount and recipient.
        execution.item.amount = considerationItem.amount;
        execution.item.recipient = considerationItem.recipient;

        // Return the final execution that will be triggered for relevant items.
        return execution; // Execution(considerationItem, offerer, conduit);
    }

    /**
     * 2. Here's the summary of this section
     * blah blah blah
     */

    /**
     * @dev Internal view function to aggregate offer or consideration items
     *      from a group of orders into a single execution via a supplied array
     *      of fulfillment components. Items that are not available to aggregate
     *      will not be included in the aggregated execution.
     *
     * @param advancedOrders        The orders to aggregate.
     * @param side                  The side (i.e. offer or consideration).
     * @param fulfillmentComponents An array designating item components to
     *                              aggregate if part of an available order.
     * @param fulfillerConduit      A flag indicating whether to source
     *                              approvals for fulfilled tokens from the
     *                              fulfiller's respective proxy.
     *
     * @return execution The transfer performed as a result of the fulfillment.
     */
    function _aggregateAvailable(
        AdvancedOrder[] memory advancedOrders,
        Side side,
        FulfillmentComponent[] memory fulfillmentComponents,
        address fulfillerConduit
    ) internal view returns (Execution memory execution) {
        // Ensure at least one fulfillment component has been supplied.
        if (fulfillmentComponents.length == 0) {
            revert MissingFulfillmentComponentOnAggregation(side);
        }

        // Determine component index after first available (zero implies none).
        uint256 nextComponentIndex = 0;

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Iterate over components until finding one with a fulfilled order.
            for (uint256 i = 0; i < fulfillmentComponents.length; ++i) {
                // Retrieve the fulfillment component index.
                uint256 orderIndex = fulfillmentComponents[i].orderIndex;

                // Ensure that the order index is in range.
                if (orderIndex >= advancedOrders.length) {
                    revert FulfilledOrderIndexOutOfRange();
                }

                // If order is being fulfilled (i.e. it is still available)...
                if (advancedOrders[orderIndex].numerator != 0) {
                    // Update the next potential component index.
                    nextComponentIndex = i + 1;

                    // Exit the loop.
                    break;
                }
            }
        }

        // If no available order was located...
        if (nextComponentIndex == 0) {
            // Return early with a null execution element that will be filtered.
            // prettier-ignore
            return Execution(
                ReceivedItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    0,
                    payable(address(0))
                ),
                address(0),
                address(0)
            );
        }

        // If the fulfillment components are offer components...
        if (side == Side.OFFER) {
            // Return execution for aggregated items provided by the offerer.
            // prettier-ignore
            return _aggregateValidFulfillmentOfferItems(
                advancedOrders,
                fulfillmentComponents,
                nextComponentIndex - 1
            );
        } else {
            // Otherwise, fulfillment components are consideration components.
            // Return execution for aggregated items provided by the fulfiller.
            // prettier-ignore
            return _aggregateConsiderationItems(
                advancedOrders,
                fulfillmentComponents,
                nextComponentIndex - 1,
                fulfillerConduit
            );
        }
    }

    /**
     * @dev Internal pure function to aggregate a group of offer items using
     *      supplied directives on which component items are candidates for
     *      aggregation, skipping items on orders that are not available.
     *
     * @param advancedOrders  The orders to aggregate offer items from.
     * @param offerComponents An array of FulfillmentComponent structs
     *                        indicating the order index and item index of each
     *                        candidate offer item for aggregation.
     * @param startIndex      The initial order index to begin iteration on when
     *                        searching for offer items to aggregate.
     *
     * @return execution The aggregated offer items.
     */
    function _aggregateValidFulfillmentOfferItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory offerComponents,
        uint256 startIndex
    ) internal view returns (Execution memory execution) {
        // Declare a variable for the final aggregated item amount.
        uint256 amount;

        // Declare a variable indicating whether the aggregation is invalid.
        bool invalidFulfillment;

        // Utilize assembly in order to efficiently aggregate the items.
        assembly {
            // Retrieve fulfillment pointer from offer component & start index.
            let fulfillmentPtr := mload(
                add(add(offerComponents, 0x20), mul(startIndex, 0x20))
            )

            // Retrieve the order index using the fulfillment pointer.
            let orderIndex := mload(fulfillmentPtr)

            // Retrieve item index using an offset of the fulfillment pointer.
            let itemIndex := mload(
                add(fulfillmentPtr, Fulfillment_itemIndex_offset)
            )

            // Ensure that the order index is not out of range.
            invalidFulfillment := iszero(lt(orderIndex, mload(advancedOrders)))

            // Retrieve the initial order pointer from the order index.
            let orderPtr := mload(
                mload(
                    add(
                        // Calculate pointer to start of advancedOrders head.
                        add(advancedOrders, 0x20),
                        // Calculate offset to pointer for desired order.
                        mul(orderIndex, 0x20)
                    )
                )
            )
            // Retrieve offer array pointer using offset of the order pointer.
            let offerArrPtr := mload(
                add(orderPtr, OrderParameters_offer_head_offset)
            )

            // Ensure that the item index is not out of range.
            invalidFulfillment := or(
                iszero(lt(itemIndex, mload(offerArrPtr))),
                invalidFulfillment
            )

            // Retrieve the offer item pointer using offset of the item index.
            let offerItemPtr := mload(
                add(
                    // Get pointer to beginning of OfferItem.
                    add(offerArrPtr, 0x20),
                    // Calculate offset to pointer for desired order.
                    mul(itemIndex, 0x20)
                )
            )

            // Retrieve the received item pointer.
            let receivedItemPtr := mload(execution)

            // Set itemType located at the offerItem pointer on receivedItem.
            mstore(receivedItemPtr, mload(offerItemPtr))

            // Set token located at offset of offerItem pointer on receivedItem.
            mstore(
                add(receivedItemPtr, Common_token_offset),
                mload(add(offerItemPtr, Common_token_offset))
            )

            // Set identifier located at offset of offerItem pointer as well.
            mstore(
                add(receivedItemPtr, 0x40),
                mload(add(offerItemPtr, Common_identifier_offset))
            )

            // Set amount on received item and additionaly place on the stack.
            let amountPtr := add(offerItemPtr, Common_amount_offset)
            amount := mload(amountPtr)

            // Set the caller as the recipient on the received item.
            mstore(
                add(receivedItemPtr, ReceivedItem_recipient_offset),
                caller()
            )

            // Zero out amount on original offerItem to indicate it is spent.
            mstore(amountPtr, 0)

            // Set the offerer on returned execution using order pointer.
            mstore(add(execution, Execution_offerer_offset), mload(orderPtr))

            // Set conduit on returned execution using offset of order pointer.
            mstore(
                add(execution, Execution_conduit_offset),
                mload(add(orderPtr, OrderParameters_conduit_offset))
            )
        }

        // Declare new assembly scope to avoid stack too deep errors.
        assembly {
            // Retrieve the received item pointer using the execution.
            let receivedItemPtr := mload(execution)

            // Iterate over offer components as long as fulfillment is valid.
            // prettier-ignore
            for {
                let i := add(startIndex, 1)
            } and(iszero(invalidFulfillment), lt(i, mload(offerComponents))) {
                i := add(i, 1)
            } {
                // Retrieve fulfillment pointer for the current offer component.
                let fulfillmentPtr := mload(
                    add(add(offerComponents, 0x20), mul(i, 0x20))
                )

                // Retrieve the order index using the fulfillment pointer.
                let orderIndex := mload(fulfillmentPtr)

                // Retrieve the item index using offset of fulfillment pointer.
                let itemIndex := mload(
                    add(fulfillmentPtr, Fulfillment_itemIndex_offset)
                )

                // Ensure that the order index is in range.
                invalidFulfillment := iszero(
                    lt(orderIndex, mload(advancedOrders))
                )

                // Exit iteration if it is out of range.
                if invalidFulfillment {
                    break
                }

                // Retrieve the order pointer using the order index. Note that
                // advancedOrders[orderIndex].OrderParameters pointer is first
                // word of AdvancedOrder struct, so mload again in a moment.
                let orderPtr := mload(
                    add(add(advancedOrders, 0x20), mul(orderIndex, 0x20))
                )

                // If the order is available (i.e. has a numerator != 0)...
                if mload(add(orderPtr, AdvancedOrder_numerator_offset)) {
                    // Retrieve the order pointer (i.e. the second mload).
                    orderPtr := mload(orderPtr)

                    // Load offer item array pointer.
                    let offerArrPtr := mload(
                        add(orderPtr, OrderParameters_offer_head_offset)
                    )

                    // Ensure that the offer item index is in range.
                    invalidFulfillment := iszero(
                        lt(itemIndex, mload(offerArrPtr))
                    )

                    // Exit iteration if it is out of range.
                    if invalidFulfillment {
                        break
                    }

                    // Retrieve the offer item pointer using the item index.
                    let offerItemPtr := mload(
                        add(
                            // Get pointer to beginning of OfferItem
                            add(offerArrPtr, 0x20),
                            // Calculate offset to pointer for desired order
                            mul(itemIndex, 0x20)
                        )
                    )

                    // Retrieve the amount using the offer item pointer.
                    let amountPtr := add(offerItemPtr, Common_amount_offset)

                    // Increment the amount.
                    amount := add(amount, mload(amountPtr))

                    // Zero out amount on original item to indicate it is spent.
                    mstore(amountPtr, 0)

                    // Ensure the indicated offer item matches original item.
                    invalidFulfillment := iszero(
                        and(
                            // The identifier must match on both items.
                            eq(
                                mload(
                                    add(offerItemPtr, Common_identifier_offset)
                                ),
                                mload(
                                    add(
                                        receivedItemPtr,
                                        Common_identifier_offset
                                    )
                                )
                            ),
                            and(
                                and(
                                    // The offerer must match on both items.
                                    eq(
                                        mload(orderPtr),
                                        mload(
                                            add(execution, Common_token_offset)
                                        )
                                    ),
                                    // The conduit must match on both items.
                                    eq(
                                        mload(
                                            add(
                                                orderPtr,
                                                OrderParameters_conduit_offset
                                            )
                                        ),
                                        mload(
                                            add(
                                                execution,
                                                Execution_conduit_offset
                                            )
                                        )
                                    )
                                ),
                                and(
                                    // The item type must match on both items.
                                    eq(
                                        mload(offerItemPtr),
                                        mload(receivedItemPtr)
                                    ),
                                    // The token must match on both items.
                                    eq(
                                        mload(
                                            add(
                                                offerItemPtr,
                                                Common_token_offset
                                            )
                                        ),
                                        mload(
                                            add(
                                                receivedItemPtr,
                                                Common_token_offset
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                }
            }

            // Update the final amount on the returned received item.
            mstore(add(receivedItemPtr, Common_amount_offset), amount)
        }

        // Revert if an order/item was out of range or was not aggregatable.
        if (invalidFulfillment) {
            revert InvalidFulfillmentComponentData();
        }
    }

    /**
     * @dev Internal view function to aggregate consideration items from a group
     *      of orders into a single execution via a supplied components array.
     *      Consideration items that are not available to aggregate will not be
     *      included in the aggregated execution.
     *
     * @param advancedOrders          The orders to aggregate.
     * @param considerationComponents An array designating consideration
     *                                components to aggregate if part of an
     *                                available order.
     * @param nextComponentIndex      The index of the next potential
     *                                consideration component.
     * @param fulfillerConduit       A flag indicating whether to source
     *                                approvals for fulfilled tokens from the
     *                                fulfiller's respective proxy.
     *
     * @return execution The transfer performed as a result of the fulfillment.
     */
    function _aggregateConsiderationItems(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[] memory considerationComponents,
        uint256 nextComponentIndex,
        address fulfillerConduit
    ) internal view returns (Execution memory execution) {
        // Validate and aggregate consideration items on available orders and
        // store result as a ReceivedItem.
        ReceivedItem memory receiveConsiderationItem = (
            _aggregateValidFulfillmentConsiderationItems(
                advancedOrders,
                considerationComponents,
                nextComponentIndex
            )
        );

        // Return execution for aggregated items provided by the fulfiller.
        execution = Execution(
            receiveConsiderationItem,
            msg.sender,
            fulfillerConduit
        );
    }
}


// prettier-ignore
    BasicOrderParameters,
    OrderComponents,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    BatchExecution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver
} from "../lib/ConsiderationStructs.sol";

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1
 * @notice Consideration is a generalized ETH/ERC20/ERC721/ERC1155 marketplace.
 *         It minimizes external calls to the greatest extent possible and
 *         provides lightweight methods for common routes as well as more
 *         flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their proxy if indicated by the order) in order for
     *                   their offered ERC721 token to be transferred.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool);

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @param order             The order to fulfill. Note that both the offerer
     *                          and the fulfiller must first approve this
     *                          contract (or their proxy if indicated by the
     *                          order) to transfer any relevant tokens on their
     *                          behalf and that contracts must implement
     *                          `onERC1155Received` in order to receive ERC1155
     *                          tokens as consideration.
     * @param fulfillerConduit A flag indicating whether to source approvals
     *                          for fulfilled tokens from an associated proxy.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function fulfillOrder(Order calldata order, address fulfillerConduit)
        external
        payable
        returns (bool);

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder     The order to fulfill along with the fraction of
     *                          the order to attempt to fill. Note that both the
     *                          offerer and the fulfiller must first approve
     *                          this contract (or their proxy if indicated by
     *                          the order) to transfer any relevant tokens on
     *                          their behalf and that contracts must implement
     *                          `onERC1155Received` in order to receive ERC1155
     *                          tokens as consideration. Also note that all
     *                          offer and consideration components must have no
     *                          remainder after multiplication of the respective
     *                          amount with the supplied fraction in order for
     *                          the partial fill to be considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific offer or consideration, a token
     *                          identifier, and a proof that the supplied token
     *                          identifier is contained in the merkle root held
     *                          by the item in question's criteria element. Note
     *                          that an empty criteria indicates that any
     *                          (transferrable) token identifier on the token in
     *                          question is valid and that no associated proof
     *                          needs to be supplied.
     * @param fulfillerConduit A flag indicating whether to source approvals
     *                          for fulfilled tokens from an associated proxy.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        address fulfillerConduit
    ) external payable returns (bool);

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or their proxy if indicated by
     *                                  the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferrable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduit         A flag indicating whether to source
     *                                  approvals for fulfilled tokens from an
     *                                  associated proxy.
     *
     * @return availableOrders    An array of booleans indicating if each order
     *                            with an index corresponding to the index of
     *                            the returned boolean was fulfillable or not.
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        address fulfillerConduit
    )
        external
        payable
        returns (
            bool[] memory availableOrders,
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        );

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with as set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported).
     *
     * @param orders            The orders to match. Note that both the offerer
     *                          and fulfiller on each order must first approve
     *                          this contract (or their proxy if indicated by
     *                          the order) to transfer any relevant tokens on
     *                          their behalf and each consideration recipient
     *                          must implement `onERC1155Received` in order to
     *                          receive ERC1155 tokens.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        );

    /**
     * @notice Match an arbitrary number of full or partial orders, each with an
     *         arbitrary number of items for offer and consideration, supplying
     *         criteria resolvers containing specific token identifiers and
     *         associated proofs as well as fulfillments allocating offer
     *         components to consideration components.
     *
     * @param orders            The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or their proxy if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order toreceive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferrable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function matchAdvancedOrders(
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        );

    /**
     * @notice Cancel an arbitrary number of orders. Note that only the offerer
     * or the zone of a given order may cancel it.
     *
     * @param orders The orders to cancel.
     *
     * @return A boolean indicating whether the supplied orders were
     *         successfully cancelled.
     */
    function cancel(OrderComponents[] calldata orders) external returns (bool);

    /**
     * @notice Validate an arbitrary number of orders, thereby registering them
     *         as valid and allowing the fulfiller to skip verification. Note
     *         that anyone can validate a signed order but only the offerer can
     *         validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return A boolean indicating whether the supplied orders were
     *         successfully validated.
     */
    function validate(Order[] calldata orders) external returns (bool);

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a nonce. Note that only the offerer may increment
     *         the nonce.
     *
     * @return newNonce The new nonce.
     */
    function incrementNonce() external returns (uint256 newNonce);

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @param order The components of the order.
     *
     * @return The order hash.
     */
    function getOrderHash(OrderComponents calldata order)
        external
        view
        returns (bytes32);

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current nonce for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return The current nonce.
     */
    function getNonce(address offerer) external view returns (uint256);

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return The name of this contract.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieve the version of this contract.
     *
     * @return The version of this contract.
     */
    function version() external view returns (string memory);

    /**
     * @notice Retrieve the domain separator, used for signing and verifying
     * signed orders via EIP-712.
     *
     * @return The domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}



// prettier-ignore
    ERC20Interface,
    ERC721Interface,
    ERC1155Interface
} from "../interfaces/AbridgedTokenInterfaces.sol";



// prettier-ignore
    AdditionalRecipient,
    BasicOrderParameters,
    OfferItem,
    ConsiderationItem,
    SpentItem,
    ReceivedItem,
    OrderParameters,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver,
    Batch,
    BatchExecution
} from "./ConsiderationStructs.sol";



/**
 * @title ConsiderationInternal
 * @author 0age
 * @notice ConsiderationInternal contains all internal functions.
 */
contract ConsiderationInternal is ConsiderationInternalView {
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param legacyProxyRegistry         A proxy registry that stores per-user
     *                                    proxies that may optionally be used to
     *                                    transfer approved ERC721+1155 tokens.
     * @param legacyTokenTransferProxy    A shared proxy contract that may
     *                                    optionally be used to transfer
     *                                    approved ERC20 tokens.
     * @param requiredProxyImplementation The implementation that must be set on
     *                                    each proxy in order to utilize it.
     */
    constructor(
        address legacyProxyRegistry,
        address legacyTokenTransferProxy,
        address requiredProxyImplementation
    )
        ConsiderationInternalView(
            legacyProxyRegistry,
            legacyTokenTransferProxy,
            requiredProxyImplementation
        )
    {}

    /**
     * @dev Internal function to prepare fulfillment of a basic order with
     *      manual calldata and memory access. This calculates the order hash,
     *      emits an OrderFulfilled event, and asserts basic order validity.
     *      Note that calldata offsets must be validated as this function
     *      accesses constant calldata pointers for dynamic types that match
     *      default ABI encoding, but valid ABI encoding can use arbitrary
     *      offsets. Checking that the offsets were produced by default encoding
     *      will ensure that other functions using Solidity's calldata accessors
     *      (which calculate pointers from the stored offsets) are reading the
     *      same data as the order hash is derived from. Also note that This
     *      function accesses memory directly. It does not clear the expanded
     *      memory regions used, nor does it update the free memory pointer, so
     *      other direct memory access must not assume that unused memory is
     *      empty.
     *
     * @param parameters                   The parameters of the basic order.
     * @param orderType                    The order type.
     * @param receivedItemType             The item type of the initial
     *                                     consideration item on the order.
     * @param additionalRecipientsItemType The item type of any additional
     *                                     consideration item on the order.
     * @param additionalRecipientsToken    The ERC20 token contract adddress (if
     *                                     applicable) for any additional
     *                                     consideration item on the order.
     * @param offeredItemType              The item type of the offered item on
     *                                     the order.
     */
    function _prepareBasicFulfillmentFromCalldata(
        BasicOrderParameters calldata parameters,
        OrderType orderType,
        ItemType receivedItemType,
        ItemType additionalRecipientsItemType,
        address additionalRecipientsToken,
        ItemType offeredItemType
    ) internal {
        // Ensure this function cannot be triggered during a reentrant call.
        _setReentrancyGuard();

        // Ensure current timestamp falls between order start time and end time.
        _verifyTime(parameters.startTime, parameters.endTime, true);

        // Verify that calldata offsets for all dynamic types were produced by
        // default encoding. This ensures that the constants we use for calldata
        // pointers to dynamic types are the same as those calculated by
        // Solidity using their offsets.
        _assertValidBasicOrderParameterOffsets();

        // Ensure supplied consideration array length is not less than original.
        _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            parameters.additionalRecipients.length + 1,
            parameters.totalOriginalAdditionalRecipients
        );

        // Declare stack element for the order hash.
        bytes32 orderHash;

        {
            /**
             * First, handle consideration items. Memory Layout:
             *  0x60: final hash of the array of consideration item hashes
             *  0x80-0x160: reused space for EIP712 hashing of each item
             *   - 0x80: ConsiderationItem EIP-712 typehash (constant)
             *   - 0xa0: itemType
             *   - 0xc0: token
             *   - 0xe0: identifier
             *   - 0x100: startAmount
             *   - 0x120: endAmount
             *   - 0x140: recipient
             *  0x160-END_ARR: array of consideration item hashes
             *   - 0x160: primary consideration item EIP712 hash
             *   - 0x180-END_ARR: additional recipient item EIP712 hashes
             *  END_ARR: beginning of data for OrderFulfilled event
             *   - END_ARR + 0x120: length of ReceivedItem array
             *   - END_ARR + 0x140: beginning of data for first ReceivedItem
             * (Note: END_ARR = 0x180 + RECIPIENTS_LENGTH * 0x20)
             */

            // Load consideration item typehash from runtime and place on stack.
            bytes32 typeHash = _CONSIDERATION_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions and use
            // constant pointers when possible.
            assembly {
                /*
                 * 1. Calculate the EIP712 ConsiderationItem hash for the
                 * primary consideration item of the basic order.
                 */

                // Write ConsiderationItem type hash and item type to memory.
                mstore(BasicOrder_considerationItem_typeHash_ptr, typeHash)
                mstore(
                    BasicOrder_considerationItem_itemType_ptr,
                    receivedItemType
                )

                // Copy calldata region with (token, identifier, amount) from
                // BasicOrderParameters to ConsiderationItem. The
                // considerationAmount is written to startAmount and endAmount
                // as basic orders do not have dynamic amounts.
                calldatacopy(
                    BasicOrder_considerationItem_token_ptr,
                    BasicOrder_considerationToken_cdPtr,
                    ThreeWords
                )

                // Copy calldata region with considerationAmount and offerer
                // from BasicOrderParameters to endAmount and recipient in
                // ConsiderationItem.
                calldatacopy(
                    BasicOrder_considerationItem_endAmount_ptr,
                    BasicOrder_considerationAmount_cdPtr,
                    TwoWords
                )

                // Calculate EIP712 ConsiderationItem hash and store it in the
                // array of EIP712 consideration hashes.
                mstore(
                    BasicOrder_considerationHashesArray_ptr,
                    keccak256(
                        BasicOrder_considerationItem_typeHash_ptr,
                        EIP712_ConsiderationItem_size
                    )
                )

                /*
                 * 2. Write a ReceivedItem struct for the primary consideration
                 * item to the consideration array in OrderFulfilled.
                 */

                // Get the length of the additional recipients array.
                let len := calldataload(
                    BasicOrder_additionalRecipients_length_cdPtr
                )

                // Calculate pointer to length of OrderFulfilled consideration
                // array.
                let eventConsiderationArrPtr := add(
                    OrderFulfilled_consideration_length_baseOffset,
                    mul(0x20, len)
                )

                // Set the length of the consideration array to the number of
                // additional recipients, plus one for the primary consideration
                // item.
                mstore(
                    eventConsiderationArrPtr,
                    add(
                        calldataload(
                            BasicOrder_additionalRecipients_length_cdPtr
                        ),
                        1
                    )
                )

                // Overwrite the consideration array pointer so it points to the
                // body of the first element
                eventConsiderationArrPtr := add(eventConsiderationArrPtr, 0x20)

                // Set itemType at start of the ReceivedItem memory region.
                mstore(eventConsiderationArrPtr, receivedItemType)

                // Copy calldata region (token, identifier, amount & recipient)
                // from BasicOrderParameters to ReceivedItem memory.
                calldatacopy(
                    add(eventConsiderationArrPtr, Common_token_offset),
                    BasicOrder_considerationToken_cdPtr,
                    0x80
                )

                /*
                 * 3. Calculate EIP712 ConsiderationItem hashes for original
                 * additional recipients and add a ReceivedItem for each to the
                 * consideration array in the OrderFulfilled event. The original
                 * additional recipients are all the considerations signed by
                 * the offerer aside from the primary consideration of the
                 * order. Uses memory region from 0x80-0x160 as a buffer for
                 * calculating EIP712 ConsiderationItem hashes.
                 */

                // Put pointer to consideration hashes array on the stack.
                // This will be updated as each additional recipient is hashed
                let
                    considerationHashesPtr
                := BasicOrder_considerationHashesArray_ptr

                // Write item type, token, & identifier for additional recipient
                // to memory region for hashing EIP712 ConsiderationItem; these
                // values will be reused for each recipient.
                mstore(
                    BasicOrder_considerationItem_itemType_ptr,
                    additionalRecipientsItemType
                )
                mstore(
                    BasicOrder_considerationItem_token_ptr,
                    additionalRecipientsToken
                )
                mstore(BasicOrder_considerationItem_identifier_ptr, 0)

                // Read length of the additionalRecipients array from calldata
                // and iterate.
                len := calldataload(
                    BasicOrder_totalOriginalAdditionalRecipients_cdPtr
                )
                let i := 0
                // prettier-ignore
                for {} lt(i, len) {
                    i := add(i, 1)
                } {
                    /*
                     * Calculate EIP712 ConsiderationItem hash for recipient.
                     */

                    // Retrieve calldata pointer for additional recipient.
                    let additionalRecipientCdPtr := add(
                        BasicOrder_additionalRecipients_data_cdPtr,
                        mul(AdditionalRecipients_size, i)
                    )

                    // Copy startAmount from calldata to the ConsiderationItem
                    // struct.
                    calldatacopy(
                        BasicOrder_considerationItem_startAmount_ptr,
                        additionalRecipientCdPtr,
                        0x20
                    )

                    // Copy endAmount and recipient from calldata to the
                    // ConsiderationItem struct.
                    calldatacopy(
                        BasicOrder_considerationItem_endAmount_ptr,
                        additionalRecipientCdPtr,
                        AdditionalRecipients_size
                    )

                    // Add 1 word to the pointer as part of each loop to reduce
                    // operations needed to get local offset into the array.
                    considerationHashesPtr := add(considerationHashesPtr, 0x20)

                    // Calculate EIP712 ConsiderationItem hash and store it in
                    // the array of consideration hashes.
                    mstore(
                        considerationHashesPtr,
                        keccak256(
                            BasicOrder_considerationItem_typeHash_ptr,
                            EIP712_ConsiderationItem_size
                        )
                    )

                    /*
                     * Write ReceivedItem to OrderFulfilled data.
                     */

                    // At this point, eventConsiderationArrPtr points to the
                    // beginning of the ReceivedItem struct of the previous
                    // element in the array. Increase it by the size of the
                    // struct to arrive at the pointer for the current element.
                    eventConsiderationArrPtr := add(
                        eventConsiderationArrPtr,
                        ReceivedItem_size
                    )

                    // Write itemType to the ReceivedItem struct.
                    mstore(
                        eventConsiderationArrPtr,
                        additionalRecipientsItemType
                    )

                    // Write token to the ReceivedItem struct.
                    mstore(
                        add(eventConsiderationArrPtr, 0x20),
                        additionalRecipientsToken
                    )

                    // Copy endAmount and recipient to the ReceivedItem struct.
                    calldatacopy(
                        add(
                            eventConsiderationArrPtr,
                            ReceivedItem_amount_offset
                        ),
                        additionalRecipientCdPtr,
                        0x40
                    )
                }

                /*
                 * 4. Hash packed array of ConsiderationItem EIP712 hashes:
                 *   `keccak256(abi.encodePacked(receivedItemHashes))`
                 * Note that it is set at 0x60 — all other memory begins at
                 * 0x80. 0x60 is the "zero slot" and will be restored at the end
                 * of the assembly section and before required by the compiler.
                 */
                mstore(
                    receivedItemsHash_ptr,
                    keccak256(
                        BasicOrder_considerationHashesArray_ptr,
                        mul(add(len, 1), 32)
                    )
                )

                /*
                 * 5. Add a ReceivedItem for each tip to the consideration array
                 * in the OrderFulfilled event. The tips are all the
                 * consideration items that were not signed by the offerer and
                 * were provided by the fulfiller.
                 */

                // Overwrite length to length of the additionalRecipients array.
                len := calldataload(
                    BasicOrder_additionalRecipients_length_cdPtr
                )
                // prettier-ignore
                for {} lt(i, len) {
                    i := add(i, 1)
                } {
                    // Retrieve calldata pointer for additional recipient.
                    let additionalRecipientCdPtr := add(
                        BasicOrder_additionalRecipients_data_cdPtr,
                        mul(AdditionalRecipients_size, i)
                    )

                    // At this point, eventConsiderationArrPtr points to the
                    // beginning of the ReceivedItem struct of the previous
                    // element in the array. Increase it by the size of the
                    // struct to arrive at the pointer for the current element.
                    eventConsiderationArrPtr := add(
                        eventConsiderationArrPtr,
                        ReceivedItem_size
                    )

                    // Write itemType to the ReceivedItem struct.
                    mstore(
                        eventConsiderationArrPtr,
                        additionalRecipientsItemType
                    )

                    // Write token to the ReceivedItem struct.
                    mstore(
                        add(eventConsiderationArrPtr, 0x20),
                        additionalRecipientsToken
                    )

                    // Copy endAmount and recipient to the ReceivedItem struct.
                    calldatacopy(
                        add(
                            eventConsiderationArrPtr,
                            ReceivedItem_amount_offset
                        ),
                        additionalRecipientCdPtr,
                        0x40
                    )
                }
            }
        }

        {
            /**
             * Next, handle offered items. Memory Layout:
             *  EIP712 data for OfferItem
             *   - 0x80:  OfferItem EIP-712 typehash (constant)
             *   - 0xa0:  itemType
             *   - 0xc0:  token
             *   - 0xe0:  identifier (reused for offeredItemsHash)
             *   - 0x100: startAmount
             *   - 0x120: endAmount
             */

            // Place offer item typehash on the stack.
            bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

            // Utilize assembly to enable reuse of memory regions when possible.
            assembly {
                /*
                 * 1. Calculate OfferItem EIP712 hash
                 */

                // Write the OfferItem typeHash to memory.
                mstore(BasicOrder_offerItem_typeHash_ptr, typeHash)

                // Write the OfferItem item type to memory.
                mstore(BasicOrder_offerItem_itemType_ptr, offeredItemType)

                // Copy calldata region with (offerToken, offerIdentifier,
                // offerAmount) from OrderParameters to (token, identifier,
                // startAmount) in OfferItem struct. The offerAmount is written
                // to startAmount and endAmount as basic orders do not have
                // dynamic amounts.
                calldatacopy(
                    BasicOrder_offerItem_token_ptr,
                    BasicOrder_offerToken_cdPtr,
                    0x60
                )

                // Copy offerAmount from calldata to endAmount in OfferItem
                // struct.
                calldatacopy(
                    BasicOrder_offerItem_endAmount_ptr,
                    BasicOrder_offerAmount_cdPtr,
                    0x20
                )

                // Compute EIP712 OfferItem hash, write result to scratch space:
                //   `keccak256(abi.encode(offeredItem))`
                mstore(
                    0x00,
                    keccak256(
                        BasicOrder_offerItem_typeHash_ptr,
                        EIP712_OfferItem_size
                    )
                )

                /*
                 * 2. Calculate hash of array of EIP712 hashes and write the
                 * result to the corresponding OfferItem struct:
                 *   `keccak256(abi.encodePacked(offerItemHashes))`
                 */
                mstore(BasicOrder_order_offerHashes_ptr, keccak256(0x00, 0x20))

                /*
                 * 3. Write SpentItem to offer array in OrderFulfilled event.
                 */
                let eventConsiderationArrPtr := add(
                    OrderFulfilled_offer_length_baseOffset,
                    mul(
                        0x20,
                        calldataload(
                            BasicOrder_additionalRecipients_length_cdPtr
                        )
                    )
                )

                // Set a length of 1 for the offer array.
                mstore(eventConsiderationArrPtr, 1)

                // Write itemType to the SpentItem struct.
                mstore(add(eventConsiderationArrPtr, 0x20), offeredItemType)

                // Copy calldata region with (offerToken, offerIdentifier,
                // offerAmount) from OrderParameters to (token, identifier,
                // amount) in SpentItem struct.
                calldatacopy(
                    add(eventConsiderationArrPtr, AdditionalRecipients_size),
                    BasicOrder_offerToken_cdPtr,
                    ThreeWords
                )
            }
        }

        {
            /**
             * Once consideration items and offer items have been handled,
             * derive the final order hash. Memory Layout:
             *  0x80-0x1c0: EIP712 data for order
             *   - 0x80:   Order EIP-712 typehash (constant)
             *   - 0xa0:   orderParameters.offerer
             *   - 0xc0:   orderParameters.zone
             *   - 0xe0:   keccak256(abi.encodePacked(offerHashes))
             *   - 0x100:  keccak256(abi.encodePacked(considerationHashes))
             *   - 0x120:  orderParameters.basicOrderType (% 4 = orderType)
             *   - 0x140:  orderParameters.startTime
             *   - 0x160:  orderParameters.endTime
             *   - 0x180:  orderParameters.zoneHash
             *   - 0x1a0:  orderParameters.salt
             *   - 0x1c0:  orderParameters.conduit
             *   - 0x1e0:  _nonces[orderParameters.offerer] (from storage)
             */

            // Read the offerer from calldata and place on the stack.
            address offerer;
            assembly {
                offerer := calldataload(BasicOrder_offerer_cdPtr)
            }

            // Read offerer's current nonce from storage and place on the stack.
            uint256 nonce = _nonces[offerer];

            // Load order typehash from runtime code and place on stack.
            bytes32 typeHash = _ORDER_TYPEHASH;

            assembly {
                // Set the OrderItem typeHash in memory.
                mstore(BasicOrder_order_typeHash_ptr, typeHash)

                // Copy offerer and zone from OrderParameters in calldata to the
                // Order struct.
                calldatacopy(
                    BasicOrder_order_offerer_ptr,
                    BasicOrder_offerer_cdPtr,
                    TwoWords
                )

                // Copy receivedItemsHash from zero slot to the Order struct.
                mstore(
                    BasicOrder_order_considerationHashes_ptr,
                    mload(receivedItemsHash_ptr)
                )

                // Write the supplied orderType to the Order struct.
                mstore(BasicOrder_order_orderType_ptr, orderType)

                // Copy startTime, endTime, zoneHash, salt & conduit from
                // calldata to the Order struct.
                calldatacopy(
                    BasicOrder_order_startTime_ptr,
                    BasicOrder_startTime_cdPtr,
                    0xa0
                )

                // Take offerer's nonce retrieved from storage, write to struct.
                mstore(BasicOrder_order_nonce_ptr, nonce)

                // Compute the EIP712 Order hash.
                orderHash := keccak256(
                    BasicOrder_order_typeHash_ptr,
                    EIP712_Order_size
                )
            }
        }

        assembly {
            /**
             * After the order hash has been derived, emit OrderFulfilled event:
             *   event OrderFulfilled(
             *     bytes32 orderHash,
             *     address indexed offerer,
             *     address indexed zone,
             *     address fulfiller,
             *     SpentItem[] offer,
             *       > (itemType, token, id, amount)
             *     ReceivedItem[] consideration
             *       > (itemType, token, id, amount, recipient)
             *   )
             * topic0 - OrderFulfilled event signature
             * topic1 - offerer
             * topic2 - zone
             * data:
             *  - 0x00: orderHash
             *  - 0x20: fulfiller
             *  - 0x40: offer arr ptr (0x80)
             *  - 0x60: consideration arr ptr (0x120)
             *  - 0x80: offer arr len (1)
             *  - 0xa0: offer.itemType
             *  - 0xc0: offer.token
             *  - 0xe0: offer.identifier
             *  - 0x100: offer.amount
             *  - 0x120: 1 + recipients.length
             *  - 0x140: recipient 0
             */

            // Derive pointer to start of OrderFulfilled event data
            let eventDataPtr := add(
                OrderFulfilled_baseOffset,
                mul(
                    0x20,
                    calldataload(BasicOrder_additionalRecipients_length_cdPtr)
                )
            )

            // Write the order hash to the head of the event's data region.
            mstore(eventDataPtr, orderHash)

            // Write the fulfiller (i.e. the caller) next.
            mstore(add(eventDataPtr, OrderFulfilled_fulfiller_offset), caller())

            // Write the SpentItem and ReceivedItem array offsets (constants).
            mstore(
                // SpentItem array offset
                add(eventDataPtr, OrderFulfilled_offer_head_offset),
                OrderFulfilled_offer_body_offset
            )
            mstore(
                // ReceivedItem array offset
                add(eventDataPtr, OrderFulfilled_consideration_head_offset),
                OrderFulfilled_consideration_body_offset
            )

            // Derive total data size including SpentItem and ReceivedItem data.
            // SpentItem portion is already included in the baseSize constant,
            // as there can only be one element in the array.
            let dataSize := add(
                OrderFulfilled_baseSize,
                mul(
                    calldataload(BasicOrder_additionalRecipients_length_cdPtr),
                    ReceivedItem_size
                )
            )

            // Emit OrderFulfilled log with three topics (the event signature
            // as well as the two indexed arguments, the offerer and the zone).
            log3(
                // Supply the pointer for event data in memory.
                eventDataPtr,
                // Supply the size of event data in memory.
                dataSize,
                // Supply the OrderFulfilled event signature.
                OrderFulfilled_selector,
                // Supply the first topic (the offerer).
                calldataload(BasicOrder_offerer_cdPtr),
                // Supply the second topic (the zone).
                calldataload(BasicOrder_zone_cdPtr)
            )

            // Restore the zero slot.
            mstore(0x60, 0)
        }

        // Determine whether order is restricted and, if so, that it is valid.
        _assertRestrictedBasicOrderValidity(
            orderHash,
            parameters.zoneHash,
            orderType,
            parameters.offerer,
            parameters.zone
        );

        // Verify and update the status of the derived order.
        _validateBasicOrderAndUpdateStatus(
            orderHash,
            parameters.offerer,
            parameters.signature
        );
    }

    /**
     * @dev Internal function to verify and update the status of a basic order.
     *
     * @param orderHash The hash of the order.
     * @param offerer   The offerer of the order.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _validateBasicOrderAndUpdateStatus(
        bytes32 orderHash,
        address offerer,
        bytes memory signature
    ) internal {
        // Retrieve the order status for the given order hash.
        OrderStatus memory orderStatus = _orderStatus[orderHash];

        // Ensure order is fillable and is not cancelled.
        _verifyOrderStatus(
            orderHash,
            orderStatus,
            true, // Only allow unused orders when fulfilling basic orders.
            true // Signifies to revert if the order is invalid.
        );

        // If the order is not already validated, verify the supplied signature.
        if (!orderStatus.isValidated) {
            _verifySignature(offerer, orderHash, signature);
        }

        // Update order status as fully filled, packing struct values.
        _orderStatus[orderHash].isValidated = true;
        _orderStatus[orderHash].isCancelled = false;
        _orderStatus[orderHash].numerator = 1;
        _orderStatus[orderHash].denominator = 1;
    }

    /**
     * @dev Internal function to validate an order, determine what portion to
     *      fill, and update its status. The desired fill amount is supplied as
     *      a fraction, as is the returned amount to fill.
     *
     * @param advancedOrder    The order to fulfill as well as the fraction to
     *                         fill. Note that all offer and consideration
     *                         amounts must divide with no remainder in order
     *                         for a partial fill to be valid.
     * @param revertOnInvalid  A boolean indicating whether to revert if the
     *                         order is invalid due to the time or order status.
     * @param priorOrderHashes The order hashes of each order supplied prior to
     *                         the current order as part of a "match" variety of
     *                         order fulfillment (e.g. this array will be empty
     *                         for single or "fulfill available").
     *
     * @return orderHash      The order hash.
     * @return newNumerator   A value indicating the portion of the order that
     *                        will be filled.
     * @return newDenominator A value indicating the total size of the order.
     */
    function _validateOrderAndUpdateStatus(
        AdvancedOrder memory advancedOrder,
        bool revertOnInvalid,
        bytes32[] memory priorOrderHashes
    )
        internal
        returns (
            bytes32 orderHash,
            uint256 newNumerator,
            uint256 newDenominator
        )
    {
        // Retrieve the parameters for the order.
        OrderParameters memory orderParameters = advancedOrder.parameters;

        // Ensure current timestamp falls between order start time and end time.
        if (
            !_verifyTime(
                orderParameters.startTime,
                orderParameters.endTime,
                revertOnInvalid
            )
        ) {
            // Assuming an invalid time and no revert, return zeroed out values.
            return (bytes32(0), 0, 0);
        }

        // Read numerator and denominator from memory and place on the stack.
        uint256 numerator = uint256(advancedOrder.numerator);
        uint256 denominator = uint256(advancedOrder.denominator);

        // Ensure that the supplied numerator and denominator are valid.
        if (numerator > denominator || numerator == 0) {
            revert BadFraction();
        }

        // If attempting partial fill (n < d) check order type & ensure support.
        if (
            numerator < denominator &&
            _doesNotSupportPartialFills(orderParameters.orderType)
        ) {
            // Revert if partial fill was attempted on an unsupported order.
            revert PartialFillsNotEnabledForOrder();
        }

        // Retrieve current nonce and use it w/ parameters to derive order hash.
        orderHash = _assertConsiderationLengthAndGetNoncedOrderHash(
            orderParameters
        );

        // Determine if a proxy should be utilized and ensure a valid submitter.
        _assertRestrictedAdvancedOrderValidity(
            advancedOrder,
            priorOrderHashes,
            orderHash,
            orderParameters.zoneHash,
            orderParameters.orderType,
            orderParameters.offerer,
            orderParameters.zone
        );

        // Retrieve the order status using the derived order hash.
        OrderStatus memory orderStatus = _orderStatus[orderHash];

        // Ensure order is fillable and is not cancelled.
        if (
            !_verifyOrderStatus(
                orderHash,
                orderStatus,
                false, // Allow partially used orders to be filled.
                revertOnInvalid
            )
        ) {
            // Assuming an invalid order status and no revert, return zero fill.
            return (orderHash, 0, 0);
        }

        // If the order is not already validated, verify the supplied signature.
        if (!orderStatus.isValidated) {
            _verifySignature(
                orderParameters.offerer,
                orderHash,
                advancedOrder.signature
            );
        }

        // Read filled amount as numerator and denominator and put on the stack.
        uint256 filledNumerator = orderStatus.numerator;
        uint256 filledDenominator = orderStatus.denominator;

        // If order currently has a non-zero denominator it is partially filled.
        if (filledDenominator != 0) {
            // If denominator of 1 supplied, fill all remaining amount on order.
            if (denominator == 1) {
                // Scale numerator & denominator to match current denominator.
                numerator = filledDenominator;
                denominator = filledDenominator;
            }
            // Otherwise, if supplied denominator differs from current one...
            else if (filledDenominator != denominator) {
                // scale current numerator by the supplied denominator, then...
                filledNumerator *= denominator;

                // the supplied numerator & denominator by current denominator.
                numerator *= filledDenominator;
                denominator *= filledDenominator;
            }

            // Once adjusted, if current+supplied numerator exceeds denominator:
            if (filledNumerator + numerator > denominator) {
                // Skip underflow check: denominator >= orderStatus.numerator
                unchecked {
                    // Reduce current numerator so it + supplied = denominator.
                    numerator = denominator - filledNumerator;
                }
            }

            // Skip overflow check: checked above unless numerator is reduced.
            unchecked {
                // Update order status and fill amount, packing struct values.
                _orderStatus[orderHash].isValidated = true;
                _orderStatus[orderHash].isCancelled = false;
                _orderStatus[orderHash].numerator = uint120(
                    filledNumerator + numerator
                );
                _orderStatus[orderHash].denominator = uint120(denominator);
            }
        } else {
            // Update order status and fill amount, packing struct values.
            _orderStatus[orderHash].isValidated = true;
            _orderStatus[orderHash].isCancelled = false;
            _orderStatus[orderHash].numerator = uint120(numerator);
            _orderStatus[orderHash].denominator = uint120(denominator);
        }

        // Return order hash, new numerator and denominator, and proxy boolean.
        return (orderHash, numerator, denominator);
    }

    /**
     * @dev Internal function to validate an order and update its status, adjust
     *      prices based on current time, apply criteria resolvers, determine
     *      what portion to fill, and transfer relevant tokens.
     *
     * @param advancedOrder     The order to fulfill as well as the fraction to
     *                          fill. Note that all offer and consideration
     *                          components must divide with no remainder in
     *                          order for the partial fill to be valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific offer or consideration, a token
     *                          identifier, and a proof that the supplied token
     *                          identifier is contained in the order's merkle
     *                          root. Note that a criteria of zero indicates
     *                          that any (transferrable) token identifier is
     *                          valid and that no proof needs to be supplied.
     * @param fulfillerConduit  An address indicating what conduit, if any, to
     *                          source the fulfiller's token approvals from. The
     *                          null address signifies that no conduit should be
     *                          used (and direct approvals set on Consideration)
     *                          and `address(1)` signifies to utilize the legacy
     *                          user proxy for the fulfiller.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function _validateAndFulfillAdvancedOrder(
        AdvancedOrder memory advancedOrder,
        CriteriaResolver[] memory criteriaResolvers,
        address fulfillerConduit
    ) internal returns (bool) {
        // Ensure this function cannot be triggered during a reentrant call.
        _setReentrancyGuard();

        // Declare empty bytes32 array (unused, will remain empty).
        bytes32[] memory priorOrderHashes;

        // Validate order, update status, and determine fraction to fill.
        (
            bytes32 orderHash,
            uint256 fillNumerator,
            uint256 fillDenominator
        ) = _validateOrderAndUpdateStatus(
                advancedOrder,
                true,
                priorOrderHashes
            );

        // Create an array with length 1 containing the order.
        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](1);
        advancedOrders[0] = advancedOrder;

        // Apply criteria resolvers using generated orders and details arrays.
        _applyCriteriaResolvers(advancedOrders, criteriaResolvers);

        // Retrieve the order parameters after applying criteria resolvers.
        OrderParameters memory orderParameters = advancedOrders[0].parameters;

        // Perform each item transfer with the appropriate fractional amount.
        _applyFractionsAndTransferEach(
            orderParameters,
            fillNumerator,
            fillDenominator,
            orderParameters.conduit,
            fulfillerConduit
        );

        // Emit an event signifying that the order has been fulfilled.
        _emitOrderFulfilledEvent(
            orderHash,
            orderParameters.offerer,
            orderParameters.zone,
            msg.sender,
            orderParameters.offer,
            orderParameters.consideration
        );

        // Clear the reentrancy guard.
        _reentrancyGuard = _NOT_ENTERED;

        return true;
    }

    /**
     * @dev Internal function to transfer each item contained in a given single
     *      order fulfillment after applying a respective fraction to the amount
     *      being transferred.
     *
     * @param orderParameters  The parameters for the fulfilled order.
     * @param numerator        A value indicating the portion of the order that
     *                         should be filled.
     * @param denominator      A value indicating the total size of the order.
     * @param offererConduit   An address indicating what conduit, if any, to
     *                         source the offerer's token approvals from. The
     *                         null address signifies that no conduit should be
     *                         used (and direct approvals set on Consideration)
     *                         and `address(1)` signifies to utilize the legacy
     *                         user proxy for the offerer.
     * @param fulfillerConduit An address indicating what conduit, if any, to
     *                         source the fulfiller's token approvals from. The
     *                         null address signifies that no conduit should be
     *                         used (and direct approvals set on Consideration)
     *                         and `address(1)` signifies to utilize the legacy
     *                         user proxy for the fulfiller.
     */
    function _applyFractionsAndTransferEach(
        OrderParameters memory orderParameters,
        uint256 numerator,
        uint256 denominator,
        address offererConduit,
        address fulfillerConduit
    ) internal {
        // Derive order duration, time elapsed, and time remaining.
        uint256 duration = orderParameters.endTime - orderParameters.startTime;
        uint256 elapsed = block.timestamp - orderParameters.startTime;
        uint256 remaining = duration - elapsed;

        // Put ether value supplied by the caller on the stack.
        uint256 etherRemaining = msg.value;

        // As of solidity 0.6.0, inline assembly can not directly access function
        // definitions, but can still access locally scoped function variables.
        // This means that in order to recast the type of a function, we need to
        // create a local variable to reference the internal function definition
        // (using the same type) and a local variable with the desired type,
        // and then cast the original function pointer to the desired type.

        /**
         * Repurpose existing OfferItem memory regions on the offer array for
         * the order by overriding the _transfer function pointer to accept a
         * modified OfferItem argument in place of the usual ReceivedItem:
         *
         *   ========= OfferItem ==========   ====== ReceivedItem ======
         *   ItemType itemType; ------------> ItemType itemType;
         *   address token; ----------------> address token;
         *   uint256 identifierOrCriteria; -> uint256 identifier;
         *   uint256 startAmount; ----------> uint256 amount;
         *   uint256 endAmount; ------------> address recipient;
         */

        // Declare a nested scope to minimize stack depth.
        {
            // Declare a virtual function pointer taking an OfferItem argument.
            function(OfferItem memory, address, address)
                internal _transferOfferItem;

            // Assign _transfer function to a new function pointer (it takes a
            // ReceivedItem as its initial argument)
            function(ReceivedItem memory, address, address)
                internal _transferReceivedItem = _transfer;

            // Utilize assembly to override the virtual function pointer.
            assembly {
                // Cast initial ReceivedItem argument type to an OfferItem type.
                _transferOfferItem := _transferReceivedItem
            }

            // Iterate over each offer on the order.
            for (uint256 i = 0; i < orderParameters.offer.length; ) {
                // Retrieve the offer item.
                OfferItem memory offerItem = orderParameters.offer[i];

                // Apply fill fraction to derive offer item amount to transfer.
                uint256 amount = _applyFraction(
                    offerItem.startAmount,
                    offerItem.endAmount,
                    numerator,
                    denominator,
                    elapsed,
                    remaining,
                    duration,
                    false
                );

                // Utilize assembly to set overloaded offerItem arguments.
                assembly {
                    // Write derived fractional amount to startAmount as amount.
                    mstore(add(offerItem, 0x60), amount)
                    // Write fulfiller (i.e. caller) to endAmount as recipient.
                    mstore(add(offerItem, 0x80), caller())
                }

                // Reduce available value if offer spent ETH or a native token.
                if (offerItem.itemType == ItemType.NATIVE) {
                    // Ensure that sufficient native tokens are still available.
                    if (amount > etherRemaining) {
                        revert InsufficientEtherSupplied();
                    }

                    // Skip underflow check as a comparison has just been made.
                    unchecked {
                        etherRemaining -= amount;
                    }
                }

                // Transfer the item from the offerer to the caller.
                _transferOfferItem(
                    offerItem,
                    orderParameters.offerer,
                    offererConduit
                );

                // Skip overflow check as for loop is indexed starting at zero.
                unchecked {
                    ++i;
                }
            }
        }

        /**
         * Repurpose existing ConsiderationItem memory regions on the
         * consideration array for the order by overriding the _transfer
         * function pointer to accept a modified ConsiderationItem argument in
         * place of the usual ReceivedItem:
         *
         *   ====== ConsiderationItem =====   ====== ReceivedItem ======
         *   ItemType itemType; ------------> ItemType itemType;
         *   address token; ----------------> address token;
         *   uint256 identifierOrCriteria;--> uint256 identifier;
         *   uint256 startAmount; ----------> uint256 amount;
         *   uint256 endAmount;        /----> address recipient;
         *   address recipient; ------/
         */

        // Declare a nested scope to minimize stack depth.
        {
            // Declare virtual function pointer with ConsiderationItem argument.
            function(ConsiderationItem memory, address, address)
                internal _transferConsiderationItem;

            // Reassign _transfer function to a new function pointer (it takes a
            /// ReceivedItem as its initial argument).
            function(ReceivedItem memory, address, address)
                internal _transferReceivedItem = _transfer;

            // Utilize assembly to override the virtual function pointer.
            assembly {
                // Cast ReceivedItem argument type to ConsiderationItem type.
                _transferConsiderationItem := _transferReceivedItem
            }

            // Iterate over each consideration on the order.
            for (uint256 i = 0; i < orderParameters.consideration.length; ) {
                // Retrieve the consideration item.
                ConsiderationItem memory considerationItem = (
                    orderParameters.consideration[i]
                );

                // Apply fraction & derive considerationItem amount to transfer.
                uint256 amount = _applyFraction(
                    considerationItem.startAmount,
                    considerationItem.endAmount,
                    numerator,
                    denominator,
                    elapsed,
                    remaining,
                    duration,
                    true
                );

                // Use assembly to set overloaded considerationItem arguments.
                assembly {
                    // Write derived fractional amount to startAmount as amount.
                    mstore(add(considerationItem, 0x60), amount)

                    // Write original recipient to endAmount as recipient.
                    mstore(
                        add(considerationItem, 0x80),
                        mload(add(considerationItem, 0xa0))
                    )
                }

                // Reduce available value if offer spent ETH or a native token.
                if (considerationItem.itemType == ItemType.NATIVE) {
                    // Ensure that sufficient native tokens are still available.
                    if (amount > etherRemaining) {
                        revert InsufficientEtherSupplied();
                    }

                    // Skip underflow check as a comparison has just been made.
                    unchecked {
                        etherRemaining -= amount;
                    }
                }

                // Transfer item from caller to recipient specified by the item.
                _transferConsiderationItem(
                    considerationItem,
                    msg.sender,
                    fulfillerConduit
                );

                // Skip overflow check as for loop is indexed starting at zero.
                unchecked {
                    ++i;
                }
            }
        }

        // If any ether remains after fulfillments...
        if (etherRemaining != 0) {
            // return it to the caller.
            _transferEth(payable(msg.sender), etherRemaining);
        }
    }

    /**
     * @dev Internal function to validate a group of orders, update their
     *      statuses, reduce amounts by their previously filled fractions, apply
     *      criteria resolvers, and emit OrderFulfilled events.
     *
     * @param advancedOrders    The advanced orders to validate and reduce by
     *                          their previously filled amounts.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          a root of zero indicates that any transferrable
     *                          token identifier is valid and that no proof
     *                          needs to be supplied.
     */
    function _validateOrdersAndPrepareToFulfill(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        bool revertOnInvalid
    ) internal {
        // Ensure this function cannot be triggered during a reentrant call.
        _setReentrancyGuard();

        // Read length of orders array and place on the stack.
        uint256 totalOrders = advancedOrders.length;

        // Track the order hash for each order being fulfilled.
        bytes32[] memory orderHashes = new bytes32[](totalOrders);

        // Override orderHashes length to zero after memory has been allocated.
        assembly {
            mstore(orderHashes, 0)
        }

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the current order.
                AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Validate it, update status, and determine fraction to fill.
                (
                    bytes32 orderHash,
                    uint256 numerator,
                    uint256 denominator
                ) = _validateOrderAndUpdateStatus(
                        advancedOrder,
                        revertOnInvalid,
                        orderHashes
                    );

                // Update the length of the orderHashes array.
                assembly {
                    mstore(orderHashes, add(i, 1))
                }

                // Place the start time for the order on the stack.
                uint256 startTime = advancedOrder.parameters.startTime;

                // Derive the duration for the order and place it on the stack.
                uint256 duration = advancedOrder.parameters.endTime - startTime;

                // Derive time elapsed since the order started & place on stack.
                uint256 elapsed = block.timestamp - startTime;

                // Derive time remaining until order expires and place on stack.
                uint256 remaining = duration - elapsed;

                // Do not track hash or adjust prices if order is not fulfilled.
                if (numerator == 0) {
                    // Mark fill fraction as zero if the order is not fulfilled.
                    advancedOrder.numerator = 0;

                    // Continue iterating through the remaining orders.
                    continue;
                }

                // Otherwise, track the order hash in question.
                orderHashes[i] = orderHash;

                // Retrieve array of offer items for the order in question.
                OfferItem[] memory offer = advancedOrder.parameters.offer;

                // Iterate over each offer item on the order.
                for (uint256 j = 0; j < offer.length; ++j) {
                    // Retrieve the offer item.
                    OfferItem memory offerItem = offer[j];

                    // Apply order fill fraction to offer item end amount.
                    uint256 endAmount = _getFraction(
                        numerator,
                        denominator,
                        offerItem.endAmount
                    );

                    // Reuse same fraction if start and end amounts are equal.
                    if (offerItem.startAmount == offerItem.endAmount) {
                        // Apply derived amount to both start and end amount.
                        offerItem.startAmount = endAmount;
                    } else {
                        // Apply order fill fraction to offer item start amount.
                        offerItem.startAmount = _getFraction(
                            numerator,
                            denominator,
                            offerItem.startAmount
                        );
                    }

                    // Update end amount in memory to match the derived amount.
                    offerItem.endAmount = endAmount;

                    // Adjust offer amount using current time; round down.
                    offerItem.startAmount = _locateCurrentAmount(
                        offerItem.startAmount,
                        offerItem.endAmount,
                        elapsed,
                        remaining,
                        duration,
                        false // round down
                    );
                }

                // Retrieve array of consideration items for order in question.
                ConsiderationItem[] memory consideration = (
                    advancedOrder.parameters.consideration
                );

                // Iterate over each consideration item on the order.
                for (uint256 j = 0; j < consideration.length; ++j) {
                    // Retrieve the consideration item.
                    ConsiderationItem memory considerationItem = (
                        consideration[j]
                    );

                    // Apply fraction to consideration item end amount.
                    uint256 endAmount = _getFraction(
                        numerator,
                        denominator,
                        considerationItem.endAmount
                    );

                    // Reuse same fraction if start and end amounts are equal.
                    if (
                        considerationItem.startAmount ==
                        considerationItem.endAmount
                    ) {
                        // Apply derived amount to both start and end amount.
                        considerationItem.startAmount = endAmount;
                    } else {
                        // Apply fraction to consideration item start amount.
                        considerationItem.startAmount = _getFraction(
                            numerator,
                            denominator,
                            considerationItem.startAmount
                        );
                    }

                    // Update end amount in memory to match the derived amount.
                    considerationItem.endAmount = endAmount;

                    // Adjust consideration amount using current time; round up.
                    considerationItem.startAmount = (
                        _locateCurrentAmount(
                            considerationItem.startAmount,
                            considerationItem.endAmount,
                            elapsed,
                            remaining,
                            duration,
                            true // round up
                        )
                    );

                    // Utilize assembly to manually "shift" the recipient value.
                    assembly {
                        // Write recipient to endAmount, as endAmount is not
                        // used from this point on and can be repurposed to fit
                        // the layout of a ReceivedItem.
                        mstore(
                            add(considerationItem, 0x80), // endAmount
                            mload(add(considerationItem, 0xa0)) // recipient
                        )
                    }
                }
            }
        }

        // Apply criteria resolvers to each order as applicable.
        _applyCriteriaResolvers(advancedOrders, criteriaResolvers);

        // Determine the fulfiller (revertOnInvalid ? address(0) : msg.sender).
        address fulfiller;

        // Utilize assembly to operate on revertOnInvalid boolean as an integer.
        assembly {
            // Set the fulfiller to the caller if revertOnValid is false.
            fulfiller := mul(iszero(revertOnInvalid), caller())
        }

        // Emit an event for each order signifying that it has been fulfilled.
        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ++i) {
                // Do not emit an event if no order hash is present.
                if (orderHashes[i] == bytes32(0)) {
                    continue;
                }

                // Retrieve parameters for the order in question.
                OrderParameters memory orderParameters = (
                    advancedOrders[i].parameters
                );

                // Emit an OrderFulfilled event.
                _emitOrderFulfilledEvent(
                    orderHashes[i],
                    orderParameters.offerer,
                    orderParameters.zone,
                    fulfiller,
                    orderParameters.offer,
                    orderParameters.consideration
                );
            }
        }
    }

    /**
     * @dev Internal function to fulfill an arbitrary number of orders, either
     *      full or partial, after validating, adjusting amounts, and applying
     *      criteria resolvers.
     *
     * @param advancedOrders     The orders to match, including a fraction to
     *                           attempt to fill for each order.
     * @param fulfillments       An array of elements allocating offer
     *                           components to consideration components. Note
     *                           that the final amount of each consideration
     *                           component must be zero for a match operation to
     *                           be considered valid.
     *
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function _fulfillAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        Fulfillment[] calldata fulfillments
    )
        internal
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {
        // Allocate executions by fulfillment and apply them to each execution.
        Execution[] memory executions = new Execution[](fulfillments.length);

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Track number of filtered executions.
            uint256 totalFilteredExecutions = 0;

            // Iterate over each fulfillment.
            for (uint256 i = 0; i < fulfillments.length; ++i) {
                /// Retrieve the fulfillment in question.
                Fulfillment memory fulfillment = fulfillments[i];

                // Derive the execution corresponding with the fulfillment.
                Execution memory execution = _applyFulfillment(
                    advancedOrders,
                    fulfillment.offerComponents,
                    fulfillment.considerationComponents
                );

                // If offerer and recipient on the execution are the same...
                if (execution.item.recipient == execution.offerer) {
                    // increment total filtered executions.
                    totalFilteredExecutions += 1;
                } else {
                    // Otherwise, assign the execution to the executions array.
                    executions[i - totalFilteredExecutions] = execution;
                }
            }

            // If some number of executions have been filtered...
            if (totalFilteredExecutions != 0) {
                // reduce the total length of the executions array.
                assembly {
                    mstore(
                        executions,
                        sub(mload(executions), totalFilteredExecutions)
                    )
                }
            }
        }

        // Perform final checks and compress executions into standard and batch.
        (
            ,
            standardExecutions,
            batchExecutions
        ) = _performFinalChecksAndExecuteOrders(advancedOrders, executions);

        // Return both standard and batch ERC1155 executions.
        return (standardExecutions, batchExecutions);
    }

    /**
     * @dev Internal function to fulfill a group of validated orders, fully or
     *      partially, with an arbitrary number of items for offer and
     *      consideration per order and to execute transfers. Any order that is
     *      not currently active, has already been fully filled, or has been
     *      cancelled will be omitted. Remaining offer and consideration items
     *      will then be aggregated where possible as indicated by the supplied
     *      offer and consideration component arrays and aggregated items will
     *      be transferred to the fulfiller or to each intended recipient,
     *      respectively. Note that a failing item transfer or an issue with
     *      order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or the conduit if indicated by
     *                                  the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     *
     * @return availableOrders    An array of booleans indicating if each order
     *                            with an index corresponding to the index of
     *                            the returned boolean was fulfillable or not.
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function _fulfillAvailableOrders(
        AdvancedOrder[] memory advancedOrders,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        address fulfillerConduit
    )
        internal
        returns (
            bool[] memory availableOrders,
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {
        // Allocate an execution for each offer and consideration fulfillment.
        Execution[] memory executions = new Execution[](
            offerFulfillments.length + considerationFulfillments.length
        );

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Track number of filtered executions.
            uint256 totalFilteredExecutions = 0;

            // Iterate over each offer fulfillment.
            for (uint256 i = 0; i < offerFulfillments.length; ++i) {
                /// Retrieve the offer fulfillment components in question.
                FulfillmentComponent[] memory components = offerFulfillments[i];

                // Derive aggregated execution corresponding with fulfillment.
                Execution memory execution = _aggregateAvailable(
                    advancedOrders,
                    Side.OFFER,
                    components,
                    fulfillerConduit
                );

                // If offerer and recipient on the execution are the same...
                if (execution.item.recipient == execution.offerer) {
                    // increment total filtered executions.
                    totalFilteredExecutions += 1;
                } else {
                    // Otherwise, assign the execution to the executions array.
                    executions[i - totalFilteredExecutions] = execution;
                }
            }

            // Iterate over each consideration fulfillment.
            for (uint256 i = 0; i < considerationFulfillments.length; ++i) {
                /// Retrieve consideration fulfillment components in question.
                FulfillmentComponent[] memory components = (
                    considerationFulfillments[i]
                );

                // Derive aggregated execution corresponding with fulfillment.
                Execution memory execution = _aggregateAvailable(
                    advancedOrders,
                    Side.CONSIDERATION,
                    components,
                    fulfillerConduit
                );

                // If offerer and recipient on the execution are the same...
                if (execution.item.recipient == execution.offerer) {
                    // increment total filtered executions.
                    totalFilteredExecutions += 1;
                } else {
                    // Otherwise, assign the execution to the executions array.
                    executions[
                        i + offerFulfillments.length - totalFilteredExecutions
                    ] = execution;
                }
            }

            // If some number of executions have been filtered...
            if (totalFilteredExecutions != 0) {
                // reduce the total length of the executions array.
                assembly {
                    mstore(
                        executions,
                        sub(mload(executions), totalFilteredExecutions)
                    )
                }
            }
        }

        // Revert if no orders are available.
        if (executions.length == 0) {
            revert NoSpecifiedOrdersAvailable();
        }

        // Perform final checks, compress executions, and return.
        return _performFinalChecksAndExecuteOrders(advancedOrders, executions);
    }

    /**
     * @dev Internal function to perform a final check that each consideration
     *      item for an arbitrary number of fulfilled orders has been met and to
     *      compress and trigger associated execututions, transferring the
     *      respective items.
     *
     * @param advancedOrders     The orders to check and perform executions for.
     * @param executions         An array of uncompressed elements indicating
     *                           the sequence of transfers to perform when
     *                           fulfilling the given orders.
     *
     * @return availableOrders    An array of booleans indicating if each order
     *                            with an index corresponding to the index of
     *                            the returned boolean was fulfillable or not.
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            fulfilling the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            fulfilling the given orders.
     */
    function _performFinalChecksAndExecuteOrders(
        AdvancedOrder[] memory advancedOrders,
        Execution[] memory executions
    )
        internal
        returns (
            bool[] memory availableOrders,
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {
        // Retrieve the length of the advanced orders array and place on stack.
        uint256 totalOrders = advancedOrders.length;

        // Initialize array for tracking available orders.
        availableOrders = new bool[](totalOrders);

        // Skip overflow checks as all for loops are indexed starting at zero.
        unchecked {
            // Iterate over orders to ensure all considerations are met.
            for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the order in question.
                AdvancedOrder memory advancedOrder = advancedOrders[i];

                // Skip consideration item checks for order if not fulfilled.
                if (advancedOrder.numerator == 0) {
                    // Note: orders do not need to be marked as unavailable as a
                    // new memory region has been allocated. Review carefully if
                    // altering compiler version or managing memory manually.
                    continue;
                }

                // Mark the order as available.
                availableOrders[i] = true;

                // Retrieve consideration items to ensure they are fulfilled.
                ConsiderationItem[] memory consideration = (
                    advancedOrder.parameters.consideration
                );

                // Iterate over each consideration item to ensure it is met.
                for (uint256 j = 0; j < consideration.length; ++j) {
                    // Retrieve remaining amount on the consideration item.
                    uint256 unmetAmount = consideration[j].startAmount;

                    // Revert if the remaining amount is not zero.
                    if (unmetAmount != 0) {
                        revert ConsiderationNotMet(i, j, unmetAmount);
                    }
                }
            }
        }

        // Split executions into "standard" (no batch) and "batch" executions.
        (standardExecutions, batchExecutions) = _compressExecutions(executions);

        // Put ether value supplied by the caller on the stack.
        uint256 etherRemaining = msg.value;

        // Iterate over each standard execution.
        for (uint256 i = 0; i < standardExecutions.length; ) {
            // Retrieve the execution and the associated received item.
            Execution memory execution = standardExecutions[i];
            ReceivedItem memory item = execution.item;

            // If execution transfers native tokens, reduce value available.
            if (item.itemType == ItemType.NATIVE) {
                // Ensure that sufficient native tokens are still available.
                if (item.amount > etherRemaining) {
                    revert InsufficientEtherSupplied();
                }

                // Skip underflow check as amount is less than ether remaining.
                unchecked {
                    etherRemaining -= item.amount;
                }
            }

            // Transfer the item specified by the execution.
            _transfer(item, execution.offerer, execution.conduit);

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }

        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Iterate over each batch execution.
            for (uint256 i = 0; i < batchExecutions.length; ++i) {
                _batchTransferERC1155(batchExecutions[i]);
            }
        }

        // If any ether remains after fulfillments, return it to the caller.
        if (etherRemaining != 0) {
            _transferEth(payable(msg.sender), etherRemaining);
        }

        // Clear the reentrancy guard.
        _reentrancyGuard = _NOT_ENTERED;

        // Return arrays with available orders and triggered executions.
        return (availableOrders, standardExecutions, batchExecutions);
    }

    /**
     * @dev Internal function to transfer a given item.
     *
     * @param item    The item to transfer, including an amount and recipient.
     * @param offerer The account offering the item, i.e. the from address.
     * @param conduit An address indicating what conduit, if any, to source
     *                token approvals from. The null address signifies that no
     *                conduit should be used (and direct approvals set on
     *                Consideration) and `address(1)` signifies to utilize the
     *                legacy user proxy for the transfer.
     */
    function _transfer(
        ReceivedItem memory item,
        address offerer,
        address conduit
    ) internal {
        // If the item type indicates Ether or a native token...
        if (item.itemType == ItemType.NATIVE) {
            // transfer the native tokens to the recipient.
            _transferEth(item.recipient, item.amount);
        } else if (item.itemType == ItemType.ERC20) {
            // Transfer ERC20 tokens from the offerer to the recipient.
            _transferERC20(
                item.token,
                offerer,
                item.recipient,
                item.amount,
                conduit
            );
        } else if (item.itemType == ItemType.ERC721) {
            // Transfer ERC721 token from the offerer to the recipient.
            _transferERC721(
                item.token,
                offerer,
                item.recipient,
                item.identifier,
                item.amount,
                conduit
            );
        } else {
            // Transfer ERC1155 token from the offerer to the recipient.
            _transferERC1155(
                item.token,
                offerer,
                item.recipient,
                item.identifier,
                item.amount,
                conduit
            );
        }
    }

    /**
     * @dev Internal function to transfer Ether or other native tokens to a
     *      given recipient.
     *
     * @param to     The recipient of the transfer.
     * @param amount The amount to transfer.
     */
    function _transferEth(address payable to, uint256 amount) internal {
        // Ensure that the supplied amount is non-zero.
        _assertNonZeroAmount(amount);

        // Declare a variable indicating whether the call was successful or not.
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        // If the call fails...
        if (!success) {
            // Revert and pass the revert reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic error message.
            revert EtherTransferGenericFailure(to, amount);
        }
    }

    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a given recipient using a given conduit if applicable. Sufficient
     *      approvals must be set on this contract, the conduit, or the token
     *      transfer proxy in cases where the conduit is set to `address(1)`.
     *
     * @param token      The ERC20 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param amount     The amount to transfer.
     * @param conduit    An address indicating what conduit, if any, to source
     *                   token approvals from. The null address signifies that
     *                   no conduit should be used (and direct approvals set on
     *                   Consideration) and `address(1)` signifies to utilize
     *                   the legacy token transfer proxy for the transfer.
     */
    function _transferERC20(
        address token,
        address from,
        address to,
        uint256 amount,
        address conduit
    ) internal {
        // Ensure that the supplied amount is non-zero.
        _assertNonZeroAmount(amount);

        // If no conduit has been specified...
        if (conduit == address(0)) {
            // Perform the token transfer directly.
            _performDirectERC20Transfer(token, from, to, amount);
        } else if (conduit == address(1)) {
            // Perform transfer via a call to the legacy token transfer proxy.
            bool success = _LEGACY_TOKEN_TRANSFER_PROXY.transferFrom(
                token,
                from,
                to,
                amount
            );

            // If the call to the token transfer proxy does not return true...
            if (!success) {
                // Revert with an error indicating that return value is falsey.
                // Note that the legacy token transfer proxy does not support
                // non-compliant ERC20 tokens that do not return any data on a
                // successful transfer.
                revert BadReturnValueFromERC20OnTransfer(
                    token,
                    from,
                    to,
                    amount
                );
            }
        } else {
            revert("Not yet implemented");
        }
    }

    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a given recipient. Sufficient approvals must be set on this
     *      contract.
     *
     * @param token      The ERC20 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param amount     The amount to transfer.
     */
    function _performDirectERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        // Utilize assembly to perform an optimized ERC20 token transfer.
        assembly {
            // Write calldata to the free memory pointer, but restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write calldata into memory, starting with function selector.
            mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
            mstore(ERC20_transferFrom_from_ptr, from)
            mstore(ERC20_transferFrom_to_ptr, to)
            mstore(ERC20_transferFrom_amount_ptr, amount)

            // to copy up to 32 bytes of return data to scratch space.
            let callStatus := call(
                gas(),
                token,
                0,
                ERC20_transferFrom_sig_ptr,
                ERC20_transferFrom_length,
                0,
                0x20
            )

            let success := and(
                // Set success to whether the call reverted, if not check it
                // either returned exactly 1 (can't just be non-zero data), or
                // had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                callStatus
            )

            // If the transfer failed or it returned nothing:
            // Group these because they should be uncommon.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed:
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up:
                            if returndatasize() {
                                // Copy returndata to memory; overwrite existing
                                // memory.
                                returndatacopy(0, 0, returndatasize())

                                // Revert, specifying memory region with copied
                                // returndata.
                                revert(0, returndatasize())
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_signature
                            )
                            mstore(
                                TokenTransferGenericFailure_error_token_ptr,
                                token
                            )
                            mstore(
                                TokenTransferGenericFailure_error_from_ptr,
                                from
                            )
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(TokenTransferGenericFailure_error_id_ptr, 0)
                            mstore(
                                TokenTransferGenericFailure_error_amount_ptr,
                                amount
                            )
                            revert(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_length
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false.
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_signature
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_token_ptr,
                            token
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_from_ptr,
                            from
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_to_ptr,
                            to
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_amount_ptr,
                            amount
                        )
                        revert(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            TokenTransferGenericFailure_error_length
                        )
                    }

                    // Otherwise revert with error about token not having code:
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Otherwise the token just returned nothing but otherwise
                // succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @dev Internal function to transfer a single ERC721 token from a given
     *      originator to a given recipient. Sufficient approvals must be set,
     *      either on the respective conduit or on this contract itself.
     *
     * @param token      The ERC721 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The tokenId to transfer.
     * @param amount     The "amount" (this value must be equal to one).
     * @param conduit    An address indicating what conduit, if any, to source
     *                   token approvals from. The null address signifies that
     *                   no conduit should be used (and direct approvals set on
     *                   Consideration) and `address(1)` signifies to utilize
     *                   the legacy user proxy for the transfer.
     */
    function _transferERC721(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount,
        address conduit
    ) internal {
        // Ensure that exactly one 721 item is being transferred.
        if (amount != 1) {
            revert InvalidERC721TransferAmount();
        }

        // If no conduit has been specified...
        if (conduit == address(0)) {
            // Perform transfer via the token contract directly.
            assembly {
                // If the token has no code, revert.
                if iszero(extcodesize(token)) {
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Write calldata to the free memory pointer (restore it later).
                let memPointer := mload(FreeMemoryPointerSlot)

                // Write calldata into memory starting with function selector.
                mstore(
                    ERC721_transferFrom_sig_ptr,
                    ERC721_transferFrom_signature
                )
                mstore(ERC721_transferFrom_from_ptr, from)
                mstore(ERC721_transferFrom_to_ptr, to)
                mstore(ERC721_transferFrom_id_ptr, identifier)

                let success := call(
                    gas(),
                    token,
                    0,
                    ERC721_transferFrom_sig_ptr,
                    ERC721_transferFrom_length,
                    0,
                    0
                )

                // If the transfer reverted:
                if iszero(success) {
                    // If it returned a message, bubble it up:
                    if returndatasize() {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, specifying memory region with returndata.
                        revert(0, returndatasize())
                    }

                    // Otherwise revert with a generic error message.
                    mstore(
                        TokenTransferGenericFailure_error_sig_ptr,
                        TokenTransferGenericFailure_error_signature
                    )
                    mstore(TokenTransferGenericFailure_error_token_ptr, token)
                    mstore(TokenTransferGenericFailure_error_from_ptr, from)
                    mstore(TokenTransferGenericFailure_error_to_ptr, to)
                    mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                    mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                    revert(
                        TokenTransferGenericFailure_error_sig_ptr,
                        TokenTransferGenericFailure_error_length
                    )
                }

                // Restore the original free memory pointer.
                mstore(FreeMemoryPointerSlot, memPointer)

                // Restore the zero slot to zero.
                mstore(ZeroSlot, 0)
            }
        } else if (conduit == address(1)) {
            // Perform transfer via a call to the proxy for the supplied owner.
            bool success = _callProxy(
                from,
                token,
                abi.encodeCall(
                    ERC721Interface.transferFrom,
                    (from, to, identifier)
                )
            );

            // Ensure that the transfer succeeded.
            _assertValidTokenTransfer(
                success,
                token,
                from,
                to,
                identifier,
                amount
            );
        } else {
            revert("Not yet implemented");
        }
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given originator
     *      to a given recipient. Sufficient approvals must be set, either on
     *      the respective conduit or on this contract itself.
     *
     * @param token      The ERC1155 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The tokenId to transfer.
     * @param amount     The amount to transfer.
     * @param conduit    An address indicating what conduit, if any, to source
     *                   token approvals from. The null address signifies that
     *                   no conduit should be used (and direct approvals set on
     *                   Consideration) and `address(1)` signifies to utilize
     *                   the legacy user proxy for the transfer.
     */
    function _transferERC1155(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount,
        address conduit
    ) internal {
        // Ensure that the supplied amount is non-zero.
        _assertNonZeroAmount(amount);

        // If no conduit has been specified...
        if (conduit == address(0)) {
            // Perform transfer via the token contract directly.
            assembly {
                // If the token has no code, revert.
                if iszero(extcodesize(token)) {
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Write calldata to these slots below, but restore them later.
                let memPointer := mload(FreeMemoryPointerSlot)
                let slot0x80 := mload(0x80)
                let slot0xA0 := mload(0xA0)

                // Write calldata into memory, beginning with function selector.
                mstore(
                    ERC1155_safeTransferFrom_sig_ptr,
                    ERC1155_safeTransferFrom_signature
                )
                mstore(ERC1155_safeTransferFrom_from_ptr, from)
                mstore(ERC1155_safeTransferFrom_to_ptr, to)
                mstore(ERC1155_safeTransferFrom_id_ptr, identifier)
                mstore(ERC1155_safeTransferFrom_amount_ptr, amount)
                mstore(
                    ERC1155_safeTransferFrom_data_offset_ptr,
                    ERC1155_safeTransferFrom_data_length_offset
                )
                mstore(ERC1155_safeTransferFrom_data_length_ptr, 0)

                let success := call(
                    gas(),
                    token,
                    0,
                    ERC1155_safeTransferFrom_sig_ptr,
                    ERC1155_safeTransferFrom_length,
                    0,
                    0
                )

                // If the transfer reverted:
                if iszero(success) {
                    // If it returned a message, bubble it up:
                    if returndatasize() {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert; specify memory region with copied returndata.
                        revert(0, returndatasize())
                    }

                    // Otherwise revert with a generic error message.
                    mstore(
                        TokenTransferGenericFailure_error_sig_ptr,
                        TokenTransferGenericFailure_error_signature
                    )
                    mstore(TokenTransferGenericFailure_error_token_ptr, token)
                    mstore(TokenTransferGenericFailure_error_from_ptr, from)
                    mstore(TokenTransferGenericFailure_error_to_ptr, to)
                    mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                    mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                    revert(
                        TokenTransferGenericFailure_error_sig_ptr,
                        TokenTransferGenericFailure_error_length
                    )
                }

                mstore(0x80, slot0x80) // Restore slot 0x80.
                mstore(0xA0, slot0xA0) // Restore slot 0xA0.

                // Restore the original free memory pointer.
                mstore(FreeMemoryPointerSlot, memPointer)

                // Restore the zero slot to zero.
                mstore(ZeroSlot, 0)
            }
        } else if (conduit == address(1)) {
            // Perform transfer via a call to the proxy for the supplied owner.
            bool success = _callProxy(
                from,
                token,
                abi.encodeWithSelector(
                    ERC1155Interface.safeTransferFrom.selector,
                    from,
                    to,
                    identifier,
                    amount,
                    ""
                )
            );

            // Ensure that the transfer succeeded.
            _assertValidTokenTransfer(
                success,
                token,
                from,
                to,
                identifier,
                amount
            );
        } else {
            revert("Not yet implemented");
        }
    }

    /**
     * @dev Internal function to transfer a batch of ERC1155 tokens from a given
     *      originator to a given recipient. Sufficient approvals must be set,
     *      either on the respective conduit or on this contract itself.
     *
     * @param batchExecution The batch of 1155 tokens to be transferred.
     */
    function _batchTransferERC1155(BatchExecution memory batchExecution)
        internal
    {
        // Place elements of the batch execution in memory onto the stack.
        address conduit = batchExecution.conduit;
        address token = batchExecution.token;
        address from = batchExecution.from;
        address to = batchExecution.to;

        // Retrieve the tokenIds and amounts.
        uint256[] memory tokenIds = batchExecution.tokenIds;
        uint256[] memory amounts = batchExecution.amounts;

        bool success;

        // If no conduit has been specified...
        if (conduit == address(0)) {
            // Perform transfer via the token contract directly.
            (success, ) = token.call(
                abi.encodeWithSelector(
                    ERC1155Interface.safeBatchTransferFrom.selector,
                    from,
                    to,
                    tokenIds,
                    amounts,
                    ""
                )
            );
        } else if (conduit == address(1)) {
            // Perform transfer via a call to the proxy for the supplied owner.
            success = _callProxy(
                from,
                token,
                abi.encodeWithSelector(
                    ERC1155Interface.safeBatchTransferFrom.selector,
                    from,
                    to,
                    tokenIds,
                    amounts,
                    ""
                )
            );
        } else {
            revert("Not yet implemented");
        }

        // If the call fails...
        if (!success) {
            // Revert and pass the revert reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with a generic 1155 batch transfer error.
            revert ERC1155BatchTransferGenericFailure(
                token,
                from,
                to,
                tokenIds,
                amounts
            );
        }

        // Ensure that a contract is deployed to the token address.
        _assertContractIsDeployed(token);
    }

    /**
     * @dev Internal function to trigger a call to a proxy contract. The proxy
     *      contract must be registered on the legacy proxy registry for the
     *      given proxy owner and must declare that its implementation matches
     *      the required proxy implementation in accordance with EIP-897.
     *
     * @param proxyOwner The original owner of the proxy in question. Note that
     *                   this owner may have been modified since the proxy was
     *                   originally deployed.
     * @param target     The account that should be called by the proxy.
     * @param callData   The calldata to supply when calling the target from the
     *                   proxy.
     *
     * @return success The status of the call to the proxy.
     */
    function _callProxy(
        address proxyOwner,
        address target,
        bytes memory callData
    ) internal returns (bool success) {
        // Retrieve the user proxy from the registry assuming one is set.
        address proxy = _LEGACY_PROXY_REGISTRY.proxies(proxyOwner);

        // Assert that the user proxy has the correct implementation.
        if (
            ProxyInterface(proxy).implementation() !=
            _REQUIRED_PROXY_IMPLEMENTATION
        ) {
            revert InvalidProxyImplementation();
        }

        // perform call to proxy via proxyAssert and HowToCall = CALL (value 0).
        (success, ) = proxy.call(
            abi.encodeWithSelector(
                ProxyInterface.proxyAssert.selector,
                target,
                0,
                callData
            )
        );
    }

    /**
     * @dev Internal function to transfer Ether (or other native tokens) to a
     *      given recipient as part of basic order fulfillment. Note that
     *      proxies are not utilized for native tokens as the transferred amount
     *      must be provided as msg.value.
     *
     * @param amount      The amount to transfer.
     * @param parameters  The parameters of the basic order in question.
     */
    function _transferEthAndFinalize(
        uint256 amount,
        BasicOrderParameters calldata parameters
    ) internal {
        // Put ether value supplied by the caller on the stack.
        uint256 etherRemaining = msg.value;

        // Iterate over each additional recipient.
        for (uint256 i = 0; i < parameters.additionalRecipients.length; ) {
            // Retrieve the additional recipient.
            AdditionalRecipient calldata additionalRecipient = (
                parameters.additionalRecipients[i]
            );

            // Read ether amount to transfer to recipient and place on stack.
            uint256 additionalRecipientAmount = additionalRecipient.amount;

            // Ensure that sufficient Ether is available.
            if (additionalRecipientAmount > etherRemaining) {
                revert InsufficientEtherSupplied();
            }

            // Transfer Ether to the additional recipient.
            _transferEth(
                additionalRecipient.recipient,
                additionalRecipientAmount
            );

            // Skip underflow check as subtracted value is less than remaining.
            unchecked {
                // Reduce ether value available.
                etherRemaining -= additionalRecipientAmount;
            }

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }

        // Ensure that sufficient Ether is still available.
        if (amount > etherRemaining) {
            revert InsufficientEtherSupplied();
        }

        // Transfer Ether to the offerer.
        _transferEth(parameters.offerer, amount);

        // If any Ether remains after transfers, return it to the caller.
        if (etherRemaining > amount) {
            // Skip underflow check as etherRemaining > amount.
            unchecked {
                // Transfer remaining Ether to the caller.
                _transferEth(payable(msg.sender), etherRemaining - amount);
            }
        }

        // Clear the reentrancy guard.
        _reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal function to transfer ERC20 tokens to a given recipient as
     *      part of basic order fulfillment. Note that proxies are not utilized
     *      for ERC20 tokens.
     *
     * @param from        The originator of the ERC20 token transfer.
     * @param to          The recipient of the ERC20 token transfer.
     * @param erc20Token  The ERC20 token to transfer.
     * @param amount      The amount of ERC20 tokens to transfer.
     * @param parameters  The parameters of the order.
     * @param fromOfferer Whether to decrement amount from the offered amount.
     */
    function _transferERC20AndFinalize(
        address from,
        address to,
        address erc20Token,
        uint256 amount,
        BasicOrderParameters calldata parameters,
        bool fromOfferer
    ) internal {
        // Determine the appropriate conduit to utilize.
        address conduit = fromOfferer
            ? parameters.offererConduit
            : parameters.fulfillerConduit;

        // Iterate over each additional recipient.
        for (uint256 i = 0; i < parameters.additionalRecipients.length; ) {
            // Retrieve the additional recipient.
            AdditionalRecipient calldata additionalRecipient = (
                parameters.additionalRecipients[i]
            );

            // Decrement the amount to transfer to fulfiller if indicated.
            if (fromOfferer) {
                amount -= additionalRecipient.amount;
            }

            // Transfer ERC20 tokens to additional recipient given approval.
            _transferERC20(
                erc20Token,
                from,
                additionalRecipient.recipient,
                additionalRecipient.amount,
                conduit
            );

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }

        // Transfer ERC20 token amount (from account must have proper approval).
        _transferERC20(erc20Token, from, to, amount, conduit);

        // Clear the reentrancy guard.
        _reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal function to ensure that the sentinel value for the
     *      reentrancy guard is not currently set and, if not, to set the
     *      sentinel value for the reentrancy guard.
     */
    function _setReentrancyGuard() internal {
        // Ensure that the reentrancy guard is not already set.
        _assertNonReentrant();

        // Set the reentrancy guard.
        _reentrancyGuard = _ENTERED;
    }

    /**
     * @dev Internal function to emit an OrderFulfilled event. OfferItems are
     *      translated into SpentItems and ConsiderationItems are translated
     *      into ReceivedItems.
     *
     * @param orderHash     The order hash.
     * @param offerer       The offerer for the order.
     * @param zone          The zone for the order.
     * @param fulfiller     The fulfiller of the order, or the null address if
     *                      the order was fulfilled via order matching.
     * @param offer         The offer items for the order.
     * @param consideration The consideration items for the order.
     */
    function _emitOrderFulfilledEvent(
        bytes32 orderHash,
        address offerer,
        address zone,
        address fulfiller,
        OfferItem[] memory offer,
        ConsiderationItem[] memory consideration
    ) internal {
        // Cast already-modified offer memory region as spent items.
        SpentItem[] memory spentItems;
        assembly {
            spentItems := offer
        }

        // Cast already-modified consideration memory region as received items.
        ReceivedItem[] memory receivedItems;
        assembly {
            receivedItems := consideration
        }

        // Emit an event signifying that the order has been fulfilled.
        emit OrderFulfilled(
            orderHash,
            offerer,
            zone,
            fulfiller,
            spentItems,
            receivedItems
        );
    }
}


// prettier-ignore
    ConsiderationInterface
} from "./interfaces/ConsiderationInterface.sol";

// prettier-ignore
    OrderType,
    ItemType,
    BasicOrderRouteType
} from "./lib/ConsiderationEnums.sol";

// prettier-ignore
    BasicOrderParameters,
    OfferItem,
    ConsiderationItem,
    OrderParameters,
    OrderComponents,
    Fulfillment,
    FulfillmentComponent,
    Execution,
    Order,
    AdvancedOrder,
    OrderStatus,
    CriteriaResolver,
    BatchExecution
} from "./lib/ConsiderationStructs.sol";


/**
 * @title Consideration
 * @author 0age
 * @custom:coauthor d1ll0n
 * @custom:coauthor transmissions11
 * @custom:version rc-1
 * @notice Consideration is a generalized ETH/ERC20/ERC721/ERC1155 marketplace.
 *         It minimizes external calls to the greatest extent possible and
 *         provides lightweight methods for common routes as well as more
 *         flexible methods for composing advanced orders or groups of orders.
 *         Each order contains an arbitrary number of items that may be spent
 *         (the "offer") along with an arbitrary number of items that must be
 *         received back by the indicated recipients (the "consideration").
 */
contract Consideration is ConsiderationInterface, ConsiderationInternal {
    /**
     * @notice Derive and set hashes, reference chainId, and associated domain
     *         separator during deployment.
     *
     * @param legacyProxyRegistry         A proxy registry that stores per-user
     *                                    proxies that may optionally be used to
     *                                    transfer approved ERC721+1155 tokens.
     * @param legacyTokenTransferProxy    A shared proxy contract that may
     *                                    optionally be used to transfer
     *                                    approved ERC20 tokens.
     * @param requiredProxyImplementation The implementation that must be set on
     *                                    each proxy in order to utilize it.
     */
    constructor(
        address legacyProxyRegistry,
        address legacyTokenTransferProxy,
        address requiredProxyImplementation
    )
        ConsiderationInternal(
            legacyProxyRegistry,
            legacyTokenTransferProxy,
            requiredProxyImplementation
        )
    {}

    /**
     * @notice Fulfill an order offering an ERC20, ERC721, or ERC1155 item by
     *         supplying Ether (or other native tokens), ERC20 tokens, an ERC721
     *         item, or an ERC1155 item as consideration. Six permutations are
     *         supported: Native token to ERC721, Native token to ERC1155, ERC20
     *         to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and ERC1155 to
     *         ERC20 (with native tokens supplied as msg.value). For an order to
     *         be eligible for fulfillment via this method, it must contain a
     *         single offer item (though that item may have a greater amount if
     *         the item is not an ERC721). An arbitrary number of "additional
     *         recipients" may also be supplied which will each receive native
     *         tokens or ERC20 items from the fulfiller as consideration. Refer
     *         to the documentation for a more comprehensive summary of how to
     *         utilize with this method and what orders are compatible with it.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` in order to receive those
     *                   items.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        override
        returns (bool)
    {
        // Declare enums for order type & route to extract from basicOrderType.
        BasicOrderRouteType route;
        OrderType orderType;

        // Declare additional recipient item type to derive from the route type.
        ItemType additionalRecipientsItemType;

        // Utilize assembly to extract the order type and the basic order route.
        assembly {
            // Mask all but 2 least-significant bits to derive the order type.
            orderType := and(calldataload(0x124), 3)

            // Divide basicOrderType by four to derive the route.
            route := div(calldataload(0x124), 4)

            // If route > 1 additionalRecipient items are ERC20 (1) else Eth (0)
            additionalRecipientsItemType := gt(route, 1)
        }

        {
            // Declare temporary variable for enforcing payable status.
            bool correctPayableStatus;

            // Utilize assembly to compare the route to the callvalue.
            assembly {
                // route 0 and 1 are payable, otherwise route is not payable.
                correctPayableStatus := eq(
                    additionalRecipientsItemType,
                    iszero(callvalue())
                )
            }

            // Revert if msg.value has not been supplied as part of payable
            // routes or has been supplied as part of non-payable routes.
            if (!correctPayableStatus) {
                revert InvalidMsgValue(msg.value);
            }
        }

        // Declare more arguments that will be derived from route and calldata.
        address additionalRecipientsToken;
        ItemType receivedItemType;
        ItemType offeredItemType;

        // Utilize assembly to retrieve function arguments and cast types.
        assembly {
            // Determine if offered item type == additional recipient item type.
            let offerTypeIsAdditionalRecipientsType := gt(route, 3)

            // If route > 3 additionalRecipientsToken is at 0xc4 else 0x24
            additionalRecipientsToken := calldataload(
                add(0x24, mul(0xa0, offerTypeIsAdditionalRecipientsType))
            )

            // If route > 2, receivedItemType is route - 2. If route is 2, then
            // receivedItemType is ERC20 (1). Otherwise, it is Eth (0).
            receivedItemType := add(
                mul(sub(route, 2), gt(route, 2)),
                eq(route, 2)
            )

            // If route > 3, offeredItemType is ERC20 (1). If route is 2 or 3,
            // offeredItemType = route. If route is 0 or 1, it is route + 2.
            offeredItemType := sub(
                add(route, mul(iszero(additionalRecipientsItemType), 2)),
                mul(
                    offerTypeIsAdditionalRecipientsType,
                    add(receivedItemType, 1)
                )
            )
        }

        // Derive & validate order using parameters and update order status.
        _prepareBasicFulfillmentFromCalldata(
            parameters,
            orderType,
            receivedItemType,
            additionalRecipientsItemType,
            additionalRecipientsToken,
            offeredItemType
        );

        // Read offerer from calldata and place on the stack.
        address payable offerer = parameters.offerer;

        // Declare conduit argument used by transfer functions.
        address conduit;

        // Utilize assembly to derive conduit (if relevant) based on route.
        assembly {
            // use offerer conduit for routes 0-3, fulfiller conduit otherwise.
            conduit := calldataload(add(0x1c4, mul(gt(route, 3), 0x20)))
        }

        // Transfer tokens based on the route.
        if (route == BasicOrderRouteType.ETH_TO_ERC721) {
            // Transfer ERC721 to caller using offerer's conduit if applicable.
            _transferERC721(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );

            // Transfer native to recipients, return excess to caller & wrap up.
            _transferEthAndFinalize(parameters.considerationAmount, parameters);
        } else if (route == BasicOrderRouteType.ETH_TO_ERC1155) {
            // Transfer ERC1155 to caller using offerer's conduit if applicable.
            _transferERC1155(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );

            // Transfer native to recipients, return excess to caller & wrap up.
            _transferEthAndFinalize(parameters.considerationAmount, parameters);
        } else if (route == BasicOrderRouteType.ERC20_TO_ERC721) {
            // Transfer ERC721 to caller using offerer's conduit if applicable.
            _transferERC721(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );

            // Transfer ERC20 tokens to all recipients and wrap up.
            _transferERC20AndFinalize(
                msg.sender,
                offerer,
                parameters.considerationToken,
                parameters.considerationAmount,
                parameters,
                false // Send full amount indicated by all consideration items.
            );
        } else if (route == BasicOrderRouteType.ERC20_TO_ERC1155) {
            // Transfer ERC1155 to caller using offerer's conduit if applicable.
            _transferERC1155(
                parameters.offerToken,
                offerer,
                msg.sender,
                parameters.offerIdentifier,
                parameters.offerAmount,
                conduit
            );

            // Transfer ERC20 tokens to all recipients and wrap up.
            _transferERC20AndFinalize(
                msg.sender,
                offerer,
                parameters.considerationToken,
                parameters.considerationAmount,
                parameters,
                false // Send full amount indicated by all consideration items.
            );
        } else if (route == BasicOrderRouteType.ERC721_TO_ERC20) {
            // Transfer ERC721 to offerer using caller's conduit if applicable.
            _transferERC721(
                parameters.considerationToken,
                msg.sender,
                offerer,
                parameters.considerationIdentifier,
                parameters.considerationAmount,
                conduit
            );

            // Transfer ERC20 tokens to all recipients and wrap up.
            _transferERC20AndFinalize(
                offerer,
                msg.sender,
                parameters.offerToken,
                parameters.offerAmount,
                parameters,
                true // Reduce amount sent to fulfiller by additional amounts.
            );
        } else {
            // route == BasicOrderRouteType.ERC1155_TO_ERC20

            // Transfer ERC1155 to offerer using caller's conduit if applicable.
            _transferERC1155(
                parameters.considerationToken,
                msg.sender,
                offerer,
                parameters.considerationIdentifier,
                parameters.considerationAmount,
                conduit
            );

            // Transfer ERC20 tokens to all recipients and wrap up.
            _transferERC20AndFinalize(
                offerer,
                msg.sender,
                parameters.offerToken,
                parameters.offerAmount,
                parameters,
                true // Reduce amount sent to fulfiller by additional amounts.
            );
        }

        return true;
    }

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @param order            The order to fulfill. Note that both the offerer
     *                         and the fulfiller must first approve this
     *                         contract (or the supplied conduit if indicated)
     *                         to transfer any relevant tokens on their behalf
     *                         and that contracts must implement
     *                         `onERC1155Received` in order to receive ERC1155
     *                         tokens as consideration.
     * @param fulfillerConduit An address indicating what conduit, if any, to
     *                         source the fulfiller's token approvals from. The
     *                         null address signifies that no conduit should be
     *                         used (and direct approvals set on Consideration)
     *                         and `address(1)` signifies to utilize the legacy
     *                         user proxy for the fulfiller.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    function fulfillOrder(Order calldata order, address fulfillerConduit)
        external
        payable
        override
        returns (bool)
    {
        // Convert order to "advanced" order, then validate and fulfill it.
        // prettier-ignore
        return _validateAndFulfillAdvancedOrder(
            _convertOrderToAdvanced(order),
            new CriteriaResolver[](0), // No criteria resolvers supplied.
            fulfillerConduit
        );
    }

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder     The order to fulfill along with the fraction of
     *                          the order to attempt to fill. Note that both the
     *                          offerer and the fulfiller must first approve
     *                          this contract (or their proxy if indicated by
     *                          the order) to transfer any relevant tokens on
     *                          their behalf and that contracts must implement
     *                          `onERC1155Received` in order to receive ERC1155
     *                          tokens as consideration. Also note that all
     *                          offer and consideration components must have no
     *                          remainder after multiplication of the respective
     *                          amount with the supplied fraction in order for
     *                          the partial fill to be considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific offer or consideration, a token
     *                          identifier, and a proof that the supplied token
     *                          identifier is contained in the merkle root held
     *                          by the item in question's criteria element. Note
     *                          that an empty criteria indicates that any
     *                          (transferrable) token identifier on the token in
     *                          question is valid and that no associated proof
     *                          needs to be supplied.
     * @param fulfillerConduit  An address indicating what conduit, if any, to
     *                          source the fulfiller's token approvals from. The
     *                          null address signifies that no conduit should be
     *                          used (and direct approvals set on Consideration)
     *                          and `address(1)` signifies to utilize the legacy
     *                          user proxy for the fulfiller.
     *
     * @return A boolean indicating whether the order has been fulfilled.
     */
    //  SWC-Integer Overflow and Underflow: L387 - L399
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        address fulfillerConduit
    ) external payable override returns (bool) {
        // Validate and fulfill the order.
        return
            _validateAndFulfillAdvancedOrder(
                advancedOrder,
                criteriaResolvers,
                fulfillerConduit
            );
    }

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or their proxy if indicated by
     *                                  the order) to transfer any relevant
     *                                  tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` in order to receive
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferrable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduit          An address indicating what conduit, if
     *                                  any, to source the fulfiller's token
     *                                  approvals from. The null address
     *                                  signifies that no conduit should be used
     *                                  (with direct token approvals set on
     *                                  Consideration) and `address(1)`
     *                                  signifies to utilize the legacy user
     *                                  proxy for the fulfiller.
     *
     * @return availableOrders    An array of booleans indicating if each order
     *                            with an index corresponding to the index of
     *                            the returned boolean was fulfillable or not.
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        address fulfillerConduit
    )
        external
        payable
        override
        returns (
            bool[] memory availableOrders,
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {
        // Validate orders, apply amounts, & determine if they utilize conduits.
        _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            false // Signifies that invalid orders should NOT revert.
        );

        // Aggregate used offer and consideration items and execute transfers.
        (
            availableOrders,
            standardExecutions,
            batchExecutions
        ) = _fulfillAvailableOrders(
            advancedOrders,
            offerFulfillments,
            considerationFulfillments,
            fulfillerConduit
        );

        // Return order fulfillment details and executions.
        return (availableOrders, standardExecutions, batchExecutions);
    }

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with a set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported).
     *
     * @param orders            The orders to match. Note that both the offerer
     *                          and fulfiller on each order must first approve
     *                          this contract (or their proxy if indicated by
     *                          the order) to transfer any relevant tokens on
     *                          their behalf and each consideration recipient
     *                          must implement `onERC1155Received` in order to
     *                          receive ERC1155 tokens.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {
        // Convert orders to "advanced" orders.
        AdvancedOrder[] memory advancedOrders = _convertOrdersToAdvanced(
            orders
        );

        // Validate orders, apply amounts, & determine if they utilize proxies.
        _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            new CriteriaResolver[](0), // No criteria resolvers supplied.
            true // Signifies that invalid orders should revert.
        );

        // Fulfill the orders using the supplied fulfillments.
        return _fulfillAdvancedOrders(advancedOrders, fulfillments);
    }

    /**
     * @notice Match an arbitrary number of full or partial orders, each with an
     *         arbitrary number of items for offer and consideration, supplying
     *         criteria resolvers containing specific token identifiers and
     *         associated proofs as well as fulfillments allocating offer
     *         components to consideration components.
     *
     * @param advancedOrders    The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or their proxy if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order toreceive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferrable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     *
     * @return standardExecutions An array of elements indicating the sequence
     *                            of non-batch transfers performed as part of
     *                            matching the given orders.
     * @return batchExecutions    An array of elements indicating the sequence
     *                            of batch transfers performed as part of
     *                            matching the given orders.
     */
    function matchAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        Fulfillment[] calldata fulfillments
    )
        external
        payable
        override
        returns (
            Execution[] memory standardExecutions,
            BatchExecution[] memory batchExecutions
        )
    {
        // Validate orders, apply amounts, & determine if they utilize conduits.
        _validateOrdersAndPrepareToFulfill(
            advancedOrders,
            criteriaResolvers,
            true // Signifies that invalid orders should revert.
        );

        // Fulfill the orders using the supplied fulfillments.
        return _fulfillAdvancedOrders(advancedOrders, fulfillments);
    }

    /**
     * @notice Cancel an arbitrary number of orders. Note that only the offerer
     * or the zone of a given order may cancel it.
     *
     * @param orders The orders to cancel.
     *
     * @return A boolean indicating whether the supplied orders were
     *         successfully cancelled.
     */
    function cancel(OrderComponents[] calldata orders)
        external
        override
        returns (bool)
    {
        // Ensure that the reentrancy guard is not currently set.
        _assertNonReentrant();

        address offerer;
        address zone;

        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Read length of the orders array from memory and place on stack.
            uint256 totalOrders = orders.length;

            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ) {
                // Retrieve the order.
                OrderComponents calldata order = orders[i];

                offerer = order.offerer;
                zone = order.zone;

                // Ensure caller is either offerer or zone of the order.
                if (msg.sender != offerer && msg.sender != zone) {
                    revert InvalidCanceller();
                }

                // Derive order hash using the order parameters and the nonce.
                bytes32 orderHash = _getOrderHash(
                    OrderParameters(
                        offerer,
                        zone,
                        order.offer,
                        order.consideration,
                        order.orderType,
                        order.startTime,
                        order.endTime,
                        order.zoneHash,
                        order.salt,
                        order.conduit,
                        order.consideration.length
                    ),
                    order.nonce
                );

                // Update the order status as not valid and cancelled.
                _orderStatus[orderHash].isValidated = false;
                _orderStatus[orderHash].isCancelled = true;

                // Emit an event signifying that the order has been cancelled.
                emit OrderCancelled(orderHash, offerer, zone);

                // Increment counter inside body of loop for gas efficiency.
                ++i;
            }
        }

        return true;
    }

    /**
     * @notice Validate an arbitrary number of orders, thereby registering them
     *         as valid and allowing the fulfiller to skip verification. Note
     *         that anyone can validate a signed order but only the offerer can
     *         validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return A boolean indicating whether the supplied orders were
     *         successfully validated.
     */
    function validate(Order[] calldata orders)
        external
        override
        returns (bool)
    {
        // Ensure that the reentrancy guard is not currently set.
        _assertNonReentrant();

        // Declare variables outside of the loop.
        bytes32 orderHash;
        address offerer;

        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Read length of the orders array from memory and place on stack.
            uint256 totalOrders = orders.length;

            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ) {
                // Retrieve the order.
                Order calldata order = orders[i];

                // Retrieve the order parameters.
                OrderParameters calldata orderParameters = order.parameters;

                // Move offerer from memory to the stack.
                offerer = orderParameters.offerer;

                // Get current nonce and use it w/ params to derive order hash.
                orderHash = _assertConsiderationLengthAndGetNoncedOrderHash(
                    orderParameters
                );

                // Retrieve the order status using the derived order hash.
                OrderStatus memory orderStatus = _orderStatus[orderHash];

                // Ensure order is fillable and retrieve the filled amount.
                _verifyOrderStatus(
                    orderHash,
                    orderStatus,
                    false, // Signifies that partially filled orders are valid.
                    true // Signifies to revert if the order is invalid.
                );

                // If the order has not already been validated...
                if (!orderStatus.isValidated) {
                    // Verify the supplied signature.
                    _verifySignature(offerer, orderHash, order.signature);

                    // Update order status to mark the order as valid.
                    _orderStatus[orderHash].isValidated = true;

                    // Emit an event signifying the order has been validated.
                    emit OrderValidated(
                        orderHash,
                        offerer,
                        orderParameters.zone
                    );
                }

                // Increment counter inside body of the loop for gas efficiency.
                ++i;
            }
        }

        return true;
    }

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a nonce. Note that only the offerer may increment
     *         the nonce.
     *
     * @return newNonce The new nonce.
     */
    function incrementNonce() external override returns (uint256 newNonce) {
        // Ensure that the reentrancy guard is not currently set.
        _assertNonReentrant();

        // No need to check for overflow; nonce cannot be incremented that far.
        unchecked {
            // Increment current nonce for the supplied offerer.
            newNonce = ++_nonces[msg.sender];
        }

        // Emit an event containing the new nonce.
        emit NonceIncremented(newNonce, msg.sender);
    }

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @param order The components of the order.
     *
     * @return The order hash.
     */
    function getOrderHash(OrderComponents memory order)
        external
        view
        override
        returns (bytes32)
    {
        // Derive order hash by supplying order parameters along with the nonce.
        // prettier-ignore
        return _getOrderHash(
            OrderParameters(
                order.offerer,
                order.zone,
                order.offer,
                order.consideration,
                order.orderType,
                order.startTime,
                order.endTime,
                order.zoneHash,
                order.salt,
                order.conduit,
                order.consideration.length
            ),
            order.nonce
        );
    }

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        override
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        )
    {
        // Retrieve the order status using the order hash.
        OrderStatus memory orderStatus = _orderStatus[orderHash];

        // Return the fields on the order status.
        return (
            orderStatus.isValidated,
            orderStatus.isCancelled,
            orderStatus.numerator,
            orderStatus.denominator
        );
    }

    /**
     * @notice Retrieve the current nonce for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return The current nonce.
     */
    function getNonce(address offerer)
        external
        view
        override
        returns (uint256)
    {
        // Return the nonce for the supplied offerer.
        return _nonces[offerer];
    }

    /**
     * @notice Retrieve the domain separator, used for signing and verifying
     * signed orders via EIP-712.
     *
     * @return The domain separator.
     */
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        // Get domain separator, either precomputed or derived based on chainId.
        return _domainSeparator();
    }

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return The name of this contract.
     */
    function name() external pure override returns (string memory) {
        // Return the name of the contract.
        return _NAME;
    }

    /**
     * @notice Retrieve the version of this contract.
     *
     * @return The version of this contract.
     */
    function version() external pure override returns (string memory) {
        // Return the version.
        return _VERSION;
    }
}
