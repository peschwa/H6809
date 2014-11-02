use Test;
use ASM::H6809::Assembler;

plan 48;

ok 1, 'loading Module works.';

my $asm = ASM::H6809::Assembler.new;

is $asm.WHAT, ASM::H6809::Assembler, 'instantiation works';

# Opcodes without operand
ok $asm.first-pass('NOP') eq Buf.new(0x12), 'first-pass for <NOP> works.';
ok $asm.first-pass('CLRA') eq Buf.new(0x4F), 'first-pass for <CLRA> works.';
ok $asm.first-pass('COMA') eq Buf.new(0x43), 'first-pass for <COMA> works.';
ok $asm.first-pass('NEGA') eq Buf.new(0x40), 'first-pass for <NEGA> works.';
ok $asm.first-pass('RORA') eq Buf.new(0x46), 'first-pass for <RORA> works.';
ok $asm.first-pass('RTS') eq Buf.new(0x39), 'first-pass for <RTS> works.';

# Opcodes with hex address as operand
ok $asm.first-pass('LDA $00ff') eq Buf.new(0xB6, 0, 255), 'first-pass for <LDA> works with hex address';
ok $asm.first-pass('STA $1000') eq Buf.new(0xB7, 16, 0), 'first-pass for <STA> works with hex address';
ok $asm.first-pass('ADDA $1000') eq Buf.new(0xBB, 16, 0), 'first-pass for <ADDA> works with hex address';
ok $asm.first-pass('CMPA $1000') eq Buf.new(0xB1, 16, 0), 'first-pass for <CMPA> works with hex address';
ok $asm.first-pass('ANDA $1000') eq Buf.new(0xB4, 16, 0), 'first-pass for <ANDA> works with hex address';
ok $asm.first-pass('LDX $1000') eq Buf.new(0xBE, 16, 0), 'first-pass for <LDX> works with hex address';
ok $asm.first-pass('STX $1000') eq Buf.new(0xBF, 16, 0), 'first-pass for <STX> works with hex address';
ok $asm.first-pass('CMPX $1000') eq Buf.new(0xBC, 16, 0), 'first-pass for <CMPX> works with hex address';
ok $asm.first-pass('ADDX $1000') eq Buf.new(0x31, 16, 0), 'first-pass for <ADDX> works with hex address';
ok $asm.first-pass('JMP $1000') eq Buf.new(0x7E, 16, 0), 'first-pass for <JMP> works with hex address';
ok $asm.first-pass('JSR $1000') eq Buf.new(0xBD, 16, 0), 'first-pass for <JSR> works with hex address';

# Opcodes with dec address as operand
ok $asm.first-pass('LDA 255') eq Buf.new(0xB6, 0d00, 0xff), 'first-pass for <LDA> works with dec address';
ok $asm.first-pass('STA 512') eq Buf.new(0xB7, 2, 0d00), 'first-pass for <STA> works with dec address';
ok $asm.first-pass('ADDA 1024') eq Buf.new(0xBB, 4, 0d00), 'first-pass for <ADDA> works with dec address';
ok $asm.first-pass('CMPA 2048') eq Buf.new(0xB1, 8, 0d00), 'first-pass for <CMPA> works with dec address';
ok $asm.first-pass('ANDA 4096') eq Buf.new(0xB4, 0x10, 0d00), 'first-pass for <ANDA> works with dec address';
ok $asm.first-pass('LDX 255') eq Buf.new(0xBE, 0, 0xff), 'first-pass for <LDX> works with dec address';
ok $asm.first-pass('STX 255') eq Buf.new(0xBF, 0, 0xff), 'first-pass for <STX> works with dec address';
ok $asm.first-pass('CMPX 255') eq Buf.new(0xBC, 0, 0xff), 'first-pass for <CMPX> works with dec address';
ok $asm.first-pass('ADDX 255') eq Buf.new(0x31, 0, 0xff), 'first-pass for <ADDX> works with dec address';
ok $asm.first-pass('JMP 255') eq Buf.new(0x7E, 0, 0xff), 'first-pass for <JMP> works with dec address';
ok $asm.first-pass('JSR 255') eq Buf.new(0xBD, 0, 0xff), 'first-pass for <JSR> works with dec address';

# more than one Opcode
ok $asm.first-pass("NOP\nLDA 50") eq Buf.new(0x12, 0xB6, 0, 50), 'more than one opcode works';

# Directives
ok $asm.first-pass(".ORG \$2\nNOP") eq Buf.new(0d00, 0d00, 0x12), 'directive .ORG works';
ok $asm.first-pass("NOP\n.ORG 3\nLDA 1\n.ORG 1\nCOMA") eq Buf.new(0x12, 0x43, 0, 0xB6, 0, 1), '.ORG really works';

# Some error handling
throws_like q[my $asm = ASM::H6809::Assembler.new; $asm.first-pass('HURR')], X::ASM::UnknownMnemonic;
throws_like q[my $asm = ASM::H6809::Assembler.new; $asm.first-pass('LDA')], X::ASM::MissingOrMistypedArgument;
throws_like q[my $asm = ASM::H6809::Assembler.new; $asm.first-pass('STX #1')], X::ASM::MissingOrMistypedArgument;

# Opcodes with immediate dec value as operand
ok $asm.first-pass('LDA #123') eq Buf.new( 0x86, 123 ), 'first-pass for <LDA> works.';
ok $asm.first-pass('ADDA #123') eq Buf.new( 0x8B, 123 ), 'first-pass for <ADDA> works.';
ok $asm.first-pass('ANDA #123') eq Buf.new( 0x84, 123 ),'first-pass for <ANDA> works.';
ok $asm.first-pass('CMPA #123') eq Buf.new( 0x81, 123 ), 'first-pass for <CMPA> works.';
ok $asm.first-pass('LDX #123') eq Buf.new( 0x8E, 0, 123 ), 'first-pass for <LDX> works.';
ok $asm.first-pass('CMPX #123') eq Buf.new( 0x8c, 0, 123 ), 'first-pass for <CMPX> works.';
ok $asm.first-pass('ADDX #123') eq Buf.new( 0x30, 0, 123 ), 'first-pass for <ADDX> works.';
ok $asm.first-pass('LDS #123') eq Buf.new( 0x8F, 0, 123 ), 'first-pass for <LDS> works.';

# Opcodes with address register as operand
ok $asm.first-pass('STA @X') eq Buf.new(0xA7), 'first-pass for <STA> works.';
ok $asm.first-pass('LDA @X') eq Buf.new(0xA6), 'first-pass for <LDA> works.';

# Opcodes with offset as operand
ok $asm.first-pass(".ORG 2\nLOOP: BNE LOOP") eq Buf.new( 0, 0, 0x26, 2 ), 'first-pass for <BNE> works.';

# Labels for variables
ok $asm.first-pass(".ORG 10\nZ1 .BYTE 1\n.ORG 0\nLDA #1\nSTA Z1") eq 
    Buf.new(0x86, 1, 0xb7, 10, 0, 0, 0, 0, 0, 0, 0), 'labels work as addresses';
#is $asm.first-pass('BEQ'), 0x27, 'first-pass for <BEQ> works.';
#is $asm.first-pass('BRA'), 0x20, 'first-pass for <BRA> works.';
