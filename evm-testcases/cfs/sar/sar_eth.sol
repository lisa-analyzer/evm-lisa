PUSH1 0x02
PUSH1 0x01
SAR
PUSH1 0x01
EQ
PUSH32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0
PUSH1 0x04
SAR
PUSH32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
EQ
PUSH32 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH2 0x0100
SAR
PUSH1 0x00
EQ
PUSH32 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH1 0xff
SAR
PUSH1 0x00
EQ
PUSH32 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH1 0xfe
SAR
PUSH1 0x01
EQ
PUSH32 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH1 0xf8
SAR
PUSH32 0x000000000000000000000000000000000000000000000000000000000000007f
EQ
PUSH32 0x4000000000000000000000000000000000000000000000000000000000000000
PUSH1 0xfe
SAR
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000001
EQ
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
PUSH1 0x01
SAR
PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
EQ
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH1 0x0100
SAR
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
EQ
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH1 0xff
SAR
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
EQ
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH1 0x01
SAR
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
EQ
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
PUSH1 0x00
SAR
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
EQ
PUSH32 0x8000000000000000000000000000000000000000000000000000000000000000
PUSH2 0x0101
SAR
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
EQ
PUSH32 0x8000000000000000000000000000000000000000000000000000000000000000
PUSH2 0x0100
SAR
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
EQ
PUSH32 0x8000000000000000000000000000000000000000000000000000000000000000
PUSH1 0xff
SAR
PUSH32 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
EQ
PUSH32 0x8000000000000000000000000000000000000000000000000000000000000000
PUSH1 0x01
SAR
PUSH32 0xc000000000000000000000000000000000000000000000000000000000000000
EQ