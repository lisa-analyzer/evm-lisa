PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
PUSH1 0x00
SLOAD
AND
PUSH32 0xa619486e00000000000000000000000000000000000000000000000000000000
PUSH1 0x00
CALLDATALOAD
EQ
ISZERO
PUSH1 0x50
JUMPI
DUP1
PUSH1 0x00
MSTORE
PUSH1 0x20
PUSH1 0x00
RETURN
JUMPDEST
CALLDATASIZE
PUSH1 0x00
DUP1
CALLDATACOPY
PUSH1 0x00
DUP1
CALLDATASIZE
PUSH1 0x00
DUP5
GAS
DELEGATECALL
RETURNDATASIZE
PUSH1 0x00
DUP1
RETURNDATACOPY
PUSH1 0x00
DUP2
EQ
ISZERO
PUSH1 0x70
JUMPI
RETURNDATASIZE
PUSH1 0x00
REVERT
JUMPDEST
RETURNDATASIZE
PUSH1 0x00
RETURN
INVALID
