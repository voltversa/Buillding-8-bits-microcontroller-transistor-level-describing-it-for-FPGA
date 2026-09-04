library ieee;
use ieee.std_logic_1164.all;

-- Structural 2-to-1 multiplexer built from the reusable Boolean cells.
entity mux2_1bit is
    port (
        input_0 : in  std_logic;
        input_1 : in  std_logic;
        select_1 : in  std_logic;
        output_y : out std_logic
    );
end entity;

architecture structural of mux2_1bit is
    signal select_0  : std_logic;
    signal input_0_on : std_logic;
    signal input_1_on : std_logic;
begin
    select_inverter : entity work.inv1(rtl)
        port map (a => select_1, y => select_0);

    input_0_gate : entity work.and2(structural)
        port map (a => input_0, b => select_0, y => input_0_on);

    input_1_gate : entity work.and2(structural)
        port map (a => input_1, b => select_1, y => input_1_on);

    output_gate : entity work.or2(structural)
        port map (a => input_0_on, b => input_1_on, y => output_y);
end architecture;
