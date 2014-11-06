class ASM::Opcode {
    has Str $.mnemo; # mnemonic
    has Int $.hex; # object code for the op, not neccessarily hex FIXME
    has $.arglength; # amount of bytes consumed as arguments
    has $.argtype; # type of the arguments, e.g. address/label, immediate etc
    has $.op; # closure which computes the function of the mnemonic
}
