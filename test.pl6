use v6;
use ASM::H6809::Assembler;

my $asm = ASM::H6809::Assembler.new;

$asm.first-pass("NOP").say;
