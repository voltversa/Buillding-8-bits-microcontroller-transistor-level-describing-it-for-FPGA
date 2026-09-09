library ieee;
use ieee.std_logic_1164.all;

-- One byte of synchronous, reset-loadable storage for the structural memory.
entity memory_byte is
    generic (
        reset_value : std_logic_vector(7 downto 0) := x"00"
    );
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        write_enable : in  std_logic;
        data_in      : in  std_logic_vector(7 downto 0);
        data_out     : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of memory_byte is
    signal stored_value : std_logic_vector(7 downto 0) := reset_value;
begin
    store_byte : process (clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                stored_value <= reset_value;
            elsif write_enable = '1' then
                stored_value <= data_in;
            end if;
        end if;
    end process;

    data_out <= stored_value;
end architecture;
