library ieee;
use ieee.std_logic_1164.all;

entity inv1 is
    port (
        a : in  std_logic;
        y : out std_logic
    );
end entity;

architecture rtl of inv1 is
begin
    y <= not a;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity nand2 is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity;

architecture rtl of nand2 is
begin
    y <= not (a and b);
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity nor2 is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity;

architecture rtl of nor2 is
begin
    y <= not (a or b);
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity and2 is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity;

architecture structural of and2 is
    signal nand_result : std_logic;
begin
    nand_gate : entity work.nand2(rtl)
        port map (a => a, b => b, y => nand_result);

    output_inverter : entity work.inv1(rtl)
        port map (a => nand_result, y => y);
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity or2 is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity;

architecture structural of or2 is
    signal nor_result : std_logic;
begin
    nor_gate : entity work.nor2(rtl)
        port map (a => a, b => b, y => nor_result);

    output_inverter : entity work.inv1(rtl)
        port map (a => nor_result, y => y);
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity xor2 is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity;

architecture structural of xor2 is
    signal a_nand_b : std_logic;
    signal a_term   : std_logic;
    signal b_term   : std_logic;
begin
    shared_nand : entity work.nand2(rtl)
        port map (a => a, b => b, y => a_nand_b);

    a_path : entity work.nand2(rtl)
        port map (a => a, b => a_nand_b, y => a_term);

    b_path : entity work.nand2(rtl)
        port map (a => b, b => a_nand_b, y => b_term);

    output_nand : entity work.nand2(rtl)
        port map (a => a_term, b => b_term, y => y);
end architecture;
