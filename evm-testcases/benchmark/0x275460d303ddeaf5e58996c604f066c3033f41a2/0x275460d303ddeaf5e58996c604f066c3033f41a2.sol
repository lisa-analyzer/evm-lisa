PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH2 0x0042
JUMPI
PUSH0
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x0f01755b
EQ
PUSH2 0x005b
JUMPI
DUP1
PUSH4 0x472446d4
EQ
PUSH2 0x0065
JUMPI
DUP1
PUSH4 0x5c60da1b
EQ
PUSH2 0x00a1
JUMPI
DUP1
PUSH4 0x7d9147fb
EQ
PUSH2 0x00cb
JUMPI
PUSH2 0x0051
JUMP
JUMPDEST
CALLDATASIZE
PUSH2 0x0051
JUMPI
PUSH2 0x004f
PUSH2 0x0107
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0059
PUSH2 0x0107
JUMP
JUMPDEST
STOP
JUMPDEST
PUSH2 0x0063
PUSH2 0x0121
JUMP
JUMPDEST
STOP
JUMPDEST
CALLVALUE
DUP1
ISZERO
PUSH2 0x0070
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x008b
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x0086
SWAP2
SWAP1
PUSH2 0x03f8
JUMP
JUMPDEST
PUSH2 0x02b2
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x0098
SWAP2
SWAP1
PUSH2 0x043b
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
CALLVALUE
DUP1
ISZERO
PUSH2 0x00ac
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x00b5
PUSH2 0x02c6
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x00c2
SWAP2
SWAP1
PUSH2 0x0463
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
CALLVALUE
DUP1
ISZERO
PUSH2 0x00d6
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
PUSH2 0x00f1
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
DUP2
ADD
SWAP1
PUSH2 0x00ec
SWAP2
SWAP1
PUSH2 0x04a6
JUMP
JUMPDEST
PUSH2 0x02d4
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH2 0x00fe
SWAP2
SWAP1
PUSH2 0x04fe
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
PUSH2 0x010f
PUSH2 0x031d
JUMP
JUMPDEST
PUSH2 0x011f
PUSH2 0x011a
PUSH2 0x031f
JUMP
JUMPDEST
PUSH2 0x0372
JUMP
JUMPDEST
JUMP
JUMPDEST
PUSH7 0x2386f26fc10000
CALLVALUE
LT
ISZERO
PUSH2 0x016b
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x0162
SWAP1
PUSH2 0x0597
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
PUSH7 0x17a93c16344000
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
BALANCE
GT
ISZERO
PUSH2 0x01cc
JUMPI
PUSH1 0x40
MLOAD
PUSH32 0x08c379a000000000000000000000000000000000000000000000000000000000
DUP2
MSTORE
PUSH1 0x04
ADD
PUSH2 0x01c3
SWAP1
PUSH2 0x0625
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
REVERT
JUMPDEST
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH32 0x266ebd273f8a13fae09801163316ea6c394d12d2f9d65875b4c01fac80829a84
CALLVALUE
PUSH1 0x40
MLOAD
PUSH2 0x0212
SWAP2
SWAP1
PUSH2 0x043b
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
LOG2
CALLVALUE
PUSH0
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
PUSH0
SHA3
PUSH0
DUP3
DUP3
SLOAD
PUSH2 0x0265
SWAP2
SWAP1
PUSH2 0x0670
JUMP
JUMPDEST
SWAP3
POP
POP
DUP2
SWAP1
SSTORE
POP
CALLER
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
PUSH2 0x08fc
CALLVALUE
SWAP1
DUP2
ISZERO
MUL
SWAP1
PUSH1 0x40
MLOAD
PUSH0
PUSH1 0x40
MLOAD
DUP1
DUP4
SUB
DUP2
DUP6
DUP9
DUP9
CALL
SWAP4
POP
POP
POP
POP
ISZERO
DUP1
ISZERO
PUSH2 0x02af
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
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
MSTORE
DUP1
PUSH0
MSTORE
PUSH1 0x40
PUSH0
SHA3
PUSH0
SWAP2
POP
SWAP1
POP
SLOAD
DUP2
JUMP
JUMPDEST
PUSH0
PUSH2 0x02cf
PUSH2 0x031f
JUMP
JUMPDEST
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH0
DUP2
PUSH0
DUP1
DUP6
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
PUSH0
SHA3
SLOAD
LT
ISZERO
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
JUMP
JUMPDEST
PUSH0
PUSH2 0x034b
PUSH32 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
PUSH0
SHL
PUSH2 0x0391
JUMP
JUMPDEST
PUSH0
ADD
PUSH0
SWAP1
SLOAD
SWAP1
PUSH2 0x0100
EXP
SWAP1
DIV
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
AND
SWAP1
POP
SWAP1
JUMP
JUMPDEST
CALLDATASIZE
PUSH0
DUP1
CALLDATACOPY
PUSH0
DUP1
CALLDATASIZE
PUSH0
DUP5
GAS
DELEGATECALL
RETURNDATASIZE
PUSH0
DUP1
RETURNDATACOPY
DUP1
PUSH0
DUP2
EQ
PUSH2 0x038d
JUMPI
RETURNDATASIZE
PUSH0
RETURN
JUMPDEST
RETURNDATASIZE
PUSH0
REVERT
JUMPDEST
PUSH0
DUP2
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
DUP1
REVERT
JUMPDEST
PUSH0
PUSH20 0xffffffffffffffffffffffffffffffffffffffff
DUP3
AND
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x03c7
DUP3
PUSH2 0x039e
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x03d7
DUP2
PUSH2 0x03bd
JUMP
JUMPDEST
DUP2
EQ
PUSH2 0x03e1
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
JUMP
JUMPDEST
PUSH0
DUP2
CALLDATALOAD
SWAP1
POP
PUSH2 0x03f2
DUP2
PUSH2 0x03ce
JUMP
JUMPDEST
SWAP3
SWAP2
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
PUSH2 0x040d
JUMPI
PUSH2 0x040c
PUSH2 0x039a
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x041a
DUP5
DUP3
DUP6
ADD
PUSH2 0x03e4
JUMP
JUMPDEST
SWAP2
POP
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
DUP2
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x0435
DUP2
PUSH2 0x0423
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x044e
PUSH0
DUP4
ADD
DUP5
PUSH2 0x042c
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH2 0x045d
DUP2
PUSH2 0x03bd
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x0476
PUSH0
DUP4
ADD
DUP5
PUSH2 0x0454
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH2 0x0485
DUP2
PUSH2 0x0423
JUMP
JUMPDEST
DUP2
EQ
PUSH2 0x048f
JUMPI
PUSH0
DUP1
REVERT
JUMPDEST
POP
JUMP
JUMPDEST
PUSH0
DUP2
CALLDATALOAD
SWAP1
POP
PUSH2 0x04a0
DUP2
PUSH2 0x047c
JUMP
JUMPDEST
SWAP3
SWAP2
POP
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
PUSH2 0x04bc
JUMPI
PUSH2 0x04bb
PUSH2 0x039a
JUMP
JUMPDEST
JUMPDEST
PUSH0
PUSH2 0x04c9
DUP6
DUP3
DUP7
ADD
PUSH2 0x03e4
JUMP
JUMPDEST
SWAP3
POP
POP
PUSH1 0x20
PUSH2 0x04da
DUP6
DUP3
DUP7
ADD
PUSH2 0x0492
JUMP
JUMPDEST
SWAP2
POP
POP
SWAP3
POP
SWAP3
SWAP1
POP
JUMP
JUMPDEST
PUSH0
DUP2
ISZERO
ISZERO
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH2 0x04f8
DUP2
PUSH2 0x04e4
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH2 0x0511
PUSH0
DUP4
ADD
DUP5
PUSH2 0x04ef
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH0
DUP3
DUP3
MSTORE
PUSH1 0x20
DUP3
ADD
SWAP1
POP
SWAP3
SWAP2
POP
POP
JUMP
JUMPDEST
PUSH32 0x596f75206d75737420636c65616e7365206174206c6561737420302e30312065
PUSH0
DUP3
ADD
MSTORE
PUSH32 0x7468657200000000000000000000000000000000000000000000000000000000
PUSH1 0x20
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x0581
PUSH1 0x24
DUP4
PUSH2 0x0517
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x058c
DUP3
PUSH2 0x0527
JUMP
JUMPDEST
PUSH1 0x40
DUP3
ADD
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
DUP2
DUP2
SUB
PUSH0
DUP4
ADD
MSTORE
PUSH2 0x05ae
DUP2
PUSH2 0x0575
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x596f75206d75737420636c65616e736520796f757220656e746972652062616c
PUSH0
DUP3
ADD
MSTORE
PUSH32 0x616e636500000000000000000000000000000000000000000000000000000000
PUSH1 0x20
DUP3
ADD
MSTORE
POP
JUMP
JUMPDEST
PUSH0
PUSH2 0x060f
PUSH1 0x24
DUP4
PUSH2 0x0517
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x061a
DUP3
PUSH2 0x05b5
JUMP
JUMPDEST
PUSH1 0x40
DUP3
ADD
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
DUP2
DUP2
SUB
PUSH0
DUP4
ADD
MSTORE
PUSH2 0x063c
DUP2
PUSH2 0x0603
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH32 0x4e487b7100000000000000000000000000000000000000000000000000000000
PUSH0
MSTORE
PUSH1 0x11
PUSH1 0x04
MSTORE
PUSH1 0x24
PUSH0
REVERT
JUMPDEST
PUSH0
PUSH2 0x067a
DUP3
PUSH2 0x0423
JUMP
JUMPDEST
SWAP2
POP
PUSH2 0x0685
DUP4
PUSH2 0x0423
JUMP
JUMPDEST
SWAP3
POP
DUP3
DUP3
ADD
SWAP1
POP
DUP1
DUP3
GT
ISZERO
PUSH2 0x069d
JUMPI
PUSH2 0x069c
PUSH2 0x0643
JUMP
JUMPDEST
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
INVALID
LOG2
PUSH5 0x6970667358
'22'(Unknown Opcode)
SLT
SHA3
CHAINID
SWAP6
'd3'(Unknown Opcode)
TIMESTAMP
DUP3
DUP9
PUSH30 0xb5fbfeb6de65377c2136ad0d766ad60fe96d62594c9cdeff9d64736f6c63
NUMBER
STOP
ADDMOD
OR
STOP
CALLER
