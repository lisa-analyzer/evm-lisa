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
PUSH4 0x8a4068dd
EQ
PUSH2 0x002d
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x0035
PUSH2 0x0037
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH1 0x01
PUSH0
SWAP1
SLOAD
SWAP1
PUSH2 0x0100
EXP
SWAP1
DIV
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
EQ
PUSH2 0x00c6
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x00bd
SWAP1
PUSH2 0x02d0
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
PUSH1 0x01
ISZERO
ISZERO
PUSH1 0x05
PUSH0
SWAP1
SLOAD
SWAP1
PUSH2 0x0100
EXP
SWAP1
DIV
PUSH1 0xff
AND
ISZERO
ISZERO
SUB
PUSH2 0x011b
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0112
SWAP1
PUSH2 0x0338
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
PUSH1 0x01
PUSH1 0x05
PUSH0
PUSH2 0x0100
EXP
DUP2
SLOAD
DUP2
PUSH1 0xff
MUL
NOT
AND
SWAP1
DUP4
ISZERO
ISZERO
MUL
OR
SWAP1
SSTORE
POP
PUSH1 0x03
SLOAD
PUSH1 0x04
SLOAD
PUSH2 0x0145
SWAP2
SWAP1
PUSH2 0x038c
JUMP
JUMPDEST
TIMESTAMP
LT
ISZERO
PUSH2 0x0187
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x017e
SWAP1
PUSH2 0x0409
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
PUSH0
DUP1
SLOAD
SWAP1
PUSH2 0x0100
EXP
SWAP1
DIV
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH4 0xa9059cbb
PUSH1 0x01
PUSH0
SWAP1
SLOAD
SWAP1
PUSH2 0x0100
EXP
SWAP1
DIV
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH1 0x02
SLOAD
PUSH1 0x40
MLOAD
DUP4
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0204
SWAP3
SWAP2
SWAP1
PUSH2 0x0475
JUMP
JUMPDEST
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH0
DUP8
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x0220
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
PUSH2 0x0244
SWAP2
SWAP1
PUSH2 0x04d5
JUMP
JUMPDEST
POP
PUSH1 0x03
SLOAD
PUSH1 0x04
SLOAD
PUSH2 0x0255
SWAP2
SWAP1
PUSH2 0x038c
JUMP
JUMPDEST
PUSH1 0x04
DUP2
SWAP1
SSTORE
POP
PUSH0
PUSH1 0x05
PUSH0
PUSH2 0x0100
EXP
DUP2
SLOAD
DUP2
PUSH1 0xff
MUL
NOT
AND
SWAP1
DUP4
ISZERO
ISZERO
MUL
OR
SWAP1
SSTORE
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
PUSH32 0x6f6e6c79206f776e65722063616e20646f20746869732e000000000000000000
PUSH0
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x02ba
PUSH1 0x17
DUP4
PUSH2 0x0276
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x02c5
DUP3
PUSH2 0x0286
JUMP
JUMPDEST
PUSH1 0x20
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
PUSH2 0x02e7
DUP2
PUSH2 0x02ae
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x4e6f205265656e7472616e63792e2e2e00000000000000000000000000000000
PUSH0
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x0322
PUSH1 0x10
DUP4
PUSH2 0x0276
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x032d
DUP3
PUSH2 0x02ee
JUMP
JUMPDEST
PUSH1 0x20
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
PUSH2 0x034f
DUP2
PUSH2 0x0316
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
DUP2
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
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
PUSH2 0x0396
DUP3
PUSH2 0x0356
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x03a1
DUP4
PUSH2 0x0356
JUMP
JUMPDEST
SWAP3
POP
DUP3
DUP3
ADD
SWAP1
POP
DUP1
DUP3
GT
ISZERO
PUSH2 0x03b9
JUMPI
PUSH2 0x03b8
PUSH2 0x035f
JUMP
JUMPDEST
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH32 0x63616e2774207472616e73666572207965742100000000000000000000000000
PUSH0
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x03f3
PUSH1 0x13
DUP4
PUSH2 0x0276
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x03fe
DUP3
PUSH2 0x03bf
JUMP
JUMPDEST
PUSH1 0x20
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
PUSH2 0x0420
DUP2
PUSH2 0x03e7
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
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
PUSH2 0x0450
DUP3
PUSH2 0x0427
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x0460
DUP2
PUSH2 0x0446
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH2 0x046f
DUP2
PUSH2 0x0356
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x40
DUP3
ADD
SWAP1
POP
PUSH2 0x0488
PUSH0
DUP4
ADD
DUP6
PUSH2 0x0457
JUMP
JUMPDEST
PUSH2 0x0495
PUSH1 0x20
DUP4
ADD
DUP5
PUSH2 0x0466
JUMP
JUMPDEST
SWAP4
SWAP3
POP
POP
POP
JUMP
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH0
DUP2
ISZERO
ISZERO
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x04b4
DUP2
PUSH2 0x04a0
JUMP
JUMPDEST
DUP2
EQ
PUSH2 0x04be
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
MLOAD
SWAP1
POP
PUSH2 0x04cf
DUP2
PUSH2 0x04ab
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
PUSH2 0x04ea
JUMPI
PUSH2 0x04e9
PUSH2 0x049c
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x04f7
DUP5
DUP3
DUP6
ADD
PUSH2 0x04c1
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
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
'4d'(Unknown Opcode)
'b0'(Unknown Opcode)
ADDRESS
SHR
'c6'(Unknown Opcode)
TIMESTAMP
SUB
'c6'(Unknown Opcode)
PUSH6 0x552f5c13f0a2
'e6'(Unknown Opcode)
PUSH3 0xa2ff49
PUSH23 0x99805e45a0806c6ae35b3b64736f6c63430008190033
