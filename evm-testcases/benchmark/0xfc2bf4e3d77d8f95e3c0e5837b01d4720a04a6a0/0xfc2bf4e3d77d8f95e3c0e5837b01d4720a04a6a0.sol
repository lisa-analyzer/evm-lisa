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
PUSH2 0x004a
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x1c59236b
EQ
PUSH2 0x004e
JUMPI
DUP1
PUSH4 0x250c2cc1
EQ
PUSH2 0x0058
JUMPI
DUP1
PUSH4 0xda3dcc21
EQ
PUSH2 0x009b
JUMPI
DUP1
PUSH4 0xfd0db133
EQ
PUSH2 0x00ae
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH2 0x0056
PUSH2 0x00e7
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0086
PUSH2 0x0066
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0204
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH0
SWAP1
DUP2
MSTORE
PUSH1 0x20
DUP2
SWAP1
MSTORE
PUSH1 0x40
SWAP1
SHA3
PUSH1 0x02
ADD
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
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0056
PUSH2 0x00a9
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0231
JUMP
JUMPDEST
PUSH2 0x0196
JUMP
JUMPDEST
PUSH2 0x00d9
PUSH2 0x00bc
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0204
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH0
SWAP1
DUP2
MSTORE
PUSH1 0x20
DUP2
SWAP1
MSTORE
PUSH1 0x40
SWAP1
SHA3
PUSH1 0x01
ADD
SLOAD
SWAP1
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH2 0x0092
JUMP
JUMPDEST
CALLER
PUSH0
SWAP1
DUP2
MSTORE
PUSH1 0x20
DUP2
SWAP1
MSTORE
PUSH1 0x40
SWAP1
SHA3
PUSH1 0x02
DUP2
ADD
SLOAD
PUSH1 0xff
AND
PUSH2 0x014d
JUMPI
PUSH1 0x40
MLOAD
PUSH3 0x461bcd
PUSH1 0xe5
SHL
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
DUP2
SWAP1
MSTORE
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x41757468656e7469636174696f6e206d6574686f64206e6f7420616374697665
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x02
DUP2
ADD
DUP1
SLOAD
PUSH1 0xff
NOT
AND
SWAP1
SSTORE
PUSH1 0x01
DUP2
ADD
SLOAD
PUSH1 0x40
MLOAD
SWAP1
DUP2
MSTORE
CALLER
SWAP1
PUSH32 0xc1e5e845d9d2c0db444b59598c74097b5022f60719a02fe3d3f9d9d392267031
SWAP1
PUSH1 0x20
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG2
POP
JUMP
JUMPDEST
CALLER
PUSH0
DUP2
DUP2
MSTORE
PUSH1 0x20
DUP2
DUP2
MSTORE
PUSH1 0x40
SWAP2
DUP3
SWAP1
SHA3
DUP1
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
NOT
AND
DUP5
OR
DUP2
SSTORE
PUSH1 0x01
DUP1
DUP3
ADD
DUP7
SWAP1
SSTORE
PUSH1 0x02
DUP3
ADD
DUP1
SLOAD
PUSH1 0xff
NOT
AND
SWAP1
SWAP2
OR
SWAP1
SSTORE
SWAP2
MLOAD
DUP5
DUP2
MSTORE
SWAP2
SWAP3
SWAP2
PUSH32 0xb39c64420a845b476c05dc2a1c0cd73487e92cb39dac40d335a12c1d73085a03
SWAP2
ADD
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
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0214
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
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
PUSH2 0x022a
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
SWAP4
SWAP3
POP
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0241
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
SWAP2
SWAP1
POP
JUMP
INVALID
