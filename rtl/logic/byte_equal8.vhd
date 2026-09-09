library ieee;
use ieee.std_logic_1164.all;

-- Structural eight-bit equality comparator used by address decoders.
entity byte_equal8 is
    generic (
        expected_value : std_logic_vector(7 downto 0)
    );
    port (
        value    : in  std_logic_vector(7 downto 0);
        is_equal : out std_logic
    );
end entity;

architecture structural of byte_equal8 is
    signal bit_differs : std_logic_vector(7 downto 0);
    signal bit_matches : std_logic_vector(7 downto 0);
    signal pair_matches : std_logic_vector(3 downto 0);
    signal quad_matches : std_logic_vector(1 downto 0);
begin
    compare_bits : for bit_index in 0 to 7 generate
        difference_gate : entity work.xor2(structural)
            port map (
                a => value(bit_index),
                b => expected_value(bit_index),
                y => bit_differs(bit_index)
            );

        equality_inverter : entity work.inv1(rtl)
            port map (
                a => bit_differs(bit_index),
                y => bit_matches(bit_index)
            );
    end generate;

    reduce_pairs : for pair_index in 0 to 3 generate
        pair_gate : entity work.and2(structural)
            port map (
                a => bit_matches(pair_index * 2),
                b => bit_matches(pair_index * 2 + 1),
                y => pair_matches(pair_index)
            );
    end generate;

    reduce_quads : for quad_index in 0 to 1 generate
        quad_gate : entity work.and2(structural)
            port map (
                a => pair_matches(quad_index * 2),
                b => pair_matches(quad_index * 2 + 1),
                y => quad_matches(quad_index)
            );
    end generate;

    output_gate : entity work.and2(structural)
        port map (
            a => quad_matches(0),
            b => quad_matches(1),
            y => is_equal
        );
end architecture;
