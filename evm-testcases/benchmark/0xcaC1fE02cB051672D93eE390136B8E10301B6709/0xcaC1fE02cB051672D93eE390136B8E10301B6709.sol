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
PUSH2 0x0036
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x828bd7fe
EQ
PUSH2 0x003b
JUMPI
DUP1
PUSH4 0xa05f32dc
EQ
PUSH2 0x0050
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x004e
PUSH2 0x0049
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0144
JUMP
JUMPDEST
PUSH2 0x0093
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0077
PUSH32 0x0000000000000000000000009757f2d2b135150bbeb65308d4a91804107cd8d6
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
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH1 0x40
MLOAD
PUSH4 0x5ba6474d
PUSH1 0xe1
SHL
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP5
DUP2
AND
PUSH1 0x04
DUP4
ADD
MSTORE
PUSH6 0xffffffffffff
DUP1
DUP6
AND
PUSH1 0x24
DUP5
ADD
MSTORE
DUP4
AND
PUSH1 0x44
DUP4
ADD
MSTORE
PUSH32 0x0000000000000000000000009757f2d2b135150bbeb65308d4a91804107cd8d6
AND
SWAP1
PUSH4 0xb74c8e9a
SWAP1
PUSH1 0x64
ADD
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
PUSH2 0x010c
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
PUSH2 0x0120
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
POP
POP
POP
JUMP
JUMPDEST
DUP1
CALLDATALOAD
PUSH6 0xffffffffffff
DUP2
AND
DUP2
EQ
PUSH2 0x013f
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
PUSH1 0x00
DUP1
PUSH1 0x00
PUSH1 0x60
DUP5
DUP7
SUB
SLT
ISZERO
PUSH2 0x0159
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP4
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
PUSH2 0x0170
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP3
POP
PUSH2 0x017e
PUSH1 0x20
DUP6
ADD
PUSH2 0x0129
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x018c
PUSH1 0x40
DUP6
ADD
PUSH2 0x0129
JUMP
JUMPDEST
SWAP1
POP
SWAP3
POP
SWAP3
POP
SWAP3
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
'f8'(Unknown Opcode)
PUSH4 0x6f1ab42f
SWAP1
PUSH14 0xde6f7ae76a2f5ed9ad5e74f9ae18
'2d'(Unknown Opcode)
'b2'(Unknown Opcode)
SWAP11
PUSH10 0x9df97f70cf0164736f6c
PUSH4 0x43000810
STOP
CALLER
