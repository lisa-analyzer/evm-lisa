PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x0077
JUMPI
PUSH4 0xffffffff
PUSH29 0x0100000000000000000000000000000000000000000000000000000000
PUSH1 0x00
CALLDATALOAD
DIV
AND
PUSH4 0x4b5166a2
DUP2
EQ
PUSH2 0x007c
JUMPI
DUP1
PUSH4 0x5036258b
EQ
PUSH2 0x009f
JUMPI
DUP1
PUSH4 0x66aa01ca
EQ
PUSH2 0x00c0
JUMPI
DUP1
PUSH4 0x715018a6
EQ
PUSH2 0x00f5
JUMPI
DUP1
PUSH4 0x8da5cb5b
EQ
PUSH2 0x010a
JUMPI
DUP1
PUSH4 0xf2fde38b
EQ
PUSH2 0x013b
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0088
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x009d
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
PUSH1 0x04
CALLDATALOAD
AND
PUSH2 0x015c
JUMP
JUMPDEST
STOP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x00ab
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x009d
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
PUSH1 0x04
CALLDATALOAD
AND
PUSH2 0x0181
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x00cc
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x00e1
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
PUSH1 0x04
CALLDATALOAD
AND
PUSH2 0x01a3
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
SWAP2
ISZERO
ISZERO
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
CALLVALUE
DUP1
ISZERO
PUSH2 0x0101
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x009d
PUSH2 0x01b8
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0116
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x011f
PUSH2 0x0224
JUMP
JUMPDEST
PUSH1 0x40
DUP1
MLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
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
CALLVALUE
DUP1
ISZERO
PUSH2 0x0147
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x009d
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
PUSH1 0x04
CALLDATALOAD
AND
PUSH2 0x0233
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
AND
CALLER
EQ
PUSH2 0x0173
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x017e
DUP2
PUSH1 0x01
PUSH2 0x0253
JUMP
JUMPDEST
POP
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
AND
CALLER
EQ
PUSH2 0x0198
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x017e
DUP2
PUSH1 0x00
PUSH2 0x0253
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0x20
MSTORE
PUSH1 0x00
SWAP1
DUP2
MSTORE
PUSH1 0x40
SWAP1
SHA3
SLOAD
PUSH1 0xff
AND
DUP2
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
AND
CALLER
EQ
PUSH2 0x01cf
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x00
DUP1
SLOAD
PUSH1 0x40
MLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
SWAP1
SWAP2
AND
SWAP2
PUSH32 0xf8df31144d9c2f0f6b59d69b8b98abd5459d07f2742c4df920b25aae33c64820
SWAP2
LOG2
PUSH1 0x00
DUP1
SLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
NOT
AND
SWAP1
SSTORE
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
AND
DUP2
JUMP
JUMPDEST
PUSH1 0x00
SLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
AND
CALLER
EQ
PUSH2 0x024a
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x017e
DUP2
PUSH2 0x02b7
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
DUP3
AND
PUSH1 0x00
DUP2
DUP2
MSTORE
PUSH1 0x01
PUSH1 0x20
SWAP1
DUP2
MSTORE
PUSH1 0x40
SWAP2
DUP3
SWAP1
SHA3
DUP1
SLOAD
PUSH1 0xff
NOT
AND
DUP6
ISZERO
ISZERO
SWAP1
DUP2
OR
SWAP1
SWAP2
SSTORE
DUP3
MLOAD
SWAP4
DUP5
MSTORE
SWAP1
DUP4
ADD
MSTORE
DUP1
MLOAD
PUSH32 0x5cd80611a2df211d776cd3cd9e0db9a489a02ac865d46c7614482160b02e846a
SWAP3
DUP2
SWAP1
SUB
SWAP1
SWAP2
ADD
SWAP1
LOG1
POP
POP
JUMP
JUMPDEST
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
DUP2
AND
ISZERO
ISZERO
PUSH2 0x02cc
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x00
DUP1
SLOAD
PUSH1 0x40
MLOAD
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
DUP1
DUP6
AND
SWAP4
SWAP3
AND
SWAP2
PUSH32 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
SWAP2
LOG3
PUSH1 0x00
DUP1
SLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
NOT
AND
PUSH1 0x01
PUSH1 0xa0
PUSH1 0x02
EXP
SUB
SWAP3
SWAP1
SWAP3
AND
SWAP2
SWAP1
SWAP2
OR
SWAP1
SSTORE
JUMP
STOP