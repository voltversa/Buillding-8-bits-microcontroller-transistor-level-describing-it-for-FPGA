library ieee;
use ieee.std_logic_1164.all;
use work.control_pkg.all;
use work.memory_pkg.all;

-- Vendor-neutral demonstration wrapper. A board-specific constraints file must
-- map these ports to the oscillator, reset button, and LEDs on a chosen board.
entity fpga_demo_top is
    generic (
        CLOCKS_PER_CPU_STEP : positive := 50_000_000
    );
    port (
        system_clock      : in  std_logic;
        reset_button      : in  std_logic;
        gpio_switches     : in  std_logic_vector(7 downto 0);
        accumulator_leds  : out std_logic_vector(7 downto 0);
        pc_leds           : out std_logic_vector(7 downto 0);
        state_leds        : out std_logic_vector(2 downto 0);
        zero_led          : out std_logic;
        carry_led         : out std_logic;
        gpio_leds         : out std_logic_vector(7 downto 0);
        halted_led        : out std_logic;
        fault_led         : out std_logic;
        cpu_step_debug    : out std_logic;
        reset_active_debug : out std_logic
    );
end entity;

architecture structural of fpga_demo_top is
    signal reset_synchronized : std_logic;
    signal cpu_step : std_logic;
    signal operand_unused : std_logic_vector(7 downto 0);
    signal instruction_unused : std_logic_vector(7 downto 0);
    signal memory_unused : std_logic_vector(7 downto 0);
begin
    reset_conditioner : entity work.reset_synchronizer(rtl)
        port map (
            clock => system_clock,
            reset_async => reset_button,
            reset_sync => reset_synchronized
        );

    step_generator : entity work.clock_enable_generator(rtl)
        generic map (
            CLOCKS_PER_STEP => CLOCKS_PER_CPU_STEP
        )
        port map (
            clock => system_clock,
            reset => reset_synchronized,
            enable_pulse => cpu_step
        );

    processor : entity work.cpu8(structural)
        generic map (
            initial_content => FPGA_DEMO_PROGRAM
        )
        port map (
            clock => system_clock,
            reset => reset_synchronized,
            clock_enable => cpu_step,
            gpio_input => gpio_switches,
            memory_debug_enable => '0',
            memory_debug_address => (others => '0'),
            memory_debug_data => memory_unused,
            accumulator_debug => accumulator_leds,
            operand_debug => operand_unused,
            instruction_debug => instruction_unused,
            pc_debug => pc_leds,
            zero_flag_debug => zero_led,
            carry_flag_debug => carry_led,
            gpio_output => gpio_leds,
            state_debug => state_leds,
            halted => halted_led,
            fault => fault_led
        );

    cpu_step_debug <= cpu_step;
    reset_active_debug <= reset_synchronized;
end architecture;
