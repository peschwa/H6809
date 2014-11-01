use Test;
use ASM::H6809::Assembler;

plan 32;

ok 1, 'loading Module works.';

my $asm = ASM::H6809::Assembler.new;

is $asm.WHAT, ASM::H6809::Assembler, 'instantiation works';

# Opcodes without operand
is $asm.first-pass('NOP'), [0x12], 'first-pass for <NOP> works.';
is $asm.first-pass('CLRA'), [0x4F], 'first-pass for <CLRA> works.';
is $asm.first-pass('COMA'), [0x43], 'first-pass for <COMA> works.';
is $asm.first-pass('NEGA'), [0x40], 'first-pass for <NEGA> works.';
is $asm.first-pass('RORA'), [0x46], 'first-pass for <RORA> works.';
is $asm.first-pass('RTS'), [0x39], 'first-pass for <RTS> works.';

# Opcodes with hex address as operand
is $asm.first-pass('LDA $1000'), [0xB6, 40, 96], 'first-pass for <LDA> works with hex address';
is $asm.first-pass('STA $1000'), [0xB7, 40, 96], 'first-pass for <STA> works with hex address';
is $asm.first-pass('ADDA $1000'), [0xBB, 40, 96], 'first-pass for <ADDA> works with hex address';
is $asm.first-pass('CMPA $1000'), [0xB1, 40, 96], 'first-pass for <CMPA> works with hex address';
is $asm.first-pass('ANDA $1000'), [0xB4, 40, 96], 'first-pass for <ANDA> works with hex address';
is $asm.first-pass('LDX $1000'), [0xBE, 40, 96], 'first-pass for <LDX> works with hex address';
is $asm.first-pass('STX $1000'), [0xBF, 40, 96], 'first-pass for <STX> works with hex address';
is $asm.first-pass('CMPX $1000'), [0xBC, 40, 96], 'first-pass for <CMPX> works with hex address';
is $asm.first-pass('ADDX $1000'), [0x31, 40, 96], 'first-pass for <ADDX> works with hex address';
is $asm.first-pass('JMP $1000'), [0x7E, 40, 96], 'first-pass for <JMP> works with hex address';
is $asm.first-pass('JSR $1000'), [0xBD, 40, 96], 'first-pass for <JSR> works with hex address';

# Opcodes with dec address as operand
is $asm.first-pass('LDA 4096'), [0xB6, 10, 0d00], 'first-pass for <LDA> works with dec address';
is $asm.first-pass('STA 4096'), [0xB7, 10, 0d00], 'first-pass for <STA> works with dec address';
is $asm.first-pass('ADDA 4096'), [0xBB, 10, 0d00], 'first-pass for <ADDA> works with dec address';
is $asm.first-pass('CMPA 4096'), [0xB1, 10, 0d00], 'first-pass for <CMPA> works with dec address';
is $asm.first-pass('ANDA 4096'), [0xB4, 10, 0d00], 'first-pass for <ANDA> works with dec address';
is $asm.first-pass('LDX 4096'), [0xBE, 10, 0d00], 'first-pass for <LDX> works with dec address';
is $asm.first-pass('STX 4096'), [0xBF, 10, 0d00], 'first-pass for <STX> works with dec address';
is $asm.first-pass('CMPX 4096'), [0xBC, 10, 0d00], 'first-pass for <CMPX> works with dec address';
is $asm.first-pass('ADDX 4096'), [0x31, 10, 0d00], 'first-pass for <ADDX> works with dec address';
is $asm.first-pass('JMP 4096'), [0x7E, 10, 0d00], 'first-pass for <JMP> works with dec address';
is $asm.first-pass('JSR 4096'), [0xBD, 10, 0d00], 'first-pass for <JSR> works with dec address';

# more than one Opcode
is $asm.first-pass("NOP\nLDA \$1000"), [0x12, 0xB6, 40, 96], 'more than one opcode works';

# Directives
is $asm.first-pass(".ORG \$2\nNOP"), [0d00, 0d00, 0x12], 'directive .ORG works';

# Opcodes with immediate value as operand
is $asm.first-pass('LDA'), 0x86, 'first-pass for <LDA> works.';
#is $asm.first-pass('ADDA'), 0x8B, 'first-pass for <ADDA> works.';
#is $asm.first-pass('ANDA'), 0x84, 'first-pass for <ANDA> works.';
#is $asm.first-pass('CMPA'), 0x81, 'first-pass for <CMPA> works.';
#is $asm.first-pass('LDX'), 0x8E, 'first-pass for <LDX> works.';
#is $asm.first-pass('CMPX'), 0x8c, 'first-pass for <CMPX> works.';
#is $asm.first-pass('ADDX'), 0x30, 'first-pass for <ADDX> works.';
#is $asm.first-pass('LDS'), 0x8F, 'first-pass for <LDS> works.';
#
## Opcodes with address register as operand
#is $asm.first-pass('LDA'), 0xA6, 'first-pass for <LDA> works.';
#is $asm.first-pass('STA'), 0xA7, 'first-pass for <STA> works.';
#
## Opcodes with offset as operand
#is $asm.first-pass('BNE'), 0x26, 'first-pass for <BNE> works.';
#is $asm.first-pass('BEQ'), 0x27, 'first-pass for <BEQ> works.';
#is $asm.first-pass('BRA'), 0x20, 'first-pass for <BRA> works.';
