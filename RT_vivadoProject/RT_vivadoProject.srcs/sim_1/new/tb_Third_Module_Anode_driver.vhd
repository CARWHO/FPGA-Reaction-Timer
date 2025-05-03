library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Four_Digit_Anode_driver is
end tb_Four_Digit_Anode_driver;

architecture tb of tb_Four_Digit_Anode_driver is

    -- Test signals
    signal DISPLAY_SELECTED : std_logic_vector(2 downto 0) := "000";
    signal ANODE            : std_logic_vector(6 downto 0);

begin
    -- Instantiate the Unit Under Test (UUT)
    UUT: entity work.Four_Digit_Anode_driver
        port map(
            DISPLAY_SELECTED => DISPLAY_SELECTED,
            ANODE            => ANODE
        );

    -- Simple stimulus: cycle through 0..7 (i.e., "000" to "111")
    stimulus: process
    begin
        for i in 0 to 7 loop
            DISPLAY_SELECTED <= std_logic_vector(to_unsigned(i, 3));
            wait for 20 ns;
        end loop;

        wait;  -- End simulation
    end process;

end tb;
