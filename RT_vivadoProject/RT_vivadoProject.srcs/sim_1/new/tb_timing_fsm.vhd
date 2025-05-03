----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/06/2025 02:27:34 PM
-- Design Name: 
-- Module Name: tb_timing_fsm - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timing_fsm_tb is
end timing_fsm_tb;

architecture Behavioral of timing_fsm_tb is

    -- Signals for FSM ports
    signal clk, rst, BTNC : std_logic := '0';
    signal COUNT_1, COUNT_2, COUNT_3, COUNT_4 : std_logic_vector(3 downto 0) := (others => '0');
    signal counter_en, counter_rst : std_logic;
    signal message : std_logic_vector(31 downto 0);

begin

    --------------------------------------------------------------------------
    -- 1) Clock Generation
    --    10 ns period => 100 MHz in real hardware, but we can scale for sim
    --------------------------------------------------------------------------
    clk <= not clk after 5 ns;

    --------------------------------------------------------------------------
    -- 2) Instantiate the FSM Under Test
    --------------------------------------------------------------------------
    uut_fsm : entity work.timing_fsm(Behavioral)
        port map (
            clk         => clk,
            rst         => rst,
            BTNC        => BTNC,
            COUNT_1     => COUNT_1,
            COUNT_2     => COUNT_2,
            COUNT_3     => COUNT_3,
            COUNT_4     => COUNT_4,
            counter_en  => counter_en,
            counter_rst => counter_rst,
            message     => message
        );

    --------------------------------------------------------------------------
    -- 3) Mimic the Counters (Module5 style)
    --------------------------------------------------------------------------
    -- This process increments COUNT_1..COUNT_4 whenever 'counter_en' = '1'
    -- and resets them if 'counter_rst' = '1'.
    --------------------------------------------------------------------------
    process
    begin
        if counter_rst = '1' then
            COUNT_1 <= (others => '0');
            COUNT_2 <= (others => '0');
            COUNT_3 <= (others => '0');
            COUNT_4 <= (others => '0');
        else
            if counter_en = '1' then
                -- increment COUNT_1 from 0..9
                COUNT_1 <= std_logic_vector(unsigned(COUNT_1) + 1);
                if COUNT_1 = "1001" then
                    COUNT_1 <= (others => '0');
                    -- increment COUNT_2
                    COUNT_2 <= std_logic_vector(unsigned(COUNT_2) + 1);
                    if COUNT_2 = "1001" then
                        COUNT_2 <= (others => '0');
                        COUNT_3 <= std_logic_vector(unsigned(COUNT_3) + 1);
                        if COUNT_3 = "1001" then
                            COUNT_3 <= (others => '0');
                            COUNT_4 <= std_logic_vector(unsigned(COUNT_4) + 1);
                        end if;
                    end if;
                end if;
            end if;
        end if;
        wait for 10 ns;  -- increment every 10 ns
    end process;

    --------------------------------------------------------------------------
    -- 4) Stimulus Process
    --    Drive 'rst' and 'BTNC' to test the FSM transitions.
    --------------------------------------------------------------------------
    stimulus: process
    begin
        -- 1) Assert reset for 100 ns
        rst <= '1';
        wait for 100 ns;
        rst <= '0';

        -- 2) Wait some time, press BTNC to move from waiting -> countdown
        wait for 200 ns;
        BTNC <= '1';
        wait for 20 ns;
        BTNC <= '0';

        -- 3) Let countdown expire, then we go to timing.
        --    We'll press BTNC to stop timing and move to display
        wait for 1500 ns;  -- enough to pass the countdown state
        BTNC <= '1';
        wait for 20 ns;
        BTNC <= '0';

        -- 4) Let display time out or press again to go back to waiting
        wait for 1500 ns;
        BTNC <= '1';
        wait for 20 ns;
        BTNC <= '0';

        wait;
    end process;

end Behavioral;

