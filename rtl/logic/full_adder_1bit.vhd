library ieee;
use ieee.std_logic_1164.all;

entity full_adder_1bit is
    port (
        a         : in  std_logic;
        b         : in  std_logic;
        carry_in  : in  std_logic;
        sum       : out std_logic;
        carry_out : out std_logic
    );
end entity;

architecture structural of full_adder_1bit is
    signal a_xor_b          : std_logic;
    signal carry_from_ab    : std_logic;
    signal carry_from_input : std_logic;
begin
    xor_ab : entity work.xor2(structural)
        port map (a => a, b => b, y => a_xor_b);

    xor_sum : entity work.xor2(structural)
        port map (a => a_xor_b, b => carry_in, y => sum);

    and_ab : entity work.and2(structural)
        port map (a => a, b => b, y => carry_from_ab);

    and_input : entity work.and2(structural)
        port map (
            a => a_xor_b,
            b => carry_in,
            y => carry_from_input
        );

    or_carry : entity work.or2(structural)
        port map (
            a => carry_from_ab,
            b => carry_from_input,
            y => carry_out
        );
end architecture;
