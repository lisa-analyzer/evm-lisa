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
PUSH2 0x004a
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x013cf08b
EQ
PUSH2 0x004e
JUMPI
DUP1
PUSH4 0x2ab09d14
EQ
PUSH2 0x0079
JUMPI
DUP1
PUSH4 0x49c2a1a6
EQ
PUSH2 0x008f
JUMPI
DUP1
PUSH4 0xb384abef
EQ
PUSH2 0x00a4
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x0061
PUSH2 0x005c
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0212
JUMP
JUMPDEST
PUSH2 0x00b7
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0070
SWAP4
SWAP3
SWAP2
SWAP1
PUSH2 0x0229
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0081
PUSH0
SLOAD
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH2 0x0070
JUMP
JUMPDEST
PUSH2 0x00a2
PUSH2 0x009d
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0298
JUMP
JUMPDEST
PUSH2 0x015e
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x00a2
PUSH2 0x00b2
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0343
JUMP
JUMPDEST
PUSH2 0x0177
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x20
DUP2
SWAP1
MSTORE
PUSH0
SWAP2
DUP3
MSTORE
PUSH1 0x40
SWAP1
SWAP2
SHA3
DUP1
SLOAD
SWAP2
DUP2
ADD
DUP1
SLOAD
PUSH2 0x00d7
SWAP1
PUSH2 0x0363
JUMP
JUMPDEST
DUP1
PUSH1 0x1f
ADD
PUSH1 0x20
DUP1
SWAP2
DIV
MUL
PUSH1 0x20
ADD
PUSH1 0x40
MLOAD
SWAP1
DUP2
ADD
PUSH1 0x40
MSTORE
DUP1
SWAP3
SWAP2
SWAP1
DUP2
DUP2
MSTORE
PUSH1 0x20
ADD
DUP3
DUP1
SLOAD
PUSH2 0x0103
SWAP1
PUSH2 0x0363
JUMP
JUMPDEST
DUP1
ISZERO
PUSH2 0x014e
JUMPI
DUP1
PUSH1 0x1f
LT
PUSH2 0x0125
JUMPI
PUSH2 0x0100
DUP1
DUP4
SLOAD
DIV
MUL
DUP4
MSTORE
SWAP2
PUSH1 0x20
ADD
SWAP2
PUSH2 0x014e
JUMP
JUMPDEST
DUP3
ADD
SWAP2
SWAP1
PUSH0
MSTORE
PUSH1 0x20
PUSH0
SHA3
SWAP1
JUMPDEST
DUP2
SLOAD
DUP2
MSTORE
SWAP1
PUSH1 0x01
ADD
SWAP1
PUSH1 0x20
ADD
DUP1
DUP4
GT
PUSH2 0x0131
JUMPI
DUP3
SWAP1
SUB
PUSH1 0x1f
AND
DUP3
ADD
SWAP2
JUMPDEST
POP
POP
POP
POP
POP
SWAP1
DUP1
PUSH1 0x02
ADD
SLOAD
SWAP1
POP
DUP4
JUMP
JUMPDEST
PUSH0
DUP1
SLOAD
SWAP1
DUP2
SWAP1
DUP1
PUSH2 0x016e
DUP4
PUSH2 0x03af
JUMP
JUMPDEST
SWAP2
SWAP1
POP
SSTORE
POP
POP
POP
JUMP
JUMPDEST
PUSH0
DUP3
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x20
SWAP1
DUP2
MSTORE
PUSH1 0x40
DUP1
DUP4
SHA3
CALLER
DUP5
MSTORE
PUSH1 0x03
DUP2
ADD
SWAP1
SWAP3
MSTORE
SWAP1
SWAP2
SHA3
SLOAD
PUSH1 0xff
AND
ISZERO
PUSH2 0x01d9
JUMPI
PUSH1 0x40
MLOAD
PUSH3 0x461bcd
PUSH1 0xe5
SHL
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x0d
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH13 0x105b1c9958591e481d9bdd1959
PUSH1 0x9a
SHL
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x01
DUP2
PUSH1 0x02
ADD
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x01ed
SWAP2
SWAP1
PUSH2 0x03c7
JUMP
JUMPDEST
SWAP1
SWAP2
SSTORE
POP
POP
CALLER
PUSH0
SWAP1
DUP2
MSTORE
PUSH1 0x03
SWAP1
SWAP2
ADD
PUSH1 0x20
MSTORE
PUSH1 0x40
SWAP1
SHA3
DUP1
SLOAD
PUSH1 0xff
NOT
AND
PUSH1 0x01
OR
SWAP1
SSTORE
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
PUSH2 0x0222
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
DUP4
DUP2
MSTORE
PUSH0
PUSH1 0x20
PUSH1 0x60
PUSH1 0x20
DUP5
ADD
MSTORE
DUP5
MLOAD
DUP1
PUSH1 0x60
DUP6
ADD
MSTORE
PUSH0
JUMPDEST
DUP2
DUP2
LT
ISZERO
PUSH2 0x025c
JUMPI
DUP7
DUP2
ADD
DUP4
ADD
MLOAD
DUP6
DUP3
ADD
PUSH1 0x80
ADD
MSTORE
DUP3
ADD
PUSH2 0x0240
JUMP
JUMPDEST
POP
PUSH0
PUSH1 0x80
DUP3
DUP7
ADD
ADD
MSTORE
PUSH1 0x80
PUSH1 0x1f
NOT
PUSH1 0x1f
DUP4
ADD
AND
DUP6
ADD
ADD
SWAP3
POP
POP
POP
DUP3
PUSH1 0x40
DUP4
ADD
MSTORE
SWAP5
SWAP4
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
PUSH0
MSTORE
PUSH1 0x41
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH0
REVERT
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x02a8
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
PUSH8 0xffffffffffffffff
DUP1
DUP3
GT
ISZERO
PUSH2 0x02bf
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
DUP5
ADD
SWAP2
POP
DUP5
PUSH1 0x1f
DUP4
ADD
SLT
PUSH2 0x02d2
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
DUP2
DUP2
GT
ISZERO
PUSH2 0x02e4
JUMPI
PUSH2 0x02e4
PUSH2 0x0284
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x1f
DUP3
ADD
PUSH1 0x1f
NOT
SWAP1
DUP2
AND
PUSH1 0x3f
ADD
AND
DUP2
ADD
SWAP1
DUP4
DUP3
GT
DUP2
DUP4
LT
OR
ISZERO
PUSH2 0x030c
JUMPI
PUSH2 0x030c
PUSH2 0x0284
JUMP
JUMPDEST
DUP2
PUSH1 0x40
MSTORE
DUP3
DUP2
MSTORE
DUP8
PUSH1 0x20
DUP5
DUP8
ADD
ADD
GT
ISZERO
PUSH2 0x0324
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP3
PUSH1 0x20
DUP7
ADD
PUSH1 0x20
DUP4
ADD
CALLDATACOPY
PUSH0
SWAP3
DUP2
ADD
PUSH1 0x20
ADD
SWAP3
SWAP1
SWAP3
MSTORE
POP
SWAP6
SWAP5
POP
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH0
DUP1
PUSH1 0x40
DUP4
DUP6
SUB
SLT
ISZERO
PUSH2 0x0354
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
POP
DUP1
CALLDATALOAD
SWAP3
PUSH1 0x20
SWAP1
SWAP2
ADD
CALLDATALOAD
SWAP2
POP
JUMP
JUMPDEST
PUSH1 0x01
DUP2
DUP2
SHR
SWAP1
DUP3
AND
DUP1
PUSH2 0x0377
JUMPI
PUSH1 0x7f
DUP3
AND
SWAP2
POP
JUMPDEST
PUSH1 0x20
DUP3
LT
DUP2
SUB
PUSH2 0x0395
JUMPI
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
PUSH0
MSTORE
PUSH1 0x22
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH0
REVERT
JUMPDEST
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
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
PUSH0
PUSH1 0x01
DUP3
ADD
PUSH2 0x03c0
JUMPI
PUSH2 0x03c0
PUSH2 0x039b
JUMP
JUMPDEST
POP
PUSH1 0x01
ADD
SWAP1
JUMP
JUMPDEST
DUP1
DUP3
ADD
DUP1
DUP3
GT
ISZERO
PUSH2 0x03da
JUMPI
PUSH2 0x03da
PUSH2 0x039b
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
EXTCODECOPY
CODECOPY
PUSH0
PUSH1 0xac
CALL
'ae'(Unknown Opcode)
PC
BASEFEE
PUSH19 0xaabce2d7f7d420f5924c2d30260d29cc49ad5c
'be'(Unknown Opcode)
JUMP
SWAP12
PUSH5 0x736f6c6343
STOP
ADDMOD
XOR
STOP
CALLER