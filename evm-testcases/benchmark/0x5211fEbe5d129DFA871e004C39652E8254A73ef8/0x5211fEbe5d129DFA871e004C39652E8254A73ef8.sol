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
PUSH2 0x0052
JUMPI
PUSH29 0x0100000000000000000000000000000000000000000000000000000000
PUSH1 0x00
CALLDATALOAD
DIV
PUSH4 0x57de26a4
DUP2
EQ
PUSH2 0x0057
JUMPI
DUP1
PUSH4 0xcac8ea6c
EQ
PUSH2 0x0071
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x005f
PUSH2 0x00a2
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
SWAP2
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
PUSH2 0x0079
PUSH2 0x0158
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP3
AND
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
PUSH1 0x00
DUP1
PUSH1 0x00
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
PUSH4 0x57de26a4
PUSH1 0x40
MLOAD
DUP2
PUSH4 0xffffffff
AND
PUSH29 0x0100000000000000000000000000000000000000000000000000000000
MUL
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP7
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0127
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x013b
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
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x0151
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
JUMP
INVALID