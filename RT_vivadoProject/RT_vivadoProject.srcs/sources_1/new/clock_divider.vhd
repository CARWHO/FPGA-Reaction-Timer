library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_divider is
    Port ( CLK : in STD_LOGIC;
           UPPERBOUND : in STD_LOGIC_VECTOR (27 downto 0);
           SLOWCLK : out STD_LOGIC);
end clock_divider;

architecture Behavioral of clock_divider is
    signal count: std_logic_vector (27 downto 0) := (others => '0');
    signal dummy: std_logic := '1'; -- Internal signal used to generate a toggling clock output
begin

    SLOWCLK <= dummy; -- Assign the toggling signal to the output slow clock
    
    process (CLK)
    begin
        if rising_edge(CLK) then
            if count = UPPERBOUND then
                count <= (others => '0');
                dummy <= not dummy;
            else
                count <= std_logic_vector(unsigned(count) + 1);
            end if;
        end if;
    end process;
    
end Behavioral;
