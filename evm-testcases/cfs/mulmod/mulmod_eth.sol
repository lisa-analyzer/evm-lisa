PUSH1 0x08
PUSH1 0x10
PUSH1 0x10
MULMOD
PUSH1 0x00
EQ
PUSH1 0x12
PUSH32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
PUSH32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
MULMOD
PUSH1 0x09
EQ