use ASM::H6809::CPU;

class X::ASM::UnknownMnemonic is Exception {
    has $.mnemo;
    method message { "Unknown mnemonic {$.mnemo}." }
}

class X::ASM::MissingOrMistypedArgument is Exception {
    has $.mnemo;
    method message { "Failed to parse " ~ $.mnemo ~ ". Argument missing or of the wrong type." }
}

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
        %!mnemo-to-opcode{.mnemo}.push($_) for $!cpu.opcodes;
        @.mnemos = %!mnemo-to-opcode.keys;
    }

    method first-pass(Str $input) {

        my grammar ASMFirstPassGrammar {
            token TOP {
                [
                    [
                        [ <label('d')> ' '+ ]?
                        '.' <directive>
                    ||  [ <label('j')> ':' ' '+ ]?
                        <opcode>
                    ]
                ]+ %% \x0A +?
            }

            token directive {
                $<name> = [ 'ORG' | 'EQU' | 'BYTE' ] \s+ $<arg> = <-[\xA]>+
            }

            token opcode {
                [
                    $<name> = @*MNEMOS
                    [
                        <?{ %*M2O{$<name>}.elems == 1
                        && %*M2O{$<name>}[0].arglength == 0}>
                    ||
                        ' '+? <operand>
                        <?{
                            $<operand><addr-reg> && %*M2O{$<name>}.grep(*.argtype eq 'X')
                        ||  $<operand><immediate-val> && %*M2O{$<name>}.grep(*.argtype eq 'I')
                        ||  $<operand><address> && %*M2O{$<name>}.grep(*.argtype eq 'A')
                        ||  $<operand><label> && %*M2O{$<name>}.grep(*.argtype eq 'O'|'A')
                        }>
                    ||  { X::ASM::MissingOrMistypedArgument.new(:mnemo($<name>)).throw }
                    ]
                ||
                    $<name> = \w+ { X::ASM::UnknownMnemonic.new(:mnemo($<name>)).throw }
                ]
            }

            token operand {
                [
                    <addr-reg>
                ||  <immediate-val>
                ||  <address>
                ||  <label('x')>
                ]
            }

            token addr-reg {
                [ '@' 'X' ]
            }

            token immediate-val {
                '#' <.address>
            }

            token address {
                [
                    '$' <[0..9A..Fa..f]>+
                ||  <[0..9]>+
                ]
            }

            token label($arg) {
                \w+ 
                [
                    <?{ $arg eq 'd' }> $<d> = <?>
                ||  <?{ $arg eq 'j' }> $<j> = <?>
                ||  <?{ $arg eq 'x' }> <?>
                ]
            }

        }

        my class ASMFirstPassAction {
            has $.position = 0;
            has @.memory;
            has %.labels;

            method TOP($/) {
                my $label;
                if $<label> ne any(@*MNEMOS) {
                    if $<directive> {
                        $label = make $<label>>>.ast;
                        my $directive = make $<directive>>>.ast;
                        if $directive && $label {
                            %.labels{$label} //= $.position;
                        }
                    }
                }

                my $i = 0;
                while $i <= @!memory {
                    my $cur := @!memory[$i];
                    unless $cur {
                        $i++;
                        next;
                    }
                    for %.labels.pairs -> $pair {
                        if $pair.key && $cur eq $pair.key {
                            if @!memory[1+$i] && @!memory[1+$i] eq $pair.key {
                                my @parts = :16($pair.value.substr(1,2)).Int, :16($pair.value.substr(3,2)).Int;
                                @!memory[$i .. $i+1] = @parts.flat;
                            }
                            else {
                                $cur = :16($pair.value.substr(3)).Int;
                            }
                            last;
                        }
                        elsif $pair.key && $cur eq ("O:" ~ $pair.key) {
                            my $labelpos = :16($pair.value.substr(1,2)).Int +< 0x8 + :16($pair.value.substr(3,2)).Int;
                            my $pos = ($labelpos - $i);
                            $cur = $pos <= 0 ?? $pos - 1 !! $pos - 1;
                        }
                    }
                    $i++
                }

                @!memory = map { $_ ?? $_.Int !! 0 }, @!memory;

                my $buf = Buf.new(|@.memory);
                make $buf;
            }

            method label($/) {
                if $/.Str ne any(@*MNEMOS) {
                    my $label = $/.Str;
                    if $<j> || $<d> {
                        %!labels{$label} //= $.position.fmt("%04x");
                    }
                    make $label
                }
            }

            method directive($/) {
                if $<name> eq 'ORG' {
                    if $<arg>.substr(0, 1) eq '$' {
                        $!position = :16($<arg>.substr(1)).Int;
                    } 
                    else {
                        $!position = $<arg>.Int;
                    }
                    CATCH {
                        when X::Str::Numeric {
                            X::ASM::MissingOrMistypedArgument.new(:mnemo('.ORG'))
                        }
                    }
                    @!memory[$!position] = 0;
                    make '';
                }
                else {
                    make $<arg>.Str
                }
            }

            method opcode($/) {
                my $argtype = $<operand><addr-reg> ?? 'X' !!
                              $<operand><immediate-val> ?? 'I' !!
                              $<operand><address> ?? 'A' !!
                              $<operand><label> ?? any('O', 'A') !! ' ';

                my $opcode = %*M2O{$<name>}.grep(*.argtype eq $argtype)[0];

                @.memory[$!position] = $opcode.hex;
                $!position++;

                my @next; 
                if $opcode.argtype eq ' ' || $argtype eq 'X' {
                    @next = Nil
                }
                elsif $opcode.argtype eq 'O' && $opcode.arglength == 1  {
                    if $<operand><label> {
                        @next = "O:" ~ $<operand><label>;
                    }
                    if $<operand><immediate-val> {
                        @next = convert-address($<operand><immediate-val>, bytes => $opcode.arglength);
                    }
                }
                elsif $opcode.argtype eq 'O' && $opcode.arglength == 2 {
                    if $<operand><label> {
                        @next = ~$<operand><label>, ~$<operand><label>;
                    }
                    if $<operand><immediate-val> {
                        my $argval = ~$<operand><immediate-val>.substr(1);
                        @next = convert-address($<operand><immediate-val>, bytes => $opcode.arglength);
                    }
                }
                else {
                    if $<operand><label> {
                        @next = ~$<operand><label>, ~$<operand><label>;
                    }
                    if $<operand><immediate-val> && $opcode.arglength == 1 {
                        @next = convert-address($<operand><immediate-val>, bytes => $opcode.arglength);
                    }
                    if $<operand><immediate-val> && $opcode.arglength == 2 {
                        @next = convert-address($<operand><immediate-val>, bytes => $opcode.arglength);
                    }
                    if $<operand><address> {
                        @next = convert-address($<operand><address>, bytes => $opcode.arglength);
                    }
                }

                for @next -> $elem {
                    @.memory[$.position] = ~$elem;
                    $!position++;
                }
            }
        }

        sub convert-address($addr is copy, Int :$bytes! where { * == 1 || * == 2 }) {
            my @ret;

            # remove indicator for immediate value, the callsite knows
            if $addr.substr(0, 1) eq '#' {
                $addr .= substr(1);
            }

            my $is-hex = $addr.substr(0, 1) eq '$';

            if $bytes == 2 {
                if $is-hex {
                    @ret = :16($addr.substr(1, 2)), :16($addr.substr(3, 2));
                }
                else {
                    @ret = sprintf("%04x", $addr).comb(/../).map({ :16( $^a ) });
                }
            }
            elsif $bytes == 1 {
                if $is-hex {
                    @ret = :16($addr.substr(1, 2));
                }
                else {
                    @ret = :16(sprintf("%02x", $addr));
                }
            }
            @ret[0 .. $bytes];
        }

        my %*M2O = %!mnemo-to-opcode;
        my @*MNEMOS = @!mnemos;

        ASMFirstPassGrammar.parse($input, :actions(ASMFirstPassAction.new)).ast;
    }

    method assemble(Str $input) {
        self.first-pass($input)
    }
}
