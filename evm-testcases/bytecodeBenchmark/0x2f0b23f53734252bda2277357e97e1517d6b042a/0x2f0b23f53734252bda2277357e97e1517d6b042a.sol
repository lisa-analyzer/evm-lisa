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
PUSH2 0x00a9
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x957aa58c
GT
PUSH2 0x0071
JUMPI
DUP1
PUSH4 0x957aa58c
EQ
PUSH2 0x01de
JUMPI
DUP1
PUSH4 0x9c52a7f1
EQ
PUSH2 0x01fc
JUMPI
DUP1
PUSH4 0xb3bcfa82
EQ
PUSH2 0x0240
JUMPI
DUP1
PUSH4 0xbf353dbb
EQ
PUSH2 0x025e
JUMPI
DUP1
PUSH4 0xc5ce281e
EQ
PUSH2 0x02b6
JUMPI
DUP1
PUSH4 0xef693bed
EQ
PUSH2 0x02d4
JUMPI
PUSH2 0x00a9
JUMP
JUMPDEST
DUP1
PUSH4 0x36569e77
EQ
PUSH2 0x00ae
JUMPI
DUP1
PUSH4 0x3b4da69f
EQ
PUSH2 0x00f8
JUMPI
DUP1
PUSH4 0x65fae35e
EQ
PUSH2 0x0146
JUMPI
DUP1
PUSH4 0x69245009
EQ
PUSH2 0x018a
JUMPI
DUP1
PUSH4 0x7bd2bea7
EQ
PUSH2 0x0194
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x00b6
PUSH2 0x0322
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
DUP3
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0144
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x40
DUP2
LT
ISZERO
PUSH2 0x010e
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
ADD
SWAP1
DUP1
DUP1
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
DUP1
CALLDATALOAD
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
POP
POP
POP
PUSH2 0x0348
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0188
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x015c
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
ADD
SWAP1
DUP1
DUP1
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
POP
POP
POP
PUSH2 0x06c3
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0192
PUSH2 0x07f1
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x019c
PUSH2 0x08e2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
DUP3
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x01e6
PUSH2 0x0908
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x023e
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x0212
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
ADD
SWAP1
DUP1
DUP1
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
POP
POP
POP
PUSH2 0x090e
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0248
PUSH2 0x0a3c
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x02a0
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x0274
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
ADD
SWAP1
DUP1
DUP1
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
POP
POP
POP
PUSH2 0x0a42
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x02be
PUSH2 0x0a5a
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x0320
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x40
DUP2
LT
ISZERO
PUSH2 0x02ea
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
ADD
SWAP1
DUP1
DUP1
CALLDATALOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
DUP1
CALLDATALOAD
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
POP
POP
POP
PUSH2 0x0a60
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH1 0x01
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
DUP2
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x05
SLOAD
EQ
PUSH2 0x03c0
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x10
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6e6f742d6c69766500000000000000000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x00
DUP2
SLT
ISZERO
PUSH2 0x0437
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x10
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6f766572666c6f7700000000000000000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x01
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
PUSH4 0x7cdd3fde
PUSH1 0x02
SLOAD
DUP5
DUP5
PUSH1 0x40
MLOAD
DUP5
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP5
DUP2
MSTORE
PUSH1 0x20
ADD
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP4
POP
POP
POP
POP
PUSH1 0x00
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH1 0x00
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x04ea
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x04fe
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
PUSH1 0x03
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
PUSH4 0x23b872dd
CALLER
ADDRESS
DUP5
PUSH1 0x40
MLOAD
DUP5
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP5
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP4
POP
POP
POP
POP
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH1 0x00
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x05df
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x05f3
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
PUSH2 0x0609
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
ADD
SWAP1
DUP1
DUP1
MLOAD
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
POP
POP
POP
PUSH2 0x068c
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x17
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6661696c65642d7472616e73666572000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
MSIZE
PUSH2 0x0120
DUP2
ADD
PUSH1 0x40
MSTORE
PUSH1 0x20
DUP2
MSTORE
PUSH1 0xe0
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0xe0
PUSH1 0x00
PUSH1 0x40
DUP4
ADD
CALLDATACOPY
PUSH1 0x24
CALLDATALOAD
PUSH1 0x04
CALLDATALOAD
CALLER
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
PUSH1 0xe0
SHL
PUSH2 0x0120
DUP6
LOG4
POP
POP
POP
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x00
DUP1
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x00
SHA3
SLOAD
EQ
PUSH2 0x0777
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x16
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6e6f742d617574686f72697a656400000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x01
PUSH1 0x00
DUP1
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x00
SHA3
DUP2
SWAP1
SSTORE
POP
MSIZE
PUSH2 0x0120
DUP2
ADD
PUSH1 0x40
MSTORE
PUSH1 0x20
DUP2
MSTORE
PUSH1 0xe0
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0xe0
PUSH1 0x00
PUSH1 0x40
DUP4
ADD
CALLDATACOPY
PUSH1 0x24
CALLDATALOAD
PUSH1 0x04
CALLDATALOAD
CALLER
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
PUSH1 0xe0
SHL
PUSH2 0x0120
DUP6
LOG4
POP
POP
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x00
DUP1
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x00
SHA3
SLOAD
EQ
PUSH2 0x08a5
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x16
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6e6f742d617574686f72697a656400000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x00
PUSH1 0x05
DUP2
SWAP1
SSTORE
POP
MSIZE
PUSH2 0x0120
DUP2
ADD
PUSH1 0x40
MSTORE
PUSH1 0x20
DUP2
MSTORE
PUSH1 0xe0
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0xe0
PUSH1 0x00
PUSH1 0x40
DUP4
ADD
CALLDATACOPY
PUSH1 0x24
CALLDATALOAD
PUSH1 0x04
CALLDATALOAD
CALLER
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
PUSH1 0xe0
SHL
PUSH2 0x0120
DUP6
LOG4
POP
JUMP
JUMPDEST
PUSH1 0x03
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
DUP2
JUMP
JUMPDEST
PUSH1 0x05
SLOAD
DUP2
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x00
DUP1
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x00
SHA3
SLOAD
EQ
PUSH2 0x09c2
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x16
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6e6f742d617574686f72697a656400000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x00
DUP1
PUSH1 0x00
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x00
SHA3
DUP2
SWAP1
SSTORE
POP
MSIZE
PUSH2 0x0120
DUP2
ADD
PUSH1 0x40
MSTORE
PUSH1 0x20
DUP2
MSTORE
PUSH1 0xe0
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0xe0
PUSH1 0x00
PUSH1 0x40
DUP4
ADD
CALLDATACOPY
PUSH1 0x24
CALLDATALOAD
PUSH1 0x04
CALLDATALOAD
CALLER
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
PUSH1 0xe0
SHL
PUSH2 0x0120
DUP6
LOG4
POP
POP
JUMP
JUMPDEST
PUSH1 0x04
SLOAD
DUP2
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
MSTORE
DUP1
PUSH1 0x00
MSTORE
PUSH1 0x40
PUSH1 0x00
SHA3
PUSH1 0x00
SWAP2
POP
SWAP1
POP
SLOAD
DUP2
JUMP
JUMPDEST
PUSH1 0x02
SLOAD
DUP2
JUMP
JUMPDEST
PUSH32 0x8000000000000000000000000000000000000000000000000000000000000000
DUP2
GT
ISZERO
PUSH2 0x0af6
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x10
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6f766572666c6f7700000000000000000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x01
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
PUSH4 0x7cdd3fde
PUSH1 0x02
SLOAD
CALLER
DUP5
PUSH1 0x00
SUB
PUSH1 0x40
MLOAD
DUP5
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP5
DUP2
MSTORE
PUSH1 0x20
ADD
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP4
POP
POP
POP
POP
PUSH1 0x00
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH1 0x00
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0bac
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x0bc0
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
PUSH1 0x03
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
PUSH4 0xa9059cbb
DUP4
DUP4
PUSH1 0x40
MLOAD
DUP4
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP4
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
MSTORE
PUSH1 0x20
ADD
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP3
POP
POP
POP
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH1 0x00
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0c6d
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x0c81
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
PUSH2 0x0c97
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
ADD
SWAP1
DUP1
DUP1
MLOAD
SWAP1
PUSH1 0x20
ADD
SWAP1
SWAP3
SWAP2
SWAP1
POP
POP
POP
PUSH2 0x0d1a
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP1
PUSH1 0x20
ADD
DUP3
DUP2
SUB
DUP3
MSTORE
PUSH1 0x17
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH32 0x47656d4a6f696e2f6661696c65642d7472616e73666572000000000000000000
DUP2
MSTORE
POP
PUSH1 0x20
ADD
SWAP2
POP
POP
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
MSIZE
PUSH2 0x0120
DUP2
ADD
PUSH1 0x40
MSTORE
PUSH1 0x20
DUP2
MSTORE
PUSH1 0xe0
PUSH1 0x20
DUP3
ADD
MSTORE
PUSH1 0xe0
PUSH1 0x00
PUSH1 0x40
DUP4
ADD
CALLDATACOPY
PUSH1 0x24
CALLDATALOAD
PUSH1 0x04
CALLDATALOAD
CALLER
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
PUSH1 0xe0
SHL
PUSH2 0x0120
DUP6
LOG4
POP
POP
POP
JUMP
INVALID