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
PUSH4 0xdf219247
EQ
PUSH2 0x0030
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x0043
PUSH2 0x003e
CALLDATASIZE
PUSH1 0x04
PUSH2 0x00e5
JUMP
JUMPDEST
PUSH2 0x0045
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH1 0x00
DUP4
DUP4
DUP4
PUSH1 0x40
MLOAD
PUSH2 0x0056
SWAP1
PUSH2 0x00d8
JUMP
JUMPDEST
SWAP3
DUP4
MSTORE
PUSH1 0x20
DUP4
ADD
SWAP2
SWAP1
SWAP2
MSTORE
PUSH1 0x40
DUP3
ADD
MSTORE
PUSH1 0x60
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
PUSH1 0x00
CREATE
DUP1
ISZERO
DUP1
ISZERO
PUSH2 0x0085
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
PUSH1 0x40
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP3
AND
DUP2
MSTORE
SWAP1
SWAP2
POP
PUSH32 0x9efa4db2d6b0aca3bd744e7cca573767c98153642feb9510b2dc458735d908de
SWAP1
PUSH1 0x20
ADD
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG1
POP
POP
POP
POP
JUMP
JUMPDEST
PUSH2 0x09bd
DUP1
PUSH2 0x0112
DUP4
CODECOPY
ADD
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
DUP1
PUSH1 0x00
PUSH1 0x60
DUP5
DUP7
SUB
SLT
ISZERO
PUSH2 0x00fa
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
POP
DUP2
CALLDATALOAD
SWAP4
PUSH1 0x20
DUP4
ADD
CALLDATALOAD
SWAP4
POP
PUSH1 0x40
SWAP1
SWAP3
ADD
CALLDATALOAD
SWAP2
SWAP1
POP
JUMP
INVALID
PUSH1 0xe0
PUSH1 0x40
MSTORE
PUSH1 0x02
DUP1
SLOAD
PUSH1 0xff
NOT
AND
SWAP1
SSTORE
CALLVALUE
DUP1
ISZERO
PUSH2 0x001a
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x40
MLOAD
PUSH2 0x09bd
CODESIZE
SUB
DUP1
PUSH2 0x09bd
DUP4
CODECOPY
DUP2
ADD
PUSH1 0x40
DUP2
SWAP1
MSTORE
PUSH2 0x0039
SWAP2
PUSH2 0x0070
JUMP
JUMPDEST
PUSH1 0x00
DUP1
SLOAD
PUSH1 0x01
PUSH1 0x01
PUSH1 0xa0
SHL
SUB
NOT
AND
PUSH20 0xa14664a2e58e804669e9ff1dfbc1bd981e13b0dc
OR
SWAP1
SSTORE
PUSH1 0x80
SWAP3
SWAP1
SWAP3
MSTORE
PUSH1 0xa0
MSTORE
PUSH1 0xc0
MSTORE
PUSH2 0x009e
JUMP
JUMPDEST
PUSH1 0x00
DUP1
PUSH1 0x00
PUSH1 0x60
DUP5
DUP7
SUB
SLT
ISZERO
PUSH2 0x0085
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP4
MLOAD
SWAP3
POP
PUSH1 0x20
DUP5
ADD
MLOAD
SWAP2
POP
PUSH1 0x40
DUP5
ADD
MLOAD
SWAP1
POP
SWAP3
POP
SWAP3
POP
SWAP3
JUMP
JUMPDEST
PUSH1 0x80
MLOAD
PUSH1 0xa0
MLOAD
PUSH1 0xc0
MLOAD
PUSH2 0x08dc
PUSH2 0x00e1
PUSH1 0x00
CODECOPY
PUSH1 0x00
DUP2
DUP2
PUSH1 0xde
ADD
MSTORE
PUSH2 0x06dd
ADD
MSTORE
PUSH1 0x00
DUP2
DUP2
PUSH2 0x026f
ADD
MSTORE
PUSH2 0x058d
ADD
MSTORE
PUSH1 0x00
DUP2
DUP2
PUSH2 0x0172
ADD
MSTORE
PUSH2 0x04f3
ADD
MSTORE
PUSH2 0x08dc
PUSH1 0x00
RETURN
INVALID
PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x00c0
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x553df021
GT
PUSH2 0x0074
JUMPI
DUP1
PUSH4 0xa8d6fe04
GT
PUSH2 0x004e
JUMPI
DUP1
PUSH4 0xa8d6fe04
EQ
PUSH2 0x0232
JUMPI
DUP1
PUSH4 0xb54a6614
EQ
PUSH2 0x0247
JUMPI
DUP1
PUSH4 0xe63db56b
EQ
PUSH2 0x025d
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
PUSH4 0x553df021
EQ
PUSH2 0x01b3
JUMPI
DUP1
PUSH4 0x7150d8ae
EQ
PUSH2 0x01dd
JUMPI
DUP1
PUSH4 0x7bd23fd6
EQ
PUSH2 0x020a
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
PUSH4 0x3dd7609a
GT
PUSH2 0x00a5
JUMPI
DUP1
PUSH4 0x3dd7609a
EQ
PUSH2 0x0160
JUMPI
DUP1
PUSH4 0x458efde3
EQ
PUSH2 0x0194
JUMPI
DUP1
PUSH4 0x49873783
EQ
PUSH2 0x01ab
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP1
PUSH4 0x0253899f
EQ
PUSH2 0x00cc
JUMPI
DUP1
PUSH4 0x07bfe86a
EQ
PUSH2 0x0113
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
CALLDATASIZE
PUSH2 0x00c7
JUMPI
STOP
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x00d8
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0100
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
SWAP1
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
CALLVALUE
DUP1
ISZERO
PUSH2 0x011f
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x013b
PUSH20 0xddea19fce1e52497206bf1969d2d56fed85aff5c
DUP2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP2
AND
DUP2
MSTORE
PUSH1 0x20
ADD
PUSH2 0x010a
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x016c
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0100
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
DUP2
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x01a0
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x01a9
PUSH2 0x0291
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x01a9
PUSH2 0x0457
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x01bf
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x02
SLOAD
PUSH2 0x01cd
SWAP1
PUSH1 0xff
AND
DUP2
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
PUSH2 0x010a
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x01e9
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH1 0x00
SLOAD
PUSH2 0x013b
SWAP1
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
DUP2
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0216
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x013b
PUSH20 0xa14664a2e58e804669e9ff1dfbc1bd981e13b0dc
DUP2
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x023e
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x01a9
PUSH2 0x07de
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0253
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0100
PUSH1 0x01
SLOAD
DUP2
JUMP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0269
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x0100
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
DUP2
JUMP
JUMPDEST
PUSH1 0x02
SLOAD
PUSH1 0xff
AND
ISZERO
DUP1
PUSH2 0x02a5
JUMPI
POP
PUSH1 0x01
SLOAD
TIMESTAMP
LT
ISZERO
JUMPDEST
PUSH2 0x0310
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x12
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x4861736e277420766573746564207965742e0000000000000000000000000000
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
PUSH1 0x00
SLOAD
PUSH1 0x40
MLOAD
PUSH32 0x70a0823100000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
ADDRESS
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH20 0xddea19fce1e52497206bf1969d2d56fed85aff5c
SWAP2
PUSH4 0xa9059cbb
SWAP2
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP2
AND
SWAP1
DUP4
SWAP1
PUSH4 0x70a08231
SWAP1
PUSH1 0x24
ADD
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP7
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x039c
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
PUSH2 0x03c0
SWAP2
SWAP1
PUSH2 0x0805
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH32 0xffffffff00000000000000000000000000000000000000000000000000000000
PUSH1 0xe0
DUP6
SWAP1
SHL
AND
DUP2
MSTORE
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP3
AND
PUSH1 0x04
DUP4
ADD
MSTORE
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH1 0x44
ADD
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
PUSH1 0x00
DUP8
GAS
CALL
ISZERO
DUP1
ISZERO
PUSH2 0x0430
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
PUSH2 0x0454
SWAP2
SWAP1
PUSH2 0x081e
JUMP
JUMPDEST
POP
JUMP
JUMPDEST
PUSH1 0x00
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffff0000000000000000000000000000000000000000
AND
CALLER
OR
SWAP1
SSTORE
PUSH1 0x02
SLOAD
PUSH1 0xff
AND
ISZERO
PUSH2 0x04ee
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x12
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x4465616c20616c726561647920646f6e652e0000000000000000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0307
JUMP
JUMPDEST
PUSH2 0x0520
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
PUSH8 0x0de0b6b3a7640000
PUSH2 0x0876
JUMP
JUMPDEST
CALLVALUE
EQ
PUSH2 0x0588
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x1f
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x57726f6e6720616d6f756e74206f6620657468657220737570706c6965642e00
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0307
JUMP
JUMPDEST
PUSH2 0x05ba
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
PUSH8 0x0de0b6b3a7640000
PUSH2 0x0876
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH32 0x70a0823100000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
ADDRESS
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH20 0xddea19fce1e52497206bf1969d2d56fed85aff5c
SWAP1
PUSH4 0x70a08231
SWAP1
PUSH1 0x24
ADD
PUSH1 0x20
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP7
GAS
STATICCALL
ISZERO
DUP1
ISZERO
PUSH2 0x0622
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
PUSH2 0x0646
SWAP2
SWAP1
PUSH2 0x0805
JUMP
JUMPDEST
EQ
PUSH2 0x06ad
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x17
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x546f6b656e2062616c616e63652069732077726f6e672e000000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0307
JUMP
JUMPDEST
PUSH1 0x02
DUP1
SLOAD
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
AND
PUSH1 0x01
OR
SWAP1
SSTORE
PUSH2 0x0705
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
PUSH3 0x015180
PUSH2 0x0876
JUMP
JUMPDEST
PUSH2 0x070f
SWAP1
TIMESTAMP
PUSH2 0x0893
JUMP
JUMPDEST
PUSH1 0x01
SSTORE
PUSH1 0x40
MLOAD
PUSH1 0x00
SWAP1
PUSH20 0xa14664a2e58e804669e9ff1dfbc1bd981e13b0dc
SWAP1
CALLVALUE
SWAP1
JUMPDEST
PUSH1 0x00
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP6
DUP8
GAS
CALL
SWAP3
POP
POP
POP
RETURNDATASIZE
DUP1
PUSH1 0x00
DUP2
EQ
PUSH2 0x076e
JUMPI
PUSH1 0x40
MLOAD
SWAP2
POP
PUSH1 0x1f
NOT
PUSH1 0x3f
RETURNDATASIZE
ADD
AND
DUP3
ADD
PUSH1 0x40
MSTORE
RETURNDATASIZE
DUP3
MSTORE
RETURNDATASIZE
PUSH1 0x00
PUSH1 0x20
DUP5
ADD
RETURNDATACOPY
PUSH2 0x0773
JUMP
JUMPDEST
PUSH1 0x60
SWAP2
POP
JUMPDEST
POP
POP
SWAP1
POP
DUP1
PUSH2 0x0454
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x20
PUSH1 0x04
DUP3
ADD
MSTORE
PUSH1 0x10
PUSH1 0x24
DUP3
ADD
MSTORE
PUSH32 0x5472616e73666572206661696c65642e00000000000000000000000000000000
PUSH1 0x44
DUP3
ADD
MSTORE
PUSH1 0x64
ADD
PUSH2 0x0307
JUMP
JUMPDEST
PUSH1 0x00
DUP1
SLOAD
PUSH1 0x40
MLOAD
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
SWAP1
SWAP2
AND
SWAP1
SELFBALANCE
SWAP1
PUSH2 0x0731
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH2 0x0817
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
MLOAD
SWAP2
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
PUSH2 0x0830
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
DUP2
MLOAD
DUP1
ISZERO
ISZERO
DUP2
EQ
PUSH2 0x0840
JUMPI
PUSH1 0x00
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
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH1 0x00
MSTORE
PUSH1 0x11
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH1 0x00
REVERT
JUMPDEST
DUP1
DUP3
MUL
DUP2
ISZERO
DUP3
DUP3
DIV
DUP5
EQ
OR
PUSH2 0x088d
JUMPI
PUSH2 0x088d
PUSH2 0x0847
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
DUP1
DUP3
ADD
DUP1
DUP3
GT
ISZERO
PUSH2 0x088d
JUMPI
PUSH2 0x088d
PUSH2 0x0847
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
ORIGIN
DIV
BASEFEE
INVALID
PUSH5 0x8d500f4e08
PUSH18 0xc577716b33cc498a572739298c2694f55357
ADDRESS
'be'(Unknown Opcode)
GASLIMIT
PUSH5 0x736f6c6343
STOP
ADDMOD
GT
STOP
CALLER
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
'4e'(Unknown Opcode)
'ec'(Unknown Opcode)
'e7'(Unknown Opcode)
'b1'(Unknown Opcode)
PUSH31 0x0c6de33fc871f22e557ad814234886a59239f70cb463311554333b64736f6c
PUSH4 0x43000811
STOP
CALLER
