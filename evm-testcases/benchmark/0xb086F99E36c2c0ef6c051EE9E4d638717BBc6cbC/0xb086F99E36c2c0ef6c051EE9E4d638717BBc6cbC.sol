PUSH1 0x80
PUSH1 0x40
MSTORE
CALLVALUE
DUP1
ISZERO
PUSH2 0x0010
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x0057
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x20c99aab
EQ
PUSH2 0x005c
JUMPI
DUP1
PUSH4 0x25986065
EQ
PUSH2 0x007b
JUMPI
DUP1
PUSH4 0xa781e7f8
EQ
PUSH2 0x0095
JUMPI
DUP1
PUSH4 0xcc0f0c17
EQ
PUSH2 0x00bb
JUMPI
DUP1
PUSH4 0xf09b8848
EQ
PUSH2 0x00e7
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x0079
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x0072
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH2 0x010d
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0083
PUSH2 0x01cf
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
SWAP2
DUP3
MSTORE
MLOAD
SWAP1
DUP2
SWAP1
SUB
PUSH1 0x20
ADD
SWAP1
RETURN
JUMPDEST
PUSH2 0x0079
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x00ab
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH2 0x01d5
JUMP
JUMPDEST
PUSH2 0x0079
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x40
DUP2
LT
ISZERO
PUSH2 0x00d1
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP2
CALLDATALOAD
AND
SWAP1
PUSH1 0x20
ADD
CALLDATALOAD
PUSH2 0x027c
JUMP
JUMPDEST
PUSH2 0x0083
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x00fd
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH2 0x0341
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x40
DUP1
MLOAD
PUSH4 0x47f3bf43
PUSH1 0xe1
SHL
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
DUP2
SWAP1
MSTORE
PUSH1 0x0e
PUSH1 0x24
DUP4
ADD
MSTORE
PUSH14 0x1b9bd919505cdcda59db9b595b9d
PUSH1 0x92
SHL
PUSH1 0x44
DUP4
ADD
MSTORE
SWAP2
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP4
AND
SWAP3
PUSH4 0x8fe77e86
SWAP3
PUSH1 0x64
DUP1
DUP5
ADD
SWAP4
SWAP2
SWAP3
SWAP2
DUP3
SWAP1
SUB
ADD
DUP2
DUP7
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0176
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x018a
JUMPI
RETURNDATASIZE
PUSH1 0x00
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH1 0x00
REVERT
JUMPDEST
POP
POP
POP
POP
PUSH1 0x40
MLOAD
RETURNDATASIZE
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x01a0
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
CALLER
EQ
PUSH2 0x01b6
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x01
SLOAD
PUSH2 0x01c9
SWAP1
DUP3
PUSH4 0xffffffff
PUSH2 0x035c
AND
JUMP
JUMPDEST
PUSH1 0x01
SSTORE
POP
JUMP
JUMPDEST
PUSH1 0x01
SLOAD
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x40
DUP1
MLOAD
PUSH4 0xa3bf06f1
PUSH1 0xe0
SHL
DUP2
MSTORE
CALLER
PUSH1 0x04
DUP3
ADD
MSTORE
SWAP1
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP3
AND
SWAP2
PUSH4 0xa3bf06f1
SWAP2
PUSH1 0x24
DUP1
DUP3
ADD
SWAP3
PUSH1 0x20
SWAP3
SWAP1
SWAP2
SWAP1
DUP3
SWAP1
SUB
ADD
DUP2
DUP7
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0220
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x0234
JUMPI
RETURNDATASIZE
PUSH1 0x00
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH1 0x00
REVERT
JUMPDEST
POP
POP
POP
POP
PUSH1 0x40
MLOAD
RETURNDATASIZE
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x024a
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
ISZERO
ISZERO
PUSH1 0x01
EQ
PUSH2 0x025a
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x00
DUP1
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
NOT
AND
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP3
SWAP1
SWAP3
AND
SWAP2
SWAP1
SWAP2
OR
SWAP1
SSTORE
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x40
DUP1
MLOAD
PUSH4 0x47f3bf43
PUSH1 0xe1
SHL
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
DUP2
SWAP1
MSTORE
PUSH1 0x0e
PUSH1 0x24
DUP4
ADD
MSTORE
PUSH14 0x1b9bd919505cdcda59db9b595b9d
PUSH1 0x92
SHL
PUSH1 0x44
DUP4
ADD
MSTORE
SWAP2
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP4
AND
SWAP3
PUSH4 0x8fe77e86
SWAP3
PUSH1 0x64
DUP1
DUP5
ADD
SWAP4
SWAP2
SWAP3
SWAP2
DUP3
SWAP1
SUB
ADD
DUP2
DUP7
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x02e5
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x02f9
JUMPI
RETURNDATASIZE
PUSH1 0x00
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH1 0x00
REVERT
JUMPDEST
POP
POP
POP
POP
PUSH1 0x40
MLOAD
RETURNDATASIZE
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x030f
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
CALLER
EQ
PUSH2 0x0325
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP2
AND
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x02
PUSH1 0x20
MSTORE
PUSH1 0x40
SWAP1
SHA3
SSTORE
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x02
PUSH1 0x20
MSTORE
PUSH1 0x40
SWAP1
SHA3
SLOAD
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
DUP3
DUP3
ADD
DUP4
DUP2
LT
ISZERO
PUSH2 0x036e
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP4
SWAP3
POP
POP
POP
JUMP
INVALID
