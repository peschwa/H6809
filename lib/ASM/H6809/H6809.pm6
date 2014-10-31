use ASM::Opcode;

class ASM::H6809::CPU is CPU {
    has $.wordsize;

    method new() {
        my $obj = self.CREATE;
        $obj.BUILD;
        $obj;
    }

    method BUILD() {
        @!opcode-types.push: 'A'; # address
        @!opcode-types.push: 'I'; # immediate value
        @!opcode-types.push: 'O'; # offset/relative address
        @!opcode-types.push: 'X'; # address register
        @!opcode-types.push: ' '; # no argument

	$!wordsize = 8;

	# pure joy typing these
	@!opcodes.push: Opcode.new(:mnemo('NOP'), :hex(0x12), :arglength(0), :argtype(' '));
	@!opcodes.push: Opcode.new(:mnemo('CLRA'), :hex(0x4F), :arglength(0), :argtype(' '));
	@!opcodes.push: Opcode.new(:mnemo('COMA'), :hex(0x43), :arglength(0), :argtype(' '));
	@!opcodes.push: Opcode.new(:mnemo('NEGA'), :hex(0x40), :arglength(0), :argtype(' '));
	@!opcodes.push: Opcode.new(:mnemo('RORA'), :hex(0x46), :arglength(0), :argtype(' '));
	@!opcodes.push: Opcode.new(:mnemo('LDA'), :hex(0x86), :arglength(1), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('LDA'), :hex(0xA6), :arglength(0), :argtype('X'));
	@!opcodes.push: Opcode.new(:mnemo('LDA'), :hex(0xB6), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('STA'), :hex(0xA7), :arglength(0), :argtype('X'));
	@!opcodes.push: Opcode.new(:mnemo('STA'), :hex(0xB7), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('ADDA'), :hex(0x8B), :arglength(1), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('ADDA'), :hex(0xBB), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('ANDA'), :hex(0x84), :arglength(1), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('ANDA'), :hex(0xB4), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('CMPA'), :hex(0x81), :arglength(1), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('CMPA'), :hex(0xB1), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('LDX'), :hex(0x8E), :arglength(2), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('LDX'), :hex(0xBE), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('STX'), :hex(0xBF), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('CMPX'), :hex(0x8c), :arglength(2), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('CMPX'), :hex(0xBC), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('ADDX'), :hex(0x30), :arglength(2), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('ADDX'), :hex(0x31), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('LDS'), :hex(0x8F), :arglength(2), :argtype('I'));
	@!opcodes.push: Opcode.new(:mnemo('BNE'), :hex(0x26), :arglength(1), :argtype('O'));
	@!opcodes.push: Opcode.new(:mnemo('BEQ'), :hex(0x27), :arglength(1), :argtype('O'));
	@!opcodes.push: Opcode.new(:mnemo('BRA'), :hex(0x20), :arglength(1), :argtype('O'));
	@!opcodes.push: Opcode.new(:mnemo('JMP'), :hex(0x7E), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('JSR'), :hex(0xBD), :arglength(2), :argtype('A'));
	@!opcodes.push: Opcode.new(:mnemo('RTS'), :hex(0x39), :arglength(0), :argtype(' '));
    }
}
