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
                        [ <label> ' '+ ]?
                        '.' <directive>
                    ||  [ <label> ':' ' '+ ]?
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
                ||  <label>
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

            token label {
                \w+
            }

        }

        my class ASMFirstPassAction {
            has $.position = 0;
            has @.memory;
            has %.labels;

            method TOP($/) {
                my $label;
                if $<directive> && $<label> ne any(@*MNEMOS) {
                    my $directive = make $<directive>>>.ast;
                    $label = make $<label>>>.ast;
                    if $directive && $label {
                        %.labels{$label} //= $.position;
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
                                my @parts = $pair.value.trans(" " => "0").comb(/../).map({ :16($^a) })>>.Int;
                                @!memory[$i .. $i+1] = @parts.flat;
                            }
                            else {
                                $cur = $pair.value.trans(" " => "0").comb(/../).map({ :16($^a) })>>.Int[1];
                            }
                            last;
                        }
                    }
                    $i++
                }

                @!memory = map { $_ ?? $_.Int !! 0 }, @!memory;

                my $buf = Buf.new(|@.memory);
                make $buf;
            }

            method label($/) {
                my $label = $/.Str.trans(':' => '');
                if $label ne any(@*MNEMOS) {
                    %!labels{$label} //= $.position.fmt("%4x");
                    make $label
                }
            }

            method directive($/) {
                if $<name> eq 'ORG' {
                    $!position = $<arg>.trans('$' => '').Int;
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
                my $argval =  $<operand><addr-reg> //
                              $<operand><immediate-val> //
                              $<operand><address> //
                              $<operand><label> // ' ';

                my $opcode = %*M2O{$<name>}.grep(*.argtype eq $argtype)[0];

                if $argtype ne 'O' {
                    # remove indicator for imidiate values, we already know from the opcode
                    $argval .= trans('#' => '');

                    my $fmt = "%0" ~ ($opcode.arglength * 2) ~ "x";

                    # argval is a string, we have to pay attention what base it's notated in
                    $argval = $argtype eq any('X', ' ') ?? $argval !!
                        $argval.substr(0, 1) eq '$'
                        ?? $argval.trans('$' => '').comb(/../).map({ :16( $^a ) })>>.Int
                        !! sprintf($fmt, $argval).comb(/../).map({ :16( $^a ) })>>.Int;
                }

                @.memory[$!position] = $opcode.hex;
                $!position++;

                my @next = ( $argtype ne any(' ', 'X')
                        ?? $argtype eq all('O', 'A') && $opcode.argtype ne 'O'
                            ?? (~$argval, ~$argval)
                            !! $argval
                        !! Nil
                    ).flat;

                for @next -> $elem {
                    @.memory[$.position] = ~$elem;
                    $!position++;
                }
            }
        }

        my %*M2O = %!mnemo-to-opcode;
        my @*MNEMOS = @!mnemos;

        ASMFirstPassGrammar.parse($input, :actions(ASMFirstPassAction.new)).ast;
    }

    method assemble(Str $input) {
        self.first-pass($input)
    }
}
