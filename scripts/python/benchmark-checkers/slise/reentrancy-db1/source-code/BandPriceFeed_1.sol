// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}


interface IPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getPrice(uint256 interval) external view returns (uint256);
}

pragma experimental ABIEncoderV2;

// Copy from https://docs.bandchain.org/band-standard-dataset/using-band-dataset/using-band-dataset-evm.html
interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote) external view returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}



contract BandPriceFeed is IPriceFeed, BlockContext {
    using Address for address;

    //
    // STRUCT
    //
    struct Observation {
        uint256 price;
        uint256 priceCumulative;
        uint256 timestamp;
    }

    //
    // EVENT
    //

    event PriceUpdated(string indexed baseAsset, uint256 price, uint256 timestamp, uint8 indexAt);

    //
    // STATE
    //
    string public constant QUOTE_ASSET = "USD";

    string public baseAsset;
    // let's use 15 mins and 1 hr twap as example
    // if the price is being updated 15 secs, then needs 60 and 240 historical data for 15mins and 1hr twap.
    Observation[256] public observations;

    IStdReference public stdRef;
    uint8 public currentObservationIndex;

    //
    // EXTERNAL NON-VIEW
    //

    constructor(IStdReference stdRefArg, string memory baseAssetArg) {
        // BPF_ANC: Reference address is not contract
        require(address(stdRefArg).isContract(), "BPF_ANC");

        stdRef = stdRefArg;
        baseAsset = baseAssetArg;
    }

    /// @dev anyone can help update it.
    function update() external {
        IStdReference.ReferenceData memory bandData = getReferenceData();

        // for the first time update
        if (currentObservationIndex == 0 && observations[0].timestamp == 0) {
            observations[0] = Observation({
                price: bandData.rate,
                priceCumulative: 0,
                timestamp: bandData.lastUpdatedBase
            });
            emit PriceUpdated(baseAsset, bandData.rate, bandData.lastUpdatedBase, 0);
            return;
        }

        // BPF_IT: invalid timestamp
        Observation memory lastObservation = observations[currentObservationIndex];
        require(bandData.lastUpdatedBase > lastObservation.timestamp, "BPF_IT");

        // overflow of currentObservationIndex is desired since currentObservationIndex is uint8 (0 - 255),
        // so 255 + 1 will be 0
        currentObservationIndex++;

    // SWC-Integer Overflow and Underflow: L77 - L82
        uint256 elapsedTime = bandData.lastUpdatedBase - lastObservation.timestamp;
        observations[currentObservationIndex] = Observation({
            priceCumulative: lastObservation.priceCumulative + (lastObservation.price * elapsedTime),
            timestamp: bandData.lastUpdatedBase,
            price: bandData.rate
        });

        emit PriceUpdated(baseAsset, bandData.rate, bandData.lastUpdatedBase, currentObservationIndex);
    }

    //
    // EXTERNAL VIEW
    //

    function getPrice(uint256 interval) public view override returns (uint256) {
        Observation memory lastestObservation = observations[currentObservationIndex];
        if (lastestObservation.price == 0) {
            // BPF_ND: no data
            revert("BPF_ND");
        }

        IStdReference.ReferenceData memory latestBandData = getReferenceData();
        if (interval == 0) {
            return latestBandData.rate;
        }

        uint256 currentTimestamp = _blockTimestamp();
        uint256 targetTimestamp = currentTimestamp - interval;
        (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(targetTimestamp);
        uint256 currentPriceCumulative =
            lastestObservation.priceCumulative +
                (lastestObservation.price * (latestBandData.lastUpdatedBase - lastestObservation.timestamp)) +
                (latestBandData.rate * (currentTimestamp - latestBandData.lastUpdatedBase));

        //
        //                   beforeOrAt                    atOrAfter
        //      ------------------+-------------+---------------+------------------
        //                <-------|             |               |
        // case 1       targetTimestamp         |               |------->
        // case 2                               |              targetTimestamp
        // case 3                          targetTimestamp
        //
        uint256 targetPriceCumulative;
        // case1. not enough historical data or just enough (`==` case)
        if (targetTimestamp <= beforeOrAt.timestamp) {
            targetTimestamp = beforeOrAt.timestamp;
            targetPriceCumulative = beforeOrAt.priceCumulative;
        }
        // case2. the latest data is older than or equal the request
        else if (atOrAfter.timestamp <= targetTimestamp) {
            targetTimestamp = atOrAfter.timestamp;
            targetPriceCumulative = atOrAfter.priceCumulative;
        }
        // case3. in the middle
        else {
            uint256 observationTimeDelta = atOrAfter.timestamp - beforeOrAt.timestamp;
            uint256 targetTimeDelta = targetTimestamp - beforeOrAt.timestamp;
            targetPriceCumulative =
                beforeOrAt.priceCumulative +
                ((atOrAfter.priceCumulative - beforeOrAt.priceCumulative) * targetTimeDelta) /
                observationTimeDelta;
        }

        return (currentPriceCumulative - targetPriceCumulative) / (currentTimestamp - targetTimestamp);
    }

    //
    // EXTERNAL PURE
    //

    function decimals() external pure override returns (uint8) {
        // We assume Band Protocol always has 18 decimals
        // https://docs.bandchain.org/band-standard-dataset/using-band-dataset/using-band-dataset-evm.html
        return 18;
    }

    //
    // INTERNAL VIEW
    //

    function getReferenceData() internal view returns (IStdReference.ReferenceData memory) {
        IStdReference.ReferenceData memory bandData = stdRef.getReferenceData(baseAsset, QUOTE_ASSET);
        // BPF_TQZ: timestamp for quote is zero
        require(bandData.lastUpdatedQuote > 0, "BPF_TQZ");
        // BPF_TBZ: timestamp for base is zero
        require(bandData.lastUpdatedBase > 0, "BPF_TBZ");
        // BPF_IP: invalid price
        require(bandData.rate > 0, "BPF_IP");

        return bandData;
    }

    function getSurroundingObservations(uint256 targetTimestamp)
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        uint8 index = currentObservationIndex;
        uint8 beforeOrAtIndex;
        uint8 atOrAfterIndex;

        // == case 1 ==
        // now: 3:45
        // target: 3:30
        // index 0: 3:40  --> chosen
        // index 1: 3:50
        // beforeOrAtIndex = 0
        // atOrAfterIndex = 0

        // == case 2 ==
        // now: 3:45
        // target: 3:30
        // index 0: 2:00
        // index 1: 2:10 --> chosen
        // beforeOrAtIndex = 1
        // atOrAfterIndex = 1

        // == case 3 ==
        // now: 3:45
        // target: 3:01
        // index 0: 3:00  --> chosen
        // index 1: 3:15
        // index 2: 3:30
        // beforeOrAtIndex = 0
        // atOrAfterIndex = 1

        // run at most 256 times
        uint256 observationLen = observations.length;
        uint256 i;
        for (i = 0; i < observationLen; i++) {
            if (observations[index].timestamp <= targetTimestamp) {
                // if the next observation is empty, using the last one
                // it implies the historical data is not enough
                if (observations[index].timestamp == 0) {
                    atOrAfterIndex = beforeOrAtIndex = index + 1;
                    break;
                }
                beforeOrAtIndex = index;
                atOrAfterIndex = beforeOrAtIndex + 1;
                break;
            }
            index--;
        }

        // not enough historical data to query
        if (i == observationLen) {
            // BPF_NEH: no enough historical data
            revert("BPF_NEH");
        }

        beforeOrAt = observations[beforeOrAtIndex];
        atOrAfter = observations[atOrAfterIndex];

        // if timestamp of the right bound is earlier than timestamp of the left bound,
        // it means the left bound is the lastest observation.
        // It implies the latest observation is older than requested
        // Then we set the right bound to the left bound.
        if (atOrAfter.timestamp < beforeOrAt.timestamp) {
            atOrAfter = beforeOrAt;
        }
    }
}
