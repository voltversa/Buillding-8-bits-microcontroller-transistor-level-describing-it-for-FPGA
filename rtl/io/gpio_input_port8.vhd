library ieee;
use ieee.std_logic_1164.all;

-- Two-stage synchronization and address decoding for eight external inputs.
entity gpio_input_port8 is
    generic (
        PORT_ADDRESS : std_logic_vector(7 downto 0) := x"FD"
    );
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        address       : in  std_logic_vector(7 downto 0);
        gpio_in       : in  std_logic_vector(7 downto 0);
        address_match : out std_logic;
        data_out      : out std_logic_vector(7 downto 0)
    );
end entity;

architecture structural of gpio_input_port8 is
    signal first_stage : std_logic_vector(7 downto 0);
begin
    address_decoder : entity work.byte_equal8(structural)
        generic map (
            expected_value => PORT_ADDRESS
        )
        port map (
            value => address,
            is_equal => address_match
        );

    metastability_stage : entity work.register8(rtl)
        port map (
            clk => clock,
            reset => reset,
            load_enable => '1',
            data_in => gpio_in,
            data_out => first_stage
        );

    synchronization_stage : entity work.register8(rtl)
        port map (
            clk => clock,
            reset => reset,
            load_enable => '1',
            data_in => first_stage,
            data_out => data_out
        );
end architecture;
