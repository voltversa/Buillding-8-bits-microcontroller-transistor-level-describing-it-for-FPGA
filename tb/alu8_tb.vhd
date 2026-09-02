library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.alu_pkg.all;

entity alu8_tb is
end entity;

architecture test of alu8_tb is
    signal a         : std_logic_vector(7 downto 0) := (others => '0');
    signal b         : std_logic_vector(7 downto 0) := (others => '0');
    signal operation : alu_operation_t := ALU_ADD;
    signal result    : std_logic_vector(7 downto 0);
    signal carry_out : std_logic;
    signal zero      : std_logic;
begin
    dut : entity work.alu8(structural)
        port map (
            a         => a,
            b         => b,
            operation => operation,
            result    => result,
            carry_out => carry_out,
            zero      => zero
        );

    stimulus : process
        variable arithmetic_value : unsigned(8 downto 0);
        variable expected_result  : unsigned(7 downto 0);
        variable expected_carry   : std_logic;
        variable expected_zero    : std_logic;
    begin
        for operation_value in 0 to 7 loop
            for a_value in 0 to 255 loop
                for b_value in 0 to 255 loop
                    a <= std_logic_vector(to_unsigned(a_value, a'length));
                    b <= std_logic_vector(to_unsigned(b_value, b'length));
                    operation <= std_logic_vector(
                        to_unsigned(operation_value, operation'length)
                    );
                    wait for 1 ns;

                    expected_carry := '0';

                    case operation_value is
                        when 0 =>
                            arithmetic_value := to_unsigned(
                                a_value + b_value,
                                arithmetic_value'length
                            );
                            expected_result := arithmetic_value(7 downto 0);
                            expected_carry := arithmetic_value(8);

                        when 1 =>
                            expected_result := to_unsigned(
                                (a_value - b_value) mod 256,
                                expected_result'length
                            );
                            if a_value >= b_value then
                                expected_carry := '1';
                            end if;

                        when 2 =>
                            expected_result := to_unsigned(a_value, 8)
                                and to_unsigned(b_value, 8);

                        when 3 =>
                            expected_result := to_unsigned(a_value, 8)
                                or to_unsigned(b_value, 8);

                        when 4 =>
                            expected_result := to_unsigned(a_value, 8)
                                xor to_unsigned(b_value, 8);

                        when 5 =>
                            expected_result := to_unsigned(a_value, 8);

                        when others =>
                            expected_result := (others => '0');
                    end case;

                    if expected_result = to_unsigned(0, 8) then
                        expected_zero := '1';
                    else
                        expected_zero := '0';
                    end if;

                    assert result = std_logic_vector(expected_result)
                        report "ALU result mismatch: operation=" &
                            integer'image(operation_value) & " a=" &
                            integer'image(a_value) & " b=" &
                            integer'image(b_value)
                        severity failure;

                    assert carry_out = expected_carry
                        report "ALU carry mismatch: operation=" &
                            integer'image(operation_value) & " a=" &
                            integer'image(a_value) & " b=" &
                            integer'image(b_value)
                        severity failure;

                    assert zero = expected_zero
                        report "ALU zero-flag mismatch: operation=" &
                            integer'image(operation_value) & " a=" &
                            integer'image(a_value) & " b=" &
                            integer'image(b_value)
                        severity failure;
                end loop;
            end loop;
        end loop;

        report "PASS: all 524288 ALU input combinations" severity note;
        finish;
    end process;
end architecture;
