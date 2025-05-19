library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce_tb is
end debounce_tb;

architecture sim of debounce_tb is

    -- Component declaration without generics (matches your current debounce.vhd)
    component debounce is
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            noisy : in  std_logic;
            clean : out std_logic
        );
    end component;

    -- Testbench signals
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    signal noisy  : std_logic := '0';
    signal clean  : std_logic;
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

begin

    -- Instantiate DUT without generic map
    DUT: debounce
        port map (
            clk   => clk,
            rst   => rst,
            noisy => noisy,
            clean => clean
        );

    -- 100 MHz clock generator
    clk_proc: process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Stimulus sequence
    stim: process
    begin
        -- 1) Release reset
        wait for 50 ns;
        rst <= '0';
        wait for 50 ns;

        -- 2) Stable low: clean must stay '0'
        noisy <= '0';
        wait for 2 us;
        assert clean = '0'
            report "Unexpected clean high during stable low" severity error;

        -- 3) Bounce emulation
        for i in 0 to 20 loop
            noisy <= not noisy;
            wait for 100 ns;
        end loop;
        wait for 2 us;
        assert clean = '0'
            report "Clean went high during bounce" severity error;

        -- 4) Valid press
        noisy <= '1';
        wait for 2 us;
        assert clean = '1'
            report "Clean did not go high after valid press" severity error;

        -- 5) Release
        noisy <= '0';
        wait for 2 us;
        assert clean = '0'
            report "Clean did not return low after release" severity error;

        report "Debounce testbench passed" severity note;
        wait;
    end process;

end sim;
