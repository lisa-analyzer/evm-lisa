PUSH20 0x5849da1a2318c0ba5e83c6fc8b3c08d557f35ceb
ADDRESS
EQ
PUSH1 0x80
PUSH1 0x40
MSTORE
PUSH1 0x04
CALLDATASIZE
LT
PUSH1 0x33
JUMPI
PUSH1 0x00
CALLDATALOAD
PUSH1 0xe0
SHR
DUP1
PUSH4 0x125d4486
EQ
PUSH1 0x38
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH1 0x3e
PUSH1 0x52
JUMP
JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x49
SWAP2
SWAP1
PUSH1 0xab
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
PUSH1 0x00
PUSH20 0x88f5771eaef92281bfff0c17e761e7f7bc823bf9
SWAP1
POP
SWAP1
JUMP
JUMPDEST
PUSH1 0x00
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
PUSH1 0x00
PUSH1 0x97
DUP3
PUSH1 0x6e
JUMP
JUMPDEST
SWAP1
POP
SWAP2
SWAP1
POP
JUMP
JUMPDEST
PUSH1 0xa5
DUP2
PUSH1 0x8e
JUMP
JUMPDEST
DUP3
MSTORE
POP
POP
JUMP
JUMPDEST
PUSH1 0x00
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH1 0xbe
PUSH1 0x00
DUP4
ADD
DUP5
PUSH1 0x9e
JUMP
JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP
INVALID