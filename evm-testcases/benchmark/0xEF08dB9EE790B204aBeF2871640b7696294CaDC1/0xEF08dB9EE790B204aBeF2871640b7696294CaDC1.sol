PUSH1 0x80
PUSH1 0x40
SWAP1
DUP1
DUP3
MSTORE
PUSH1 0x04
DUP1
CALLDATASIZE
LT
ISZERO
PUSH2 0x0016
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x00
SWAP2
DUP3
CALLDATALOAD
PUSH1 0xe0
SHR
PUSH4 0x1555fe6b
EQ
PUSH2 0x002d
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
CALLVALUE
PUSH2 0x044b
JUMPI
PUSH32 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
SWAP3
DUP5
DUP5
CALLDATASIZE
ADD
SLT
PUSH2 0x0448
JUMPI
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP4
DUP4
CALLDATALOAD
DUP6
DUP2
AND
SUB
PUSH2 0x0444
JUMPI
PUSH1 0x24
SWAP1
DUP2
CALLDATALOAD
SWAP2
PUSH8 0xffffffffffffffff
SWAP1
DUP2
DUP5
GT
PUSH2 0x0440
JUMPI
DUP4
CALLDATASIZE
SUB
PUSH1 0x60
DUP1
SWAP5
DUP3
ADD
SLT
PUSH2 0x03aa
JUMPI
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdd
PUSH1 0x44
DUP7
ADD
CALLDATALOAD
SWAP2
ADD
DUP2
SLT
ISZERO
PUSH2 0x03aa
JUMPI
DUP5
ADD
DUP8
DUP2
ADD
CALLDATALOAD
SWAP1
DUP4
DUP3
GT
PUSH2 0x043c
JUMPI
DUP3
ADD
SWAP1
DUP1
PUSH1 0x06
SHL
CALLDATASIZE
SUB
DUP3
SGT
PUSH2 0x043c
JUMPI
ISZERO
PUSH2 0x0411
JUMPI
CALLDATALOAD
SWAP4
DUP9
DUP6
AND
DUP1
SWAP6
SUB
PUSH2 0x03aa
JUMPI
DUP9
PUSH32 0xe26698d2bdb6483c27c4bb03b63ce41a68f1e73346c654a061e8af0459744f87
SLOAD
AND
SWAP7
DUP8
ISZERO
PUSH2 0x03ea
JUMPI
POP
DUP10
MLOAD
SWAP7
DUP8
SWAP6
PUSH32 0xbbe4f6db00000000000000000000000000000000000000000000000000000000
DUP8
MSTORE
DUP10
DUP8
ADD
MSTORE
DUP6
DUP4
PUSH1 0x20
SWAP8
DUP9
SWAP4
GAS
STATICCALL
SWAP7
DUP8
ISZERO
PUSH2 0x03e0
JUMPI
DUP7
SWAP8
PUSH2 0x034c
JUMPI
JUMPDEST
POP
DUP2
DUP11
MLOAD
SWAP2
PUSH32 0xc5ebeaec00000000000000000000000000000000000000000000000000000000
DUP8
DUP5
ADD
MSTORE
ADD
CALLDATALOAD
DUP3
DUP3
ADD
MSTORE
DUP2
DUP2
MSTORE
PUSH2 0x01aa
DUP2
PUSH2 0x044f
JUMP
JUMPDEST
DUP9
DUP11
MLOAD
SWAP8
PUSH2 0x01b7
DUP10
PUSH2 0x044f
JUMP
JUMPDEST
AND
DUP8
MSTORE
DUP6
DUP6
DUP9
ADD
MSTORE
DUP10
DUP8
ADD
MSTORE
DUP9
MLOAD
SWAP7
DUP10
DUP9
ADD
SWAP3
DUP9
DUP5
LT
SWAP1
DUP5
GT
OR
PUSH2 0x0322
JUMPI
POP
POP
DUP8
SWAP5
SWAP4
SWAP3
SWAP2
SWAP5
MSTORE
PUSH1 0x01
SWAP3
PUSH1 0x01
DUP7
MSTORE
DUP3
JUMPDEST
DUP3
DUP2
LT
PUSH2 0x02f3
JUMPI
POP
PUSH2 0x01f8
DUP7
PUSH2 0x049a
JUMP
JUMPDEST
MSTORE
PUSH2 0x0202
DUP6
PUSH2 0x049a
JUMP
JUMPDEST
POP
DUP7
MLOAD
SWAP6
DUP2
DUP8
ADD
SWAP3
DUP3
DUP9
MSTORE
DUP7
MLOAD
DUP1
SWAP5
MSTORE
DUP9
DUP9
ADD
SWAP1
DUP4
DUP11
DUP7
PUSH1 0x05
SHL
DUP12
ADD
ADD
SWAP9
ADD
SWAP7
DUP2
SWAP4
JUMPDEST
DUP7
DUP6
LT
PUSH2 0x0232
JUMPI
DUP11
DUP11
SUB
DUP12
RETURN
JUMPDEST
SWAP1
SWAP2
SWAP3
SWAP4
SWAP5
SWAP6
SWAP7
SWAP8
SWAP9
DUP9
DUP8
DUP3
DUP6
DUP16
DUP16
DUP16
SWAP1
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc0
SWAP1
DUP4
SWAP9
SUB
ADD
DUP12
MSTORE
MLOAD
DUP8
DUP2
MLOAD
AND
DUP5
MSTORE
DUP5
DUP2
ADD
MLOAD
DUP6
DUP6
ADD
MSTORE
ADD
MLOAD
SWAP5
DUP3
ADD
MSTORE
DUP4
MLOAD
SWAP4
DUP5
DUP8
DUP4
ADD
MSTORE
DUP8
JUMPDEST
DUP6
DUP2
LT
PUSH2 0x02db
JUMPI
POP
POP
SWAP3
DUP2
SWAP3
SWAP4
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0
PUSH1 0x1f
PUSH1 0x80
SWAP4
DUP11
DUP6
DUP3
DUP7
ADD
ADD
MSTORE
ADD
AND
ADD
ADD
SWAP12
ADD
SWAP6
ADD
SWAP6
ADD
SWAP4
SWAP8
SWAP7
SWAP6
SWAP5
SWAP3
SWAP2
SWAP1
PUSH2 0x0225
JUMP
JUMPDEST
DUP2
DUP2
ADD
DUP5
ADD
MLOAD
DUP4
DUP3
ADD
PUSH1 0x80
ADD
MSTORE
DUP14
SWAP5
POP
DUP12
SWAP4
ADD
PUSH2 0x028a
JUMP
JUMPDEST
SWAP2
DUP1
SWAP4
SWAP5
SWAP6
SWAP3
DUP10
MLOAD
PUSH2 0x0304
DUP2
PUSH2 0x044f
JUMP
JUMPDEST
DUP7
DUP2
MSTORE
DUP7
DUP4
DUP3
ADD
MSTORE
DUP5
DUP12
DUP3
ADD
MSTORE
DUP3
DUP3
DUP11
ADD
ADD
MSTORE
ADD
SWAP5
SWAP4
SWAP3
SWAP2
SWAP5
PUSH2 0x01e7
JUMP
JUMPDEST
PUSH1 0x41
DUP7
SWAP2
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
DUP4
MSTORE
MSTORE
REVERT
JUMPDEST
SWAP1
SWAP7
POP
DUP5
RETURNDATASIZE
DUP7
GT
PUSH2 0x03d9
JUMPI
JUMPDEST
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0
PUSH1 0x1f
DUP3
ADD
AND
DUP3
ADD
DUP3
DUP2
LT
DUP6
DUP3
GT
OR
PUSH2 0x03ae
JUMPI
DUP7
SWAP2
DUP4
SWAP2
DUP14
MSTORE
DUP2
ADD
SUB
SLT
PUSH2 0x03aa
JUMPI
MLOAD
DUP9
DUP2
AND
DUP2
SUB
PUSH2 0x03aa
JUMPI
SWAP6
CODESIZE
PUSH2 0x016e
JUMP
JUMPDEST
DUP6
DUP1
REVERT
JUMPDEST
DUP4
DUP9
PUSH1 0x41
DUP13
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
DUP4
MSTORE
MSTORE
REVERT
JUMPDEST
POP
RETURNDATASIZE
PUSH2 0x0358
JUMP
JUMPDEST
DUP11
MLOAD
RETURNDATASIZE
DUP9
DUP3
RETURNDATACOPY
RETURNDATASIZE
SWAP1
REVERT
JUMPDEST
DUP1
PUSH32 0x972777d000000000000000000000000000000000000000000000000000000000
DUP11
SWAP3
MSTORE
REVERT
JUMPDEST
POP
DUP5
PUSH1 0x32
DUP9
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
DUP4
MSTORE
MSTORE
REVERT
JUMPDEST
DUP7
DUP1
REVERT
JUMPDEST
DUP5
DUP1
REVERT
JUMPDEST
POP
DUP1
REVERT
JUMPDEST
DUP1
REVERT
JUMPDEST
DUP3
DUP1
REVERT
JUMPDEST
PUSH1 0x60
DUP2
ADD
SWAP1
DUP2
LT
PUSH8 0xffffffffffffffff
DUP3
GT
OR
PUSH2 0x046b
JUMPI
PUSH1 0x40
MSTORE
JUMP
JUMPDEST
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH1 0x00
MSTORE
PUSH1 0x41
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
JUMPDEST
DUP1
MLOAD
ISZERO
PUSH2 0x04a7
JUMPI
PUSH1 0x20
ADD
SWAP1
JUMP
JUMPDEST
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH1 0x00
MSTORE
PUSH1 0x32
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
'e3'(Unknown Opcode)
'4a'(Unknown Opcode)
'0f'(Unknown Opcode)
PUSH10 0x2044cb32d2b3082b87d1
'f9'(Unknown Opcode)
'0d'(Unknown Opcode)
'e2'(Unknown Opcode)
'f9'(Unknown Opcode)
GASPRICE
BASEFEE
'e1'(Unknown Opcode)
PUSH30 0x60f465f33cf74391aa3464736f6c63430008160033
