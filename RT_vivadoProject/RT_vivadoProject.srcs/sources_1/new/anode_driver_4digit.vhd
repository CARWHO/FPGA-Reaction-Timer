library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Four_Digit_Anode_driver is
    Port (
        DIGIT_SELECT : in  std_logic_vector(1 downto 0);
        ANODE        : out std_logic_vector(3 downto 0)
    );
end Four_Digit_Anode_driver;

architecture Behavioral of Four_Digit_Anode_driver is
begin
    process(DIGIT_SELECT)
    begin
        case DIGIT_SELECT is
            when "00" =>  -- thousands digit active: enable an(3)
                ANODE <= "0111";  -- bit3 = 0, others = 1
            when "01" =>  -- hundreds digit active: enable an(2)
                ANODE <= "1011";  -- bit2 = 0
            when "10" =>  -- tens digit active: enable an(1)
                ANODE <= "1101";  -- bit1 = 0
            when "11" =>  -- ones digit active: enable an(0)
                ANODE <= "1110";  -- bit0 = 0
            when others =>
                ANODE <= "1111";
        end case;
    end process;
end Behavioral;
