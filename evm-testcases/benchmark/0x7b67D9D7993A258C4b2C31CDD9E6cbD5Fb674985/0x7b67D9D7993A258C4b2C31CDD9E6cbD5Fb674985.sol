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
PUSH2 0x0072
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x9acdec25
GT
PUSH2 0x0050
JUMPI
DUP1
PUSH4 0x9acdec25
EQ
PUSH2 0x010f
JUMPI
DUP1
PUSH4 0xb268777f
EQ
PUSH2 0x0132
JUMPI
DUP1
PUSH4 0xc579d490
EQ
PUSH2 0x0145
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
PUSH4 0x27f99a5d
EQ
PUSH2 0x0077
JUMPI
DUP1
PUSH4 0x41c0e1b5
EQ
PUSH2 0x00c5
JUMPI
DUP1
PUSH4 0x8cedca71
EQ
PUSH2 0x00cf
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x00b0
PUSH2 0x0085
CALLDATASIZE
PUSH1 0x04
PUSH2 0x084a
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x20
DUP2
SWAP1
MSTORE
PUSH1 0x40
SWAP1
SHA3
SLOAD
PUSH1 0xff
AND
SWAP1
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
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x00cd
PUSH2 0x0158
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x00ea
PUSH20 0xccf3d848e08b94478ed8f46ffead3008faf581fd
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP2
AND
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH2 0x00bc
JUMP
JUMPDEST
PUSH2 0x00b0
PUSH2 0x011d
CALLDATASIZE
PUSH1 0x04
PUSH2 0x084a
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP2
SWAP1
MSTORE
SWAP1
DUP2
MSTORE
PUSH1 0x40
SWAP1
SHA3
SLOAD
PUSH1 0xff
AND
DUP2
JUMP
JUMPDEST
PUSH2 0x00cd
PUSH2 0x0140
CALLDATASIZE
PUSH1 0x04
PUSH2 0x087c
JUMP
JUMPDEST
PUSH2 0x0242
JUMP
JUMPDEST
PUSH2 0x00cd
PUSH2 0x0153
CALLDATASIZE
PUSH1 0x04
PUSH2 0x08b5
JUMP
JUMPDEST
PUSH2 0x03cc
JUMP
JUMPDEST
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xccf3d848e08b94478ed8f46ffead3008faf581fd
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH4 0xf851a440
PUSH1 0x40
MLOAD
DUP2
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP7
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x01ce
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
PUSH2 0x01f2
SWAP2
SWAP1
PUSH2 0x08f6
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
EQ
PUSH2 0x023f
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0xa6c827a900000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
CALLER
SELFDESTRUCT
JUMPDEST
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xccf3d848e08b94478ed8f46ffead3008faf581fd
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH4 0x8da5cb5b
PUSH1 0x40
MLOAD
DUP2
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP7
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x02b8
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
PUSH2 0x02dc
SWAP2
SWAP1
PUSH2 0x08f6
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
EQ
PUSH2 0x0329
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x19494c8a00000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP3
AND
PUSH2 0x0376
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0xc440e09400000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP2
SWAP1
SWAP2
AND
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x20
DUP2
SWAP1
MSTORE
PUSH1 0x40
SWAP1
SHA3
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
AND
SWAP2
ISZERO
ISZERO
SWAP2
SWAP1
SWAP2
OR
SWAP1
SSTORE
JUMP
JUMPDEST
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xccf3d848e08b94478ed8f46ffead3008faf581fd
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH4 0x8da5cb5b
PUSH1 0x40
MLOAD
DUP2
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP7
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x0442
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
PUSH2 0x0466
SWAP2
SWAP1
PUSH2 0x08f6
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
EQ
PUSH2 0x04b3
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x19494c8a00000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH20 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP5
AND
EQ
ISZERO
PUSH2 0x052e
JUMPI
PUSH1 0x40
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP4
AND
SWAP1
DUP3
ISZERO
PUSH2 0x08fc
MUL
SWAP1
DUP4
SWAP1
PUSH1 0x00
DUP2
DUP2
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
PUSH2 0x0528
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
POP
JUMP
JUMPDEST
PUSH2 0x054f
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP5
AND
DUP4
DUP4
PUSH2 0x0554
JUMP
JUMPDEST
POP
POP
POP
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP5
DUP2
AND
PUSH1 0x24
DUP4
ADD
MSTORE
PUSH1 0x44
DUP1
DUP4
ADD
DUP6
SWAP1
MSTORE
DUP4
MLOAD
DUP1
DUP5
SUB
SWAP1
SWAP2
ADD
DUP2
MSTORE
PUSH1 0x64
SWAP1
SWAP3
ADD
DUP4
MSTORE
PUSH1 0x20
DUP1
DUP4
ADD
DUP1
MLOAD
PUSH28 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0xa9059cbb00000000000000000000000000000000000000000000000000000000
OR
SWAP1
MSTORE
DUP4
MLOAD
DUP1
DUP6
ADD
SWAP1
SWAP5
MSTORE
DUP1
DUP5
MSTORE
PUSH32 0x5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c6564
SWAP1
DUP5
ADD
MSTORE
PUSH2 0x054f
SWAP3
DUP7
SWAP3
SWAP2
PUSH1 0x00
SWAP2
PUSH2 0x061f
SWAP2
DUP6
AND
SWAP1
DUP5
SWAP1
PUSH2 0x06d1
JUMP
JUMPDEST
SWAP1
POP
DUP1
MLOAD
PUSH1 0x00
EQ
DUP1
PUSH2 0x0640
JUMPI
POP
DUP1
DUP1
PUSH1 0x20
ADD
SWAP1
MLOAD
DUP2
ADD
SWAP1
PUSH2 0x0640
SWAP2
SWAP1
PUSH2 0x0913
JUMP
JUMPDEST
PUSH2 0x054f
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
PUSH1 0x2a
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x5361666545524332303a204552433230206f7065726174696f6e20646964206e
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH32 0x6f74207375636365656400000000000000000000000000000000000000000000
PUSH1 0x64
DUP3
ADD
MSTORE
PUSH1 0x84
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
PUSH1 0x60
PUSH2 0x06e0
DUP5
DUP5
PUSH1 0x00
DUP6
PUSH2 0x06e8
JUMP
JUMPDEST
SWAP5
SWAP4
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH1 0x60
PUSH2 0x06f3
DUP6
PUSH2 0x07ec
JUMP
JUMPDEST
PUSH2 0x0729
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x304619b500000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x00
DUP1
DUP7
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP6
DUP8
PUSH1 0x40
MLOAD
PUSH2 0x0752
SWAP2
SWAP1
PUSH2 0x095c
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP6
DUP8
GAS
CALL
SWAP3
POP
POP
POP
RETURNDATASIZE
DUP1
PUSH1 0x00
DUP2
EQ
PUSH2 0x078f
JUMPI
PUSH1 0x40
MLOAD
SWAP2
POP
PUSH1 0x1f
NOT
PUSH1 0x3f
RETURNDATASIZE
ADD
AND
DUP3
ADD
PUSH1 0x40
MSTORE
RETURNDATASIZE
DUP3
MSTORE
RETURNDATASIZE
PUSH1 0x00
PUSH1 0x20
DUP5
ADD
RETURNDATACOPY
PUSH2 0x0794
JUMP
JUMPDEST
PUSH1 0x60
SWAP2
POP
JUMPDEST
POP
SWAP2
POP
SWAP2
POP
DUP2
ISZERO
PUSH2 0x07a8
JUMPI
SWAP2
POP
PUSH2 0x06e0
SWAP1
POP
JUMP
JUMPDEST
DUP1
MLOAD
ISZERO
PUSH2 0x07b8
JUMPI
DUP1
MLOAD
DUP1
DUP3
PUSH1 0x20
ADD
REVERT
JUMPDEST
DUP4
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x06c8
SWAP2
SWAP1
PUSH2 0x0978
JUMP
JUMPDEST
PUSH1 0x00
DUP2
EXTCODEHASH
PUSH32 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
DUP2
DUP2
EQ
DUP1
ISZERO
SWAP1
PUSH2 0x06e0
JUMPI
POP
POP
ISZERO
ISZERO
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP2
AND
DUP2
EQ
PUSH2 0x0847
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
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
PUSH2 0x085c
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
PUSH2 0x0867
DUP2
PUSH2 0x0825
JUMP
JUMPDEST
SWAP4
SWAP3
POP
POP
POP
JUMP
JUMPDEST
DUP1
ISZERO
ISZERO
DUP2
EQ
PUSH2 0x0847
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x00
DUP1
PUSH1 0x40
DUP4
DUP6
SUB
SLT
ISZERO
PUSH2 0x088f
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP3
CALLDATALOAD
PUSH2 0x089a
DUP2
PUSH2 0x0825
JUMP
JUMPDEST
SWAP2
POP
PUSH1 0x20
DUP4
ADD
CALLDATALOAD
PUSH2 0x08aa
DUP2
PUSH2 0x086e
JUMP
JUMPDEST
DUP1
SWAP2
POP
POP
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
PUSH1 0x60
DUP5
DUP7
SUB
SLT
ISZERO
PUSH2 0x08ca
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP4
CALLDATALOAD
PUSH2 0x08d5
DUP2
PUSH2 0x0825
JUMP
JUMPDEST
SWAP3
POP
PUSH1 0x20
DUP5
ADD
CALLDATALOAD
PUSH2 0x08e5
DUP2
PUSH2 0x0825
JUMP
JUMPDEST
SWAP3
SWAP6
SWAP3
SWAP5
POP
POP
POP
PUSH1 0x40
SWAP2
SWAP1
SWAP2
ADD
CALLDATALOAD
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0908
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
MLOAD
PUSH2 0x0867
DUP2
PUSH2 0x0825
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0925
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
MLOAD
PUSH2 0x0867
DUP2
PUSH2 0x086e
JUMP
JUMPDEST
PUSH1 0x00
JUMPDEST
DUP4
DUP2
LT
ISZERO
PUSH2 0x094b
JUMPI
DUP2
DUP2
ADD
MLOAD
DUP4
DUP3
ADD
MSTORE
PUSH1 0x20
ADD
PUSH2 0x0933
JUMP
JUMPDEST
DUP4
DUP2
GT
ISZERO
PUSH2 0x0528
JUMPI
POP
POP
PUSH1 0x00
SWAP2
ADD
MSTORE
JUMP
JUMPDEST
PUSH1 0x00
DUP3
MLOAD
PUSH2 0x096e
DUP2
DUP5
PUSH1 0x20
DUP8
ADD
PUSH2 0x0930
JUMP
JUMPDEST
SWAP2
SWAP1
SWAP2
ADD
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH1 0x20
DUP2
MSTORE
PUSH1 0x00
DUP3
MLOAD
DUP1
PUSH1 0x20
DUP5
ADD
MSTORE
PUSH2 0x0997
DUP2
PUSH1 0x40
DUP6
ADD
PUSH1 0x20
DUP8
ADD
PUSH2 0x0930
JUMP
JUMPDEST
PUSH1 0x1f
ADD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0
AND
SWAP2
SWAP1
SWAP2
ADD
PUSH1 0x40
ADD
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
RETURN
BASEFEE
'e0'(Unknown Opcode)
LOG1
PUSH9 0xc2f5b5aee93c5ed996
'ec'(Unknown Opcode)
PUSH9 0x3ce4a6f172c3334fbe
PUSH15 0x58bcf431c50964736f6c634300080a
STOP
CALLER
