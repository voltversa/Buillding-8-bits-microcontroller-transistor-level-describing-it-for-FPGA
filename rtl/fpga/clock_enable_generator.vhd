library ieee;
use ieee.std_logic_1164.all;

-- Produce one system-clock-wide enable pulse every CLOCKS_PER_STEP cycles.
-- Keeping the CPU on the system clock avoids a logic-generated clock domain.
entity clock_enable_generator is
    generic (
        CLOCKS_PER_STEP : positive := 50_000_000
    );
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        enable_pulse : out std_logic
    );
end entity;

architecture rtl of clock_enable_generator is
    signal counter : natural range 0 to CLOCKS_PER_STEP - 1 := 0;
begin
    enable_pulse <= '1' when counter = CLOCKS_PER_STEP - 1 else '0';

    process (clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                counter <= 0;
            elsif counter = CLOCKS_PER_STEP - 1 then
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
end architecture;
