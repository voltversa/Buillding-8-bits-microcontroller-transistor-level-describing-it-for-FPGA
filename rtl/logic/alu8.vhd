library ieee;
use ieee.std_logic_1164.all;
use work.alu_pkg.all;

entity alu8 is
    port (
        a         : in  std_logic_vector(7 downto 0);
        b         : in  std_logic_vector(7 downto 0);
        operation : in  alu_operation_t;
        result    : out std_logic_vector(7 downto 0);
        carry_out : out std_logic;
        zero      : out std_logic
    );
end entity;

architecture structural of alu8 is
    signal subtract_enable   : std_logic;
    signal conditioned_b     : std_logic_vector(7 downto 0);
    signal arithmetic_result : std_logic_vector(7 downto 0);
    signal arithmetic_carry  : std_logic;
    signal and_result        : std_logic_vector(7 downto 0);
    signal or_result         : std_logic_vector(7 downto 0);
    signal xor_result        : std_logic_vector(7 downto 0);
    signal result_internal   : std_logic_vector(7 downto 0);
begin
    -- SUB reuses the adder: A - B = A + not(B) + 1.
    subtract_enable <= '1' when operation = ALU_SUB else '0';

    generate_bit_slices : for bit_index in 0 to 7 generate
        condition_b : entity work.xor2(structural)
            port map (
                a => b(bit_index),
                b => subtract_enable,
                y => conditioned_b(bit_index)
            );

        bitwise_and : entity work.and2(structural)
            port map (
                a => a(bit_index),
                b => b(bit_index),
                y => and_result(bit_index)
            );

        bitwise_or : entity work.or2(structural)
            port map (
                a => a(bit_index),
                b => b(bit_index),
                y => or_result(bit_index)
            );

        bitwise_xor : entity work.xor2(structural)
            port map (
                a => a(bit_index),
                b => b(bit_index),
                y => xor_result(bit_index)
            );
    end generate;

    arithmetic_unit : entity work.ripple_carry_adder_8bit(structural)
        port map (
            a         => a,
            b         => conditioned_b,
            carry_in  => subtract_enable,
            sum       => arithmetic_result,
            carry_out => arithmetic_carry
        );

    with operation select
        result_internal <= arithmetic_result when ALU_ADD,
                           arithmetic_result when ALU_SUB,
                           and_result        when ALU_AND,
                           or_result         when ALU_OR,
                           xor_result        when ALU_XOR,
                           a                 when ALU_PASS_A,
                           (others => '0')   when others;

    result <= result_internal;

    carry_out <= arithmetic_carry
        when operation = ALU_ADD or operation = ALU_SUB
        else '0';

    zero <= '1' when result_internal = x"00" else '0';
end architecture;
