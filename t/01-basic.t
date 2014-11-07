use Test;
use ASM::H6809::Assembler;

plan 51;

ok 1, 'loading Module works.';

my $asm = ASM::H6809::Assembler.new;
my $cpu = ASM::H6809::CPU.new;

is $asm.WHAT, ASM::H6809::Assembler.WHAT, 'instantiation works';

# Opcodes without operand
ok $asm.assemble('NOP') eq Buf.new(0x12), 'assembling <NOP> works.';
ok $asm.assemble('CLRA') eq Buf.new(0x4F), 'assembling <CLRA> works.';
ok $asm.assemble('COMA') eq Buf.new(0x43), 'assembling <COMA> works.';
ok $asm.assemble('NEGA') eq Buf.new(0x40), 'assembling <NEGA> works.';
ok $asm.assemble('RORA') eq Buf.new(0x46), 'assembling <RORA> works.';
ok $asm.assemble('RTS') eq Buf.new(0x39), 'assembling <RTS> works.';

# Opcodes with hex address as operand
ok $asm.assemble('LDA $00ff') eq Buf.new(0xB6, 0, 255), 'assembling <LDA> works with hex address';
ok $asm.assemble('STA $1000') eq Buf.new(0xB7, 16, 0), 'assembling <STA> works with hex address';
ok $asm.assemble('ADDA $1000') eq Buf.new(0xBB, 16, 0), 'assembling <ADDA> works with hex address';
ok $asm.assemble('CMPA $1000') eq Buf.new(0xB1, 16, 0), 'assembling <CMPA> works with hex address';
ok $asm.assemble('ANDA $1000') eq Buf.new(0xB4, 16, 0), 'assembling <ANDA> works with hex address';
ok $asm.assemble('LDX $1000') eq Buf.new(0xBE, 16, 0), 'assembling <LDX> works with hex address';
ok $asm.assemble('STX $1000') eq Buf.new(0xBF, 16, 0), 'assembling <STX> works with hex address';
ok $asm.assemble('CMPX $1000') eq Buf.new(0xBC, 16, 0), 'assembling <CMPX> works with hex address';
ok $asm.assemble('ADDX $1000') eq Buf.new(0x31, 16, 0), 'assembling <ADDX> works with hex address';
ok $asm.assemble('JMP $1000') eq Buf.new(0x7E, 16, 0), 'assembling <JMP> works with hex address';
ok $asm.assemble('JSR $1000') eq Buf.new(0xBD, 16, 0), 'assembling <JSR> works with hex address';

# Opcodes with dec address as operand
ok $asm.assemble('LDA 255') eq Buf.new(0xB6, 0d00, 0xff), 'assembling <LDA> works with dec address';
ok $asm.assemble('STA 512') eq Buf.new(0xB7, 2, 0d00), 'assembling <STA> works with dec address';
ok $asm.assemble('ADDA 1024') eq Buf.new(0xBB, 4, 0d00), 'assembling <ADDA> works with dec address';
ok $asm.assemble('CMPA 2048') eq Buf.new(0xB1, 8, 0d00), 'assembling <CMPA> works with dec address';
ok $asm.assemble('ANDA 4096') eq Buf.new(0xB4, 0x10, 0d00), 'assembling <ANDA> works with dec address';
ok $asm.assemble('LDX 255') eq Buf.new(0xBE, 0, 0xff), 'assembling <LDX> works with dec address';
ok $asm.assemble('STX 255') eq Buf.new(0xBF, 0, 0xff), 'assembling <STX> works with dec address';
ok $asm.assemble('CMPX 255') eq Buf.new(0xBC, 0, 0xff), 'assembling <CMPX> works with dec address';
ok $asm.assemble('ADDX 255') eq Buf.new(0x31, 0, 0xff), 'assembling <ADDX> works with dec address';
ok $asm.assemble('JMP 255') eq Buf.new(0x7E, 0, 0xff), 'assembling <JMP> works with dec address';
ok $asm.assemble('JSR 255') eq Buf.new(0xBD, 0, 0xff), 'assembling <JSR> works with dec address';

