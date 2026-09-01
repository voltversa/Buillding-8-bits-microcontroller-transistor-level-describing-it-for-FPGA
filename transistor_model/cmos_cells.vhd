library ieee;
use ieee.std_logic_1164.all;

-- VHDL behavior of an ideal complementary CMOS inverter. See the documented
-- PMOS pull-up and NMOS pull-down network in docs/cmos-foundations.md.
entity cmos_inverter is
    port (
        a : in  std_logic;
        y : out std_logic
    );
end entity;

architecture behavioral of cmos_inverter is
begin
    y <= not a;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

-- Behavior of parallel PMOS pull-up devices and series NMOS pull-down devices.
entity cmos_nand2 is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity;

architecture behavioral of cmos_nand2 is
begin
    y <= not (a and b);
end architecture;

library ieee;
use ieee.std_logic_1164.all;

-- Behavior of series PMOS pull-up devices and parallel NMOS pull-down devices.
entity cmos_nor2 is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end entity;

architecture behavioral of cmos_nor2 is
begin
    y <= not (a or b);
end architecture;
