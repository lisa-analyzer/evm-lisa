PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x0a
PUSH1 0x0c
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH1 0x18
PUSH1 0x14
PUSH1 0x1a
JUMP
JUMPDEST
PUSH1 0x51
JUMP
JUMPDEST
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x4c
PUSH32 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
SWAP1
JUMP
JUMPDEST
SWAP1
POP
SWAP1
JUMP
JUMPDEST
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
PUSH1 0x6f
JUMPI
RETURNDATASIZE
PUSH1 0x00
RETURN
JUMPDEST
RETURNDATASIZE
PUSH1 0x00
REVERT
INVALID