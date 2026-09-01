library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity ripple_carry_adder_8bit_tb is
end entity;

architecture test of ripple_carry_adder_8bit_tb is
    signal a         : std_logic_vector(7 downto 0) := (others => '0');
    signal b         : std_logic_vector(7 downto 0) := (others => '0');
    signal carry_in  : std_logic := '0';
    signal sum       : std_logic_vector(7 downto 0);
    signal carry_out : std_logic;

    function to_bit(value : natural) return std_logic is
    begin
        if value = 0 then
            return '0';
        end if;
        return '1';
    end function;
begin
    dut : entity work.ripple_carry_adder_8bit(structural)
        port map (
            a         => a,
            b         => b,
            carry_in  => carry_in,
            sum       => sum,
            carry_out => carry_out
        );

    stimulus : process
        variable expected : unsigned(8 downto 0);
    begin
        for carry_value in 0 to 1 loop
            for a_value in 0 to 255 loop
                for b_value in 0 to 255 loop
                    a <= std_logic_vector(to_unsigned(a_value, a'length));
                    b <= std_logic_vector(to_unsigned(b_value, b'length));
                    carry_in <= to_bit(carry_value);
                    wait for 1 ns;

                    expected := to_unsigned(
                        a_value + b_value + carry_value,
                        expected'length
                    );

                    assert unsigned(carry_out & sum) = expected
                        report "Ripple-carry adder mismatch"
                        severity failure;
                end loop;
            end loop;
        end loop;

        report "PASS: all 131072 ripple-carry adder cases" severity note;
        finish;
    end process;
end architecture;
