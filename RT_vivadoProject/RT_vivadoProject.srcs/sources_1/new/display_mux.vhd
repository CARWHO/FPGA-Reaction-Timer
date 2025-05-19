library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_mux is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic; -- From FSM counter_rst

        -- Control signals
        show_final      : in  std_logic;
        error_detected  : in  std_logic;
        use_stats       : in  std_logic;
        stat_valid      : in  std_logic;
        dp_sec          : in  std_logic; -- DP for hundreds digit (an(2))
        dp_hundredms    : in  std_logic; -- DP for tens digit (an(1))
        dp_tensms       : in  std_logic; -- DP for ones digit (an(0))

        -- Live counter values
        live_thousands  : in  std_logic_vector(3 downto 0);
        live_hundreds   : in  std_logic_vector(3 downto 0);
        live_tens       : in  std_logic_vector(3 downto 0);
        live_ones       : in  std_logic_vector(3 downto 0);

        -- Snapshot values
        snap_thousands  : in  std_logic_vector(3 downto 0);
        snap_hundreds   : in  std_logic_vector(3 downto 0);
        snap_tens       : in  std_logic_vector(3 downto 0);
        snap_ones       : in  std_logic_vector(3 downto 0);

        -- Statistics values
        stat_thousands  : in  std_logic_vector(3 downto 0);
        stat_hundreds   : in  std_logic_vector(3 downto 0);
        stat_tens       : in  std_logic_vector(3 downto 0);
        stat_ones       : in  std_logic_vector(3 downto 0);

        -- Display outputs
        AN              : out std_logic_vector(3 downto 0); -- Only driving lower 4 anodes
        CA              : out std_logic;
        CB              : out std_logic;
        CC              : out std_logic;
        CD              : out std_logic;
        CE              : out std_logic;
        CF              : out std_logic;
        CG              : out std_logic;
        DP              : out std_logic
    );
end display_mux;

architecture Behavioral of display_mux is

    ----------------------------------------------------------------------------
    -- Error display constants - "Err" on the display
    ----------------------------------------------------------------------------
    constant ERROR_THOUSANDS : std_logic_vector(3 downto 0) := "1110"; -- E
    constant ERROR_HUNDREDS  : std_logic_vector(3 downto 0) := "1111"; -- r
    constant ERROR_TENS      : std_logic_vector(3 downto 0) := "1111"; -- r
    constant ERROR_ONES      : std_logic_vector(3 downto 0) := "1010"; -- blank

    ----------------------------------------------------------------------------
    -- Multiplexing & Display Signals
    ----------------------------------------------------------------------------
    signal mux_divider  : unsigned(15 downto 0) := (others => '0');
    -- 2-bit digit_select:
    -- "00" = thousands (an(3)), "01" = hundreds (an(2)),
    -- "10" = tens (an(1)), "11" = ones (an(0))
    signal digit_select : std_logic_vector(1 downto 0) := "00";
    signal bcd_mux      : std_logic_vector(3 downto 0);
    signal seg_signal   : std_logic_vector(0 to 7);

    constant dp_const : std_logic := '1';  -- Default: decimal point segment off ('1' typically means off for common cathode 7-seg)

    ----------------------------------------------------------------------------
    -- Anode signal from the 4-digit driver
    signal anode_signal : std_logic_vector(3 downto 0);

