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
PUSH2 0x00cd
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x580e2458
GT
PUSH2 0x008a
JUMPI
DUP1
PUSH4 0x95d89b41
GT
PUSH2 0x0064
JUMPI
DUP1
PUSH4 0x95d89b41
EQ
PUSH2 0x01ff
JUMPI
DUP1
PUSH4 0x961eb4d2
EQ
PUSH2 0x021d
JUMPI
DUP1
PUSH4 0xa9059cbb
EQ
PUSH2 0x0239
JUMPI
DUP1
PUSH4 0xdd62ed3e
EQ
PUSH2 0x0269
JUMPI
PUSH2 0x00cd
JUMP
JUMPDEST
DUP1
PUSH4 0x580e2458
EQ
PUSH2 0x01a7
JUMPI
DUP1
PUSH4 0x70a08231
EQ
PUSH2 0x01b1
JUMPI
DUP1
PUSH4 0x8da5cb5b
EQ
PUSH2 0x01e1
JUMPI
PUSH2 0x00cd
JUMP
JUMPDEST
DUP1
PUSH4 0x06fdde03
EQ
PUSH2 0x00d1
JUMPI
DUP1
PUSH4 0x095ea7b3
EQ
PUSH2 0x00ef
JUMPI
DUP1
PUSH4 0x0d1ca691
EQ
PUSH2 0x011f
JUMPI
DUP1
PUSH4 0x18160ddd
EQ
PUSH2 0x013b
JUMPI
DUP1
PUSH4 0x23b872dd
EQ
PUSH2 0x0159
JUMPI
DUP1
PUSH4 0x313ce567
EQ
PUSH2 0x0189
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x00d9
PUSH2 0x0299
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x00e6
SWAP2
SWAP1
PUSH2 0x0fff
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
PUSH2 0x0109
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x0104
SWAP2
SWAP1
PUSH2 0x10b0
JUMP
JUMPDEST
PUSH2 0x0329
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0116
SWAP2
SWAP1
PUSH2 0x1108
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
PUSH2 0x0139
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x0134
SWAP2
SWAP1
PUSH2 0x10b0
JUMP
JUMPDEST
PUSH2 0x0424
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0143
PUSH2 0x0491
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0150
SWAP2
SWAP1
PUSH2 0x1130
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
PUSH2 0x0173
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x016e
SWAP2
SWAP1
PUSH2 0x1149
JUMP
JUMPDEST
PUSH2 0x049a
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0180
SWAP2
SWAP1
PUSH2 0x1108
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
PUSH2 0x0191
PUSH2 0x082d
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x019e
SWAP2
SWAP1
PUSH2 0x11b4
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
PUSH2 0x01af
PUSH2 0x0842
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x01cb
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x01c6
SWAP2
SWAP1
PUSH2 0x11cd
JUMP
JUMPDEST
PUSH2 0x0978
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x01d8
SWAP2
SWAP1
PUSH2 0x1130
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
PUSH2 0x01e9
PUSH2 0x09be
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x01f6
SWAP2
SWAP1
PUSH2 0x1207
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
PUSH2 0x0207
PUSH2 0x09e5
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0214
SWAP2
SWAP1
PUSH2 0x0fff
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
PUSH2 0x0237
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x0232
SWAP2
SWAP1
PUSH2 0x10b0
JUMP
JUMPDEST
PUSH2 0x0a75
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0253
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x024e
SWAP2
SWAP1
PUSH2 0x10b0
JUMP
JUMPDEST
PUSH2 0x0b18
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0260
SWAP2
SWAP1
PUSH2 0x1108
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
PUSH2 0x0283
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x027e
SWAP2
SWAP1
PUSH2 0x1220
JUMP
JUMPDEST
PUSH2 0x0df6
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0290
SWAP2
SWAP1
PUSH2 0x1130
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
PUSH1 0x60
PUSH1 0x04
DUP1
SLOAD
PUSH2 0x02a8
SWAP1
PUSH2 0x128b
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
PUSH2 0x02d4
SWAP1
PUSH2 0x128b
JUMP
JUMPDEST
DUP1
ISZERO
PUSH2 0x031f
JUMPI
DUP1
PUSH1 0x1f
LT
PUSH2 0x02f6
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
PUSH2 0x031f
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
PUSH2 0x0302
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
POP
SWAP1
JUMP
JUMPDEST
PUSH0
DUP2
PUSH1 0x02
PUSH0
PUSH2 0x0336
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP6
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
DUP2
SWAP1
SSTORE
POP
DUP3
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x03cd
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
DUP5
PUSH1 0x40
MLOAD
PUSH2 0x0412
SWAP2
SWAP1
PUSH2 0x1130
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG3
PUSH1 0x01
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH2 0x042d
CALLER
PUSH2 0x0e7f
JUMP
JUMPDEST
PUSH2 0x046c
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0463
SWAP1
PUSH2 0x132b
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
PUSH1 0x64
SWAP1
POP
PUSH0
DUP2
DUP4
GT
ISZERO
SWAP1
POP
PUSH2 0x0481
DUP2
PUSH2 0x0e8f
JUMP
JUMPDEST
PUSH2 0x048b
DUP5
DUP5
PUSH2 0x0ed2
JUMP
JUMPDEST
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x07
SLOAD
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH0
DUP2
PUSH1 0x02
PUSH0
DUP7
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
PUSH2 0x04e2
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
SLOAD
LT
ISZERO
PUSH2 0x055d
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0554
SWAP1
PUSH2 0x13b9
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
PUSH1 0x64
PUSH1 0x03
PUSH0
DUP8
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
SLOAD
DUP5
PUSH2 0x05a9
SWAP2
SWAP1
PUSH2 0x1404
JUMP
JUMPDEST
PUSH2 0x05b3
SWAP2
SWAP1
PUSH2 0x1472
JUMP
JUMPDEST
SWAP1
POP
PUSH0
DUP2
DUP5
PUSH2 0x05c2
SWAP2
SWAP1
PUSH2 0x14a2
JUMP
JUMPDEST
SWAP1
POP
DUP4
PUSH1 0x01
PUSH0
DUP9
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x0610
SWAP2
SWAP1
PUSH2 0x14a2
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
DUP1
PUSH1 0x01
PUSH0
DUP8
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x0663
SWAP2
SWAP1
PUSH2 0x14d5
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
DUP4
PUSH1 0x02
PUSH0
DUP9
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
PUSH2 0x06b1
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x06f8
SWAP2
SWAP1
PUSH2 0x14a2
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
DUP2
PUSH1 0x01
PUSH0
PUSH2 0xdead
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x074d
SWAP2
SWAP1
PUSH2 0x14d5
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
DUP5
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP7
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
DUP4
PUSH1 0x40
MLOAD
PUSH2 0x07b1
SWAP2
SWAP1
PUSH2 0x1130
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG3
PUSH2 0xdead
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP7
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
DUP5
PUSH1 0x40
MLOAD
PUSH2 0x0818
SWAP2
SWAP1
PUSH2 0x1130
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG3
PUSH1 0x01
SWAP3
POP
POP
POP
SWAP4
SWAP3
POP
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x06
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
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH2 0x084a
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x0868
PUSH2 0x09be
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
EQ
PUSH2 0x08be
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x08b5
SWAP1
PUSH2 0x1552
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
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
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
PUSH32 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
PUSH1 0x40
MLOAD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG3
PUSH0
DUP1
PUSH0
PUSH2 0x0100
EXP
DUP2
SLOAD
DUP2
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
MUL
NOT
AND
SWAP1
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
MUL
OR
SWAP1
SSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x01
PUSH0
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
SLOAD
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
DUP1
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
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH1 0x60
PUSH1 0x05
DUP1
SLOAD
PUSH2 0x09f4
SWAP1
PUSH2 0x128b
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
PUSH2 0x0a20
SWAP1
PUSH2 0x128b
JUMP
JUMPDEST
DUP1
ISZERO
PUSH2 0x0a6b
JUMPI
DUP1
PUSH1 0x1f
LT
PUSH2 0x0a42
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
PUSH2 0x0a6b
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
PUSH2 0x0a4e
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
POP
SWAP1
JUMP
JUMPDEST
PUSH0
DUP2
SWAP1
POP
DUP1
PUSH1 0x01
PUSH0
DUP6
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x0ac5
SWAP2
SWAP1
PUSH2 0x14d5
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
PUSH2 0x0ad4
PUSH2 0x0f18
JUMP
JUMPDEST
PUSH2 0x0b13
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0b0a
SWAP1
PUSH2 0x132b
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
POP
POP
POP
JUMP
JUMPDEST
PUSH0
DUP2
PUSH1 0x01
PUSH0
PUSH2 0x0b25
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
SLOAD
LT
ISZERO
PUSH2 0x0ba0
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0b97
SWAP1
PUSH2 0x15e0
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
PUSH1 0x64
PUSH1 0x03
PUSH0
PUSH2 0x0bae
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
SLOAD
DUP5
PUSH2 0x0bf3
SWAP2
SWAP1
PUSH2 0x1404
JUMP
JUMPDEST
PUSH2 0x0bfd
SWAP2
SWAP1
PUSH2 0x1472
JUMP
JUMPDEST
SWAP1
POP
PUSH0
DUP2
DUP5
PUSH2 0x0c0c
SWAP2
SWAP1
PUSH2 0x14a2
JUMP
JUMPDEST
SWAP1
POP
DUP4
PUSH1 0x01
PUSH0
PUSH2 0x0c1a
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x0c61
SWAP2
SWAP1
PUSH2 0x14a2
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
DUP1
PUSH1 0x01
PUSH0
DUP8
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x0cb4
SWAP2
SWAP1
PUSH2 0x14d5
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
DUP2
PUSH1 0x01
PUSH0
PUSH2 0xdead
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x0d09
SWAP2
SWAP1
PUSH2 0x14d5
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
DUP5
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x0d2f
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
DUP4
PUSH1 0x40
MLOAD
PUSH2 0x0d74
SWAP2
SWAP1
PUSH2 0x1130
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG3
PUSH2 0xdead
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x0d9d
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
DUP5
PUSH1 0x40
MLOAD
PUSH2 0x0de2
SWAP2
SWAP1
PUSH2 0x1130
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG3
PUSH1 0x01
SWAP3
POP
POP
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x02
PUSH0
DUP5
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
PUSH0
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
SLOAD
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
CALLER
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH0
PUSH2 0x0e88
PUSH2 0x0f18
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
DUP1
PUSH2 0x0ecf
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0ec6
SWAP1
PUSH2 0x1648
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
POP
JUMP
JUMPDEST
DUP1
PUSH1 0x03
PUSH0
DUP5
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH0
SHA3
DUP2
SWAP1
SSTORE
POP
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x08
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
PUSH2 0x0f59
PUSH2 0x0e78
JUMP
JUMPDEST
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
EQ
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH0
DUP2
MLOAD
SWAP1
POP
SWAP2
SWAP1
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
PUSH0
JUMPDEST
DUP4
DUP2
LT
ISZERO
PUSH2 0x0fac
JUMPI
DUP1
DUP3
ADD
MLOAD
DUP2
DUP5
ADD
MSTORE
PUSH1 0x20
DUP2
ADD
SWAP1
POP
PUSH2 0x0f91
JUMP
JUMPDEST
PUSH0
DUP5
DUP5
ADD
MSTORE
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x1f
NOT
PUSH1 0x1f
DUP4
ADD
AND
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x0fd1
DUP3
PUSH2 0x0f75
JUMP
JUMPDEST
PUSH2 0x0fdb
DUP2
DUP6
PUSH2 0x0f7f
JUMP
JUMPDEST
SWAP4
POP
PUSH2 0x0feb
DUP2
DUP6
PUSH1 0x20
DUP7
ADD
PUSH2 0x0f8f
JUMP
JUMPDEST
PUSH2 0x0ff4
DUP2
PUSH2 0x0fb7
JUMP
JUMPDEST
DUP5
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
PUSH2 0x1017
DUP2
DUP5
PUSH2 0x0fc7
JUMP
JUMPDEST
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
DUP1
REVERT
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
PUSH2 0x104c
DUP3
PUSH2 0x1023
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x105c
DUP2
PUSH2 0x1042
JUMP
JUMPDEST
DUP2
EQ
PUSH2 0x1066
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
CALLDATALOAD
SWAP1
POP
PUSH2 0x1077
DUP2
PUSH2 0x1053
JUMP
JUMPDEST
SWAP3
SWAP2
POP
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
PUSH2 0x108f
DUP2
PUSH2 0x107d
JUMP
JUMPDEST
DUP2
EQ
PUSH2 0x1099
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
CALLDATALOAD
SWAP1
POP
PUSH2 0x10aa
DUP2
PUSH2 0x1086
JUMP
JUMPDEST
SWAP3
SWAP2
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
PUSH2 0x10c6
JUMPI
PUSH2 0x10c5
PUSH2 0x101f
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x10d3
DUP6
DUP3
DUP7
ADD
PUSH2 0x1069
JUMP
JUMPDEST
SWAP3
POP
POP
PUSH1 0x20
PUSH2 0x10e4
DUP6
DUP3
DUP7
ADD
PUSH2 0x109c
JUMP
JUMPDEST
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
PUSH2 0x1102
DUP2
PUSH2 0x10ee
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x111b
PUSH0
DUP4
ADD
DUP5
PUSH2 0x10f9
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH2 0x112a
DUP2
PUSH2 0x107d
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x1143
PUSH0
DUP4
ADD
DUP5
PUSH2 0x1121
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
DUP1
PUSH0
PUSH1 0x60
DUP5
DUP7
SUB
SLT
ISZERO
PUSH2 0x1160
JUMPI
PUSH2 0x115f
PUSH2 0x101f
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x116d
DUP7
DUP3
DUP8
ADD
PUSH2 0x1069
JUMP
JUMPDEST
SWAP4
POP
POP
PUSH1 0x20
PUSH2 0x117e
DUP7
DUP3
DUP8
ADD
PUSH2 0x1069
JUMP
JUMPDEST
SWAP3
POP
POP
PUSH1 0x40
PUSH2 0x118f
DUP7
DUP3
DUP8
ADD
PUSH2 0x109c
JUMP
JUMPDEST
SWAP2
POP
POP
SWAP3
POP
SWAP3
POP
SWAP3
JUMP
JUMPDEST
PUSH0
PUSH1 0xff
DUP3
AND
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x11ae
DUP2
PUSH2 0x1199
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x11c7
PUSH0
DUP4
ADD
DUP5
PUSH2 0x11a5
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
PUSH2 0x11e2
JUMPI
PUSH2 0x11e1
PUSH2 0x101f
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x11ef
DUP5
DUP3
DUP6
ADD
PUSH2 0x1069
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
JUMPDEST
PUSH2 0x1201
DUP2
PUSH2 0x1042
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x121a
PUSH0
DUP4
ADD
DUP5
PUSH2 0x11f8
JUMP
JUMPDEST
SWAP3
SWAP2
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
PUSH2 0x1236
JUMPI
PUSH2 0x1235
PUSH2 0x101f
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x1243
DUP6
DUP3
DUP7
ADD
PUSH2 0x1069
JUMP
JUMPDEST
SWAP3
POP
POP
PUSH1 0x20
PUSH2 0x1254
DUP6
DUP3
DUP7
ADD
PUSH2 0x1069
JUMP
JUMPDEST
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
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH0
MSTORE
PUSH1 0x22
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH0
REVERT
JUMPDEST
PUSH0
PUSH1 0x02
DUP3
DIV
SWAP1
POP
PUSH1 0x01
DUP3
AND
DUP1
PUSH2 0x12a2
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
PUSH2 0x12b5
JUMPI
PUSH2 0x12b4
PUSH2 0x125e
JUMP
JUMPDEST
JUMPDEST
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x43616c6c6572206973206e6f7420746865206f726967696e616c2063616c6c65
PUSH0
DUP3
ADD
MSTORE
PUSH32 0x7200000000000000000000000000000000000000000000000000000000000000
PUSH1 0x20
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x1315
PUSH1 0x21
DUP4
PUSH2 0x0f7f
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x1320
DUP3
PUSH2 0x12bb
JUMP
JUMPDEST
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
PUSH2 0x1342
DUP2
PUSH2 0x1309
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x54543a207472616e7366657220616d6f756e74206578636565647320616c6c6f
PUSH0
DUP3
ADD
MSTORE
PUSH32 0x77616e6365000000000000000000000000000000000000000000000000000000
PUSH1 0x20
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x13a3
PUSH1 0x25
DUP4
PUSH2 0x0f7f
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x13ae
DUP3
PUSH2 0x1349
JUMP
JUMPDEST
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
PUSH2 0x13d0
DUP2
PUSH2 0x1397
JUMP
JUMPDEST
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
PUSH2 0x140e
DUP3
PUSH2 0x107d
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x1419
DUP4
PUSH2 0x107d
JUMP
JUMPDEST
SWAP3
POP
DUP3
DUP3
MUL
PUSH2 0x1427
DUP2
PUSH2 0x107d
JUMP
JUMPDEST
SWAP2
POP
DUP3
DUP3
DIV
DUP5
EQ
DUP4
ISZERO
OR
PUSH2 0x143e
JUMPI
PUSH2 0x143d
PUSH2 0x13d7
JUMP
JUMPDEST
JUMPDEST
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH0
MSTORE
PUSH1 0x12
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH0
REVERT
JUMPDEST
PUSH0
PUSH2 0x147c
DUP3
PUSH2 0x107d
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x1487
DUP4
PUSH2 0x107d
JUMP
JUMPDEST
SWAP3
POP
DUP3
PUSH2 0x1497
JUMPI
PUSH2 0x1496
PUSH2 0x1445
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
PUSH0
PUSH2 0x14ac
DUP3
PUSH2 0x107d
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x14b7
DUP4
PUSH2 0x107d
JUMP
JUMPDEST
SWAP3
POP
DUP3
DUP3
SUB
SWAP1
POP
DUP2
DUP2
GT
ISZERO
PUSH2 0x14cf
JUMPI
PUSH2 0x14ce
PUSH2 0x13d7
JUMP
JUMPDEST
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x14df
DUP3
PUSH2 0x107d
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x14ea
DUP4
PUSH2 0x107d
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
PUSH2 0x1502
JUMPI
PUSH2 0x1501
PUSH2 0x13d7
JUMP
JUMPDEST
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH32 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572
PUSH0
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x153c
PUSH1 0x20
DUP4
PUSH2 0x0f7f
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x1547
DUP3
PUSH2 0x1508
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
PUSH2 0x1569
DUP2
PUSH2 0x1530
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x54543a207472616e7366657220616d6f756e7420657863656564732062616c61
PUSH0
DUP3
ADD
MSTORE
PUSH32 0x6e63650000000000000000000000000000000000000000000000000000000000
PUSH1 0x20
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x15ca
PUSH1 0x23
DUP4
PUSH2 0x0f7f
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x15d5
DUP3
PUSH2 0x1570
JUMP
JUMPDEST
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
PUSH2 0x15f7
DUP2
PUSH2 0x15be
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x496e76616c6964206665652070657263656e7400000000000000000000000000
PUSH0
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x1632
PUSH1 0x13
DUP4
PUSH2 0x0f7f
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x163d
DUP3
PUSH2 0x15fe
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
PUSH2 0x165f
DUP2
PUSH2 0x1626
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
INVALID
