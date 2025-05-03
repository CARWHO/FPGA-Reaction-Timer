library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bcd_to_7_seg_tb is
end bcd_to_7_seg_tb;

architecture test of bcd_to_7_seg_tb is

  -- Test signals
  signal bcd : std_logic_vector(3 downto 0) := (others => '0');
  signal dp  : std_logic := '0';
  signal seg : std_logic_vector(0 to 7);

begin
  -- Instantiate the Unit Under Test (UUT)
  UUT: entity work.bcd_to_7_seg
    port map(
      bcd => bcd,
      dp  => dp,
      seg => seg
    );

  -- Stimulus process: cycle through all 4-bit BCD values (0..15)
  stimulus_proc: process
  begin
    for i in 0 to 15 loop
      -- Apply the 4-bit pattern to bcd
      bcd <= std_logic_vector(to_unsigned(i, 4));

      -- Toggle the decimal point at halfway
      if i < 8 then
        dp <= '0';
      else
        dp <= '1';
      end if;

      wait for 20 ns;  -- Wait time between steps
    end loop;

    wait;  -- Stop simulation
  end process stimulus_proc;

end test;
