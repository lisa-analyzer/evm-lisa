PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x0028
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x3ccfd60b
EQ
PUSH2 0x002c
JUMPI
DUP1
PUSH4 0xaf347b61
EQ
PUSH2 0x0042
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0037
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0040
PUSH2 0x004c
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x004a
PUSH2 0x0107
JUMP
JUMPDEST
STOP
JUMPDEST
CALLER
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
EQ
PUSH2 0x00a2
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
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
PUSH2 0x08fc
SELFBALANCE
SWAP1
DUP2
ISZERO
MUL
SWAP1
PUSH1 0x40
MLOAD
PUSH0
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
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
PUSH2 0x0104
JUMPI
RETURNDATASIZE
PUSH0
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH0
REVERT
JUMPDEST
POP
JUMP
JUMPDEST
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
ADDRESS
EXTCODESIZE
PUSH29 0x7a28c75626fc2de399adb7ed7e9f6f26d22c2d832458d50efb6e4b31fa
PUSH5 0x736f6c6343
STOP
ADDMOD
OR
STOP
CALLER
