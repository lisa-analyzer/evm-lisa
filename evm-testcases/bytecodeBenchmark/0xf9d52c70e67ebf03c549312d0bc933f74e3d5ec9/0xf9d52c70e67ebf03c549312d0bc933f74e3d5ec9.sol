PUSH1 0x80
PUSH1 0x40
MSTORE
CALLVALUE
DUP1
ISZERO
PUSH1 0x0e
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x04
CALLDATASIZE
LT
PUSH1 0x3a
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x7f1403f7
EQ
PUSH1 0x3e
JUMPI
DUP1
PUSH4 0xb5d8b38f
EQ
PUSH1 0x3e
JUMPI
DUP1
PUSH4 0xd9cc446a
EQ
PUSH1 0x3e
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH1 0x50
PUSH1 0x49
CALLDATASIZE
PUSH1 0x04
PUSH1 0x6c
JUMP
JUMPDEST
POP
POP
POP
POP
POP
JUMP
JUMPDEST
STOP
JUMPDEST
DUP1
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
PUSH1 0x67
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
DUP1
PUSH0
DUP1
PUSH0
PUSH1 0xa0
DUP7
DUP9
SUB
SLT
ISZERO
PUSH1 0x7f
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
PUSH1 0x86
DUP7
PUSH1 0x52
JUMP
JUMPDEST
SWAP5
POP
PUSH1 0x92
PUSH1 0x20
DUP8
ADD
PUSH1 0x52
JUMP
JUMPDEST
SWAP4
POP
PUSH1 0x40
DUP7
ADD
CALLDATALOAD
SWAP3
POP
PUSH1 0x60
DUP7
ADD
CALLDATALOAD
PUSH1 0xff
DUP2
AND
DUP2
EQ
PUSH1 0xad
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
SWAP5
SWAP8
SWAP4
SWAP7
POP
SWAP2
SWAP5
PUSH1 0x80
ADD
CALLDATALOAD
SWAP3
SWAP2
POP
POP
JUMP
INVALID
