use ASM::Opcode;
use ASM::CPU;

class ASM::H6809::CPU is ASM::CPU {
    has $.wordsize;
    has @.opcode-types;
    has @.opcodes;

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

        sub toaddr($hibyte, $lobyte) {
            ($hibyte // 0) +< 8 + ($lobyte // 0)
        }

        sub argshexjoin {
            toaddr(@*args[0], @*args[1])
        }

        sub xreghexjoin {
            toaddr($*xreg.fmt("%4x").comb(/../)>>.Int)
        }

        @!opcodes.push: ASM::Opcode.new(
            :op({ }), 
            :mnemo('NOP'), :hex(0x12), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc = 0 }), 
            :mnemo('CLRA'), :hex(0x4F), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc -= 127 }), 
            :mnemo('COMA'), :hex(0x43), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc -= 128 }), 
            :mnemo('NEGA'), :hex(0x40), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc /= 2 }), 
            :mnemo('RORA'), :hex(0x46), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op({ #`[[ TODO ]] }), 
            :mnemo('RTS'), :hex(0x39), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc = @*objcode[argshexjoin()] }), 
            :mnemo('LDA'), :hex(0xB6), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ @*objcode[argshexjoin()] = $*acc }), 
            :mnemo('STA'), :hex(0xB7), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc += @*objcode[argshexjoin()] }), 
            :mnemo('ADDA'), :hex(0xBB), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*zflag = ($*acc - @*objcode[argshexjoin()]) == 0 }),
            :mnemo('CMPA'), :hex(0xB1), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc = ($*acc +& @*objcode[argshexjoin()]) % 255 }),
            :mnemo('ANDA'), :hex(0xB4), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*xreg = @*objcode[argshexjoin()] }),
            :mnemo('LDX'), :hex(0xBE), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ @*objcode[argshexjoin()] = @*objcode[xreghexjoin()] }),
            :mnemo('STX'), :hex(0xBF), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*zflag = (@*objcode[argshexjoin()] - @*objcode[xreghexjoin()]) == 0 }),
            :mnemo('CMPX'), :hex(0xBC), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ @*objcode[xreghexjoin()] += @*objcode[argshexjoin()] }), 
            :mnemo('ADDX'), :hex(0x31), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*pc = argshexjoin }),
            :mnemo('JMP'), :hex(0x7E), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ #`[[ TODO ]] }),
            :mnemo('JSR'), :hex(0xBD), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc = @*args[0] }), 
            :mnemo('LDA'), :hex(0x86), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc += @*args[0] }),
            :mnemo('ADDA'), :hex(0x8B), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc = ( $*acc +& @*args[0]) % 255 }),
            :mnemo('ANDA'), :hex(0x84), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*zflag = ($*acc - (@*args[0] // 0)) == 0 }),
            :mnemo('CMPA'), :hex(0x81), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*xreg = xreghexjoin }),
            :mnemo('LDX'), :hex(0x8E), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*zflag = @*objcode[xreghexjoin] - @*objcode[argshexjoin] == 0}),
            :mnemo('CMPX'), :hex(0x8c), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ @*objcode[xreghexjoin] += argshexjoin }),
            :mnemo('ADDX'), :hex(0x30), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*sreg = argshexjoin }),
            :mnemo('LDS'), :hex(0x8F), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*acc = @*objcode[xreghexjoin] }),
            :mnemo('LDA'), :hex(0xA6), :arglength(0), :argtype('X'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ @*objcode[xreghexjoin] = $*acc }),
            :mnemo('STA'), :hex(0xA7), :arglength(0), :argtype('X'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*pc += !$*zflag ?? @*args[0] !! 0 }),
            :mnemo('BNE'), :hex(0x26), :arglength(1), :argtype('O'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*pc += $*zflag ?? @*args[0] !! 0 }),
            :mnemo('BEQ'), :hex(0x27), :arglength(1), :argtype('O'));
        @!opcodes.push: ASM::Opcode.new(
            :op({ $*pc += @*args[0] }),
            :mnemo('BRA'), :hex(0x20), :arglength(1), :argtype('O'));
    }

    method compute(Buf $objcode) {
        my $*pc = 0;
        my $*zflag = False;
        my $*acc = 0;
        my $*xreg = 0;
        my $*sreg = 0;
        my @*objcode := $objcode.list;
        while $*pc < +@*objcode & 2 ** 8 - 1 {
            my $ophex = @*objcode[$*pc];
            my $opcode = @!opcodes.grep(*.hex == $ophex)[0];
            my @*args = @*objcode[$*pc + 1 .. $opcode.arglength];
            $*pc += 1 + $opcode.arglength;
            $opcode.op()();
        }
        Buf.new(|@*objcode)
    }
}
