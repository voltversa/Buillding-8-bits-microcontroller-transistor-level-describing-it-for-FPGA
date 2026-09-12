library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.control_pkg.all;

entity fpga_demo_top_tb is
end entity;

architecture test of fpga_demo_top_tb is
    constant CLOCK_PERIOD : time := 10 ns;
    signal system_clock : std_logic := '0';
    signal reset_button : std_logic := '1';
    signal accumulator_leds : std_logic_vector(7 downto 0);
    signal pc_leds : std_logic_vector(7 downto 0);
    signal state_leds : std_logic_vector(2 downto 0);
    signal zero_led : std_logic;
    signal carry_led : std_logic;
    signal gpio_leds : std_logic_vector(7 downto 0);
    signal halted_led : std_logic;
    signal fault_led : std_logic;
    signal cpu_step_debug : std_logic;
    signal reset_active_debug : std_logic;
begin
    system_clock <= not system_clock after CLOCK_PERIOD / 2;

    dut : entity work.fpga_demo_top(structural)
        generic map (
            CLOCKS_PER_CPU_STEP => 3
        )
        port map (
            system_clock => system_clock,
            reset_button => reset_button,
            accumulator_leds => accumulator_leds,
            pc_leds => pc_leds,
            state_leds => state_leds,
            zero_led => zero_led,
            carry_led => carry_led,
            gpio_leds => gpio_leds,
            halted_led => halted_led,
            fault_led => fault_led,
            cpu_step_debug => cpu_step_debug,
            reset_active_debug => reset_active_debug
        );

    stimulus : process
        variable enabled_cycles : natural := 0;
        variable sampled_step : std_logic;
    begin
        wait for 1 ns;
        assert reset_active_debug = '1'
            report "synchronized reset did not assert asynchronously" severity failure;

        wait until falling_edge(system_clock);
        reset_button <= '0';

        wait until rising_edge(system_clock);
        wait for 1 ns;
        assert reset_active_debug = '1'
            report "reset released before the second synchronization edge" severity failure;
        wait until rising_edge(system_clock);
        wait for 1 ns;
        assert reset_active_debug = '0'
            report "reset did not release after two synchronization edges" severity failure;

        assert state_leds = CONTROL_FETCH and accumulator_leds = x"00" and
            pc_leds = x"00"
            report "wrapper did not reset the CPU" severity failure;

        while halted_led /= '1' and fault_led /= '1' and enabled_cycles < 64 loop
            wait until rising_edge(system_clock);
            sampled_step := cpu_step_debug;
            wait for 1 ns;
            if sampled_step = '1' then
                enabled_cycles := enabled_cycles + 1;
            end if;
        end loop;

        assert fault_led = '0'
            report "wrapper execution entered the fault state" severity failure;
        assert halted_led = '1' and state_leds = CONTROL_HALTED
            report "wrapper execution did not halt" severity failure;
        assert enabled_cycles = 19
            report "wrapper CPU-step count mismatch: " &
                integer'image(enabled_cycles)
            severity failure;
        assert accumulator_leds = x"A5" and pc_leds = x"09"
            report "wrapper debug LEDs show an incorrect final CPU state" severity failure;
        assert gpio_leds = x"A5"
            report "FPGA demo program did not update the GPIO LEDs" severity failure;
        assert zero_led = '0' and carry_led = '0'
            report "wrapper flag LEDs changed unexpectedly" severity failure;

        -- Async reset indication asserts immediately and CPU state clears on
        -- the following system-clock edge, even while the divider is stopped.
        reset_button <= '1';
        wait for 1 ns;
        assert reset_active_debug = '1'
            report "reset did not reassert asynchronously" severity failure;
        wait until rising_edge(system_clock);
        wait for 1 ns;
        assert state_leds = CONTROL_FETCH and halted_led = '0' and
            accumulator_leds = x"00" and pc_leds = x"00"
            report "wrapper reset did not recover the halted CPU" severity failure;

        assert gpio_leds = x"00"
            report "wrapper reset did not clear the GPIO LEDs" severity failure;

        report "PASS: FPGA wrapper wrote and read GPIO in 19 CPU steps" severity note;
        finish;
    end process;
end architecture;
