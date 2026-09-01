library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity cmos_cells_tb is
end entity;

architecture test of cmos_cells_tb is
    signal a          : std_logic := '0';
    signal b          : std_logic := '0';
    signal inverter_y : std_logic;
    signal nand_y     : std_logic;
    signal nor_y      : std_logic;

    function to_bit(value : natural) return std_logic is
    begin
        if value = 0 then
            return '0';
        end if;
        return '1';
    end function;
begin
    inverter_dut : entity work.cmos_inverter(behavioral)
        port map (a => a, y => inverter_y);

    nand_dut : entity work.cmos_nand2(behavioral)
        port map (a => a, b => b, y => nand_y);

    nor_dut : entity work.cmos_nor2(behavioral)
        port map (a => a, b => b, y => nor_y);

    stimulus : process
    begin
        for a_value in 0 to 1 loop
            for b_value in 0 to 1 loop
                a <= to_bit(a_value);
                b <= to_bit(b_value);
                wait for 1 ns;

                assert inverter_y = not a
                    report "CMOS inverter truth-table mismatch"
                    severity failure;

                assert nand_y = not (a and b)
                    report "CMOS NAND truth-table mismatch"
                    severity failure;

                assert nor_y = not (a or b)
                    report "CMOS NOR truth-table mismatch"
                    severity failure;
            end loop;
        end loop;

        report "PASS: CMOS cell truth tables" severity note;
        finish;
    end process;
end architecture;
