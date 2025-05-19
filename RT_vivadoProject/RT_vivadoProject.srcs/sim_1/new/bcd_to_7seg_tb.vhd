library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bcd_to_7_seg_tb is
end bcd_to_7_seg_tb;

architecture test of bcd_to_7_seg_tb is

  ------------------------------------------------------------------------------
  -- Success Criteria:
  -- 1. For each valid BCD input (0-9), the seg(0 to 6) output matches the
  --    expected 7-segment pattern for that digit.
  -- 2. For BCD inputs greater than 9 (i.e., "1010" through "1111"), the
  --    seg(0 to 6) output should represent a blank display.
  -- 3. The decimal point output seg(7) should correctly reflect the state
  --    of the dp input signal (dp='0' -> seg(7)='0', dp='1' -> seg(7)='1').
  -- 4. All assertions within the stimulus process must pass.
  -- 5. The simulation should complete with a "Test Passed" message.
  ------------------------------------------------------------------------------

  -- Test signals
  signal bcd : std_logic_vector(3 downto 0) := (others => '0');
  signal dp  : std_logic := '0';
  signal seg : std_logic_vector(0 to 7);

  -- Expected 7-segment patterns (seg(0 to 6))
  -- seg = (CA, CB, CC, CD, CE, CF, CG)
  constant SEG_0 : std_logic_vector(0 to 6) := "0000001"; -- 0
  constant SEG_1 : std_logic_vector(0 to 6) := "1001111"; -- 1
  constant SEG_2 : std_logic_vector(0 to 6) := "0010010"; -- 2
  constant SEG_3 : std_logic_vector(0 to 6) := "0000110"; -- 3
  constant SEG_4 : std_logic_vector(0 to 6) := "1001100"; -- 4
  constant SEG_5 : std_logic_vector(0 to 6) := "0100100"; -- 5
  constant SEG_6 : std_logic_vector(0 to 6) := "0100000"; -- 6
  constant SEG_7 : std_logic_vector(0 to 6) := "0001111"; -- 7
  constant SEG_8 : std_logic_vector(0 to 6) := "0000000"; -- 8
  constant SEG_9 : std_logic_vector(0 to 6) := "0001100"; -- 9
  constant SEG_BLANK : std_logic_vector(0 to 6) := "1111111"; -- Blank

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
    variable expected_seg : std_logic_vector(0 to 6);
  begin
    report "Starting bcd_to_7_seg_tb stimulus process.";
    
    -- Wait for 100 ns before applying any inputs to allow signals to settle.
    wait for 100 ns; 

    for i in 0 to 15 loop
      bcd <= std_logic_vector(to_unsigned(i, 4));

      -- Determine expected segment output based on BCD input i
      case i is
        when 0      => expected_seg := SEG_0;
        when 1      => expected_seg := SEG_1;
        when 2      => expected_seg := SEG_2;
        when 3      => expected_seg := SEG_3;
        when 4      => expected_seg := SEG_4;
        when 5      => expected_seg := SEG_5;
        when 6      => expected_seg := SEG_6;
        when 7      => expected_seg := SEG_7;
        when 8      => expected_seg := SEG_8;
        when 9      => expected_seg := SEG_9;
        when others => expected_seg := SEG_BLANK; -- For BCD > 9, expect blank
      end case;

      -- Toggle the decimal point input
      if i mod 2 = 0 then
        dp <= '0'; -- DP ON
      else
        dp <= '1'; -- DP OFF
      end if;

      wait for 20 ns;  -- Wait for outputs to settle

      -- Check the 7-segment outputs (CA-CG)
      assert seg(0 to 6) = expected_seg
        report "Assertion failed for BCD input " & integer'image(i) &
               ". Expected seg(0 to 6), Got seg(0 to 6)." -- Simplified message
        severity error;

      -- Check the decimal point output
      -- dp input is active low in bcd_to_7_seg (seg(7) <= dp)
      -- so if dp input is '0', seg(7) should be '0'
      -- if dp input is '1', seg(7) should be '1'
      assert seg(7) = dp
        report "Assertion failed for DP output with BCD input " & integer'image(i) &
               " and DP input " & std_logic'image(dp) &
               "." -- Simplified message
        severity error;

    end loop;

    report "Test Passed: All BCD to 7-segment conversions are correct." severity note;
    wait;  -- Stop simulation
  end process stimulus_proc;

end test;
