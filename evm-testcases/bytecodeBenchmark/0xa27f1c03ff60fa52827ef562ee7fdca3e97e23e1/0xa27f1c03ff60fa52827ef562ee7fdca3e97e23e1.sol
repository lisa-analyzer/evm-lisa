PUSH1 0x80
PUSH1 0x40
MSTORE
CALLVALUE
DUP1
ISZERO
PUSH1 0x0f
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x04
CALLDATASIZE
LT
PUSH1 0x32
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x61da1439
EQ
PUSH1 0x37
JUMPI
DUP1
PUSH4 0xe2e52ec1
EQ
PUSH1 0x63
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x51
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH1 0x4b
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH1 0x85
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
PUSH1 0x83
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x40
DUP2
LT
ISZERO
PUSH1 0x77
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
DUP1
CALLDATALOAD
SWAP1
PUSH1 0x20
ADD
CALLDATALOAD
PUSH1 0x97
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x01
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
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
CALLER
EQ
PUSH1 0xad
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x00
SWAP2
DUP3
MSTORE
PUSH1 0x01
PUSH1 0x20
MSTORE
PUSH1 0x40
SWAP1
SWAP2
SHA3
SSTORE
JUMP
INVALID
