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
PUSH4 0x5ed86d5c
EQ
PUSH2 0x0030
JUMPI
JUMPDEST
PUSH1 0x00
DUP1
REVERT
JUMPDEST
PUSH2 0x004d
PUSH1 0x04
DUP1
CALLDATASIZE
SUB
PUSH1 0x20
DUP2
LT
ISZERO
PUSH2 0x0046
JUMPI
PUSH1 0x00
DUP1
REVERT
JUMPDEST
POP
CALLDATALOAD
PUSH2 0x005f
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
PUSH1 0x00
PUSH32 0x0800000000000011000000000000000000000000000000000000000000000001
DUP1
DUP4
DUP2
DUP2
DUP2
DUP2
DUP2
DUP2
DUP2
DUP2
DUP2
DUP2
DUP2
DUP2
DUP16
MULMOD
PUSH32 0x0143ce163d9e857b549efa236512d839954411bc04e888aa114215f991ee8a57
ADD
MULMOD
PUSH32 0x04430620ab3eb75b8b2c3ee9c8bafd3408efbe93661f670002b3f96d354c2bc0
ADD
MULMOD
PUSH31 0x16ba64f5ffc9bcb3a71b49f79a1c26ce608e33f1b6ce5fdfeae1c732b5d0b5
ADD
MULMOD
PUSH32 0x026315e8a17d10270d98790f94772ab99b185baeab1e0ec64e783de5c5b35859
ADD
MULMOD
PUSH32 0x021052369229137423604dbda64cdab20290c4da86882c0444750eaf0687d1c8
ADD
MULMOD
PUSH32 0x067fa64d83009acfaae5a7a0e910d322b5d4dbc825090c1239dc68cd18338ed4
ADD
MULMOD
PUSH32 0x017190a2c4fe2fb2a1c4061a3aaa8d89e8a363f653a905e43ab819ff47516c67
ADD
SWAP2
POP
DUP1
DUP4
DUP4
MULMOD
PUSH32 0x0587584d86e310744ac2167594e87c72847cc1018d766c61b29b572ba4552a80
ADD
SWAP2
POP
DUP1
DUP3
DUP2
PUSH2 0x01b8
JUMPI
INVALID
JUMPDEST
MOD
SWAP4
SWAP3
POP
POP
POP
JUMP
INVALID
