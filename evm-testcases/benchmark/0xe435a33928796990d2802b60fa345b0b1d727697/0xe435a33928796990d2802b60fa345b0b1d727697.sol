PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x002d
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x4c0925aa
EQ
PUSH2 0x017b
JUMPI
DUP1
PUSH4 0xd5678321
EQ
PUSH2 0x01a6
JUMPI
PUSH2 0x0176
JUMP
JUMPDEST
CALLDATASIZE
PUSH2 0x0176
JUMPI
PUSH1 0x00
CALLVALUE
GT
PUSH2 0x0075
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x006c
SWAP1
PUSH2 0x02ab
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
PUSH1 0x00
PUSH1 0x64
PUSH1 0x5a
CALLVALUE
PUSH2 0x0086
SWAP2
SWAP1
PUSH2 0x030d
JUMP
JUMPDEST
PUSH2 0x0090
SWAP2
SWAP1
PUSH2 0x02dc
JUMP
JUMPDEST
SWAP1
POP
PUSH1 0x00
DUP2
CALLVALUE
PUSH2 0x00a0
SWAP2
SWAP1
PUSH2 0x0367
JUMP
JUMPDEST
SWAP1
POP
PUSH1 0x00
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
PUSH2 0x08fc
DUP4
SWAP1
DUP2
ISZERO
MUL
SWAP1
PUSH1 0x40
MLOAD
PUSH1 0x00
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
PUSH2 0x0108
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
PUSH1 0x01
PUSH1 0x00
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
PUSH2 0x08fc
DUP3
SWAP1
DUP2
ISZERO
MUL
SWAP1
PUSH1 0x40
MLOAD
PUSH1 0x00
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
PUSH2 0x0171
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
STOP
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0187
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0190
PUSH2 0x01d1
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x019d
SWAP2
SWAP1
PUSH2 0x0290
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
CALLVALUE
DUP1
ISZERO
PUSH2 0x01b2
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x01bb
PUSH2 0x01f5
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x01c8
SWAP2
SWAP1
PUSH2 0x0290
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
PUSH1 0x00
DUP1
SLOAD
SWAP1
PUSH2 0x0100
EXP
SWAP1
DIV
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x00
SWAP1
SLOAD
SWAP1
PUSH2 0x0100
EXP
SWAP1
DIV
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
JUMP
JUMPDEST
PUSH2 0x0224
DUP2
PUSH2 0x039b
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH2 0x0237
PUSH1 0x36
DUP4
PUSH2 0x02cb
JUMP
JUMPDEST
SWAP2
POP
PUSH32 0x5061796d656e7453706c69747465723a205061796d656e7420616d6f756e7420
PUSH1 0x00
DUP4
ADD
MSTORE
PUSH32 0x6d7573742062652067726561746572207468616e203000000000000000000000
PUSH1 0x20
DUP4
ADD
MSTORE
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
PUSH1 0x00
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x02a5
PUSH1 0x00
DUP4
ADD
DUP5
PUSH2 0x021b
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
ADD
SWAP1
POP
DUP2
DUP2
SUB
PUSH1 0x00
DUP4
ADD
MSTORE
PUSH2 0x02c4
DUP2
PUSH2 0x022a
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH1 0x00
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
PUSH1 0x00
PUSH2 0x02e7
DUP3
PUSH2 0x03cd
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x02f2
DUP4
PUSH2 0x03cd
JUMP
JUMPDEST
SWAP3
POP
DUP3
PUSH2 0x0302
JUMPI
PUSH2 0x0301
PUSH2 0x0406
JUMP
JUMPDEST
JUMPDEST
DUP3
DUP3
DIV
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH2 0x0318
DUP3
PUSH2 0x03cd
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x0323
DUP4
PUSH2 0x03cd
JUMP
JUMPDEST
SWAP3
POP
DUP2
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
DIV
DUP4
GT
DUP3
ISZERO
ISZERO
AND
ISZERO
PUSH2 0x035c
JUMPI
PUSH2 0x035b
PUSH2 0x03d7
JUMP
JUMPDEST
JUMPDEST
DUP3
DUP3
MUL
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH2 0x0372
DUP3
PUSH2 0x03cd
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x037d
DUP4
PUSH2 0x03cd
JUMP
JUMPDEST
SWAP3
POP
DUP3
DUP3
LT
ISZERO
PUSH2 0x0390
JUMPI
PUSH2 0x038f
PUSH2 0x03d7
JUMP
JUMPDEST
JUMPDEST
DUP3
DUP3
SUB
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH2 0x03a6
DUP3
PUSH2 0x03ad
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH1 0x00
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
PUSH1 0x00
DUP2
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
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
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH1 0x00
MSTORE
PUSH1 0x12
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
INVALID
SELFDESTRUCT
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
'd6'(Unknown Opcode)
CALLVALUE
'd9'(Unknown Opcode)
'22'(Unknown Opcode)
'c5'(Unknown Opcode)
'4e'(Unknown Opcode)
PUSH14 0x3dcaf7e654b023b7f6d3b37d4ba6
'4b'(Unknown Opcode)
'f7'(Unknown Opcode)
PUSH19 0xdb4e697f4f6d383364736f6c63430008000033