begin

    ----------------------------------------------------------------------------
    -- BCD Input Multiplexer
    -- Selects the appropriate BCD value for the currently active digit based
    -- on the FSM state (live, snapshot, error, or statistics).
    ----------------------------------------------------------------------------
    process(digit_select, live_thousands, live_hundreds, live_tens, live_ones,
            reset, show_final, error_detected, use_stats,
            snap_thousands, snap_hundreds, snap_tens, snap_ones,
            stat_thousands, stat_hundreds, stat_tens, stat_ones, stat_valid)
    begin
        if reset = '1' and error_detected = '1' then
            -- Display "Err" when error is detected
            case digit_select is
                when "00" => bcd_mux <= ERROR_THOUSANDS; -- E
                when "01" => bcd_mux <= ERROR_HUNDREDS;  -- r
                when "10" => bcd_mux <= ERROR_TENS;      -- r
                when "11" => bcd_mux <= ERROR_ONES;      -- blank
                when others => bcd_mux <= "1010";        -- blank
            end case;
        elsif use_stats = '1' then -- Display stats regardless of valid flag (ALU outputs 0 if not valid)
            -- Display statistics result
            case digit_select is
                when "00" => bcd_mux <= stat_thousands;
                when "01" => bcd_mux <= stat_hundreds;
                when "10" => bcd_mux <= stat_tens;
                when "11" => bcd_mux <= stat_ones;
                when others => bcd_mux <= "1010";  -- blank
            end case;
        -- Removed the condition for use_stats='1' and stat_valid='0'
        -- Now, if use_stats='1', it always displays the stat_... values.
        -- If valid_count was 0, the ALU correctly outputs 0000 for stat_...
        elsif reset = '1' and error_detected = '0' and use_stats = '0' then
             bcd_mux <= "1010";  -- blank -- Keep blanking if reset outside of stats mode
        else
            case digit_select is
                when "00" =>  -- thousands digit (an(3))
                    if show_final = '1' then
                        bcd_mux <= snap_thousands;
                    else
                        bcd_mux <= live_thousands;
                    end if;
                when "01" =>  -- hundreds digit (an(2))
                    if show_final = '1' then
                        bcd_mux <= snap_hundreds;
                    else
                        bcd_mux <= live_hundreds;
                    end if;
                when "10" =>  -- tens digit (an(1))
                    if show_final = '1' then
                        bcd_mux <= snap_tens;
                    else
                        bcd_mux <= live_tens;
                    end if;
                when "11" =>  -- ones digit (an(0))
                    if show_final = '1' then
                        bcd_mux <= snap_ones;
                    else
                        bcd_mux <= live_ones;
                    end if;
                when others =>
                    bcd_mux <= "1010";
            end case;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- BCD to 7-Segment Decoder Instantiation
    -- Converts the selected BCD value to 7-segment display signals.
    ----------------------------------------------------------------------------
    bcd_to_7_seg_inst : entity work.bcd_to_7_seg
        port map (
            bcd => bcd_mux,
            dp  => dp_const,   -- default off; overridden by process below
            seg => seg_signal
        );

    ----------------------------------------------------------------------------
    -- Decimal Point Control
    -- Overrides the default decimal point signal based on FSM state for prompts.
    -- Only the lower three digits (an(2:0)) show DPs during the countdown.
    ----------------------------------------------------------------------------
    process(digit_select, dp_sec, dp_hundredms, dp_tensms, seg_signal)
    begin
        case digit_select is
            when "00" =>  -- thousands digit: no DP
                DP <= seg_signal(7);
            when "01" =>  -- hundreds digit
                if dp_sec = '0' then
                    DP <= '0';
                else
                    DP <= seg_signal(7);
                end if;
            when "10" =>  -- tens digit
                if dp_hundredms = '0' then
                    DP <= '0';
                else
                    DP <= seg_signal(7);
                end if;
            when "11" =>  -- ones digit
                if dp_tensms = '0' then
                    DP <= '0';
                else
                    DP <= seg_signal(7);
                end if;
            when others =>
                DP <= seg_signal(7);
        end case;
    end process;

    ----------------------------------------------------------------------------
    -- Display Multiplexing Counter
    -- Generates the digit_select signal to cycle through the 4 display digits
    -- at a fast rate (approx 12kHz with 100MHz clock) to create persistence of vision.
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if mux_divider = x"1FFF" then -- Approx 12 kHz refresh rate @ 100MHz clock
                mux_divider <= (others => '0');
                if digit_select = "11" then
                    digit_select <= "00";
                else
                    digit_select <= std_logic_vector(unsigned(digit_select) + 1);
                end if;
            else
                mux_divider <= mux_divider + 1;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 4-Digit Anode Driver Instantiation
    -- Activates the correct anode based on the digit_select signal.
    ----------------------------------------------------------------------------
    anode_driver_inst : entity work.Four_Digit_Anode_driver
        port map (
            DIGIT_SELECT => digit_select,
            ANODE        => anode_signal
        );

    ----------------------------------------------------------------------------
    -- Anode Output Assignment
    -- Connects the internal anode_signal to the top-level AN output.
    ----------------------------------------------------------------------------
    AN <= anode_signal; -- Drive the 4 anode outputs

    ----------------------------------------------------------------------------
    -- Cathode Output Assignments
    -- Connects the 7-segment pattern to the top-level cathode outputs.
    ----------------------------------------------------------------------------
    CA <= seg_signal(0);
    CB <= seg_signal(1);
    CC <= seg_signal(2);
    CD <= seg_signal(3);
    CE <= seg_signal(4);
    CF <= seg_signal(5);
    CG <= seg_signal(6);

end Behavioral;
