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
PUSH2 0x0041
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x30fa738c
EQ
PUSH2 0x0046
JUMPI
DUP1
PUSH4 0xd4fac45d
EQ
PUSH2 0x0064
JUMPI
DUP1
PUSH4 0xf72c0791
EQ
PUSH2 0x0084
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x004e
PUSH2 0x008c
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x005b
SWAP2
SWAP1
PUSH2 0x01d6
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0077
PUSH2 0x0072
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0176
JUMP
JUMPDEST
PUSH2 0x00ad
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x005b
SWAP2
SWAP1
PUSH2 0x0229
JUMP
JUMPDEST
PUSH2 0x004e
PUSH2 0x013e
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
PUSH1 0x40
ADD
PUSH1 0x40
MSTORE
DUP1
PUSH1 0x05
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH5 0x0455243323
PUSH1 0xdc
SHL
DUP2
MSTORE
POP
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH3 0x466131
PUSH1 0xe1
SHL
DUP2
MSTORE
PUSH1 0x00
SWAP1
PUSH20 0xc746bc860781dc90bbfcd381d6a058dc16357f8d
SWAP1
PUSH3 0x8cc262
SWAP1
PUSH2 0x00e5
SWAP1
DUP6
SWAP1
PUSH1 0x04
ADD
PUSH2 0x01c2
JUMP
JUMPDEST
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
PUSH2 0x00fd
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
PUSH2 0x0111
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
PUSH2 0x0135
SWAP2
SWAP1
PUSH2 0x01aa
JUMP
JUMPDEST
SWAP1
POP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
PUSH1 0x40
ADD
PUSH1 0x40
MSTORE
DUP1
PUSH1 0x05
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH5 0x105cdcd95d
PUSH1 0xda
SHL
DUP2
MSTORE
POP
DUP2
JUMP
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
PUSH2 0x0138
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x00
DUP1
PUSH1 0x40
DUP4
DUP6
SUB
SLT
ISZERO
PUSH2 0x0188
JUMPI
DUP2
DUP3
REVERT
JUMPDEST
PUSH2 0x0192
DUP5
DUP5
PUSH2 0x015f
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x01a1
DUP5
PUSH1 0x20
DUP6
ADD
PUSH2 0x015f
JUMP
JUMPDEST
SWAP1
POP
SWAP3
POP
SWAP3
SWAP1
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x01bb
JUMPI
DUP1
DUP2
REVERT
JUMPDEST
POP
MLOAD
SWAP2
SWAP1
POP
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
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP1
DUP4
MSTORE
DUP4
MLOAD
DUP1
DUP3
DUP6
ADD
MSTORE
DUP3
JUMPDEST
DUP2
DUP2
LT
ISZERO
PUSH2 0x0202
JUMPI
DUP6
DUP2
ADD
DUP4
ADD
MLOAD
DUP6
DUP3
ADD
PUSH1 0x40
ADD
MSTORE
DUP3
ADD
PUSH2 0x01e6
JUMP
JUMPDEST
DUP2
DUP2
GT
ISZERO
PUSH2 0x0213
JUMPI
DUP4
PUSH1 0x40
DUP4
DUP8
ADD
ADD
MSTORE
JUMPDEST
POP
PUSH1 0x1f
ADD
PUSH1 0x1f
NOT
AND
SWAP3
SWAP1
SWAP3
ADD
PUSH1 0x40
ADD
SWAP4
SWAP3
POP
POP
POP
JUMP
JUMPDEST
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
JUMP
INVALID
