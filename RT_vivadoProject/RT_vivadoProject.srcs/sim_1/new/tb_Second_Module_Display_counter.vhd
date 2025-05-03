----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2025 05:00:00 PM
-- Design Name: Test Bench for Display Counter
-- Module Name: tb_Hundreds_counter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--   Test bench for Hundreds_counter.
--   Generates a clock signal and observes the CURRENT_DISPLAY output.
-- Dependencies: Hundreds_counter.vhd
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Hundreds_counter is
end tb_Hundreds_counter;

architecture test of tb_Hundreds_counter is
    signal DISPLAY_CLK     : std_logic := '0';
    signal CURRENT_DISPLAY : std_logic_vector(2 downto 0);
begin

    -- Instantiate the Display Counter (Device Under Test)
    DUT: entity work.Hundreds_counter
        port map(
            DISPLAY_CLK     => DISPLAY_CLK,
            CURRENT_DISPLAY => CURRENT_DISPLAY
        );

    -- Clock generation process: 100MHz clock (period = 10 ns)
    clock_process : process
    begin
        while true loop
            DISPLAY_CLK <= '0';
            wait for 5 ns;
            DISPLAY_CLK <= '1';
            wait for 5 ns;
        end loop;
    end process;

end test;
