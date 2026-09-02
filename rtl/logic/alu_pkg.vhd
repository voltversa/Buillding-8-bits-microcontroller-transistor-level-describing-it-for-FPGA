library ieee;
use ieee.std_logic_1164.all;

package alu_pkg is
    subtype alu_operation_t is std_logic_vector(2 downto 0);

    constant ALU_ADD    : alu_operation_t := "000";
    constant ALU_SUB    : alu_operation_t := "001";
    constant ALU_AND    : alu_operation_t := "010";
    constant ALU_OR     : alu_operation_t := "011";
    constant ALU_XOR    : alu_operation_t := "100";
    constant ALU_PASS_A : alu_operation_t := "101";
end package;

package body alu_pkg is
end package body;
