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
PUSH2 0x003f
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x0f95416d
EQ
PUSH2 0x0043
JUMPI
DUP1
PUSH4 0x73125163
EQ
PUSH2 0x0058
JUMPI
DUP1
PUSH4 0x7d294e62
EQ
PUSH2 0x006b
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x0056
PUSH2 0x0051
CALLDATASIZE
PUSH1 0x04
PUSH2 0x016c
JUMP
JUMPDEST
PUSH2 0x00b5
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0056
PUSH2 0x0066
CALLDATASIZE
PUSH1 0x04
PUSH2 0x016c
JUMP
JUMPDEST
PUSH2 0x0116
JUMP
JUMPDEST
PUSH2 0x00a1
PUSH2 0x0079
CALLDATASIZE
PUSH1 0x04
PUSH2 0x016c
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP2
SWAP1
SWAP2
AND
PUSH0
SWAP1
DUP2
MSTORE
PUSH1 0x20
DUP2
DUP2
MSTORE
PUSH1 0x40
DUP1
DUP4
SHA3
SWAP4
DUP4
MSTORE
SWAP3
SWAP1
MSTORE
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
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP3
AND
PUSH0
DUP2
DUP2
MSTORE
PUSH1 0x20
DUP2
DUP2
MSTORE
PUSH1 0x40
DUP1
DUP4
SHA3
DUP6
DUP5
MSTORE
DUP3
MSTORE
SWAP2
DUP3
SWAP1
SHA3
DUP1
SLOAD
PUSH1 0xff
NOT
AND
PUSH1 0x01
OR
SWAP1
SSTORE
SWAP1
MLOAD
DUP4
DUP2
MSTORE
PUSH32 0xbd4f54568b7c91392f03009967e46b0688bd75843f35612613c087fd973cea53
SWAP2
ADD
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG2
POP
POP
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP3
AND
PUSH0
DUP2
DUP2
MSTORE
PUSH1 0x20
DUP2
DUP2
MSTORE
PUSH1 0x40
DUP1
DUP4
SHA3
DUP6
DUP5
MSTORE
DUP3
MSTORE
SWAP2
DUP3
SWAP1
SHA3
DUP1
SLOAD
PUSH1 0xff
NOT
AND
SWAP1
SSTORE
SWAP1
MLOAD
DUP4
DUP2
MSTORE
PUSH32 0x6161f38d7bcbdabae613358e81c1e09bb790d78ad5ef6863c32d798ca667fa90
SWAP2
ADD
PUSH2 0x010a
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
PUSH2 0x017d
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP3
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
PUSH2 0x0193
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
SWAP5
PUSH1 0x20
SWAP4
SWAP1
SWAP4
ADD
CALLDATALOAD
SWAP4
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
'bf'(Unknown Opcode)
'f7'(Unknown Opcode)
'a5'(Unknown Opcode)
'4d'(Unknown Opcode)
REVERT
'cc'(Unknown Opcode)
'b8'(Unknown Opcode)
PUSH25 0xc30c39a638491b4cd23ed2a3fa41304e2815bea48d9e81fb64
PUSH20 0x6f6c63430008190033