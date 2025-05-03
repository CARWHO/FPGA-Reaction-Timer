library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity timing_fsm is
    Port (
        clk       : in  std_logic;  -- 100 MHz clock
        btnc      : in  std_logic;  -- Debounced center button input
        btnr      : in  std_logic;  -- Debounced right button input (average)
        btnu      : in  std_logic;  -- Debounced up button input (max)
        btnd      : in  std_logic;  -- Debounced down button input (min)
        btnl      : in  std_logic;  -- Debounced left button input (clear)
        
        random_in : in  std_logic_vector(5 downto 0); -- 6 random bits for delay variation

        -- Control signals for counters:
        counter_en  : out std_logic;  -- '1' to enable counting (timing state)
        counter_rst : out std_logic;  -- '1' to hold counters in reset

        -- Decimal point outputs (active low: '0' = on)
        dp_ones : out std_logic;  -- Used for the SECONDS digit (leftmost)
        dp_tens : out std_logic;  -- 100-ms digit (middle)
        dp_third: out std_logic;  -- 10-ms digit (rightmost)

        -- Signal indicating final display state (snapshot display)
        show_final : out std_logic;

        -- Snapshot trigger: goes high for one clock cycle when transitioning 
        -- from timing to display_clear.
        snapshot : out std_logic;
        
        -- Error signal for premature button press
        error_detected : out std_logic;
        
        -- Statistics control signals
        store_time    : out std_logic;  -- Trigger to store reaction time
        clear_times   : out std_logic;  -- Clear stored times
        
        -- ALU operation control
        op_avg        : out std_logic;  -- Calculate average
        op_min        : out std_logic;  -- Find minimum
        op_max        : out std_logic;  -- Find maximum
        
        -- Display mode indicators
        show_avg      : out std_logic;  -- Showing average time
        show_min      : out std_logic;  -- Showing minimum time
        show_max      : out std_logic;  -- Showing maximum time
        
        -- Use ALU result instead of snapshot
        use_stats     : out std_logic   -- '1' to show statistics instead of current time
    );
end timing_fsm;

architecture Behavioral of timing_fsm is

    type state_type is (
        waiting, prompt_1, prompt_2, prompt_3, timing, 
        display_clear, display_value, error_state,
        avg_display, max_display, min_display
    );
    signal current_state, next_state : state_type := waiting;

    -- Widen constants and signals to 30 bits to accommodate max delay up to ~10.7s
    constant T_PROMPT : unsigned(29 downto 0) := to_unsigned(100000000, 30);  -- ~1 second at 100 MHz
    constant T_RAND_STEP : unsigned(29 downto 0) := to_unsigned(10000000, 30); -- ~0.1 second step for random delay
    
    signal t : unsigned(29 downto 0) := (others => '0'); -- Timer, now up to ~10.7s max
    
    -- Sampled random value (now 6 bits) and calculated target delay for prompt_3
    signal sampled_random_6bit : unsigned(5 downto 0) := (others => '0'); -- Changed to 6 bits
    signal target_delay_prompt3 : unsigned(29 downto 0) := T_PROMPT; -- Default to base delay, now 30 bits

    -- For edge detection on the buttons:
    signal btnc_prev : std_logic := '0';
    signal btnr_prev : std_logic := '0';
    signal btnu_prev : std_logic := '0';
    signal btnd_prev : std_logic := '0';
    signal btnl_prev : std_logic := '0';