# more than one Opcode
ok $asm.assemble("NOP\nLDA 50") eq Buf.new(0x12, 0xB6, 0, 50), 'more than one opcode works';

# Directives
ok $asm.assemble(".ORG \$2\nNOP") eq Buf.new(0d00, 0d00, 0x12), 'directive .ORG works';
ok $asm.assemble("NOP\n.ORG 3\nLDA 1\n.ORG 1\nCOMA") eq Buf.new(0x12, 0x43, 0, 0xB6, 0, 1), '.ORG really works';

# Some error handling
throws_like q[my $asm = ASM::H6809::Assembler.new; $asm.assemble('HURR')], X::ASM::UnknownMnemonic;
throws_like q[my $asm = ASM::H6809::Assembler.new; $asm.assemble('LDA')], X::ASM::MissingOrMistypedArgument;
throws_like q[my $asm = ASM::H6809::Assembler.new; $asm.assemble('STX #1')], X::ASM::MissingOrMistypedArgument;

# Opcodes with immediate dec value as operand
ok $asm.assemble('LDA #123') eq Buf.new( 0x86, 123 ), 'assembling <LDA> works.';
ok $asm.assemble('ADDA #123') eq Buf.new( 0x8B, 123 ), 'assembling <ADDA> works.';
ok $asm.assemble('ANDA #123') eq Buf.new( 0x84, 123 ),'assembling <ANDA> works.';
ok $asm.assemble('CMPA #123') eq Buf.new( 0x81, 123 ), 'assembling <CMPA> works.';
ok $asm.assemble('LDX #123') eq Buf.new( 0x8E, 0, 123 ), 'assembling <LDX> works.';
ok $asm.assemble('CMPX #123') eq Buf.new( 0x8c, 0, 123 ), 'assembling <CMPX> works.';
ok $asm.assemble('ADDX #123') eq Buf.new( 0x30, 0, 123 ), 'assembling <ADDX> works.';
ok $asm.assemble('LDS #123') eq Buf.new( 0x8F, 0, 123 ), 'assembling <LDS> works.';

# Opcodes with address register as operand
ok $asm.assemble('STA @X') eq Buf.new(0xA7), 'assembling <STA> works.';
ok $asm.assemble('LDA @X') eq Buf.new(0xA6), 'assembling <LDA> works.';

# Opcodes with offset as operand
ok $asm.assemble(".ORG 2\nLOOP: BNE LOOP") eq Buf.new( 0, 0, 0x26, 0xFE ), 'assembling <BNE> works.';

# Labels for variables
ok $asm.assemble(".ORG 10\nZ1 .BYTE 1\n.ORG 0\nLDA #1\nSTA Z1") eq 
    Buf.new(0x86, 1, 0xb7, 0, 0x0a, 0, 0, 0, 0, 0, 0), 'labels work as addresses';
#is $asm.assemble('BEQ'), 0x27, 'assembling <BEQ> works.';
#is $asm.assemble('BRA'), 0x20, 'assembling <BRA> works.';

ok $cpu.compute($asm.assemble("Z1 .BYTE 1\nLDA #1\nSTA Z1")) eq Buf.new(0x01, 0x01, 0xb7, 0x00, 0x00), 
    'computing assembled object code works';

ok $cpu.compute($asm.assemble("LDA #1\nCMPA #1\nBEQ JUMP\nSTA 0\nJUMP: STA 2"))
    eq Buf.new(0x86, 0x01, 0x01, 0x01, 0x27, 0x03, 0xb7, 0x00, 0x00, 0xb7, 0x00, 0x02),
    'BEQ is assembled and computed correctly';

# same with a label
ok $cpu.compute($asm.assemble("LDA #1\nZ1: CMPA #1\nBEQ JUMP\nSTA 0\nJUMP: STA Z1"))
    eq Buf.new(0x86, 0x01, 0x01, 0x01, 0x27, 0x03, 0xb7, 0x00, 0x00, 0xb7, 0x00, 0x02),
    'BEQ is assembled and computed correctly (with label)';
