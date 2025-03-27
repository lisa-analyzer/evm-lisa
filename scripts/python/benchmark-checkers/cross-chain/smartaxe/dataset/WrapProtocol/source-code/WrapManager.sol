pragma solidity >=0.5.0 <0.7.0;

contract MultisigManager {

    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    address administrator;
    mapping(address => address) internal owners;
    uint256 ownerCount;
    uint256 internal threshold;

    modifier authorized() {
        require(msg.sender == administrator, "WRAP: METHOD_CAN_ONLY_BE_CALLED_BY_ADMINISTRATOR");
        _;
    }

    function _setup(address[] memory _owners, uint256 _threshold)
        internal
    {
        require(threshold == 0, "WRAP: CONTRACT_ALREADY_SETUP");
        require(_threshold <= _owners.length, "WRAP: THRESHOLD_CANNOT_EXCEED_OWNER_COUNT");
        require(_threshold >= 1, "WRAP: THRESHOLD_NEEED_TO_BE_GREETER_THAN_0");
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS, "WRAP: INVALID_OWNER_PROVIDED");
            require(owners[owner] == address(0), "WRAP: DUPLICATE_OWNER_ADDRESS_PROVIDED");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    function addOwnerWithThreshold(
        address owner,
        uint256 _threshold
    )
        public
        authorized
    {
        require(owner != address(0) && owner != SENTINEL_OWNERS, "WRAP: INVALID_OWNER_ADDRESS_PROVIDED");
        require(owners[owner] == address(0), "WRAP: ADDRESS_IS_ALREADY_AN_OWNER");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    )
        public
        authorized
    {
        require(ownerCount - 1 >= _threshold, "WRAP: NEW_OWNER_COUNT_NEEDS_TO_BE_LONGER_THAN_THRESHOLD");
        require(owner != address(0) && owner != SENTINEL_OWNERS, "WRAP: INVALID_OWNER_ADDRESS_PROVIDED");
        require(owners[prevOwner] == owner, "WRAP: INVALID_PREV_OWNER_OWNER_PAIR_PROVIDED");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        if (threshold != _threshold)
            changeThreshold(_threshold);
    }

    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    )
        public
        authorized
    {
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS, "WRAP: INVALID_OWNER_ADDRESS_PROVIDED");
        require(owners[newOwner] == address(0), "WRAP: ADDRESS_IS_ALREADY_AN_OWNER");
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "WRAP: INVALID_OWNER_ADDRESS_PROVIDED");
        require(owners[prevOwner] == oldOwner, "WRAP: INVALID_PREV_OWNER_OWNER_PAIR_PROVIDED");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    function changeThreshold(
        uint256 _threshold
    )
        public
        authorized
    {
        require(_threshold <= ownerCount, "WRAP: THRESHOLD_CANNOT_EXCEED_OWNER_COUNT");
        require(_threshold >= 1, "WRAP: THRESHOLD_NEEED_TO_BE_GREETER_THAN_0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold()
        public
        view
        returns (uint256)
    {
        return threshold;
    }

    function isOwner(address owner)
        public
        view
        returns (bool)
    {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    function getOwners()
        public
        view
        returns (address[] memory)
    {
        address[] memory array = new address[](ownerCount);

        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while(currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index ++;
        }
        return array;
    }

    function getAdministrator()
        public
        view
        returns (address)
    {
        return administrator;
    }
}
