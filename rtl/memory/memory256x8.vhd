library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.memory_pkg.all;

-- Educational structural memory: 256 byte registers, a decoded synchronous
-- write path, and an eight-level combinational read-multiplexer tree.
entity memory256x8 is
    generic (
        initial_content : memory_image_t := REFERENCE_PROGRAM
    );
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        address      : in  std_logic_vector(7 downto 0);
        write_enable : in  std_logic;
        data_in      : in  std_logic_vector(7 downto 0);
        data_out     : out std_logic_vector(7 downto 0)
    );
end entity;

architecture structural of memory256x8 is
    type memory_level_128_t is array (0 to 127) of std_logic_vector(7 downto 0);
    type memory_level_64_t is array (0 to 63) of std_logic_vector(7 downto 0);
    type memory_level_32_t is array (0 to 31) of std_logic_vector(7 downto 0);
    type memory_level_16_t is array (0 to 15) of std_logic_vector(7 downto 0);
    type memory_level_8_t is array (0 to 7) of std_logic_vector(7 downto 0);
    type memory_level_4_t is array (0 to 3) of std_logic_vector(7 downto 0);
    type memory_level_2_t is array (0 to 1) of std_logic_vector(7 downto 0);

    signal address_match : std_logic_vector(255 downto 0);
    signal byte_write_enable : std_logic_vector(255 downto 0);
    signal byte_data : memory_image_t;
    signal read_level_1 : memory_level_128_t;
    signal read_level_2 : memory_level_64_t;
    signal read_level_3 : memory_level_32_t;
    signal read_level_4 : memory_level_16_t;
    signal read_level_5 : memory_level_8_t;
    signal read_level_6 : memory_level_4_t;
    signal read_level_7 : memory_level_2_t;
    signal read_level_8 : std_logic_vector(7 downto 0);
begin
    generate_memory_bytes : for byte_index in 0 to 255 generate
        address_decoder : entity work.byte_equal8(structural)
            generic map (
                expected_value => std_logic_vector(to_unsigned(byte_index, 8))
            )
            port map (
                value => address,
                is_equal => address_match(byte_index)
            );

        write_gate : entity work.and2(structural)
            port map (
                a => write_enable,
                b => address_match(byte_index),
                y => byte_write_enable(byte_index)
            );

        byte_storage : entity work.memory_byte(rtl)
            generic map (
                reset_value => initial_content(byte_index)
            )
            port map (
                clock => clock,
                reset => reset,
                write_enable => byte_write_enable(byte_index),
                data_in => data_in,
                data_out => byte_data(byte_index)
            );
    end generate;

    generate_read_level_1 : for node_index in 0 to 127 generate
        generate_level_1_bits : for bit_index in 0 to 7 generate
            read_mux : entity work.mux2_1bit(structural)
                port map (
                    input_0 => byte_data(node_index * 2)(bit_index),
                    input_1 => byte_data(node_index * 2 + 1)(bit_index),
                    select_1 => address(0),
                    output_y => read_level_1(node_index)(bit_index)
                );
        end generate;
    end generate;

    generate_read_level_2 : for node_index in 0 to 63 generate
        generate_level_2_bits : for bit_index in 0 to 7 generate
            read_mux : entity work.mux2_1bit(structural)
                port map (
                    input_0 => read_level_1(node_index * 2)(bit_index),
                    input_1 => read_level_1(node_index * 2 + 1)(bit_index),
                    select_1 => address(1),
                    output_y => read_level_2(node_index)(bit_index)
                );
        end generate;
    end generate;

    generate_read_level_3 : for node_index in 0 to 31 generate
        generate_level_3_bits : for bit_index in 0 to 7 generate
            read_mux : entity work.mux2_1bit(structural)
                port map (
                    input_0 => read_level_2(node_index * 2)(bit_index),
                    input_1 => read_level_2(node_index * 2 + 1)(bit_index),
                    select_1 => address(2),
                    output_y => read_level_3(node_index)(bit_index)
                );
        end generate;
    end generate;

    generate_read_level_4 : for node_index in 0 to 15 generate
        generate_level_4_bits : for bit_index in 0 to 7 generate
            read_mux : entity work.mux2_1bit(structural)
                port map (
                    input_0 => read_level_3(node_index * 2)(bit_index),
                    input_1 => read_level_3(node_index * 2 + 1)(bit_index),
                    select_1 => address(3),
                    output_y => read_level_4(node_index)(bit_index)
                );
        end generate;
    end generate;

    generate_read_level_5 : for node_index in 0 to 7 generate
        generate_level_5_bits : for bit_index in 0 to 7 generate
            read_mux : entity work.mux2_1bit(structural)
                port map (
                    input_0 => read_level_4(node_index * 2)(bit_index),
                    input_1 => read_level_4(node_index * 2 + 1)(bit_index),
                    select_1 => address(4),
                    output_y => read_level_5(node_index)(bit_index)
                );
        end generate;
    end generate;

    generate_read_level_6 : for node_index in 0 to 3 generate
        generate_level_6_bits : for bit_index in 0 to 7 generate
            read_mux : entity work.mux2_1bit(structural)
                port map (
                    input_0 => read_level_5(node_index * 2)(bit_index),
                    input_1 => read_level_5(node_index * 2 + 1)(bit_index),
                    select_1 => address(5),
                    output_y => read_level_6(node_index)(bit_index)
                );
        end generate;
    end generate;

    generate_read_level_7 : for node_index in 0 to 1 generate
        generate_level_7_bits : for bit_index in 0 to 7 generate
            read_mux : entity work.mux2_1bit(structural)
                port map (
                    input_0 => read_level_6(node_index * 2)(bit_index),
                    input_1 => read_level_6(node_index * 2 + 1)(bit_index),
                    select_1 => address(6),
                    output_y => read_level_7(node_index)(bit_index)
                );
        end generate;
    end generate;

    generate_read_level_8 : for bit_index in 0 to 7 generate
        read_mux : entity work.mux2_1bit(structural)
            port map (
                input_0 => read_level_7(0)(bit_index),
                input_1 => read_level_7(1)(bit_index),
                select_1 => address(7),
                output_y => read_level_8(bit_index)
            );
    end generate;

    data_out <= read_level_8;
end architecture;
