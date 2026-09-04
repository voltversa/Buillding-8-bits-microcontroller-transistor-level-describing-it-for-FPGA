library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.bus_pkg.all;

entity internal_bus8_tb is
end entity;

architecture test of internal_bus8_tb is
    signal accumulator_value : std_logic_vector(7 downto 0) := (others => '0');
    signal operand_value     : std_logic_vector(7 downto 0) := (others => '0');
    signal instruction_value : std_logic_vector(7 downto 0) := (others => '0');
    signal pc_value          : std_logic_vector(7 downto 0) := (others => '0');
    signal memory_value      : std_logic_vector(7 downto 0) := (others => '0');
    signal alu_value         : std_logic_vector(7 downto 0) := (others => '0');
    signal source_select     : bus_select_t := BUS_ACCUMULATOR;
    signal bus_data          : std_logic_vector(7 downto 0);
begin
    dut : entity work.internal_bus8(structural)
        port map (
            source_accumulator => accumulator_value,
            source_operand     => operand_value,
            source_instruction => instruction_value,
            source_pc          => pc_value,
            source_memory      => memory_value,
            source_alu         => alu_value,
            source_select      => source_select,
            bus_data           => bus_data
        );

    stimulus : process
        variable expected : std_logic_vector(7 downto 0);
    begin
        -- Exercise every selector code while sweeping every possible byte
        -- pattern through every source.
        for selector_value in 0 to 7 loop
            for data_value in 0 to 255 loop
                accumulator_value <= std_logic_vector(to_unsigned(data_value, 8));
                operand_value <= std_logic_vector(to_unsigned((data_value + 37) mod 256, 8));
                instruction_value <= std_logic_vector(to_unsigned((data_value + 73) mod 256, 8));
                pc_value <= std_logic_vector(to_unsigned((data_value + 109) mod 256, 8));
                memory_value <= std_logic_vector(to_unsigned((data_value + 151) mod 256, 8));
                alu_value <= std_logic_vector(to_unsigned((data_value + 211) mod 256, 8));
                source_select <= std_logic_vector(to_unsigned(selector_value, 3));
                wait for 1 ns;

                case selector_value is
                    when 0 => expected := accumulator_value;
                    when 1 => expected := operand_value;
                    when 2 => expected := instruction_value;
                    when 3 => expected := pc_value;
                    when 4 => expected := memory_value;
                    when 5 => expected := alu_value;
                    when others => expected := (others => '0');
                end case;

                assert bus_data = expected
                    report "internal bus mismatch: selector=" &
                        integer'image(selector_value) & " pattern=" &
                        integer'image(data_value)
                    severity failure;
            end loop;
        end loop;

        report "PASS: all selectors and 2048 bus cases" severity note;
        finish;
    end process;
end architecture;
