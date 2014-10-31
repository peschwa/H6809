class ASM::H6809::Assembler # is ASM::Assembler
{
    has ASM::H6809::CPU $.cpu;
    has %.mnemo-to-opcode;
    has @.mnemos;

    method new() {
        my $obj = self.CREATE;
        $obj.BUILD;
        $obj;
    }

    method BUILD() {
        $!cpu = ASM::H6809::CPU.new;
	# probably bag this instead?
	# trouble as-is is, mnemos repeat
        %!mnemo-to-opcode = map $_.mnemo => $_, $!cpu.opcodes;
	@.mnemos = %!mnemo-to-opcode.keys;
    }

    method first-pass(Str $input) {
        my grammar ASMFirstPass {
            token TOP(:@opcodes, :%mnemos-to-opcodes) {
		:my %*M2O = %mnemos-to-opcodes;
                [
                    <directive>+ %% "\n"+?
                    <opcode(@opcodes)>+ %% "\n"+?
                ]+
            }

            token directive {
                '.' $<name> = <[A..Z]>+ \s $<arg> = .+
            }

            token opcode(@opcodes) {
                $<name> = @opcodes 
		[ 
                    <{ #repeating mnemos break this, because we don't know
			# what kind of arg is even allowed if multiple could be...
            }
        }

    }

    method second-pass(Str $input) {

    }

    method assemble(Str $input) {
        second-pass(first-pass($input))
    }
}
