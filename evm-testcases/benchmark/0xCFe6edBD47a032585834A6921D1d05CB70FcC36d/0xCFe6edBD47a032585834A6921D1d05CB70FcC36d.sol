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
PUSH2 0x002b
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0xf7e83aee
EQ
PUSH2 0x0030
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x0043
PUSH2 0x003e
CALLDATASIZE
PUSH1 0x04
PUSH2 0x01d4
JUMP
JUMPDEST
PUSH2 0x0057
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
SWAP1
ISZERO
ISZERO
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
PUSH1 0x00
PUSH1 0x20
DUP3
EQ
PUSH2 0x00c7
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x1a
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x496e76616c6964207368613235362068617368206c656e677468000000000000
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
PUSH2 0x010b
PUSH1 0x00
DUP5
DUP5
DUP1
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
SWAP4
SWAP3
SWAP2
SWAP1
DUP2
DUP2
MSTORE
PUSH1 0x20
ADD
DUP4
DUP4
DUP1
DUP3
DUP5
CALLDATACOPY
PUSH1 0x00
SWAP3
ADD
SWAP2
SWAP1
SWAP2
MSTORE
POP
SWAP3
SWAP4
SWAP3
POP
POP
PUSH2 0x0167
SWAP1
POP
JUMP
JUMPDEST
PUSH1 0x02
DUP7
DUP7
PUSH1 0x40
MLOAD
PUSH2 0x011d
SWAP3
SWAP2
SWAP1
PUSH2 0x0240
JUMP
JUMPDEST
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP6
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x013a
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
PUSH1 0x40
MLOAD
RETURNDATASIZE
PUSH1 0x1f
NOT
PUSH1 0x1f
DUP3
ADD
AND
DUP3
ADD
DUP1
PUSH1 0x40
MSTORE
POP
DUP2
ADD
SWAP1
PUSH2 0x015d
SWAP2
SWAP1
PUSH2 0x0250
JUMP
JUMPDEST
EQ
SWAP6
SWAP5
POP
POP
POP
POP
POP
JUMP
JUMPDEST
DUP2
MLOAD
PUSH1 0x00
SWAP1
PUSH2 0x0177
DUP4
PUSH1 0x20
PUSH2 0x0269
JUMP
JUMPDEST
GT
ISZERO
PUSH2 0x0182
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
ADD
PUSH1 0x20
ADD
MLOAD
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
DUP1
DUP4
PUSH1 0x1f
DUP5
ADD
SLT
PUSH2 0x019d
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
DUP2
CALLDATALOAD
PUSH8 0xffffffffffffffff
DUP2
GT
ISZERO
PUSH2 0x01b5
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x20
DUP4
ADD
SWAP2
POP
DUP4
PUSH1 0x20
DUP3
DUP6
ADD
ADD
GT
ISZERO
PUSH2 0x01cd
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP3
POP
SWAP3
SWAP1
POP
JUMP
JUMPDEST
PUSH1 0x00
DUP1
PUSH1 0x00
DUP1
PUSH1 0x40
DUP6
DUP8
SUB
SLT
ISZERO
PUSH2 0x01ea
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP5
CALLDATALOAD
PUSH8 0xffffffffffffffff
DUP1
DUP3
GT
ISZERO
PUSH2 0x0202
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x020e
DUP9
DUP4
DUP10
ADD
PUSH2 0x018b
JUMP
JUMPDEST
SWAP1
SWAP7
POP
SWAP5
POP
PUSH1 0x20
DUP8
ADD
CALLDATALOAD
SWAP2
POP
DUP1
DUP3
GT
ISZERO
PUSH2 0x0227
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0234
DUP8
DUP3
DUP9
ADD
PUSH2 0x018b
JUMP
JUMPDEST
SWAP6
SWAP9
SWAP5
SWAP8
POP
SWAP6
POP
POP
POP
POP
JUMP
JUMPDEST
DUP2
DUP4
DUP3
CALLDATACOPY
PUSH1 0x00
SWAP2
ADD
SWAP1
DUP2
MSTORE
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0262
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
SWAP2
SWAP1
POP
JUMP
JUMPDEST
DUP1
DUP3
ADD
DUP1
DUP3
GT
ISZERO
PUSH2 0x02a3
JUMPI
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH1 0x00
MSTORE
PUSH1 0x11
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
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
'23'(Unknown Opcode)
BASEFEE
'aa'(Unknown Opcode)
'af'(Unknown Opcode)
'c4'(Unknown Opcode)
GASPRICE
JUMPDEST
'd6'(Unknown Opcode)
ADDMOD
PUSH14 0x9011d799efff422cd74c984a03fe
SGT
'c8'(Unknown Opcode)
'5c'(Unknown Opcode)
'c4'(Unknown Opcode)
'd4'(Unknown Opcode)
'5e'(Unknown Opcode)
DUP5
'2b'(Unknown Opcode)
PUSH5 0x736f6c6343
STOP
ADDMOD
GT
STOP
CALLER
