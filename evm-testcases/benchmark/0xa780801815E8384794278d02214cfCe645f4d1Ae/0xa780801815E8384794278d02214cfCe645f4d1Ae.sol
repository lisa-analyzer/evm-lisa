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
PUSH4 0xe1f1c4a7
EQ
PUSH1 0x37
JUMPI
DUP1
PUSH4 0xfccc2813
EQ
PUSH1 0x4c
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x2710
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
PUSH1 0x40
MLOAD
PUSH2 0xdead
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x43
JUMP
INVALID
LOG1
PUSH5 0x736f6c6343
STOP
ADDMOD
OR
STOP
EXP
