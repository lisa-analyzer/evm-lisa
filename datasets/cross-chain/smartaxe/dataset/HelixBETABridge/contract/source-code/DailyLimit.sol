// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

/// @title relay with daily limit - Allows the relay to mint token in a daily limit.
contract DailyLimit {

    event DailyLimitChange(address token, uint dailyLimit);

    mapping(address => uint) public dailyLimit;
    // deprecated, slot for upgrade
    mapping(address => uint) public _slotReserved;
    mapping(address => uint) public spentToday;

    uint constant public SPEND_BIT_LENGTH = 192;
    uint constant public LASTDAY_BIT_LENGTH = 64;

    /// ==== Internal functions ==== 

    /// @dev Contract constructor sets initial owners, required number of confirmations and daily mint limit.
    /// @param _token Token address.
    /// @param _dailyLimit Amount in wei, which can be mint without confirmations on a daily basis.
    function _setDailyLimit(address _token, uint _dailyLimit)
        internal
    {
        require(_dailyLimit < type(uint192).max, "DaliyLimit: overflow uint192");
        dailyLimit[_token] = _dailyLimit;
    }

    /// @dev Allows to change the daily limit.
    /// @param _token Token address.
    /// @param _dailyLimit Amount in wei.
    function _changeDailyLimit(address _token, uint _dailyLimit)
        internal
    {
        require(_dailyLimit < type(uint192).max, "DaliyLimit: overflow uint192");
        dailyLimit[_token] = _dailyLimit;
        emit DailyLimitChange(_token, _dailyLimit);
    }

    /// @dev Allows to change the daily limit.
    /// @param token Token address.
    /// @param amount Amount in wei.
    function expendDailyLimit(address token, uint amount)
        internal
    {
        uint spentInfo = spentToday[token];
        uint lastday = spentInfo >> SPEND_BIT_LENGTH;
        uint lastspent = spentInfo << LASTDAY_BIT_LENGTH >> LASTDAY_BIT_LENGTH;
        if (block.timestamp > lastday + 24 hours) {
            require(amount <= dailyLimit[token], "DailyLimit: amount exceed daily limit");
            spentToday[token] = (block.timestamp << SPEND_BIT_LENGTH) + amount;
            return;
        }
        require(lastspent + amount <= dailyLimit[token] && amount <= dailyLimit[token], "DailyLimit: exceed daily limit");
        spentToday[token] = spentInfo + amount;
    }

    /// ==== Web3 call functions ==== 

    /// @dev Returns maximum withdraw amount.
    /// @param token Token address.
    /// @return Returns amount.
    function calcMaxWithdraw(address token)
        public
        view
        returns (uint)
    {
        uint spentInfo = spentToday[token];
        uint lastday = spentInfo >> SPEND_BIT_LENGTH;
        uint lastspent = spentInfo << LASTDAY_BIT_LENGTH >> LASTDAY_BIT_LENGTH;
        if (block.timestamp > lastday + 24 hours) {
          return dailyLimit[token];
        }

        if (dailyLimit[token] < lastspent) {
          return 0;
        }

        return dailyLimit[token] - lastspent;
    }
}
