PUSH1 0x80
PUSH1 0x40
MSTORE
CALLVALUE
DUP1
ISZERO
PUSH1 0x0f
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x04
CALLDATASIZE
LT
PUSH1 0x32
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x86d1a69f
EQ
PUSH1 0x37
JUMPI
DUP1
PUSH4 0xa9194e31
EQ
PUSH1 0x3f
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x3d
PUSH1 0xb7
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH1 0x45
PUSH1 0xba
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
PUSH1 0x20
DUP1
DUP3
MSTORE
DUP4
MLOAD
DUP2
DUP4
ADD
MSTORE
DUP4
MLOAD
SWAP2
SWAP3
DUP4
SWAP3
SWAP1
DUP4
ADD
SWAP2
DUP6
ADD
SWAP1
DUP1
DUP4
DUP4
PUSH1 0x00
JUMPDEST
DUP4
DUP2
LT
ISZERO
PUSH1 0x7d
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
PUSH1 0x67
JUMP
JUMPDEST
POP
POP
POP
POP
SWAP1
POP
SWAP1
DUP2
ADD
SWAP1
PUSH1 0x1f
AND
DUP1
ISZERO
PUSH1 0xa9
JUMPI
DUP1
DUP3
SUB
DUP1
MLOAD
PUSH1 0x01
DUP4
PUSH1 0x20
SUB
PUSH2 0x0100
EXP
SUB
NOT
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
POP
JUMPDEST
POP
SWAP3
POP
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
CALLER
SELFDESTRUCT
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
DUP1
DUP3
ADD
SWAP1
SWAP2
MSTORE
PUSH1 0x0a
DUP2
MSTORE
PUSH10 0x1a195b1b1bdddbdb1c99
PUSH1 0xb2
SHL
PUSH1 0x20
DUP3
ADD
MSTORE
SWAP1
JUMP
INVALID
LOG2
PUSH6 0x627a7a723158
SHA3
SWAP10
'f6'(Unknown Opcode)
RETURN
'f9'(Unknown Opcode)
PUSH20 0x9a3452c26b3f613ac440e643066a90a1dad3a82f
SHL
EXTCODECOPY
'de'(Unknown Opcode)
PUSH8 0xc2987264736f6c63
NUMBER
STOP
SDIV
GT
STOP
ORIGIN
