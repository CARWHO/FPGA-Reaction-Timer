library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bcd_to_7_seg is
    port (
       bcd : in  STD_LOGIC_VECTOR (3 downto 0);
       dp  : in  STD_LOGIC;
       seg : out STD_LOGIC_VECTOR (0 to 7)
    );
end bcd_to_7_seg;

architecture bhv of bcd_to_7_seg is
begin
  process(bcd)
  begin
    case bcd is
      when "0000" => seg(0 to 6) <= "0000001"; -- 0
      when "0001" => seg(0 to 6) <= "1001111"; -- 1
      when "0010" => seg(0 to 6) <= "0010010"; -- 2
      when "0011" => seg(0 to 6) <= "0000110"; -- 3
      when "0100" => seg(0 to 6) <= "1001100"; -- 4
      when "0101" => seg(0 to 6) <= "0100100"; -- 5
      when "0110" => seg(0 to 6) <= "0100000"; -- 6
      when "0111" => seg(0 to 6) <= "0001111"; -- 7
      when "1000" => seg(0 to 6) <= "0000000"; -- 8
      when "1001" => seg(0 to 6) <= "0001100"; -- 9
      when "1010" => seg(0 to 6) <= "1111111"; -- Blank
      when others => seg(0 to 6) <= "1111111"; -- Default: Blank
    end case;
  end process;
  seg(7) <= dp;
end bhv;