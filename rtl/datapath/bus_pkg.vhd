library ieee;
use ieee.std_logic_1164.all;

package bus_pkg is
    subtype bus_select_t is std_logic_vector(2 downto 0);

    constant BUS_ACCUMULATOR : bus_select_t := "000";
    constant BUS_OPERAND     : bus_select_t := "001";
    constant BUS_INSTRUCTION : bus_select_t := "010";
    constant BUS_PC          : bus_select_t := "011";
    constant BUS_MEMORY      : bus_select_t := "100";
    constant BUS_ALU         : bus_select_t := "101";
    constant BUS_ZERO_0      : bus_select_t := "110";
    constant BUS_ZERO_1      : bus_select_t := "111";
end package;

package body bus_pkg is
end package body;
