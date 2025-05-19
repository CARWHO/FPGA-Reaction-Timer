----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.05.2025 16:51:47
-- Design Name: 
-- Module Name: snapshot_capture - Behavioral
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
use IEEE.NUMERIC_STD.ALL; -- Ensure NUMERIC_STD is used

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity snapshot_capture is
    Port (
        clk             : in  std_logic;
        snapshot_trigger: in  std_logic; -- Trigger to capture the values

        -- Live counter inputs
        ones_in         : in  std_logic_vector(3 downto 0);
        tens_in         : in  std_logic_vector(3 downto 0);
        hundreds_in     : in  std_logic_vector(3 downto 0);
        thousands_in    : in  std_logic_vector(3 downto 0);

        -- Snapshot outputs
        ones_out        : out std_logic_vector(3 downto 0);
        tens_out        : out std_logic_vector(3 downto 0);
        hundreds_out    : out std_logic_vector(3 downto 0);
        thousands_out   : out std_logic_vector(3 downto 0)
    );
end snapshot_capture;

architecture Behavioral of snapshot_capture is
    -- Internal registers to hold the snapshot
    signal reg_ones      : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_tens      : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_hundreds  : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_thousands : std_logic_vector(3 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if snapshot_trigger = '1' then
                reg_ones      <= ones_in;
                reg_tens      <= tens_in;
                reg_hundreds  <= hundreds_in;
                reg_thousands <= thousands_in;
            end if;
        end if;
    end process;

    -- Assign registered values to outputs
    ones_out      <= reg_ones;
    tens_out      <= reg_tens;
    hundreds_out  <= reg_hundreds;
    thousands_out <= reg_thousands;

end Behavioral;
