class ASM::H6809::Assembler # is ASM::Assembler
{
    has ASM::H6809::CPU $.cpu;
    has %mnemo-to-opcode;

    method new() {
        my $obj = self.CREATE;
        $obj.BUILD;
        $obj;
    }

    method BUILD() {
        $!cpu = ASM::H6809::CPU.new;
        %!mnemo-to-opcode = map $_.mnemo => $_, $!cpu.opcodes;
    }

    method first-pass(Str $input) {

    }

    method second-pass(Str $input) {

    }

    method assemble(Str $input) {
        second-pass(first-pass($input))
    }
}
