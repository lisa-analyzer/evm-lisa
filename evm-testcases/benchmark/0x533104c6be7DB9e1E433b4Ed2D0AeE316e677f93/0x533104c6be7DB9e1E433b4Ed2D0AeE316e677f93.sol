PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x0049
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x5c60da1b
EQ
PUSH2 0x006b
JUMPI
DUP1
PUSH4 0x715018a6
EQ
PUSH2 0x00a6
JUMPI
DUP1
PUSH4 0x8da5cb5b
EQ
PUSH2 0x00ba
JUMPI
DUP1
PUSH4 0xd69efdc5
EQ
PUSH2 0x00d6
JUMPI
DUP1
PUSH4 0xf2fde38b
EQ
PUSH2 0x00f5
JUMPI
JUMPDEST
CALLDATASIZE
PUSH0
DUP1
CALLDATACOPY
PUSH0
DUP1
CALLDATASIZE
PUSH0
PUSH1 0x01
SLOAD
GAS
DELEGATECALL
RETURNDATASIZE
PUSH0
DUP1
RETURNDATACOPY
DUP1
DUP1
ISZERO
PUSH2 0x0065
JUMPI
RETURNDATASIZE
PUSH0
RETURN
JUMPDEST
RETURNDATASIZE
PUSH0
REVERT
JUMPDEST
STOP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0076
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x01
SLOAD
PUSH2 0x008a
SWAP1
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP2
AND
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x00b1
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0069
PUSH2 0x0114
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x00c5
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH0
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH2 0x008a
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x00e1
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0069
PUSH2 0x00f0
CALLDATASIZE
PUSH1 0x04
PUSH2 0x020e
JUMP
JUMPDEST
PUSH2 0x0127
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0100
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0069
PUSH2 0x010f
CALLDATASIZE
PUSH1 0x04
PUSH2 0x020e
JUMP
JUMPDEST
PUSH2 0x0151
JUMP
JUMPDEST
PUSH2 0x011c
PUSH2 0x0193
JUMP
JUMPDEST
PUSH2 0x0125
PUSH0
PUSH2 0x01bf
JUMP
JUMPDEST
JUMP
JUMPDEST
PUSH2 0x012f
PUSH2 0x0193
JUMP
JUMPDEST
PUSH1 0x01
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
PUSH2 0x0159
PUSH2 0x0193
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP2
AND
PUSH2 0x0187
JUMPI
PUSH1 0x40
MLOAD
PUSH4 0x1e4fbdf7
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH0
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x24
ADD
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH2 0x0190
DUP2
PUSH2 0x01bf
JUMP
JUMPDEST
POP
JUMP
JUMPDEST
PUSH0
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
CALLER
EQ
PUSH2 0x0125
JUMPI
PUSH1 0x40
MLOAD
PUSH4 0x118cdaa7
PUSH1 0xe0
SHL
DUP2
MSTORE
CALLER
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x24
ADD
PUSH2 0x017e
JUMP
JUMPDEST
PUSH0
DUP1
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP4
DUP2
AND
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
NOT
DUP4
AND
DUP2
OR
DUP5
SSTORE
PUSH1 0x40
MLOAD
SWAP2
SWAP1
SWAP3
AND
SWAP3
DUP4
SWAP2
PUSH32 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
SWAP2
SWAP1
LOG3
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x021e
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP2
AND
DUP2
EQ
PUSH2 0x0234
JUMPI
PUSH0
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
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
ORIGIN
PUSH20 0x230425aa3ca5136dd9480522721361b76accb1a1
'21'(Unknown Opcode)
DUP4
SWAP1
STATICCALL
PUSH16 0xacc0f624d264736f6c63430008170033
