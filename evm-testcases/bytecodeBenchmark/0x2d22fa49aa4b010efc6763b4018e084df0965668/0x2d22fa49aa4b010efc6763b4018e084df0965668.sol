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
PUSH4 0x8da5cb5b
EQ
PUSH2 0x004e
JUMPI
DUP1
PUSH4 0x9e281a98
EQ
PUSH2 0x007c
JUMPI
DUP1
PUSH4 0xb6b55f25
EQ
PUSH2 0x0091
JUMPI
DUP1
PUSH4 0xf2fde38b
EQ
PUSH2 0x00a4
JUMPI
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH0
SLOAD
PUSH2 0x0060
SWAP1
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP2
AND
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN
JUMPDEST
PUSH2 0x008f
PUSH2 0x008a
CALLDATASIZE
PUSH1 0x04
PUSH2 0x0362
JUMP
JUMPDEST
PUSH2 0x00b7
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x008f
PUSH2 0x009f
CALLDATASIZE
PUSH1 0x04
PUSH2 0x038c
JUMP
JUMPDEST
PUSH2 0x0163
JUMP
JUMPDEST
PUSH2 0x008f
PUSH2 0x00b2
CALLDATASIZE
PUSH1 0x04
PUSH2 0x03a3
JUMP
JUMPDEST
PUSH2 0x02b9
JUMP
JUMPDEST
PUSH0
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
CALLER
EQ
PUSH2 0x0104
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
MSTORE
PUSH1 0x0c
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH12 0x15539055551213d492569151
PUSH1 0xa2
SHL
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH1 0x40
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
DUP3
SWAP1
MSTORE
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP4
AND
SWAP1
PUSH4 0xa9059cbb
SWAP1
PUSH1 0x44
ADD
PUSH0
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH0
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x0149
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x015b
JUMPI
RETURNDATASIZE
PUSH0
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH0
REVERT
JUMPDEST
POP
POP
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH1 0x40
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
DUP3
SWAP1
MSTORE
PUSH32 0x000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
SWAP1
PUSH4 0x23b872dd
SWAP1
PUSH1 0x64
ADD
PUSH0
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH0
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x01ce
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x01e0
JUMPI
RETURNDATASIZE
PUSH0
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH0
REVERT
JUMPDEST
POP
POP
PUSH1 0x40
MLOAD
PUSH4 0xa9059cbb
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
PUSH32 0x00000000000000000000000037915f3aca9a1e910a3171f3aaddf6a3e67d4cd0
DUP2
AND
PUSH1 0x04
DUP4
ADD
MSTORE
PUSH1 0x24
DUP3
ADD
DUP6
SWAP1
MSTORE
PUSH32 0x000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7
AND
SWAP3
POP
PUSH4 0xa9059cbb
SWAP2
POP
PUSH1 0x44
ADD
PUSH0
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH0
DUP8
DUP1
EXTCODESIZE
ISZERO
DUP1
ISZERO
PUSH2 0x026b
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x027d
JUMPI
RETURNDATASIZE
PUSH0
DUP1
RETURNDATACOPY
RETURNDATASIZE
PUSH0
REVERT
JUMPDEST
POP
POP
PUSH1 0x40
MLOAD
DUP4
DUP2
MSTORE
CALLER
SWAP3
POP
PUSH32 0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c
SWAP2
POP
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
PUSH0
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
CALLER
EQ
PUSH2 0x0301
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
MSTORE
PUSH1 0x0c
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH12 0x15539055551213d492569151
PUSH1 0xa2
SHL
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x00fb
JUMP
JUMPDEST
PUSH0
DUP1
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
NOT
AND
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP4
AND
SWAP1
DUP2
OR
DUP3
SSTORE
PUSH1 0x40
MLOAD
SWAP1
SWAP2
CALLER
SWAP2
PUSH32 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
SWAP2
SWAP1
LOG3
POP
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP2
AND
DUP2
EQ
PUSH2 0x035f
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
JUMP
JUMPDEST
PUSH0
DUP1
PUSH1 0x40
DUP4
DUP6
SUB
SLT
ISZERO
PUSH2 0x0373
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP3
CALLDATALOAD
PUSH2 0x037e
DUP2
PUSH2 0x034b
JUMP
JUMPDEST
SWAP5
PUSH1 0x20
SWAP4
SWAP1
SWAP4
ADD
CALLDATALOAD
SWAP4
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
PUSH2 0x039c
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
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x03b3
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
DUP2
CALLDATALOAD
PUSH2 0x03be
DUP2
PUSH2 0x034b
JUMP
JUMPDEST
SWAP4
SWAP3
POP
POP
POP
JUMP
INVALID
