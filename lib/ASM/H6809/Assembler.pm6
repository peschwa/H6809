use ASM::H6809::CPU;

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
                <label>?
                [
                    '.' <directive>
                ||  <opcode>
                ]+ %% "\n" +?
            }

            token label {
                \w+ ':'
            }

            token directive {
                $<name> = [ 'ORG' | 'EQU' | 'BYTE' ] \s+ $<arg> = <-[\xA]>+
            }

            token opcode {
                $<name> = @*MNEMOS
                [
                    <?{ %*M2O{$<name>}.elems == 1
                    && %*M2O{$<name>}[0].arglength == 0}>
                ||
                    <.ws>+? <operand> 
                    <?{ 
                        $<operand><addr-reg> && %*M2O{$<name>}.grep(*.argtype eq 'X') 
                    ||  $<operand><immediate-val> && %*M2O{$<name>}.grep(*.argtype eq 'I')
                    ||  $<operand><address> && %*M2O{$<name>}.grep(*.argtype eq 'A')
                    }>
                ||  { die "Failed to parse {$<name>}. Argument missing or wrong type." }
                ]
            }

            token operand {
		[
                    <addr-reg> 
                ||  <immediate-val>
                ||  <address>
                ]
            }

            token addr-reg {
                $<value> = '@X'
            }

            token immediate-val {
                '#' $<value> = <.address>
            }

            token address {
                $<value> = [
                    '$' <[0..9A..F]>+
                ||  <[0..9]>+
                ||  \w+
                ]
            }
        }

        my class ASMFirstPassAction {
            has $.position = 0;
            has Int @.memory;
            has %.labels;

            method TOP($/) {
                my $label;
                if $<label> {
                    $label = make $<label>>>.ast;
                    %!labels{$label} = $.position;
                }
                if $<directive> {
                    my $directive = make $<directive>>>.ast;
                    if $directive && $label {
                        %.labels{$label} = $.position;
                    }
                }

                make @.memory;
            }

            method label($/) {
                make $/.Str.trans(':' => '')
            }

            method directive($/) {
                if $<name> eq 'ORG' {
                    $!position = $<arg>.trans('$' => '').Int;
                    make '';
                }
                else {
                    make $<arg>.Str
                }
            }

            method opcode($/) {
                my $argtype = $<operand><add-reg> ?? 'X' !!
                              $<operand><immediate-val> ?? 'I' !!
                              $<operand><address> ?? 'A' !! ' ';
                my $argval = $<operand><add-reg> //
                             $<operand><immediate-val> //
                             $<operand><address> // ' ';

                # argval is a string, we have to pay attention what base it's notated in
                $argval = $argtype eq any('X', ' ') ?? $argval !! 
                    $argval.substr(0, 1) eq '$' 
                    ?? :16($argval.trans('$' => '')).comb(/../)>>.Int>>.base(10) 
                    !! sprintf("%04x", $argval).comb(/../);

                # still missing offset calculation
                my $opcode = %*M2O{$<name>}.grep(*.argtype eq $argtype)[0];

                @.memory[$!position] = $opcode.hex;
                $!position++;

                my @next = ( $opcode.argtype ne any(' ', 'X') 
                        ?? $argval
                        !! Nil 
                    ).flat;

                for @next -> $elem {
                    @.memory[$.position] = $elem.Int;
                    $!position++;
                }
            }
        }

        my %*M2O = %!mnemo-to-opcode;
        my @*MNEMOS = @!mnemos;

        map { $_ ?? $_.Int !! 0 }, ASMFirstPassGrammar.parse($input, :actions(ASMFirstPassAction.new)).ast;
    }

    method second-pass(Str $input) {

    }

    method assemble(Str $input) {
        self.second-pass(self.first-pass($input))
    }
}
