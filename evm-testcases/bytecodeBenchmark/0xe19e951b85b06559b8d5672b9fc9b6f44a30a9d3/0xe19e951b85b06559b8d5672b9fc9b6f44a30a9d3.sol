PUSH1 0x80
PUSH1 0x40
MSTORE
CALLVALUE
DUP1
ISZERO
PUSH2 0x000f
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x0029
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0xc290d691
EQ
PUSH2 0x002d
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x0040
PUSH2 0x003b
CALLDATASIZE
PUSH1 0x04
PUSH2 0x00e4
JUMP
JUMPDEST
PUSH2 0x0042
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH20 0xdac17f958d2ee523a2206206994597c13d831ec7
PUSH4 0x23b872dd
CALLER
PUSH20 0x13ebe96cf08086b495dd873c8c5185706df9fd6e
PUSH2 0x007f
DUP6
PUSH3 0x0f4240
PUSH2 0x00fb
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xe0
SHL
SUB
NOT
PUSH1 0xe0
DUP7
SWAP1
SHL
AND
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP4
DUP5
AND
PUSH1 0x04
DUP3
ADD
MSTORE
SWAP3
SWAP1
SWAP2
AND
PUSH1 0x24
DUP4
ADD
MSTORE
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH0
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH0
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x00cb
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x00dd
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
POP
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
PUSH2 0x00f4
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
SWAP2
SWAP1
POP
JUMP
JUMPDEST
DUP1
DUP3
MUL
DUP2
ISZERO
DUP3
DUP3
DIV
DUP5
EQ
OR
PUSH2 0x011e
JUMPI
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
PUSH0
MSTORE
PUSH1 0x11
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH0
REVERT
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
INVALID
