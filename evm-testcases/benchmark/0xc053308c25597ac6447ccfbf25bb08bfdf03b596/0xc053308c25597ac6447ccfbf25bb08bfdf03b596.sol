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
PUSH2 0x0060
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x0cdf9008
EQ
PUSH2 0x0064
JUMPI
DUP1
PUSH4 0x46a1a095
EQ
PUSH2 0x0080
JUMPI
DUP1
PUSH4 0x73b4dd53
EQ
PUSH2 0x00a4
JUMPI
DUP1
PUSH4 0xabef9ba1
EQ
PUSH2 0x00b9
JUMPI
DUP1
PUSH4 0xd6f48dc1
EQ
PUSH2 0x00cc
JUMPI
DUP1
PUSH4 0xf851a440
EQ
PUSH2 0x00eb
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x006d
PUSH1 0x02
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
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0093
PUSH2 0x008e
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0475
JUMP
JUMPDEST
PUSH2 0x0116
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0077
SWAP6
SWAP5
SWAP4
SWAP3
SWAP2
SWAP1
PUSH2 0x04ba
JUMP
JUMPDEST
PUSH2 0x00b7
PUSH2 0x00b2
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0475
JUMP
JUMPDEST
PUSH2 0x01ea
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x00b7
PUSH2 0x00c7
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0510
JUMP
JUMPDEST
PUSH2 0x030b
JUMP
JUMPDEST
PUSH2 0x006d
PUSH2 0x00da
CALLDATASIZE
PUSH1 0x04
PUSH2 0x05bf
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x20
MSTORE
PUSH0
SWAP1
DUP2
MSTORE
PUSH1 0x40
SWAP1
SHA3
SLOAD
DUP2
JUMP
JUMPDEST
PUSH1 0x03
SLOAD
PUSH2 0x00fe
SWAP1
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP2
AND
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH2 0x0077
JUMP
JUMPDEST
PUSH0
DUP2
DUP2
SLOAD
DUP2
LT
PUSH2 0x0124
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
PUSH0
SWAP2
DUP3
MSTORE
PUSH1 0x20
SWAP1
SWAP2
SHA3
PUSH1 0x05
SWAP1
SWAP2
MUL
ADD
DUP1
SLOAD
PUSH1 0x01
DUP3
ADD
SLOAD
PUSH1 0x02
DUP4
ADD
DUP1
SLOAD
SWAP3
SWAP5
POP
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP2
AND
SWAP3
SWAP2
PUSH2 0x0159
SWAP1
PUSH2 0x05ec
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
PUSH2 0x0185
SWAP1
PUSH2 0x05ec
JUMP
JUMPDEST
DUP1
ISZERO
PUSH2 0x01d0
JUMPI
DUP1
PUSH1 0x1f
LT
PUSH2 0x01a7
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
PUSH2 0x01d0
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
PUSH2 0x01b3
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
PUSH1 0x03
DUP4
ADD
SLOAD
PUSH1 0x04
SWAP1
SWAP4
ADD
SLOAD
SWAP2
SWAP3
SWAP2
PUSH1 0xff
AND
SWAP1
POP
DUP6
JUMP
JUMPDEST
PUSH1 0x03
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
CALLER
EQ
PUSH2 0x023a
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
PUSH1 0x0e
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH14 0x139bdd08185d5d1a1bdc9a5e9959
PUSH1 0x92
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
DUP1
PUSH2 0x0247
PUSH1 0x01
DUP5
PUSH2 0x0638
JUMP
JUMPDEST
DUP2
SLOAD
DUP2
LT
PUSH2 0x0257
JUMPI
PUSH2 0x0257
PUSH2 0x0651
JUMP
JUMPDEST
PUSH0
SWAP2
DUP3
MSTORE
PUSH1 0x20
SWAP1
SWAP2
SHA3
PUSH1 0x05
SWAP1
SWAP2
MUL
ADD
PUSH1 0x04
DUP2
ADD
SLOAD
SWAP1
SWAP2
POP
PUSH1 0xff
AND
ISZERO
PUSH2 0x02be
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
PUSH1 0x18
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x496e74656e7420616c72656164792066756c66696c6c65640000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0231
JUMP
JUMPDEST
PUSH1 0x04
DUP2
ADD
DUP1
SLOAD
PUSH1 0xff
NOT
AND
PUSH1 0x01
OR
SWAP1
SSTORE
PUSH1 0x40
MLOAD
PUSH32 0x513c134af77fc067dedbd02f0f0f923cf76a42245822414e189cc5ce70f1670b
SWAP1
PUSH2 0x02ff
SWAP1
DUP5
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG1
POP
POP
JUMP
JUMPDEST
PUSH1 0x02
DUP1
SLOAD
SWAP1
PUSH0
PUSH2 0x031a
DUP4
PUSH2 0x0665
JUMP
JUMPDEST
SWAP1
SWAP2
SSTORE
POP
POP
PUSH1 0x40
DUP1
MLOAD
PUSH1 0xa0
DUP2
ADD
DUP3
MSTORE
PUSH1 0x02
SLOAD
DUP2
MSTORE
CALLER
PUSH1 0x20
DUP3
ADD
SWAP1
DUP2
MSTORE
SWAP2
DUP2
ADD
DUP5
DUP2
MSTORE
PUSH1 0x60
DUP3
ADD
DUP5
SWAP1
MSTORE
PUSH0
PUSH1 0x80
DUP4
ADD
DUP2
SWAP1
MSTORE
DUP1
SLOAD
PUSH1 0x01
DUP2
ADD
DUP3
SSTORE
SWAP1
DUP1
MSTORE
DUP3
MLOAD
PUSH32 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
PUSH1 0x05
SWAP1
SWAP3
MUL
SWAP2
DUP3
ADD
SWAP1
DUP2
SSTORE
SWAP4
MLOAD
PUSH32 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e564
DUP3
ADD
DUP1
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
NOT
AND
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP3
AND
SWAP2
SWAP1
SWAP2
OR
SWAP1
SSTORE
SWAP1
MLOAD
SWAP2
SWAP3
SWAP2
PUSH32 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e565
SWAP1
SWAP2
ADD
SWAP1
PUSH2 0x03fa
SWAP1
DUP3
PUSH2 0x06c9
JUMP
JUMPDEST
POP
PUSH1 0x60
DUP3
ADD
MLOAD
PUSH1 0x03
DUP3
ADD
SSTORE
PUSH1 0x80
SWAP1
SWAP2
ADD
MLOAD
PUSH1 0x04
SWAP1
SWAP2
ADD
DUP1
SLOAD
PUSH1 0xff
NOT
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
CALLER
PUSH0
SWAP1
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x20
MSTORE
PUSH1 0x40
DUP2
SHA3
DUP1
SLOAD
SWAP2
PUSH2 0x0439
DUP4
PUSH2 0x0665
JUMP
JUMPDEST
SWAP2
SWAP1
POP
SSTORE
POP
PUSH32 0x8ea7d25b9dddca0d80c87da913e17833198553a62aaeda4c0ccc997b0c4e1d6f
PUSH1 0x02
SLOAD
CALLER
DUP5
DUP5
PUSH1 0x40
MLOAD
PUSH2 0x02ff
SWAP5
SWAP4
SWAP3
SWAP2
SWAP1
PUSH2 0x0789
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0485
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
PUSH0
DUP2
MLOAD
DUP1
DUP5
MSTORE
DUP1
PUSH1 0x20
DUP5
ADD
PUSH1 0x20
DUP7
ADD
'5e'(Unknown Opcode)
PUSH0
PUSH1 0x20
DUP3
DUP7
ADD
ADD
MSTORE
PUSH1 0x20
PUSH1 0x1f
NOT
PUSH1 0x1f
DUP4
ADD
AND
DUP6
ADD
ADD
SWAP2
POP
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
DUP6
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP6
AND
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0xa0
PUSH1 0x40
DUP3
ADD
DUP2
SWAP1
MSTORE
PUSH0
SWAP1
PUSH2 0x04e3
SWAP1
DUP4
ADD
DUP7
PUSH2 0x048c
JUMP
JUMPDEST
PUSH1 0x60
DUP4
ADD
SWAP5
SWAP1
SWAP5
MSTORE
POP
SWAP1
ISZERO
ISZERO
PUSH1 0x80
SWAP1
SWAP2
ADD
MSTORE
SWAP4
SWAP3
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
DUP1
PUSH1 0x40
DUP4
DUP6
SUB
SLT
ISZERO
PUSH2 0x0521
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
PUSH2 0x0538
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
PUSH2 0x054b
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
PUSH2 0x055d
JUMPI
PUSH2 0x055d
PUSH2 0x04fc
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
PUSH2 0x0585
JUMPI
PUSH2 0x0585
PUSH2 0x04fc
JUMP
JUMPDEST
DUP2
PUSH1 0x40
MSTORE
DUP3
DUP2
MSTORE
DUP9
PUSH1 0x20
DUP5
DUP8
ADD
ADD
GT
ISZERO
PUSH2 0x059d
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
PUSH1 0x20
SWAP4
DUP3
ADD
DUP5
ADD
MSTORE
SWAP9
SWAP7
SWAP1
SWAP2
ADD
CALLDATALOAD
SWAP7
POP
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
PUSH2 0x05cf
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
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
PUSH2 0x05e5
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
SWAP4
SWAP3
POP
POP
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
PUSH2 0x0600
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
PUSH2 0x061e
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
DUP2
DUP2
SUB
DUP2
DUP2
GT
ISZERO
PUSH2 0x064b
JUMPI
PUSH2 0x064b
PUSH2 0x0624
JUMP
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
JUMPDEST
PUSH0
PUSH1 0x01
DUP3
ADD
PUSH2 0x0676
JUMPI
PUSH2 0x0676
PUSH2 0x0624
JUMP
JUMPDEST
POP
PUSH1 0x01
ADD
SWAP1
JUMP
JUMPDEST
PUSH1 0x1f
DUP3
GT
ISZERO
PUSH2 0x06c4
JUMPI
DUP1
PUSH0
MSTORE
PUSH1 0x20
PUSH0
SHA3
PUSH1 0x1f
DUP5
ADD
PUSH1 0x05
SHR
DUP2
ADD
PUSH1 0x20
DUP6
LT
ISZERO
PUSH2 0x06a2
JUMPI
POP
DUP1
JUMPDEST
PUSH1 0x1f
DUP5
ADD
PUSH1 0x05
SHR
DUP3
ADD
SWAP2
POP
JUMPDEST
DUP2
DUP2
LT
ISZERO
PUSH2 0x06c1
JUMPI
PUSH0
DUP2
SSTORE
PUSH1 0x01
ADD
PUSH2 0x06ae
JUMP
JUMPDEST
POP
POP
JUMPDEST
POP
POP
POP
JUMP
JUMPDEST
DUP2
MLOAD
PUSH8 0xffffffffffffffff
DUP2
GT
ISZERO
PUSH2 0x06e3
JUMPI
PUSH2 0x06e3
PUSH2 0x04fc
JUMP
JUMPDEST
PUSH2 0x06f7
DUP2
PUSH2 0x06f1
DUP5
SLOAD
PUSH2 0x05ec
JUMP
JUMPDEST
DUP5
PUSH2 0x067d
JUMP
JUMPDEST
PUSH1 0x20
DUP1
PUSH1 0x1f
DUP4
GT
PUSH1 0x01
DUP2
EQ
PUSH2 0x072a
JUMPI
PUSH0
DUP5
ISZERO
PUSH2 0x0713
JUMPI
POP
DUP6
DUP4
ADD
MLOAD
JUMPDEST
PUSH0
NOT
PUSH1 0x03
DUP7
SWAP1
SHL
SHR
NOT
AND
PUSH1 0x01
DUP6
SWAP1
SHL
OR
DUP6
SSTORE
PUSH2 0x0781
JUMP
JUMPDEST
PUSH0
DUP6
DUP2
MSTORE
PUSH1 0x20
DUP2
SHA3
PUSH1 0x1f
NOT
DUP7
AND
SWAP2
JUMPDEST
DUP3
DUP2
LT
ISZERO
PUSH2 0x0758
JUMPI
DUP9
DUP7
ADD
MLOAD
DUP3
SSTORE
SWAP5
DUP5
ADD
SWAP5
PUSH1 0x01
SWAP1
SWAP2
ADD
SWAP1
DUP5
ADD
PUSH2 0x0739
JUMP
JUMPDEST
POP
DUP6
DUP3
LT
ISZERO
PUSH2 0x0775
JUMPI
DUP8
DUP6
ADD
MLOAD
PUSH0
NOT
PUSH1 0x03
DUP9
SWAP1
SHL
PUSH1 0xf8
AND
SHR
NOT
AND
DUP2
SSTORE
JUMPDEST
POP
POP
PUSH1 0x01
DUP5
PUSH1 0x01
SHL
ADD
DUP6
SSTORE
JUMPDEST
POP
POP
POP
POP
POP
POP
JUMP
JUMPDEST
DUP5
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP5
AND
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0x80
PUSH1 0x40
DUP3
ADD
DUP2
SWAP1
MSTORE
PUSH0
SWAP1
PUSH2 0x07b2
SWAP1
DUP4
ADD
DUP6
PUSH2 0x048c
JUMP
JUMPDEST
SWAP1
POP
DUP3
PUSH1 0x60
DUP4
ADD
MSTORE
SWAP6
SWAP5
POP
POP
POP
POP
POP
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
BALANCE
'cd'(Unknown Opcode)
BASEFEE
DIFFICULTY
NOT
PUSH20 0x3d4298b0f5079a114dbad7cf7712f6214956353e
PUSH25 0xda419e292164736f6c63430008190033