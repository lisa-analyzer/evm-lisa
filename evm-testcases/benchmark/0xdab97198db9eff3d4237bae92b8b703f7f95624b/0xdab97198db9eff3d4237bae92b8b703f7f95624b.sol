PUSH1 0x03
CALLDATASIZE
GT
PUSH2 0x000c
JUMPI
PUSH2 0x00a7
JUMP
JUMPDEST
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
CALLVALUE
PUSH2 0x00ad
JUMPI
PUSH4 0x0ba9d8ca
DUP2
XOR
PUSH2 0x00a5
JUMPI
PUSH1 0x24
CALLDATASIZE
LT
PUSH2 0x00ad
JUMPI
PUSH1 0x04
CALLDATALOAD
DUP1
PUSH1 0xa0
SHR
PUSH2 0x00ad
JUMPI
PUSH1 0x40
MSTORE
PUSH20 0x9ba021b0a9b958b5e75ce9f6dff97c7ee52cb3e6
PUSH1 0x40
MLOAD
XOR
PUSH2 0x00ad
JUMPI
PUSH1 0x20
PUSH4 0x07a2d13a
PUSH1 0x60
MSTORE
PUSH8 0x0de0b6b3a7640000
PUSH1 0x80
MSTORE
PUSH1 0x20
PUSH1 0x60
PUSH1 0x24
PUSH1 0x7c
PUSH20 0x9ba021b0a9b958b5e75ce9f6dff97c7ee52cb3e6
GAS
STATICCALL
PUSH2 0x0099
JUMPI
RETURNDATASIZE
PUSH1 0x00
PUSH1 0x00
RETURNDATACOPY
RETURNDATASIZE
PUSH1 0x00
REVERT
JUMPDEST
PUSH1 0x20
RETURNDATASIZE
LT
PUSH2 0x00ad
JUMPI
PUSH1 0x60
RETURN
JUMPDEST
POP
JUMPDEST
PUSH1 0x00
PUSH1 0x00
REVERT
JUMPDEST
PUSH1 0x00
DUP1
REVERT
LOG1
PUSH6 0x767970657283
STOP
SUB
SMOD
STOP
SIGNEXTEND
