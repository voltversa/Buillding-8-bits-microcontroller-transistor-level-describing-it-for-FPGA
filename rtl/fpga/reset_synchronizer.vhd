library ieee;
use ieee.std_logic_1164.all;

-- Assert reset immediately, then release it only after two rising clock edges.
entity reset_synchronizer is
    port (
        clock       : in  std_logic;
        reset_async : in  std_logic;
        reset_sync  : out std_logic
    );
end entity;

architecture rtl of reset_synchronizer is
    signal stages : std_logic_vector(1 downto 0) := (others => '1');
begin
    process (clock, reset_async)
    begin
        if reset_async = '1' then
            stages <= (others => '1');
        elsif rising_edge(clock) then
            stages <= stages(0) & '0';
        end if;
    end process;

    reset_sync <= stages(1);
end architecture;
