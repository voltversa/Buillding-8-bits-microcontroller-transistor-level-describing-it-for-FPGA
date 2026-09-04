library ieee;
use ieee.std_logic_1164.all;
use work.bus_pkg.all;

-- Combinational source selector for the CPU's internal data bus. FPGA fabric
-- implements internal buses as multiplexers rather than shared tri-state nets.
entity internal_bus8 is
    port (
        source_accumulator : in  std_logic_vector(7 downto 0);
        source_operand     : in  std_logic_vector(7 downto 0);
        source_instruction : in  std_logic_vector(7 downto 0);
        source_pc          : in  std_logic_vector(7 downto 0);
        source_memory      : in  std_logic_vector(7 downto 0);
        source_alu         : in  std_logic_vector(7 downto 0);
        source_select      : in  bus_select_t;
        bus_data           : out std_logic_vector(7 downto 0)
    );
end entity;

architecture structural of internal_bus8 is
    signal level_0_0 : std_logic_vector(7 downto 0);
    signal level_0_1 : std_logic_vector(7 downto 0);
    signal level_0_2 : std_logic_vector(7 downto 0);
    signal level_0_3 : std_logic_vector(7 downto 0);
    signal level_1_0 : std_logic_vector(7 downto 0);
    signal level_1_1 : std_logic_vector(7 downto 0);
begin
    -- An 8:1 bus multiplexer is assembled as a three-level tree of 2:1 cells.
    -- Selector codes 110 and 111 intentionally select a hard-wired zero input.
    generate_bus_bits : for bit_index in 0 to 7 generate
        choose_accumulator_or_operand : entity work.mux2_1bit(structural)
            port map (
                input_0  => source_accumulator(bit_index),
                input_1  => source_operand(bit_index),
                select_1 => source_select(0),
                output_y => level_0_0(bit_index)
            );

        choose_instruction_or_pc : entity work.mux2_1bit(structural)
            port map (
                input_0  => source_instruction(bit_index),
                input_1  => source_pc(bit_index),
                select_1 => source_select(0),
                output_y => level_0_1(bit_index)
            );

        choose_memory_or_alu : entity work.mux2_1bit(structural)
            port map (
                input_0  => source_memory(bit_index),
                input_1  => source_alu(bit_index),
                select_1 => source_select(0),
                output_y => level_0_2(bit_index)
            );

        choose_reserved_zero : entity work.mux2_1bit(structural)
            port map (
                input_0  => '0',
                input_1  => '0',
                select_1 => source_select(0),
                output_y => level_0_3(bit_index)
            );

        choose_low_group : entity work.mux2_1bit(structural)
            port map (
                input_0  => level_0_0(bit_index),
                input_1  => level_0_1(bit_index),
                select_1 => source_select(1),
                output_y => level_1_0(bit_index)
            );

        choose_high_group : entity work.mux2_1bit(structural)
            port map (
                input_0  => level_0_2(bit_index),
                input_1  => level_0_3(bit_index),
                select_1 => source_select(1),
                output_y => level_1_1(bit_index)
            );

        choose_bus_output : entity work.mux2_1bit(structural)
            port map (
                input_0  => level_1_0(bit_index),
                input_1  => level_1_1(bit_index),
                select_1 => source_select(2),
                output_y => bus_data(bit_index)
            );
    end generate;
end architecture;
