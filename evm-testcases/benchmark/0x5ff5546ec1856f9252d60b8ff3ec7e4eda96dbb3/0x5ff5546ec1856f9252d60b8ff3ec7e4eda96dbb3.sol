PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x001d
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x76a54c60
EQ
PUSH2 0x0021
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x003b
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x0036
SWAP2
SWAP1
PUSH2 0x0124
JUMP
JUMPDEST
PUSH2 0x003d
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH0
CALLVALUE
GT
PUSH2 0x007f
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0076
SWAP1
PUSH2 0x01cf
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
DUP1
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x08fc
CALLVALUE
SWAP1
DUP2
ISZERO
MUL
SWAP1
PUSH1 0x40
MLOAD
PUSH0
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP6
DUP9
DUP9
CALL
SWAP4
POP
POP
POP
POP
ISZERO
DUP1
ISZERO
PUSH2 0x00c2
JUMPI
RETURNDATASIZE
PUSH0
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH0
REVERT
JUMPDEST
POP
POP
JUMP
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH0
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP3
AND
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x00f3
DUP3
PUSH2 0x00ca
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x0103
DUP2
PUSH2 0x00e9
JUMP
JUMPDEST
DUP2
EQ
PUSH2 0x010d
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
JUMP
JUMPDEST
PUSH0
DUP2
CALLDATALOAD
SWAP1
POP
PUSH2 0x011e
DUP2
PUSH2 0x00fa
JUMP
JUMPDEST
SWAP3
SWAP2
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
PUSH2 0x0139
JUMPI
PUSH2 0x0138
PUSH2 0x00c6
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x0146
DUP5
DUP3
DUP6
ADD
PUSH2 0x0110
JUMP
JUMPDEST
SWAP2
POP
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
DUP3
DUP3
MSTORE
PUSH1 0x20
DUP3
ADD
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH32 0x4d7573742073656e642045746865722077697468207468652066756e6374696f
PUSH0
DUP3
ADD
MSTORE
PUSH32 0x6e2063616c6c0000000000000000000000000000000000000000000000000000
PUSH1 0x20
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x01b9
PUSH1 0x26
DUP4
PUSH2 0x014f
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x01c4
DUP3
PUSH2 0x015f
JUMP
JUMPDEST
PUSH1 0x40
DUP3
ADD
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
DUP2
DUP2
SUB
PUSH0
DUP4
ADD
MSTORE
PUSH2 0x01e6
DUP2
PUSH2 0x01ad
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
DUP15
'e9'(Unknown Opcode)
PUSH26 0x99be5eb7e3d10f83771f42bfac3ebb5b46ce86891052193f5c83
'ef'(Unknown Opcode)
'e1'(Unknown Opcode)
PUSH16 0x64736f6c63430008160033
