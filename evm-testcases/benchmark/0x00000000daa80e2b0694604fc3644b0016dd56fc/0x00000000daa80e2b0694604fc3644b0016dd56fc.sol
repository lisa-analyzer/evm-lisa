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
PUSH2 0x0041
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x2c82288c
EQ
PUSH2 0x0046
JUMPI
DUP1
PUSH4 0x32151432
EQ
PUSH2 0x008d
JUMPI
DUP1
PUSH4 0x6cf9ed9b
EQ
PUSH2 0x00c2
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x0079
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x005c
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x00f5
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
SWAP2
ISZERO
ISZERO
DUP3
MSTORE
MLOAD
SWAP1
DUP2
SWAP1
SUB
PUSH1 0x20
ADD
SWAP1
RETURN
JUMPDEST
PUSH2 0x00c0
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x00a3
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x0120
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0079
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x00d8
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x01ce
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
PUSH2 0x0129
DUP2
PUSH2 0x01df
JUMP
JUMPDEST
ISZERO
PUSH2 0x017f
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x2c
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH2 0x03eb
PUSH1 0x2c
SWAP2
CODECOPY
PUSH1 0x40
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
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
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
AND
PUSH1 0x01
OR
SWAP1
SSTORE
JUMP
JUMPDEST
PUSH1 0x00
PUSH2 0x01d9
DUP3
PUSH2 0x01df
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
DUP2
EXTCODESIZE
DUP1
PUSH2 0x024f
JUMPI
PUSH1 0x40
DUP1
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x12
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x4e6f20636f6465206174207461726765742e0000000000000000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
SWAP1
MLOAD
SWAP1
DUP2
SWAP1
SUB
PUSH1 0x64
ADD
SWAP1
REVERT
JUMPDEST
PUSH1 0x00
PUSH1 0x60
DUP3
PUSH1 0x40
MLOAD
SWAP1
DUP1
DUP3
MSTORE
DUP1
PUSH1 0x1f
ADD
PUSH1 0x1f
NOT
AND
PUSH1 0x20
ADD
DUP3
ADD
PUSH1 0x40
MSTORE
DUP1
ISZERO
PUSH2 0x027e
JUMPI
PUSH1 0x20
DUP3
ADD
DUP2
DUP1
CODESIZE
DUP4
CODECOPY
ADD
SWAP1
POP
JUMPDEST
POP
SWAP1
POP
PUSH1 0x20
DUP2
ADD
SWAP2
POP
DUP3
PUSH1 0x00
DUP4
DUP8
EXTCODECOPY
DUP2
DUP4
ADD
DUP3
DUP2
GT
PUSH2 0x02fe
JUMPI
PUSH1 0x40
DUP1
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x1c
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x536166654d6174683a206164646974696f6e206f766572666c6f772e00000000
PUSH1 0x44
DUP3
ADD
MSTORE
SWAP1
MLOAD
SWAP1
DUP2
SWAP1
SUB
PUSH1 0x64
ADD
SWAP1
REVERT
JUMPDEST
PUSH1 0x01
PUSH1 0x00
DUP5
JUMPDEST
DUP4
DUP2
LT
ISZERO
PUSH2 0x03dd
JUMPI
DUP1
MLOAD
PUSH1 0xf8
SHR
SWAP2
POP
PUSH1 0x5f
DUP3
GT
DUP1
ISZERO
PUSH2 0x0323
JUMPI
POP
PUSH1 0x80
DUP3
LT
JUMPDEST
ISZERO
PUSH2 0x0351
JUMPI
DUP2
ADD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa1
ADD
PUSH2 0x03d5
JUMP
JUMPDEST
DUP3
ISZERO
PUSH2 0x03c7
JUMPI
DUP2
PUSH1 0xfe
EQ
DUP1
PUSH2 0x0366
JUMPI
POP
DUP2
PUSH1 0xf3
EQ
JUMPDEST
DUP1
PUSH2 0x0371
JUMPI
POP
DUP2
PUSH1 0xfd
EQ
JUMPDEST
DUP1
PUSH2 0x037c
JUMPI
POP
DUP2
PUSH1 0x56
EQ
JUMPDEST
DUP1
PUSH2 0x0385
JUMPI
POP
DUP2
ISZERO
JUMPDEST
ISZERO
PUSH2 0x0393
JUMPI
PUSH1 0x00
SWAP3
POP
PUSH2 0x03d5
JUMP
JUMPDEST
DUP2
PUSH1 0xf2
EQ
DUP1
PUSH2 0x03a2
JUMPI
POP
DUP2
PUSH1 0xf4
EQ
JUMPDEST
DUP1
PUSH2 0x03ad
JUMPI
POP
DUP2
PUSH1 0xff
EQ
JUMPDEST
ISZERO
PUSH2 0x03c2
JUMPI
PUSH1 0x01
SWAP8
POP
POP
POP
POP
POP
POP
POP
POP
PUSH2 0x03e5
JUMP
JUMPDEST
PUSH2 0x03d5
JUMP
JUMPDEST
DUP2
PUSH1 0x5b
EQ
ISZERO
PUSH2 0x03d5
JUMPI
PUSH1 0x01
SWAP3
POP
JUMPDEST
PUSH1 0x01
ADD
PUSH2 0x0304
JUMP
JUMPDEST
POP
POP
POP
POP
POP
POP
POP
JUMPDEST
SWAP2
SWAP1
POP
JUMP
INVALID
MSTORE8
PUSH22 0x70706c6965642074617267657420697320706f74656e
