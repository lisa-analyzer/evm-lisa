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
PUSH2 0x0036
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x733eb143
EQ
PUSH2 0x003b
JUMPI
DUP1
PUSH4 0xb8d06bc4
EQ
PUSH2 0x00f6
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x00f4
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x80
DUP2
LT
ISZERO
PUSH2 0x0051
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
SWAP2
PUSH1 0x20
DUP2
ADD
CALLDATALOAD
SWAP2
PUSH1 0x40
DUP3
ADD
CALLDATALOAD
SWAP2
SWAP1
DUP2
ADD
SWAP1
PUSH1 0x80
DUP2
ADD
PUSH1 0x60
DUP3
ADD
CALLDATALOAD
PUSH5 0x0100000000
DUP2
GT
ISZERO
PUSH2 0x007f
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP3
ADD
DUP4
PUSH1 0x20
DUP3
ADD
GT
ISZERO
PUSH2 0x0091
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
CALLDATALOAD
SWAP1
PUSH1 0x20
ADD
SWAP2
DUP5
PUSH1 0x01
DUP4
MUL
DUP5
ADD
GT
PUSH5 0x0100000000
DUP4
GT
OR
ISZERO
PUSH2 0x00b3
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP2
SWAP1
DUP1
DUP1
PUSH1 0x1f
ADD
PUSH1 0x20
DUP1
SWAP2
DIV
MUL
PUSH1 0x20
ADD
PUSH1 0x40
MLOAD
SWAP1
DUP2
ADD
PUSH1 0x40
MSTORE
DUP1
SWAP4
SWAP3
SWAP2
SWAP1
DUP2
DUP2
MSTORE
PUSH1 0x20
ADD
DUP4
DUP4
DUP1
DUP3
DUP5
CALLDATACOPY
PUSH1 0x00
SWAP3
ADD
SWAP2
SWAP1
SWAP2
MSTORE
POP
SWAP3
SWAP6
POP
PUSH2 0x013a
SWAP5
POP
POP
POP
POP
POP
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0128
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x60
DUP2
LT
ISZERO
PUSH2 0x010c
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP2
CALLDATALOAD
AND
SWAP1
PUSH1 0x20
DUP2
ADD
CALLDATALOAD
SWAP1
PUSH1 0x40
ADD
CALLDATALOAD
PUSH2 0x03e2
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
PUSH1 0x20
DUP2
ADD
MLOAD
PUSH1 0x40
DUP1
DUP4
ADD
MLOAD
PUSH1 0x60
DUP5
ADD
MLOAD
DUP3
MLOAD
PUSH4 0x23f2ebc3
PUSH1 0xe2
SHL
DUP2
MSTORE
CALLER
PUSH1 0x04
DUP3
ADD
MSTORE
ADDRESS
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH1 0x44
DUP2
ADD
DUP9
SWAP1
MSTORE
PUSH1 0x64
DUP2
ADD
DUP8
SWAP1
MSTORE
PUSH1 0x01
PUSH1 0x84
DUP3
ADD
MSTORE
PUSH1 0x00
SWAP2
DUP3
BYTE
PUSH1 0xa4
DUP3
ADD
DUP2
SWAP1
MSTORE
PUSH1 0xc4
DUP3
ADD
DUP7
SWAP1
MSTORE
PUSH1 0xe4
DUP3
ADD
DUP5
SWAP1
MSTORE
SWAP4
MLOAD
SWAP3
SWAP4
SWAP3
PUSH20 0x6b175474e89094c44da98b954eedeac495271d0f
SWAP3
PUSH4 0x8fcbaf0c
SWAP3
PUSH2 0x0104
DUP1
DUP3
ADD
SWAP4
SWAP2
DUP3
SWAP1
SUB
ADD
DUP2
DUP4
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x01cf
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
PUSH2 0x01e3
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
PUSH1 0x40
DUP1
MLOAD
PUSH4 0x23b872dd
PUSH1 0xe0
SHL
DUP2
MSTORE
CALLER
PUSH1 0x04
DUP3
ADD
MSTORE
ADDRESS
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH1 0x44
DUP2
ADD
DUP12
SWAP1
MSTORE
SWAP1
MLOAD
PUSH20 0x6b175474e89094c44da98b954eedeac495271d0f
SWAP4
POP
PUSH4 0x23b872dd
SWAP3
POP
PUSH1 0x64
DUP1
DUP4
ADD
SWAP3
PUSH1 0x20
SWAP3
SWAP2
SWAP1
DUP3
SWAP1
SUB
ADD
DUP2
PUSH1 0x00
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0247
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
PUSH2 0x025b
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
PUSH2 0x0271
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
PUSH2 0x02ae
JUMPI
PUSH1 0x40
MLOAD
PUSH3 0x461bcd
PUSH1 0xe5
SHL
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
PUSH1 0x48
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH2 0x04f9
PUSH1 0x48
SWAP2
CODECOPY
PUSH1 0x60
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
PUSH16 0x938f41360a846490409500d08919856c
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH4 0x3d8b7894
DUP9
PUSH1 0x40
MLOAD
DUP3
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP3
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
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
PUSH2 0x0304
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
PUSH2 0x0318
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
PUSH1 0x40
DUP1
MLOAD
PUSH4 0xa9059cbb
PUSH1 0xe0
SHL
DUP2
MSTORE
CALLER
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x24
DUP2
ADD
DUP12
SWAP1
MSTORE
SWAP1
MLOAD
PUSH16 0x938f41360a846490409500d08919856c
SWAP4
POP
PUSH4 0xa9059cbb
SWAP3
POP
PUSH1 0x44
DUP1
DUP4
ADD
SWAP3
PUSH1 0x20
SWAP3
SWAP2
SWAP1
DUP3
SWAP1
SUB
ADD
DUP2
PUSH1 0x00
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0372
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
PUSH2 0x0386
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
PUSH2 0x039c
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
PUSH2 0x03d9
JUMPI
PUSH1 0x40
MLOAD
PUSH3 0x461bcd
PUSH1 0xe5
SHL
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
PUSH1 0x4b
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH2 0x04ae
PUSH1 0x4b
SWAP2
CODECOPY
PUSH1 0x60
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
POP
POP
POP
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
PUSH32 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb
PUSH1 0x20
DUP1
DUP4
ADD
SWAP2
SWAP1
SWAP2
MSTORE
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP6
AND
DUP2
DUP4
ADD
MSTORE
ADDRESS
PUSH1 0x60
DUP3
ADD
MSTORE
PUSH1 0x80
DUP2
ADD
SWAP4
SWAP1
SWAP4
MSTORE
PUSH1 0xa0
DUP4
ADD
SWAP2
SWAP1
SWAP2
MSTORE
PUSH1 0x01
PUSH1 0xc0
DUP1
DUP5
ADD
SWAP2
SWAP1
SWAP2
MSTORE
DUP2
MLOAD
DUP1
DUP5
SUB
SWAP1
SWAP2
ADD
DUP2
MSTORE
PUSH1 0xe0
DUP4
ADD
DUP3
MSTORE
DUP1
MLOAD
SWAP1
DUP5
ADD
SHA3
PUSH2 0x1901
PUSH1 0xf0
SHL
PUSH2 0x0100
DUP5
ADD
MSTORE
PUSH32 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7
PUSH2 0x0102
DUP5
ADD
MSTORE
PUSH2 0x0122
DUP1
DUP5
ADD
SWAP2
SWAP1
SWAP2
MSTORE
DUP2
MLOAD
DUP1
DUP5
SUB
SWAP1
SWAP2
ADD
DUP2
MSTORE
PUSH2 0x0142
SWAP1
SWAP3
ADD
SWAP1
MSTORE
DUP1
MLOAD
SWAP2
ADD
SHA3
SWAP1
JUMP
INVALID
DIFFICULTY
PUSH2 0x6942
PUSH2 0x636b
PUSH20 0x746f7053796e646963617465456e6c6973746572
JUMP
BALANCE
'2f'(Unknown Opcode)
PUSH2 0x7070
PUSH19 0x6f7665416e64456e6c6973743a20546f6b656e
SHA3
PUSH21 0x72616e73666572206f7574206661696c65642e4461
PUSH10 0x4261636b73746f705379
PUSH15 0x646963617465456e6c697374657256
BALANCE
'2f'(Unknown Opcode)
PUSH2 0x7070
PUSH19 0x6f7665416e64456e6c6973743a204461692074
