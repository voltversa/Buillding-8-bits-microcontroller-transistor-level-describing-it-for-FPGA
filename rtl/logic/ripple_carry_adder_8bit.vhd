library ieee;
use ieee.std_logic_1164.all;

entity ripple_carry_adder_8bit is
    port (
        a         : in  std_logic_vector(7 downto 0);
        b         : in  std_logic_vector(7 downto 0);
        carry_in  : in  std_logic;
        sum       : out std_logic_vector(7 downto 0);
        carry_out : out std_logic
    );
end entity;

architecture structural of ripple_carry_adder_8bit is
    signal carry : std_logic_vector(8 downto 0);
begin
    carry(0) <= carry_in;
    carry_out <= carry(8);

    generate_adders : for bit_index in 0 to 7 generate
        adder : entity work.full_adder_1bit(structural)
            port map (
                a         => a(bit_index),
                b         => b(bit_index),
                carry_in  => carry(bit_index),
                sum       => sum(bit_index),
                carry_out => carry(bit_index + 1)
            );
    end generate;
end architecture;
