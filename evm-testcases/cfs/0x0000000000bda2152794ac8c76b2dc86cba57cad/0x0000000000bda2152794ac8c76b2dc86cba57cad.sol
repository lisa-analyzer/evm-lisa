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
CALLER
PUSH16 0x011df015e8ad00d7b2486a88c2eb8210
EQ
PUSH1 0x32
JUMPI
PUSH1 0x00
SLOAD
PUSH1 0x00
MSTORE
PUSH1 0x20
PUSH1 0x00
RETURN
JUMPDEST
PUSH1 0x00
CALLDATALOAD
PUSH1 0x00
SSTORE
STOP
INVALID
