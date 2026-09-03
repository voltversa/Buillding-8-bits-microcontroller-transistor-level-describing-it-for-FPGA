library ieee;
use ieee.std_logic_1164.all;

-- Eight-bit program counter with synchronous reset, parallel load, increment,
-- and hold behavior. Control priority is reset, load, increment, then hold.
entity program_counter8 is
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        load      : in  std_logic;
        increment : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        count     : out std_logic_vector(7 downto 0)
    );
end entity;

architecture structural of program_counter8 is
    signal stored_count      : std_logic_vector(7 downto 0) := (others => '0');
    signal incremented_count : std_logic_vector(7 downto 0);
    signal unused_carry      : std_logic;
begin
    -- Reuse the transistor-derived ripple adder instead of the VHDL "+"
    -- operator. Adding carry_in=1 to a zero B operand increments the count.
    incrementer : entity work.ripple_carry_adder_8bit(structural)
        port map (
            a         => stored_count,
            b         => (others => '0'),
            carry_in  => '1',
            sum       => incremented_count,
            carry_out => unused_carry
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                stored_count <= (others => '0');
            elsif load = '1' then
                stored_count <= data_in;
            elsif increment = '1' then
                stored_count <= incremented_count;
            end if;
        end if;
    end process;

    count <= stored_count;
end architecture;
