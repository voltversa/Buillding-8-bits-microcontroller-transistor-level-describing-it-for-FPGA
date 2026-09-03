library ieee;
use ieee.std_logic_1164.all;

-- Reusable storage element for the accumulator, operand register, and
-- instruction register. Reset and load are synchronous and active high.
entity register8 is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        load_enable : in  std_logic;
        data_in     : in  std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of register8 is
    signal stored_value : std_logic_vector(7 downto 0) := (others => '0');
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                stored_value <= (others => '0');
            elsif load_enable = '1' then
                stored_value <= data_in;
            end if;
        end if;
    end process;

    data_out <= stored_value;
end architecture;
