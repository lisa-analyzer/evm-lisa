PUSH1 0x80
PUSH1 0x40
DUP2
DUP2
MSTORE
PUSH1 0x04
SWAP2
DUP3
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
SWAP3
DUP4
CALLDATALOAD
PUSH1 0xe0
SHR
SWAP2
DUP3
PUSH4 0x06fdde03
EQ
PUSH2 0x0625
JUMPI
POP
DUP2
PUSH4 0x2e0f2625
EQ
PUSH2 0x0609
JUMPI
DUP2
PUSH4 0x6f16a595
EQ
PUSH2 0x05ce
JUMPI
DUP2
PUSH4 0x70c52508
EQ
PUSH2 0x059f
JUMPI
DUP2
PUSH4 0x76d975cb
EQ
PUSH2 0x0570
JUMPI
DUP2
PUSH4 0xbd9a548b
EQ
PUSH2 0x00af
JUMPI
POP
PUSH4 0xc6d3107f
EQ
PUSH2 0x0072
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
CALLVALUE
PUSH2 0x00ab
JUMPI
DUP2
PUSH1 0x03
NOT
CALLDATASIZE
ADD
SLT
PUSH2 0x00ab
JUMPI
PUSH1 0x20
SWAP1
MLOAD
PUSH32 0x0000000000000000000000000000000000000000000000000000000000015180
DUP2
MSTORE
RETURN
JUMPDEST
POP
DUP1
REVERT
JUMPDEST
DUP4
DUP4
CALLVALUE
PUSH2 0x00ab
JUMPI
DUP2
PUSH1 0x03
NOT
CALLDATASIZE
ADD
SLT
PUSH2 0x00ab
JUMPI
DUP1
MLOAD
SWAP1
PUSH32 0x86fc88d300000000000000000000000000000000000000000000000000000000
DUP1
DUP4
MSTORE
PUSH1 0x20
SWAP3
DUP4
DUP2
DUP8
DUP2
PUSH20 0x1681195c176239ac5e72d9aebacf5b2492e0c4ee
GAS
STATICCALL
SWAP1
DUP2
ISZERO
PUSH2 0x0566
JUMPI
DUP6
SWAP2
PUSH2 0x0535
JUMPI
JUMPDEST
POP
DUP1
ISZERO
PUSH2 0x0522
JUMPI
PUSH15 0xc097ce7bc90715b34b9f1000000000
DIV
DUP3
MLOAD
SWAP1
PUSH32 0xfeaf968c00000000000000000000000000000000000000000000000000000000
DUP1
DUP4
MSTORE
PUSH1 0xa0
SWAP1
DUP2
DUP5
DUP11
DUP2
PUSH20 0xeef0c605546958c1f899b6fb336c20671f9cd49f
GAS
STATICCALL
DUP1
ISZERO
PUSH2 0x04b0
JUMPI
DUP9
SWAP5
DUP10
SWAP2
PUSH2 0x04fc
JUMPI
JUMPDEST
POP
DUP9
DUP6
SGT
SWAP1
DUP2
ISZERO
SWAP2
PUSH2 0x04c9
JUMPI
JUMPDEST
POP
PUSH2 0x04ba
JUMPI
DUP6
MLOAD
SWAP1
DUP2
MSTORE
DUP2
DUP2
DUP11
DUP2
PUSH20 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
GAS
STATICCALL
SWAP1
DUP2
ISZERO
PUSH2 0x04b0
JUMPI
DUP9
SWAP3
DUP10
SWAP3
PUSH2 0x047a
JUMPI
JUMPDEST
POP
POP
DUP8
DUP3
SGT
SWAP1
DUP2
ISZERO
SWAP2
PUSH2 0x0447
JUMPI
JUMPDEST
POP
PUSH2 0x0438
JUMPI
PUSH8 0x0de0b6b3a7640000
SWAP3
DUP4
DUP2
MUL
SWAP1
DUP1
DUP3
DIV
DUP6
EQ
SWAP1
ISZERO
OR
ISZERO
PUSH2 0x0425
JUMPI
SWAP1
PUSH2 0x01fa
SWAP2
PUSH2 0x07c9
JUMP
JUMPDEST
DUP1
DUP3
LT
ISZERO
PUSH2 0x041d
JUMPI
POP
SWAP2
JUMPDEST
DUP4
MLOAD
SWAP1
DUP2
MSTORE
PUSH20 0x3de254a0f838a844f727fee81040e0fa7884b935
SWAP1
DUP6
DUP2
DUP10
DUP2
DUP6
GAS
STATICCALL
SWAP1
DUP2
ISZERO
PUSH2 0x03a1
JUMPI
DUP4
DUP10
SWAP3
DUP9
SWAP3
DUP11
SWAP2
PUSH2 0x03eb
JUMPI
JUMPDEST
POP
DUP7
DUP3
DUP3
LT
ISZERO
PUSH2 0x03e0
JUMPI
PUSH2 0x024d
SWAP2
PUSH2 0x07a0
JUMP
JUMPDEST
DIV
SWAP3
DUP7
MLOAD
SWAP3
DUP4
DUP1
SWAP3
PUSH32 0xbb7b8b8000000000000000000000000000000000000000000000000000000000
DUP3
MSTORE
GAS
STATICCALL
SWAP1
DUP2
ISZERO
PUSH2 0x03a1
JUMPI
SWAP1
DUP4
SWAP3
SWAP2
DUP9
SWAP2
PUSH2 0x03ab
JUMPI
JUMPDEST
POP
SWAP1
PUSH2 0x0297
SWAP2
PUSH2 0x07a0
JUMP
JUMPDEST
DIV
DUP4
MLOAD
PUSH32 0x99530b0600000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
DUP6
DUP2
DUP10
DUP2
PUSH20 0xd901dcf4948a29d7d9d7e015aaf61591825ac267
GAS
STATICCALL
SWAP1
DUP2
ISZERO
PUSH2 0x03a1
JUMPI
SWAP1
DUP4
SWAP2
DUP9
SWAP2
PUSH2 0x036a
JUMPI
JUMPDEST
POP
PUSH2 0x02f4
SWAP2
SWAP3
PUSH2 0x07a0
JUMP
JUMPDEST
DIV
SWAP2
DUP2
DUP2
MUL
SWAP2
DUP2
DUP4
DIV
EQ
SWAP1
ISZERO
OR
ISZERO
PUSH2 0x0357
JUMPI
PUSH1 0x60
SWAP6
POP
SWAP1
PUSH2 0x0314
SWAP2
PUSH2 0x07c9
JUMP
JUMPDEST
PUSH32 0x0000000000000000000000000000000000000000000000000c78d8c10970f378
DUP1
DUP3
GT
ISZERO
PUSH2 0x034e
JUMPI
POP
DUP1
SWAP3
JUMPDEST
DUP3
MLOAD
SWAP5
DUP6
MSTORE
DUP5
ADD
MSTORE
DUP3
ADD
MSTORE
RETURN
JUMPDEST
SWAP1
POP
DUP1
SWAP3
PUSH2 0x0341
JUMP
JUMPDEST
PUSH1 0x24
DUP6
PUSH1 0x11
DUP9
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
DUP4
MSTORE
MSTORE
REVERT
JUMPDEST
DUP1
SWAP3
POP
DUP8
DUP1
SWAP3
POP
RETURNDATASIZE
DUP4
GT
PUSH2 0x039a
JUMPI
JUMPDEST
PUSH2 0x0383
DUP2
DUP4
PUSH2 0x0768
JUMP
JUMPDEST
DUP2
ADD
SUB
SLT
PUSH2 0x0396
JUMPI
MLOAD
DUP3
SWAP1
PUSH2 0x02f4
PUSH2 0x02e9
JUMP
JUMPDEST
DUP7
DUP1
REVERT
JUMPDEST
POP
RETURNDATASIZE
PUSH2 0x0379
JUMP
JUMPDEST
DUP6
MLOAD
RETURNDATASIZE
DUP10
DUP3
RETURNDATACOPY
RETURNDATASIZE
SWAP1
REVERT
JUMPDEST
DUP1
SWAP3
SWAP4
POP
DUP8
DUP1
SWAP3
POP
RETURNDATASIZE
DUP4
GT
PUSH2 0x03d9
JUMPI
JUMPDEST
PUSH2 0x03c5
DUP2
DUP4
PUSH2 0x0768
JUMP
JUMPDEST
DUP2
ADD
SUB
SLT
PUSH2 0x0396
JUMPI
MLOAD
DUP3
SWAP2
SWAP1
PUSH2 0x0297
PUSH2 0x028c
JUMP
JUMPDEST
POP
RETURNDATASIZE
PUSH2 0x03bb
JUMP
JUMPDEST
PUSH2 0x024d
SWAP2
POP
DUP3
PUSH2 0x07a0
JUMP
JUMPDEST
SWAP4
POP
POP
POP
DUP2
DUP2
RETURNDATASIZE
DUP4
GT
PUSH2 0x0416
JUMPI
JUMPDEST
PUSH2 0x0403
DUP2
DUP4
PUSH2 0x0768
JUMP
JUMPDEST
DUP2
ADD
SUB
SLT
PUSH2 0x0396
JUMPI
DUP6
DUP4
DUP10
SWAP3
MLOAD
DUP12
PUSH2 0x023a
JUMP
JUMPDEST
POP
RETURNDATASIZE
PUSH2 0x03f9
JUMP
JUMPDEST
SWAP1
POP
SWAP2
PUSH2 0x0205
JUMP
JUMPDEST
PUSH1 0x24
DUP9
PUSH1 0x11
DUP12
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
DUP4
MSTORE
MSTORE
REVERT
JUMPDEST
DUP8
DUP6
MLOAD
PUSH4 0x0f20c89f
PUSH1 0xe0
SHL
DUP2
MSTORE
REVERT
JUMPDEST
PUSH2 0x0452
SWAP2
POP
TIMESTAMP
PUSH2 0x083a
JUMP
JUMPDEST
PUSH32 0x0000000000000000000000000000000000000000000000000000000000015180
LT
DUP10
PUSH2 0x01d0
JUMP
JUMPDEST
PUSH2 0x049d
SWAP4
POP
DUP1
SWAP2
SWAP3
POP
SWAP1
RETURNDATASIZE
LT
PUSH2 0x04a9
JUMPI
JUMPDEST
PUSH2 0x0495
DUP2
DUP4
PUSH2 0x0768
JUMP
JUMPDEST
DUP2
ADD
SWAP1
PUSH2 0x0805
JUMP
JUMPDEST
POP
SWAP3
POP
POP
SWAP1
DUP10
DUP1
PUSH2 0x01c2
JUMP
JUMPDEST
POP
RETURNDATASIZE
PUSH2 0x048b
JUMP
JUMPDEST
DUP7
MLOAD
RETURNDATASIZE
DUP11
DUP3
RETURNDATACOPY
RETURNDATASIZE
SWAP1
REVERT
JUMPDEST
DUP9
DUP7
MLOAD
PUSH4 0x0f20c89f
PUSH1 0xe0
SHL
DUP2
MSTORE
REVERT
JUMPDEST
PUSH2 0x04d4
SWAP2
POP
TIMESTAMP
PUSH2 0x083a
JUMP
JUMPDEST
PUSH32 0x0000000000000000000000000000000000000000000000000000000000015180
LT
DUP11
PUSH2 0x018d
JUMP
JUMPDEST
SWAP1
POP
PUSH2 0x0516
SWAP2
SWAP5
POP
DUP3
RETURNDATASIZE
DUP5
GT
PUSH2 0x04a9
JUMPI
PUSH2 0x0495
DUP2
DUP4
PUSH2 0x0768
JUMP
JUMPDEST
POP
SWAP6
SWAP3
POP
POP
SWAP4
DUP11
PUSH2 0x0180
JUMP
JUMPDEST
PUSH1 0x24
DUP6
PUSH1 0x12
DUP9
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
DUP4
MSTORE
MSTORE
REVERT
JUMPDEST
SWAP1
POP
DUP4
DUP2
DUP2
RETURNDATASIZE
DUP4
GT
PUSH2 0x055f
JUMPI
JUMPDEST
PUSH2 0x054c
DUP2
DUP4
PUSH2 0x0768
JUMP
JUMPDEST
DUP2
ADD
SUB
SLT
PUSH2 0x055b
JUMPI
MLOAD
DUP7
PUSH2 0x0114
JUMP
JUMPDEST
DUP5
DUP1
REVERT
JUMPDEST
POP
RETURNDATASIZE
PUSH2 0x0542
JUMP
JUMPDEST
DUP4
MLOAD
RETURNDATASIZE
DUP8
DUP3
RETURNDATACOPY
RETURNDATASIZE
SWAP1
REVERT
JUMPDEST
POP
POP
CALLVALUE
PUSH2 0x00ab
JUMPI
DUP2
PUSH1 0x03
NOT
CALLDATASIZE
ADD
SLT
PUSH2 0x00ab
JUMPI
PUSH1 0x20
SWAP1
MLOAD
PUSH20 0x3de254a0f838a844f727fee81040e0fa7884b935
DUP2
MSTORE
RETURN
JUMPDEST
POP
POP
CALLVALUE
PUSH2 0x00ab
JUMPI
DUP2
PUSH1 0x03
NOT
CALLDATASIZE
ADD
SLT
PUSH2 0x00ab
JUMPI
PUSH1 0x20
SWAP1
MLOAD
PUSH20 0xd901dcf4948a29d7d9d7e015aaf61591825ac267
DUP2
MSTORE
RETURN
JUMPDEST
POP
POP
CALLVALUE
PUSH2 0x00ab
JUMPI
DUP2
PUSH1 0x03
NOT
CALLDATASIZE
ADD
SLT
PUSH2 0x00ab
JUMPI
PUSH1 0x20
SWAP1
MLOAD
PUSH32 0x0000000000000000000000000000000000000000000000000c78d8c10970f378
DUP2
MSTORE
RETURN
JUMPDEST
POP
POP
CALLVALUE
PUSH2 0x00ab
JUMPI
DUP2
PUSH1 0x03
NOT
CALLDATASIZE
ADD
SLT
PUSH2 0x00ab
JUMPI
PUSH1 0x20
SWAP1
MLOAD
PUSH1 0x12
DUP2
MSTORE
RETURN
JUMPDEST
SWAP2
POP
SWAP3
CALLVALUE
PUSH2 0x0765
JUMPI
DUP1
PUSH1 0x03
NOT
CALLDATASIZE
ADD
SLT
PUSH2 0x0765
JUMPI
DUP1
DUP2
SLOAD
PUSH1 0x01
DUP2
DUP2
SHR
SWAP2
DUP2
DUP2
AND
DUP1
ISZERO
PUSH2 0x075b
JUMPI
JUMPDEST
PUSH1 0x20
SWAP9
DUP10
DUP6
LT
DUP3
EQ
PUSH2 0x0748
JUMPI
POP
SWAP2
DUP4
SWAP2
DUP10
SWAP6
SWAP4
DUP9
SWAP6
DUP7
MSTORE
SWAP1
DUP2
PUSH1 0x00
EQ
PUSH2 0x0727
JUMPI
POP
PUSH1 0x01
EQ
PUSH2 0x06cc
JUMPI
JUMPDEST
POP
POP
PUSH2 0x0686
SWAP3
POP
SWAP6
SWAP4
SWAP3
SWAP6
SUB
DUP3
PUSH2 0x0768
JUMP
JUMPDEST
DUP3
MLOAD
SWAP4
DUP3
DUP6
SWAP4
DUP5
MSTORE
DUP3
MLOAD
SWAP3
DUP4
DUP3
DUP7
ADD
MSTORE
DUP3
JUMPDEST
DUP5
DUP2
LT
PUSH2 0x06b6
JUMPI
POP
POP
POP
DUP3
DUP3
ADD
DUP5
ADD
MSTORE
PUSH1 0x1f
ADD
PUSH1 0x1f
NOT
AND
DUP2
ADD
SUB
ADD
SWAP1
RETURN
JUMPDEST
DUP2
DUP2
ADD
DUP4
ADD
MLOAD
DUP9
DUP3
ADD
DUP9
ADD
MSTORE
DUP8
SWAP6
POP
DUP3
ADD
PUSH2 0x0698
JUMP
JUMPDEST
DUP6
DUP1
MSTORE
PUSH32 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
SWAP5
SWAP3
POP
DUP6
SWAP2
SWAP1
JUMPDEST
DUP2
DUP4
LT
PUSH2 0x070f
JUMPI
POP
DUP9
SWAP5
POP
POP
DUP3
ADD
ADD
PUSH2 0x0686
CODESIZE
PUSH2 0x0674
JUMP
JUMPDEST
DUP6
SLOAD
DUP9
DUP5
ADD
DUP6
ADD
MSTORE
SWAP5
DUP6
ADD
SWAP5
DUP8
SWAP5
POP
SWAP2
DUP4
ADD
SWAP2
PUSH2 0x06f7
JUMP
JUMPDEST
SWAP2
POP
POP
PUSH2 0x0686
SWAP5
SWAP3
POP
PUSH1 0xff
NOT
AND
DUP3
DUP5
ADD
MSTORE
ISZERO
ISZERO
PUSH1 0x05
SHL
DUP3
ADD
ADD
DUP7
SWAP3
CODESIZE
PUSH2 0x0674
JUMP
JUMPDEST
DUP7
PUSH1 0x22
PUSH1 0x24
SWAP3
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
DUP4
MSTORE
MSTORE
REVERT
JUMPDEST
SWAP3
PUSH1 0x7f
AND
SWAP3
PUSH2 0x064b
JUMP
JUMPDEST
DUP1
REVERT
JUMPDEST
SWAP1
PUSH1 0x1f
DUP1
NOT
SWAP2
ADD
AND
DUP2
ADD
SWAP1
DUP2
LT
PUSH8 0xffffffffffffffff
DUP3
GT
OR
PUSH2 0x078a
JUMPI
PUSH1 0x40
MSTORE
JUMP
JUMPDEST
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
PUSH1 0x00
MSTORE
PUSH1 0x41
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
JUMPDEST
DUP2
DUP2
MUL
SWAP3
SWAP2
DUP2
ISZERO
SWAP2
DUP5
DIV
EQ
OR
ISZERO
PUSH2 0x07b3
JUMPI
JUMP
JUMPDEST
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
PUSH1 0x00
MSTORE
PUSH1 0x11
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
JUMPDEST
DUP2
ISZERO
PUSH2 0x07d3
JUMPI
DIV
SWAP1
JUMP
JUMPDEST
PUSH4 0x4e487b71
PUSH1 0xe0
SHL
PUSH1 0x00
MSTORE
PUSH1 0x12
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
JUMPDEST
MLOAD
SWAP1
PUSH10 0xffffffffffffffffffff
DUP3
AND
DUP3
SUB
PUSH2 0x0800
JUMPI
JUMP
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP1
DUP2
PUSH1 0xa0
SWAP2
SUB
SLT
PUSH2 0x0800
JUMPI
PUSH2 0x0819
DUP2
PUSH2 0x07e9
JUMP
JUMPDEST
SWAP2
PUSH1 0x20
DUP3
ADD
MLOAD
SWAP2
PUSH1 0x40
DUP2
ADD
MLOAD
SWAP2
PUSH2 0x0837
PUSH1 0x80
PUSH1 0x60
DUP5
ADD
MLOAD
SWAP4
ADD
PUSH2 0x07e9
JUMP
JUMPDEST
SWAP1
JUMP
JUMPDEST
SWAP2
SWAP1
DUP3
SUB
SWAP2
DUP3
GT
PUSH2 0x07b3
JUMPI
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
INVALID
PUSH23 0xcc42710a4b87e0ca083c5765cef276a4857be925644682
STATICCALL
'bf'(Unknown Opcode)
EXTCODESIZE
CALLER
SELFBALANCE
DUP9
SWAP7
PUSH5 0x736f6c6343
STOP
ADDMOD
ISZERO
STOP
CALLER