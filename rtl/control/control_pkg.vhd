library ieee;
use ieee.std_logic_1164.all;

package control_pkg is
    subtype control_state_t is std_logic_vector(2 downto 0);

    constant CONTROL_FETCH         : control_state_t := "000";
    constant CONTROL_DECODE        : control_state_t := "001";
    constant CONTROL_OPERAND_FETCH : control_state_t := "010";
    constant CONTROL_EXECUTE       : control_state_t := "011";
    constant CONTROL_HALTED        : control_state_t := "100";
    constant CONTROL_FAULT         : control_state_t := "101";
end package;

package body control_pkg is
end package body;
