PUSH1 0x80
PUSH1 0x40
MSTORE
CALLDATASIZE
PUSH2 0x000b
JUMPI
STOP
JUMPDEST
PUSH1 0x00
PUSH32 0xbec77a503c47907b093281e779d211f6b514083b5f8064a268e3b9dcae86aa87
SLOAD
PUSH1 0x40
MLOAD
PUSH32 0xc2c9581400000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x00
DUP1
CALLDATALOAD
PUSH32 0xffffffff00000000000000000000000000000000000000000000000000000000
AND
PUSH1 0x04
DUP4
ADD
MSTORE
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP3
AND
SWAP3
POP
DUP3
SWAP1
PUSH4 0xc2c95814
SWAP1
PUSH1 0x24
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
PUSH2 0x00c2
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
PUSH2 0x00e6
SWAP2
SWAP1
PUSH2 0x010f
JUMP
JUMPDEST
SWAP1
POP
CALLDATASIZE
PUSH1 0x00
DUP1
CALLDATACOPY
PUSH1 0x00
DUP1
CALLDATASIZE
PUSH1 0x00
DUP5
GAS
DELEGATECALL
RETURNDATASIZE
PUSH1 0x00
DUP1
RETURNDATACOPY
DUP1
DUP1
ISZERO
PUSH2 0x0107
JUMPI
RETURNDATASIZE
PUSH1 0x00
RETURN
JUMPDEST
RETURNDATASIZE
PUSH1 0x00
REVERT
JUMPDEST
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
PUSH2 0x0121
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP2
AND
DUP2
EQ
PUSH2 0x0145
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP4
SWAP3
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
CALLDATALOAD
'ce'(Unknown Opcode)
CALLVALUE
'c1'(Unknown Opcode)
'2f'(Unknown Opcode)
PUSH1 0x82
'fb'(Unknown Opcode)
PUSH13 0x17799daa17ef106263ff99c592
INVALID
'b1'(Unknown Opcode)
CALLCODE
'c6'(Unknown Opcode)
'b1'(Unknown Opcode)
'1f'(Unknown Opcode)
'dd'(Unknown Opcode)
PUSH16 0xc1a864736f6c63430008120033
