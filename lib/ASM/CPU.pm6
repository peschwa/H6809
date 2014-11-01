use ASM::Opcode;

class ASM::CPU {
    has @.opcode-types;
    has ASM::Opcode @.opcodes;
}