begin

    ----------------------------------------------------------------------------
    -- 1) State Register and Previous-Button Tracking
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
            
            -- Latch 6-bit random value when starting a new test
            if current_state = waiting and next_state = prompt_1 then
                sampled_random_6bit <= unsigned(random_in); -- Changed to 6 bits
            end if;
            
            btnc_prev <= btnc;
            btnr_prev <= btnr;
            btnu_prev <= btnu;
            btnd_prev <= btnd;
            btnl_prev <= btnl;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 2) Next State Logic
    ----------------------------------------------------------------------------
    -- Added target_delay_prompt3 to sensitivity list
    process(current_state, t, btnc, btnc_prev, btnr, btnr_prev, btnu, btnu_prev, btnd, btnd_prev, btnl, btnl_prev, target_delay_prompt3)
    begin
        next_state <= current_state;  -- default
        case current_state is

            when waiting =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= prompt_1;
                elsif (btnr = '1' and btnr_prev = '0') then
                    next_state <= avg_display;
                elsif (btnu = '1' and btnu_prev = '0') then
                    next_state <= max_display;
                elsif (btnd = '1' and btnd_prev = '0') then
                    next_state <= min_display;
                else
                    next_state <= waiting;
                end if;

            when prompt_1 =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= error_state;  -- Premature button press
                elsif t = T_PROMPT then
                    next_state <= prompt_2;
                else
                    next_state <= prompt_1;
                end if;

            when prompt_2 =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= error_state;  -- Premature button press
                elsif t = T_PROMPT then
                    next_state <= prompt_3;
                else
                    next_state <= prompt_2;
                end if;

            when prompt_3 =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= error_state;  -- Premature button press
                elsif t = target_delay_prompt3 then -- Use calculated random delay
                    if btnc = '0' then
                        next_state <= timing;
                    else
                        next_state <= prompt_3;
                    end if;
                else
                    next_state <= prompt_3;
                end if;

            when timing =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= display_clear;
                else
                    next_state <= timing;
                end if;

            when display_clear =>
                if t = T_PROMPT then
                    next_state <= display_value;
                else
                    next_state <= display_clear;
                end if;

            when display_value =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= waiting;
                elsif (btnr = '1' and btnr_prev = '0') then
                    next_state <= avg_display;
                elsif (btnu = '1' and btnu_prev = '0') then
                    next_state <= max_display;
                elsif (btnd = '1' and btnd_prev = '0') then
                    next_state <= min_display;
                else
                    next_state <= display_value;
                end if;
                
            when error_state =>
                if t = T_PROMPT then
                    if (btnc = '1' and btnc_prev = '0') then
                        next_state <= waiting;
                    else
                        next_state <= error_state;
                    end if;
                else
                    next_state <= error_state;
                end if;
                
            when avg_display =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= waiting;
                elsif (btnr = '1' and btnr_prev = '0') then
                    next_state <= avg_display;  -- Stay in same state
                elsif (btnu = '1' and btnu_prev = '0') then
                    next_state <= max_display;
                elsif (btnd = '1' and btnd_prev = '0') then
                    next_state <= min_display;
                elsif (btnl = '1' and btnl_prev = '0') then
                    next_state <= waiting;  -- Clear and return to waiting
                else
                    next_state <= avg_display;
                end if;
                
            when max_display =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= waiting;
                elsif (btnr = '1' and btnr_prev = '0') then
                    next_state <= avg_display;
                elsif (btnu = '1' and btnu_prev = '0') then
                    next_state <= max_display;  -- Stay in same state
                elsif (btnd = '1' and btnd_prev = '0') then
                    next_state <= min_display;
                elsif (btnl = '1' and btnl_prev = '0') then
                    next_state <= waiting;  -- Clear and return to waiting
                else
                    next_state <= max_display;
                end if;
                
            when min_display =>
                if (btnc = '1' and btnc_prev = '0') then
                    next_state <= waiting;
                elsif (btnr = '1' and btnr_prev = '0') then
                    next_state <= avg_display;
                elsif (btnu = '1' and btnu_prev = '0') then
                    next_state <= max_display;
                elsif (btnd = '1' and btnd_prev = '0') then
                    next_state <= min_display;  -- Stay in same state
                elsif (btnl = '1' and btnl_prev = '0') then
                    next_state <= waiting;  -- Clear and return to waiting
                else
                    next_state <= min_display;
                end if;

            when others =>
                next_state <= waiting;
        end case;
    end process;

    ----------------------------------------------------------------------------
    -- 3) Timer for Prompt States
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if current_state /= next_state then
                t <= (others => '0'); -- Reset timer on state change
            -- Increment timer only if not at max value for the current state's check
            -- This prevents unnecessary incrementing beyond the target
            -- Note: T_PROMPT and target_delay_prompt3 are now 30 bits wide
            elsif (current_state = prompt_1 or current_state = prompt_2) and t < T_PROMPT then
                 t <= t + 1;
            elsif current_state = prompt_3 and t < target_delay_prompt3 then
                 t <= t + 1;
            -- Add other states that use the timer if necessary (e.g., display_clear, error_state)
            elsif (current_state = display_clear or current_state = error_state) and t < T_PROMPT then
                 t <= t + 1;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 4) Output Decode Process
    ----------------------------------------------------------------------------
    process(current_state)
    begin
        -- Defaults: all decimals off ('1' means off)
        counter_en  <= '0';
        counter_rst <= '0';
        dp_ones     <= '1';
        dp_tens     <= '1';
        dp_third    <= '1';
        show_final  <= '0';
        error_detected <= '0';
        store_time  <= '0';
        clear_times <= '0';
        op_avg      <= '0';
        op_min      <= '0';
        op_max      <= '0';
        show_avg    <= '0';
        show_min    <= '0';
        show_max    <= '0';
        use_stats   <= '0';

        case current_state is

            when waiting =>
                counter_rst <= '1';  -- hold counters in reset

            when prompt_1 =>
                counter_rst <= '1';
                dp_ones     <= '0';  -- all decimals on for countdown
                dp_tens     <= '0';
                dp_third    <= '0';

            when prompt_2 =>
                counter_rst <= '1';
                dp_ones     <= '0';  -- ones & tens decimals on for countdown
                dp_tens     <= '0';
                dp_third    <= '1';

            when prompt_3 =>
                counter_rst <= '1';
                dp_ones     <= '0';  -- just ones decimal on for countdown
                dp_tens     <= '1';
                dp_third    <= '1';

            when timing =>
                counter_rst <= '0';
                counter_en  <= '1';    -- enable counters
                -- Remove decimal points during counting
                dp_ones     <= '1';
                dp_tens     <= '1';
                dp_third    <= '1';

            when display_clear =>
                counter_rst <= '1';  -- clear counters
                dp_ones     <= '1';
                dp_tens     <= '1';
                dp_third    <= '1';
                store_time  <= '1';  -- Store the reaction time

            when display_value =>
                counter_en  <= '0';   -- freeze counters
                show_final  <= '1';
                -- Remove decimal points during display
                dp_ones     <= '1';
                dp_tens     <= '1';
                dp_third    <= '1';
                
            when error_state =>
                counter_rst <= '1';  -- clear counters
                error_detected <= '1';  -- signal error condition
                -- Flash all decimal points to indicate error
                dp_ones     <= '0';
                dp_tens     <= '0';
                dp_third    <= '0';
                
            when avg_display =>
                counter_rst <= '1';  -- clear counters
                op_avg      <= '1';  -- Select average operation
                show_avg    <= '1';  -- Indicate average display
                use_stats   <= '1';  -- Use ALU result
                -- Show decimal point on ones digit to indicate average
                dp_ones     <= '0';
                dp_tens     <= '1';
                dp_third    <= '1';
                
            when max_display =>
                counter_rst <= '1';  -- clear counters
                op_max      <= '1';  -- Select maximum operation
                show_max    <= '1';  -- Indicate maximum display
                use_stats   <= '1';  -- Use ALU result
                -- Show decimal point on tens digit to indicate maximum
                dp_ones     <= '1';
                dp_tens     <= '0';
                dp_third    <= '1';
                
            when min_display =>
                counter_rst <= '1';  -- clear counters
                op_min      <= '1';  -- Select minimum operation
                show_min    <= '1';  -- Indicate minimum display
                use_stats   <= '1';  -- Use ALU result
                -- Show decimal point on third digit to indicate minimum
                dp_ones     <= '1';
                dp_tens     <= '1';
                dp_third    <= '0';

            when others =>
                counter_rst <= '1';
        end case;
    end process;

    ----------------------------------------------------------------------------
    -- 5) Snapshot Trigger: pulses when going from timing -> display_clear
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if (current_state = timing and next_state = display_clear) then
                snapshot <= '1';
            else
                snapshot <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- 6) Calculate Target Delay for Prompt 3 (Concurrent Assignment)
    ----------------------------------------------------------------------------
    -- Use 6-bit random value. Resize multiplication result to 30 bits before adding.
    target_delay_prompt3 <= T_PROMPT + resize(sampled_random_6bit * T_RAND_STEP, T_PROMPT'length);

    ----------------------------------------------------------------------------
    -- 7) Clear Times Trigger: pulses when BTNL is pressed in a stats state
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if (btnl = '1' and btnl_prev = '0' and 
                (current_state = avg_display or 
                 current_state = max_display or 
                 current_state = min_display)) then
                clear_times <= '1';
            else
                clear_times <= '0';
            end if;
        end if;
    end process;

end Behavioral;
