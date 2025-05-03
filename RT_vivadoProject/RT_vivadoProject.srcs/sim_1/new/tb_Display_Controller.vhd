----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/01/2025 04:50:13 PM
-- Design Name: 
-- Module Name: tb_Display_Controller - Behavioral
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

entity tb_Top_Level_Display_Controller is
end tb_Top_Level_Display_Controller;

architecture Behavioral of tb_Top_Level_Display_Controller is

    -- Testbench signals
    signal tb_CLK   : std_logic := '0';
    signal tb_ANODE : std_logic_vector(6 downto 0);
    signal tb_SEG   : std_logic_vector(7 downto 0);

    -- Use a smaller clock divider bound for simulation speed-up
    constant SIM_DIVIDER_UPPERBOUND : std_logic_vector(27 downto 0) := X"000000F";

    -- Clock period definition for simulation
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Top-Level module with the simulation divider constant.
    UUT : entity work.Top_Level_Display_Controller
        generic map (
            DIVIDER_UPPERBOUND => SIM_DIVIDER_UPPERBOUND
        )
        port map (
            CLK   => tb_CLK,
            ANODE => tb_ANODE,
            SEG   => tb_SEG
        );

    -- Clock generation process for the system clock
    process
    begin
        while true loop
            tb_CLK <= '0';
            wait for CLK_PERIOD/2;
            tb_CLK <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -- Simulation runtime control
    process
    begin
        -- Run simulation for a sufficient time to observe multiple display updates
        wait for 500 ns;
        wait;
    end process;

end Behavioral;

