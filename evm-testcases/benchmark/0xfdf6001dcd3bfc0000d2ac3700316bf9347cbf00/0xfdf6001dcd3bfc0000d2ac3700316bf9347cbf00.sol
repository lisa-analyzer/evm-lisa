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
PUSH2 0x002b
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x0479bf4e
EQ
PUSH2 0x0030
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x011f
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0xe0
DUP2
LT
ISZERO
PUSH2 0x0046
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
DUP3
CALLDATALOAD
DUP2
AND
SWAP3
PUSH1 0x20
DUP2
ADD
CALLDATALOAD
DUP3
AND
SWAP3
PUSH1 0x40
DUP3
ADD
CALLDATALOAD
DUP4
AND
SWAP3
PUSH1 0x60
DUP4
ADD
CALLDATALOAD
AND
SWAP2
PUSH1 0x80
DUP2
ADD
CALLDATALOAD
SWAP2
DUP2
ADD
SWAP1
PUSH1 0xc0
DUP2
ADD
PUSH1 0xa0
DUP3
ADD
CALLDATALOAD
PUSH5 0x0100000000
DUP2
GT
ISZERO
PUSH2 0x008e
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
PUSH2 0x00a0
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
PUSH2 0x00c2
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
SWAP2
SWAP4
SWAP1
SWAP3
SWAP1
SWAP2
PUSH1 0x20
DUP2
ADD
SWAP1
CALLDATALOAD
PUSH5 0x0100000000
DUP2
GT
ISZERO
PUSH2 0x00e0
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
PUSH2 0x00f2
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
PUSH2 0x0114
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
SWAP1
SWAP3
POP
SWAP1
POP
PUSH2 0x013b
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
SWAP1
SWAP3
AND
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
PUSH1 0x00
PUSH2 0x0148
DUP10
DUP10
DUP13
PUSH2 0x022f
JUMP
JUMPDEST
SWAP1
POP
DUP1
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH4 0x44f62b3c
DUP9
DUP9
DUP9
DUP9
DUP9
DUP9
PUSH1 0x40
MLOAD
DUP8
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
DUP1
DUP8
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
DUP2
MSTORE
PUSH1 0x20
ADD
DUP7
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH1 0x20
ADD
DUP1
PUSH1 0x20
ADD
DUP4
DUP2
SUB
DUP4
MSTORE
DUP8
DUP8
DUP3
DUP2
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP3
POP
DUP1
DUP3
DUP5
CALLDATACOPY
PUSH1 0x00
DUP4
DUP3
ADD
MSTORE
PUSH1 0x1f
ADD
PUSH1 0x1f
NOT
AND
SWAP1
SWAP2
ADD
DUP5
DUP2
SUB
DUP4
MSTORE
DUP6
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP1
POP
DUP6
DUP6
DUP1
DUP3
DUP5
CALLDATACOPY
PUSH1 0x00
DUP2
DUP5
ADD
MSTORE
PUSH1 0x1f
NOT
PUSH1 0x1f
DUP3
ADD
AND
SWAP1
POP
DUP1
DUP4
ADD
SWAP3
POP
POP
POP
SWAP9
POP
POP
POP
POP
POP
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
PUSH2 0x020a
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
PUSH2 0x021e
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
SWAP10
SWAP9
POP
POP
POP
POP
POP
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
DUP2
EXTCODESIZE
DUP1
PUSH2 0x02c3
JUMPI
DUP5
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH4 0x285e7bfd
DUP6
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
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
DUP2
MSTORE
PUSH1 0x20
ADD
SWAP2
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
PUSH2 0x0290
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
PUSH2 0x02a4
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
PUSH2 0x02ba
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
SWAP2
POP
PUSH2 0x037a
JUMP
JUMPDEST
DUP3
SWAP2
POP
DUP4
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
DUP3
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
PUSH4 0x81a078d0
PUSH1 0x40
MLOAD
DUP2
PUSH4 0xffffffff
AND
PUSH1 0xe0
SHL
DUP2
MSTORE
PUSH1 0x04
ADD
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
PUSH2 0x0309
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
PUSH2 0x031d
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
PUSH2 0x0333
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
AND
EQ
PUSH2 0x037a
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
PUSH1 0x44
DUP2
MSTORE
PUSH1 0x20
ADD
DUP1
PUSH2 0x0383
PUSH1 0x44
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
SWAP4
SWAP3
POP
POP
POP
JUMP
INVALID
GASLIMIT
PUSH25 0x697374696e672075736572207369676e696e67206b65792064
PUSH10 0x66666572732066726f6d
SHA3
PUSH20 0x7570706c6965642063757272656e74207369676e
