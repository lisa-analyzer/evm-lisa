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
PUSH2 0x00f5
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x8038e4a1
GT
PUSH2 0x0097
JUMPI
DUP1
PUSH4 0xbeed9b51
GT
PUSH2 0x0066
JUMPI
DUP1
PUSH4 0xbeed9b51
EQ
PUSH2 0x0240
JUMPI
DUP1
PUSH4 0xdc7f0124
EQ
PUSH2 0x0253
JUMPI
DUP1
PUSH4 0xeda066f7
EQ
PUSH2 0x0278
JUMPI
DUP1
PUSH4 0xf2fde38b
EQ
PUSH2 0x029f
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
PUSH4 0x8038e4a1
EQ
PUSH2 0x01f4
JUMPI
DUP1
PUSH4 0x8823da6c
EQ
PUSH2 0x01fc
JUMPI
DUP1
PUSH4 0x8da5cb5b
EQ
PUSH2 0x020f
JUMPI
DUP1
PUSH4 0xa118f249
EQ
PUSH2 0x022d
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
PUSH4 0x1a93d1c3
GT
PUSH2 0x00d3
JUMPI
DUP1
PUSH4 0x1a93d1c3
EQ
PUSH2 0x019e
JUMPI
DUP1
PUSH4 0x52d84c62
EQ
PUSH2 0x01b6
JUMPI
DUP1
PUSH4 0x6b14daf8
EQ
PUSH2 0x01c9
JUMPI
DUP1
PUSH4 0x79ba5097
EQ
PUSH2 0x01ec
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
PUSH4 0x0a756983
EQ
PUSH2 0x00fa
JUMPI
DUP1
PUSH4 0x122555ff
EQ
PUSH2 0x0104
JUMPI
DUP1
PUSH4 0x181f5a77
EQ
PUSH2 0x0155
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x0102
PUSH2 0x02b2
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x012b
PUSH32 0x00000000000000000000000095bccbbbacbb7ed224ac2ee38531f2467df41ea4
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
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0191
PUSH1 0x40
MLOAD
DUP1
PUSH1 0x40
ADD
PUSH1 0x40
MSTORE
DUP1
PUSH1 0x15
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH32 0x5363726f6c6c56616c696461746f7220312e302e300000000000000000000000
DUP2
MSTORE
POP
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x014c
SWAP2
SWAP1
PUSH2 0x0ae4
JUMP
JUMPDEST
PUSH1 0x03
SLOAD
PUSH1 0x40
MLOAD
PUSH4 0xffffffff
SWAP1
SWAP2
AND
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH2 0x014c
JUMP
JUMPDEST
PUSH2 0x0102
PUSH2 0x01c4
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0af7
JUMP
JUMPDEST
PUSH2 0x0331
JUMP
JUMPDEST
PUSH2 0x01dc
PUSH2 0x01d7
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0b75
JUMP
JUMPDEST
PUSH2 0x03a3
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
PUSH2 0x014c
JUMP
JUMPDEST
PUSH2 0x0102
PUSH2 0x03f9
JUMP
JUMPDEST
PUSH2 0x0102
PUSH2 0x04fb
JUMP
JUMPDEST
PUSH2 0x0102
PUSH2 0x020a
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0c55
JUMP
JUMPDEST
PUSH2 0x058f
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x012b
JUMP
JUMPDEST
PUSH2 0x0102
PUSH2 0x023b
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0c55
JUMP
JUMPDEST
PUSH2 0x0644
JUMP
JUMPDEST
PUSH2 0x01dc
PUSH2 0x024e
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0c70
JUMP
JUMPDEST
PUSH2 0x06f8
JUMP
JUMPDEST
PUSH1 0x01
SLOAD
PUSH2 0x01dc
SWAP1
PUSH21 0x010000000000000000000000000000000000000000
SWAP1
DIV
PUSH1 0xff
AND
DUP2
JUMP
JUMPDEST
PUSH2 0x012b
PUSH32 0x0000000000000000000000006774bcbd5cecef1336b5300fb5186a12ddd8b367
DUP2
JUMP
JUMPDEST
PUSH2 0x0102
PUSH2 0x02ad
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0c55
JUMP
JUMPDEST
PUSH2 0x08f9
JUMP
JUMPDEST
PUSH2 0x02ba
PUSH2 0x090a
JUMP
JUMPDEST
PUSH1 0x01
SLOAD
PUSH21 0x010000000000000000000000000000000000000000
SWAP1
DIV
PUSH1 0xff
AND
ISZERO
PUSH2 0x032f
JUMPI
PUSH1 0x01
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffff
AND
SWAP1
SSTORE
PUSH1 0x40
MLOAD
PUSH32 0x3be8a977a014527b50ae38adda80b56911c267328965c98ddc385d248f539638
SWAP1
PUSH1 0x00
SWAP1
LOG1
JUMPDEST
JUMP
JUMPDEST
PUSH2 0x0339
PUSH2 0x090a
JUMP
JUMPDEST
PUSH1 0x03
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
AND
PUSH4 0xffffffff
DUP4
AND
SWAP1
DUP2
OR
SWAP1
SWAP2
SSTORE
PUSH1 0x40
MLOAD
SWAP1
DUP2
MSTORE
PUSH32 0x501c51f34bf3d8589156f7fd37055e69375b40034d9f99365cb3290b5d983c91
SWAP1
PUSH1 0x20
ADD
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG1
POP
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP3
AND
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x02
PUSH1 0x20
MSTORE
PUSH1 0x40
DUP2
SHA3
SLOAD
PUSH1 0xff
AND
DUP1
PUSH2 0x03f2
JUMPI
POP
PUSH1 0x01
SLOAD
PUSH21 0x010000000000000000000000000000000000000000
SWAP1
DIV
PUSH1 0xff
AND
ISZERO
JUMPDEST
SWAP4
SWAP3
POP
POP
POP
JUMP
JUMPDEST
PUSH1 0x01
SLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
CALLER
EQ
PUSH2 0x047f
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
PUSH1 0x16
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x4d7573742062652070726f706f736564206f776e657200000000000000000000
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
PUSH1 0x00
DUP1
SLOAD
CALLER
PUSH32 0xffffffffffffffffffffffff0000000000000000000000000000000000000000
DUP1
DUP4
AND
DUP3
OR
DUP5
SSTORE
PUSH1 0x01
DUP1
SLOAD
SWAP1
SWAP2
AND
SWAP1
SSTORE
PUSH1 0x40
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP3
AND
SWAP3
SWAP1
SWAP2
DUP4
SWAP2
PUSH32 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
SWAP2
LOG3
POP
JUMP
JUMPDEST
PUSH2 0x0503
PUSH2 0x090a
JUMP
JUMPDEST
PUSH1 0x01
SLOAD
PUSH21 0x010000000000000000000000000000000000000000
SWAP1
DIV
PUSH1 0xff
AND
PUSH2 0x032f
JUMPI
PUSH1 0x01
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffff
AND
PUSH21 0x010000000000000000000000000000000000000000
OR
SWAP1
SSTORE
PUSH1 0x40
MLOAD
PUSH32 0xaebf329500988c6488a0074e5a0a9ff304561fc5c6fc877aeb1d59c8282c3480
SWAP1
PUSH1 0x00
SWAP1
LOG1
JUMP
JUMPDEST
PUSH2 0x0597
PUSH2 0x090a
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP2
AND
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x02
PUSH1 0x20
MSTORE
PUSH1 0x40
SWAP1
SHA3
SLOAD
PUSH1 0xff
AND
ISZERO
PUSH2 0x0641
JUMPI
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP2
AND
PUSH1 0x00
DUP2
DUP2
MSTORE
PUSH1 0x02
PUSH1 0x20
SWAP1
DUP2
MSTORE
PUSH1 0x40
SWAP2
DUP3
SWAP1
SHA3
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
AND
SWAP1
SSTORE
SWAP1
MLOAD
SWAP2
DUP3
MSTORE
PUSH32 0x3d68a6fce901d20453d1a7aa06bf3950302a735948037deb182a8db66df2a0d1
SWAP2
ADD
PUSH2 0x0398
JUMP
JUMPDEST
POP
JUMP
JUMPDEST
PUSH2 0x064c
PUSH2 0x090a
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP2
AND
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x02
PUSH1 0x20
MSTORE
PUSH1 0x40
SWAP1
SHA3
SLOAD
PUSH1 0xff
AND
PUSH2 0x0641
JUMPI
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP2
AND
PUSH1 0x00
DUP2
DUP2
MSTORE
PUSH1 0x02
PUSH1 0x20
SWAP1
DUP2
MSTORE
PUSH1 0x40
SWAP2
DUP3
SWAP1
SHA3
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
AND
PUSH1 0x01
OR
SWAP1
SSTORE
SWAP1
MLOAD
SWAP2
DUP3
MSTORE
PUSH32 0x87286ad1f399c8e82bf0c4ef4fcdc570ea2e1e92176e5c848b6413545b885db4
SWAP2
ADD
PUSH2 0x0398
JUMP
JUMPDEST
PUSH1 0x00
PUSH2 0x073b
CALLER
PUSH1 0x00
CALLDATASIZE
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
PUSH2 0x03a3
SWAP3
POP
POP
POP
JUMP
JUMPDEST
PUSH2 0x07a1
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
PUSH1 0x09
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x4e6f206163636573730000000000000000000000000000000000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0476
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
PUSH1 0x01
DUP5
EQ
PUSH1 0x24
DUP3
ADD
MSTORE
TIMESTAMP
PUSH8 0xffffffffffffffff
AND
PUSH1 0x44
DUP1
DUP4
ADD
SWAP2
SWAP1
SWAP2
MSTORE
DUP3
MLOAD
DUP1
DUP4
SUB
SWAP1
SWAP2
ADD
DUP2
MSTORE
PUSH1 0x64
SWAP1
SWAP2
ADD
DUP3
MSTORE
PUSH1 0x20
DUP2
ADD
DUP1
MLOAD
PUSH28 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0xed8378f500000000000000000000000000000000000000000000000000000000
OR
SWAP1
MSTORE
PUSH1 0x03
SLOAD
SWAP2
MLOAD
PUSH32 0xb2267a7b00000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH32 0x0000000000000000000000006774bcbd5cecef1336b5300fb5186a12ddd8b367
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
SWAP3
PUSH4 0xb2267a7b
SWAP3
PUSH2 0x08bc
SWAP3
PUSH32 0x00000000000000000000000095bccbbbacbb7ed224ac2ee38531f2467df41ea4
SWAP3
PUSH1 0x00
SWAP3
SWAP2
PUSH4 0xffffffff
SWAP1
SWAP2
AND
SWAP1
PUSH1 0x04
ADD
PUSH2 0x0ca2
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH1 0x00
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x08d6
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x08ea
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
SWAP9
SWAP8
POP
POP
POP
POP
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH2 0x0901
PUSH2 0x090a
JUMP
JUMPDEST
PUSH2 0x0641
DUP2
PUSH2 0x098b
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
CALLER
EQ
PUSH2 0x032f
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
PUSH1 0x16
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x4f6e6c792063616c6c61626c65206279206f776e657200000000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0476
JUMP
JUMPDEST
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP3
AND
SUB
PUSH2 0x0a0a
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
PUSH1 0x17
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x43616e6e6f74207472616e7366657220746f2073656c66000000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0476
JUMP
JUMPDEST
PUSH1 0x01
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffff0000000000000000000000000000000000000000
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP4
DUP2
AND
SWAP2
DUP3
OR
SWAP1
SWAP3
SSTORE
PUSH1 0x00
DUP1
SLOAD
PUSH1 0x40
MLOAD
SWAP3
SWAP4
AND
SWAP2
PUSH32 0xed8889f560326eb138920d842192f0eb3dd22b4f139c87a2c57538e05bae1278
SWAP2
SWAP1
LOG3
POP
JUMP
JUMPDEST
PUSH1 0x00
DUP2
MLOAD
DUP1
DUP5
MSTORE
PUSH1 0x00
JUMPDEST
DUP2
DUP2
LT
ISZERO
PUSH2 0x0aa6
JUMPI
PUSH1 0x20
DUP2
DUP6
ADD
DUP2
ADD
MLOAD
DUP7
DUP4
ADD
DUP3
ADD
MSTORE
ADD
PUSH2 0x0a8a
JUMP
JUMPDEST
POP
PUSH1 0x00
PUSH1 0x20
DUP3
DUP7
ADD
ADD
MSTORE
PUSH1 0x20
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0
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
PUSH1 0x20
DUP2
MSTORE
PUSH1 0x00
PUSH2 0x03f2
PUSH1 0x20
DUP4
ADD
DUP5
PUSH2 0x0a80
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0b09
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
PUSH4 0xffffffff
DUP2
AND
DUP2
EQ
PUSH2 0x03f2
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP2
AND
DUP2
EQ
PUSH2 0x0b41
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP2
SWAP1
POP
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
PUSH1 0x00
DUP1
PUSH1 0x40
DUP4
DUP6
SUB
SLT
ISZERO
PUSH2 0x0b88
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x0b91
DUP4
PUSH2 0x0b1d
JUMP
JUMPDEST
SWAP2
POP
PUSH1 0x20
DUP4
ADD
CALLDATALOAD
PUSH8 0xffffffffffffffff
DUP1
DUP3
GT
ISZERO
PUSH2 0x0bae
JUMPI
PUSH1 0x00
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
PUSH2 0x0bc2
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
DUP2
DUP2
GT
ISZERO
PUSH2 0x0bd4
JUMPI
PUSH2 0x0bd4
PUSH2 0x0b46
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x1f
DUP3
ADD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0
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
PUSH2 0x0c1a
JUMPI
PUSH2 0x0c1a
PUSH2 0x0b46
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
PUSH2 0x0c33
JUMPI
PUSH1 0x00
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
PUSH1 0x00
PUSH1 0x20
DUP5
DUP4
ADD
ADD
MSTORE
DUP1
SWAP6
POP
POP
POP
POP
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
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0c67
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x03f2
DUP3
PUSH2 0x0b1d
JUMP
JUMPDEST
PUSH1 0x00
DUP1
PUSH1 0x00
DUP1
PUSH1 0x80
DUP6
DUP8
SUB
SLT
ISZERO
PUSH2 0x0c86
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
POP
DUP3
CALLDATALOAD
SWAP5
PUSH1 0x20
DUP5
ADD
CALLDATALOAD
SWAP5
POP
PUSH1 0x40
DUP5
ADD
CALLDATALOAD
SWAP4
PUSH1 0x60
ADD
CALLDATALOAD
SWAP3
POP
SWAP1
POP
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP6
AND
DUP2
MSTORE
DUP4
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0x80
PUSH1 0x40
DUP3
ADD
MSTORE
PUSH1 0x00
PUSH2 0x0cd7
PUSH1 0x80
DUP4
ADD
DUP6
PUSH2 0x0a80
JUMP
JUMPDEST
SWAP1
POP
PUSH4 0xffffffff
DUP4
AND
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
LOG1
PUSH5 0x736f6c6343
STOP
ADDMOD
SGT
STOP
EXP
