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
PUSH4 0xa2b52f22
EQ
PUSH2 0x0021
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x0034
PUSH2 0x002f
CALLDATASIZE
PUSH1 0x04
PUSH2 0x019e
JUMP
JUMPDEST
PUSH2 0x0036
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH0
DUP3
MLOAD
GT
PUSH2 0x007b
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
PUSH13 0x4e6f20726563697069656e7473
PUSH1 0x98
SHL
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
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
PUSH0
DUP2
GT
PUSH2 0x00b8
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
PUSH1 0x0b
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH11 0x16995c9bc8185b5bdd5b9d
PUSH1 0xaa
SHL
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0072
JUMP
JUMPDEST
DUP1
DUP3
MLOAD
PUSH2 0x00c5
SWAP2
SWAP1
PUSH2 0x0264
JUMP
JUMPDEST
CALLVALUE
EQ
PUSH2 0x0107
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
PUSH1 0x11
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH17 0x496e76616c6964206d73672076616c7565
PUSH1 0x78
SHL
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0072
JUMP
JUMPDEST
PUSH0
JUMPDEST
DUP3
MLOAD
DUP2
LT
ISZERO
PUSH2 0x016a
JUMPI
DUP3
DUP2
DUP2
MLOAD
DUP2
LT
PUSH2 0x0124
JUMPI
PUSH2 0x0124
PUSH2 0x028d
JUMP
JUMPDEST
PUSH1 0x20
MUL
PUSH1 0x20
ADD
ADD
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH2 0x08fc
DUP4
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
PUSH2 0x0161
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
PUSH1 0x01
ADD
PUSH2 0x0109
JUMP
JUMPDEST
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
DUP1
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
PUSH2 0x0199
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
SWAP2
SWAP1
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
PUSH2 0x01af
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP3
CALLDATALOAD
PUSH8 0xffffffffffffffff
DUP1
DUP3
GT
ISZERO
PUSH2 0x01c6
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
DUP6
ADD
SWAP2
POP
DUP6
PUSH1 0x1f
DUP4
ADD
SLT
PUSH2 0x01d9
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
PUSH1 0x20
DUP3
DUP3
GT
ISZERO
PUSH2 0x01ed
JUMPI
PUSH2 0x01ed
PUSH2 0x016f
JUMP
JUMPDEST
DUP2
PUSH1 0x05
SHL
PUSH1 0x40
MLOAD
PUSH1 0x1f
NOT
PUSH1 0x3f
DUP4
ADD
AND
DUP2
ADD
DUP2
DUP2
LT
DUP7
DUP3
GT
OR
ISZERO
PUSH2 0x0212
JUMPI
PUSH2 0x0212
PUSH2 0x016f
JUMP
JUMPDEST
PUSH1 0x40
MSTORE
SWAP3
DUP4
MSTORE
DUP2
DUP4
ADD
SWAP4
POP
DUP5
DUP2
ADD
DUP3
ADD
SWAP3
DUP10
DUP5
GT
ISZERO
PUSH2 0x022f
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
SWAP5
DUP3
ADD
SWAP5
JUMPDEST
DUP4
DUP7
LT
ISZERO
PUSH2 0x0254
JUMPI
PUSH2 0x0245
DUP7
PUSH2 0x0183
JUMP
JUMPDEST
DUP6
MSTORE
SWAP5
DUP3
ADD
SWAP5
SWAP4
DUP3
ADD
SWAP4
PUSH2 0x0234
JUMP
JUMPDEST
SWAP10
SWAP8
SWAP1
SWAP2
ADD
CALLDATALOAD
SWAP8
POP
POP
POP
POP
POP
POP
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
PUSH2 0x0287
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
JUMPDEST
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
PUSH0
MSTORE
PUSH1 0x32
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH0
REVERT
INVALID
SELFDESTRUCT
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
'c4'(Unknown Opcode)
LT
SWAP14
'dc'(Unknown Opcode)
'c1'(Unknown Opcode)
'af'(Unknown Opcode)

CALLDATACOPY
PUSH23 0xbb03a0eecc618518ca9f2943ad84d54a592152b5685dce
PUSH5 0x736f6c6343
STOP
ADDMOD
XOR
STOP
CALLER