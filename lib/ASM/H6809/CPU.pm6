use ASM::Opcode;
use ASM::CPU;

class ASM::H6809::CPU {
    has $.wordsize;
    has @.opcode-types;
    has @.opcodes;

    has $.pc is rw;
    has $.zflag is rw;
    has $.acc is rw;
    has $.xreg is rw;
    has $.sreg is rw;
    has @.objcode is rw;

    method new {
        my $obj = self.CREATE;
        $obj.BUILD;
        $obj;
    }

    method toaddr($hibyte, $lobyte) {
        ($hibyte // 0) +< 8 + ($lobyte // 0)
    }

    method argshexjoin($hi, $low) {
        self.toaddr($hi, $low)
    }

    method xreghexjoin($xreg) {
        self.toaddr($xreg.fmt("%4x").comb(/../)>>.Int)
    }


    method BUILD {
        @!opcode-types.push: 'A'; # address
        @!opcode-types.push: 'I'; # immediate value
        @!opcode-types.push: 'O'; # offset/relative address
        @!opcode-types.push: 'X'; # address register
        @!opcode-types.push: ' '; # no argument

        $!wordsize = 8;
        $!pc = 0;
        $!zflag = 0;
        $!acc = 0;
        $!xreg = 0;
        $!sreg = 0;

        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { }), 
            :mnemo('NOP'), :hex(0x12), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc = 0 }), 
            :mnemo('CLRA'), :hex(0x4F), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc -= 127 }), 
            :mnemo('COMA'), :hex(0x43), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc -= 128 }), 
            :mnemo('NEGA'), :hex(0x40), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc /= 2 }), 
            :mnemo('RORA'), :hex(0x46), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { #`[[ TODO ]] }), 
            :mnemo('RTS'), :hex(0x39), :arglength(0), :argtype(' '));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc = $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] }), 
            :mnemo('LDA'), :hex(0xB6), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] = $cpu.acc }), 
            :mnemo('STA'), :hex(0xB7), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc += $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] }), 
            :mnemo('ADDA'), :hex(0xBB), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.zflag = ($cpu.acc - $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])]) == 0 }),
            :mnemo('CMPA'), :hex(0xB1), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc = ($cpu.acc +& $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])]) % 255 }),
            :mnemo('ANDA'), :hex(0xB4), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.xreg = $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] }),
            :mnemo('LDX'), :hex(0xBE), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] = $cpu.objcode[$cpu.xreghexjoin($cpu.xreg)] }),
            :mnemo('STX'), :hex(0xBF), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.zflag = ($cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] 
                - $cpu.objcode[$cpu.xreghexjoin($cpu.xreg)]) == 0 }),
            :mnemo('CMPX'), :hex(0xBC), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.objcode[$cpu.xreghexjoin($cpu.xreg)] 
                += $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] }), 
            :mnemo('ADDX'), :hex(0x31), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.pc = $cpu.argshexjoin(@args[0], @args[1]) }),
            :mnemo('JMP'), :hex(0x7E), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { #`[[ TODO ]] }),
            :mnemo('JSR'), :hex(0xBD), :arglength(2), :argtype('A'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc = @args[0] }), 
            :mnemo('LDA'), :hex(0x86), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc += @args[0] }),
            :mnemo('ADDA'), :hex(0x8B), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc = ( $cpu.acc +& @args[0]) % 255 }),
            :mnemo('ANDA'), :hex(0x84), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.zflag = ($cpu.acc - (@args[0] // 0)) == 0 }),
            :mnemo('CMPA'), :hex(0x81), :arglength(1), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.xreg = $cpu.xreghexjoin($cpu.xreg) }),
            :mnemo('LDX'), :hex(0x8E), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.zflag = $cpu.objcode[$cpu.xreghexjoin($cpu.xreg)] 
                - $cpu.objcode[$cpu.argshexjoin(@args[0], @args[1])] }),
            :mnemo('CMPX'), :hex(0x8c), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.objcode[$cpu.xreghexjoin($cpu.xreg)] += $cpu.argshexjoin(@args[0], @args[1]) }),
            :mnemo('ADDX'), :hex(0x30), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.sreg = $cpu.argshexjoin(@args[0], @args[1]) }),
            :mnemo('LDS'), :hex(0x8F), :arglength(2), :argtype('I'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.acc = $cpu.objcode[$cpu.xreghexjoin($cpu.xreg)] }),
            :mnemo('LDA'), :hex(0xA6), :arglength(0), :argtype('X'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.objcode[$cpu.xreghexjoin($cpu.xreg)] = $cpu.acc }),
            :mnemo('STA'), :hex(0xA7), :arglength(0), :argtype('X'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.pc += !$cpu.zflag ?? ( @args[0] > 127 ?? @args[0] - 256 !! @args[0] ) !! 0 }),
            :mnemo('BNE'), :hex(0x26), :arglength(1), :argtype('O'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.pc += $cpu.zflag ?? ( @args[0] > 127 ?? @args[0] - 256 !! @args[0] ) !! 0 }),
            :mnemo('BEQ'), :hex(0x27), :arglength(1), :argtype('O'));
        @!opcodes.push: ASM::Opcode.new(
            :op(-> $cpu, @args { $cpu.pc += ( @args[0] > 127 ?? @args[0] - 256 !! @args[0] ) }),
            :mnemo('BRA'), :hex(0x20), :arglength(1), :argtype('O'));
    }

    method compute(Buf $objcode) {
        $.init($objcode);

        say $.gist;
        while $.pc < +@.objcode & 2 ** 8 - 1 {
            $.step;
            say $.gist;
        }
        Buf.new(|@!objcode)
    }

    method init(Buf $objcode) {
        $!wordsize = 8;
        $!pc = 0;
        $!zflag = 0;
        $!acc = 0;
        $!xreg = 0;
        $!sreg = 0;

        @!objcode = $objcode.list;
    }

    method step {
        my $ophex = @.objcode[$.pc];
        my $opcode = @.opcodes.grep(*.hex == $ophex)[0];
        my @args = @.objcode[$.pc + 1 .. $.pc + $opcode.arglength];
        $!pc += 1 + $opcode.arglength;
        $opcode.op()(self, @args);
    }

    method gist() {
        "PC: $.pc\tZ: $.zflag\tA: $.acc\tX: $.xreg\tS: $.sreg"
    }
}
