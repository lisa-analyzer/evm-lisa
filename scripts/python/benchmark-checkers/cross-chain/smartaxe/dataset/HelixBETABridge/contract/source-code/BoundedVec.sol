// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library BoundedVec {
    struct Vec {
        bytes32[] _values;
        uint256 _capacity;
        uint256 _start;
        uint256 _length;
    }

    function _setCapacity(Vec storage vec, uint256 _capacity) internal {
        require(vec._capacity == 0, "BoundedVec:can't resize vec");
        vec._capacity = _capacity;
    }

    function _length(Vec storage vec) internal view returns(uint256) {
        return vec._length;
    }

    function _start(Vec storage vec) internal view returns(uint256) {
        return vec._start;
    }

    function _at(Vec storage vec, uint256 index) internal view returns(bytes32) {
        require(index < vec._length, "BoundedVec:index overflow");
        uint256 pos = index + vec._start;
        if (pos >= vec._capacity) {
            return vec._values[pos - vec._capacity];
        } else {
            return vec._values[pos];
        }
    }

    function _push(Vec storage vec, bytes32 _value) internal {
        uint256 size = vec._length;
        require(size < vec._capacity, "BoundedVec:index overflow");
        uint256 pos = vec._start + size;
        if (pos >= vec._capacity) {
            vec._values[pos - vec._capacity] = _value;
        } else {
            if (vec._values.length < vec._capacity) {
                vec._values.push(_value);
            } else {
                vec._values[pos] = _value;
            }
        }
        vec._length = size + 1;
    }

    function _pop(Vec storage vec) internal {
        uint256 size = vec._length;
        require(size > 0, "BoundedVec:!empty");
        uint256 next = vec._start + 1;
        if (next >= vec._capacity) {
            next = 0;
        }
        vec._start = next;
        vec._length = size - 1;
    }

    // this is only for sorted vector
    function _contains(Vec storage vec, bytes32 value) internal view returns(bool) {
        if (vec._length == 0) {
            return false;
        }
        uint256 high = vec._start + vec._length - 1;
        uint256 low = vec._start;
        while (low < high) {
            uint256 mid = (low & high) + (low ^ high) / 2;
            uint256 pos = mid > vec._capacity ? mid - vec._capacity : mid;
            if (vec._values[pos] > value) {
                high = mid;
            } else if (vec._values[pos] < value) {
                low = mid + 1;
            } else {
                return true;
            }
        }
        return false;
    }

    struct Uint64Vec {
        Vec _inner;
    }

    function push(Uint64Vec storage vec, uint64 value) internal {
        _push(vec._inner, bytes32(uint256(value)));
    }

    function pop(Uint64Vec storage vec) internal {
        _pop(vec._inner);
    }

    function at(Uint64Vec storage vec, uint256 index) internal view returns(uint64) {
        return uint64(uint256(_at(vec._inner, index)));
    }

    function length(Uint64Vec storage vec) internal view returns(uint256) {
        return _length(vec._inner);
    }

    function contains(Uint64Vec storage vec, uint64 value) internal view returns(bool) {
        return _contains(vec._inner, bytes32(uint256(value)));
    }

    function setCapacity(Uint64Vec storage vec, uint256 _capacity) internal {
        _setCapacity(vec._inner, _capacity);
    }
}

