library ieee;
use ieee.std_logic_1164.all;

package instruction_pkg is
    subtype opcode_t is std_logic_vector(7 downto 0);
    subtype instruction_kind_t is std_logic_vector(3 downto 0);

    constant OPCODE_NOP : opcode_t := x"00";
    constant OPCODE_LDI : opcode_t := x"10";
    constant OPCODE_LDA : opcode_t := x"11";
    constant OPCODE_STA : opcode_t := x"12";
    constant OPCODE_ADD : opcode_t := x"20";
    constant OPCODE_SUB : opcode_t := x"21";
    constant OPCODE_AND : opcode_t := x"22";
    constant OPCODE_OR  : opcode_t := x"23";
    constant OPCODE_XOR : opcode_t := x"24";
    constant OPCODE_JMP : opcode_t := x"30";
    constant OPCODE_JZ  : opcode_t := x"31";
    constant OPCODE_JC  : opcode_t := x"32";
    constant OPCODE_HLT : opcode_t := x"FF";

    constant INSTRUCTION_INVALID        : instruction_kind_t := "0000";
    constant INSTRUCTION_NOP            : instruction_kind_t := "0001";
    constant INSTRUCTION_LOAD_IMMEDIATE : instruction_kind_t := "0010";
    constant INSTRUCTION_LOAD_MEMORY    : instruction_kind_t := "0011";
    constant INSTRUCTION_STORE_MEMORY   : instruction_kind_t := "0100";
    constant INSTRUCTION_ALU            : instruction_kind_t := "0101";
    constant INSTRUCTION_JUMP           : instruction_kind_t := "0110";
    constant INSTRUCTION_JUMP_ZERO      : instruction_kind_t := "0111";
    constant INSTRUCTION_JUMP_CARRY     : instruction_kind_t := "1000";
    constant INSTRUCTION_HALT           : instruction_kind_t := "1001";
end package;

package body instruction_pkg is
end package body;
