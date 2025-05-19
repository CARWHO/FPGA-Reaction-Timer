library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Display_Controller_ms is
    generic (
        -- For a 100 MHz clock, setting half period to 50,000 cycles yields a 1ms slow clock.
        -- Original value: x"00061A8" (25000 dec -> ~0.5ms period)
        -- Intended value for 1ms: x"000C34F" (49999 dec)
        -- Value for 1.5ms period (2/3 speed): x"00124F7" (74999 dec)
        -- Value for 1.2ms period (20% faster than 1.5ms): x"000EA5F" (59999 dec)
        -- New value for ~0.9ms period: x"000AFE8" (45000 dec)
        MS_UPPERBOUND : std_logic_vector(27 downto 0) := x"000AFE8" -- Changed to 45000
    );
    port (
        CLK100MHZ : in  std_logic;
        BTNC      : in  std_logic;  -- center pushbutton input
        BTNR      : in  std_logic;  -- right pushbutton input (average)
        BTNU      : in  std_logic;  -- up pushbutton input (max)
        BTND      : in  std_logic;  -- down pushbutton input (min)
        BTNL      : in  std_logic;  -- left pushbutton input (clear)
        AN        : out std_logic_vector(7 downto 0);
        CA        : out std_logic;
        CB        : out std_logic;
        CC        : out std_logic;
        CD        : out std_logic;
        CE        : out std_logic;
        CF        : out std_logic;
        CG        : out std_logic;
        DP        : out std_logic;
        LED       : out std_logic_vector(15 downto 0)  -- LEDs for status indication
    );
end Display_Controller_ms;

architecture Structural of Display_Controller_ms is

    ----------------------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------------------
    constant ANODE_OFF : std_logic := '1'; -- Value to turn off an anode segment

    ----------------------------------------------------------------------------
    -- Slow Clock Signal for 1-ms ticks
    ----------------------------------------------------------------------------
    signal slow_clk_ms : std_logic;

    ----------------------------------------------------------------------------
    -- Millisecond Counter Outputs (each digit in BCD)
    ----------------------------------------------------------------------------
    signal ones_count        : std_logic_vector(3 downto 0);
    signal ones_rollover     : std_logic;
    signal tens_count        : std_logic_vector(3 downto 0);
    signal tens_rollover     : std_logic;
    signal hundreds_count    : std_logic_vector(3 downto 0);
    signal hundreds_rollover : std_logic;  -- for thousands counter
    signal thousands_count   : std_logic_vector(3 downto 0);

    ----------------------------------------------------------------------------
    -- FSM, Debounce, and Display Signals
    ----------------------------------------------------------------------------
    signal btnc_db          : std_logic;
    signal btnr_db          : std_logic;
    signal btnu_db          : std_logic;
    signal btnd_db          : std_logic;
    signal btnl_db          : std_logic;
    
    signal btnr_edge        : std_logic;
    signal btnu_edge        : std_logic;
    signal btnd_edge        : std_logic;
    signal btnl_edge        : std_logic;
    
    signal counter_en       : std_logic;
    signal counter_rst      : std_logic;
    -- These three DP signals drive only the lower three digits:
    -- hundreds (an(2)), tens (an(1)), ones (an(0))
    signal dp_sec       : std_logic;  -- for hundreds digit (an(2))
    signal dp_hundredms : std_logic;  -- for tens digit (an(1))
    signal dp_tensms    : std_logic;  -- for ones digit (an(0))
    signal show_final   : std_logic;
    signal snapshot_trigger : std_logic;
    signal error_detected : std_logic;
    
    -- Statistics control signals
    signal store_time    : std_logic;
    signal clear_times   : std_logic;
    signal op_avg        : std_logic;
    signal op_min        : std_logic;
    signal op_max        : std_logic;
    signal show_avg      : std_logic;
    signal show_min      : std_logic;
    signal show_max      : std_logic;
    signal use_stats     : std_logic;

    -- Snapshot registers for final displayed values (from snapshot_capture module)
    signal snapshot_thousands : std_logic_vector(3 downto 0);
    signal snapshot_hundreds  : std_logic_vector(3 downto 0);
    signal snapshot_tens      : std_logic_vector(3 downto 0);
    signal snapshot_ones      : std_logic_vector(3 downto 0);

    -- Statistics ALU outputs
    signal stat_thousands : std_logic_vector(3 downto 0);
    signal stat_hundreds  : std_logic_vector(3 downto 0);
    signal stat_tens      : std_logic_vector(3 downto 0);
    signal stat_ones      : std_logic_vector(3 downto 0);
    signal stat_valid     : std_logic;
    
    -- Storage module signals
    signal valid_count    : std_logic_vector(1 downto 0);
    signal time1_thousands : std_logic_vector(3 downto 0);
    signal time1_hundreds  : std_logic_vector(3 downto 0);
    signal time1_tens      : std_logic_vector(3 downto 0);
    signal time1_ones      : std_logic_vector(3 downto 0);
    signal time2_thousands : std_logic_vector(3 downto 0);
    signal time2_hundreds  : std_logic_vector(3 downto 0);
    signal time2_tens      : std_logic_vector(3 downto 0);
    signal time2_ones      : std_logic_vector(3 downto 0);
    signal time3_thousands : std_logic_vector(3 downto 0);
    signal time3_hundreds  : std_logic_vector(3 downto 0);
    signal time3_tens      : std_logic_vector(3 downto 0);
    signal time3_ones      : std_logic_vector(3 downto 0);

    ----------------------------------------------------------------------------
    -- PRNG Signals
    ----------------------------------------------------------------------------
    signal prng_out           : std_logic_vector(15 downto 0);
    signal prng_6bit_to_fsm   : std_logic_vector(5 downto 0); -- Changed to 6 bits

    ----------------------------------------------------------------------------
    -- Error display constants - "Err" on the display
    ----------------------------------------------------------------------------
    constant ERROR_THOUSANDS : std_logic_vector(3 downto 0) := "1110"; -- E
    constant ERROR_HUNDREDS  : std_logic_vector(3 downto 0) := "1111"; -- r
begin

    ----------------------------------------------------------------------------
    -- Component Instantiation: Clock Divider (generates 1ms tick)
    ----------------------------------------------------------------------------
    clock_divider_ms_inst : entity work.clock_divider
        port map (
            CLK        => CLK100MHZ,
            UPPERBOUND => MS_UPPERBOUND,
            SLOWCLK    => slow_clk_ms
        );
        
    ----------------------------------------------------------------------------
    -- Component Instantiation: Pseudo-Random Number Generator (PRNG)
    ----------------------------------------------------------------------------
    prng_inst : entity work.PRNG
        port map (
            clk        => CLK100MHZ,
            reset      => '0', -- Tie reset low for continuous operation
            enable     => '1', -- Enable continuous running
            random_out => prng_out
        );
        
    -- Select lower 6 bits from PRNG for FSM's random delay variation
    prng_6bit_to_fsm <= prng_out(5 downto 0); -- Changed to 6 bits

    ----------------------------------------------------------------------------
    -- Component Instantiation: Button Handler (debounces and edge-detects BTNR,U,D,L)
    ----------------------------------------------------------------------------
    button_handler_inst : entity work.button_handler
        port map (
            clk       => CLK100MHZ,
            btnr      => BTNR,
            btnu      => BTNU,
            btnd      => BTND,
            btnl      => BTNL,
            btnr_db   => btnr_db,
            btnu_db   => btnu_db,
            btnd_db   => btnd_db,
            btnl_db   => btnl_db,
            btnr_edge => btnr_edge,
            btnu_edge => btnu_edge,
            btnd_edge => btnd_edge,
            btnl_edge => btnl_edge
        );
    
    ----------------------------------------------------------------------------
    -- Component Instantiation: Debouncer (for BTNC)
    ----------------------------------------------------------------------------
    debounce_inst : entity work.debounce
        port map (
            clk   => CLK100MHZ,
            rst   => '0', -- Debouncer reset tied low
            noisy => BTNC,
            clean => btnc_db
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: Timing Finite State Machine (FSM)
    ----------------------------------------------------------------------------
    fsm_inst : entity work.timing_fsm
        port map (
            clk         => CLK100MHZ,
            btnc        => btnc_db,
            btnr        => btnr_db,
            btnu        => btnu_db,
            btnd        => btnd_db,
            btnl        => btnl_db,
            random_in   => prng_6bit_to_fsm, -- Connect 6-bit PRNG output
            counter_en  => counter_en,
            counter_rst => counter_rst,
            dp_ones     => dp_sec,       -- drives hundreds digit (an(2))
            dp_tens     => dp_hundredms, -- drives tens digit (an(1))
            dp_third    => dp_tensms,    -- drives ones digit (an(0))
            show_final  => show_final,
            snapshot    => snapshot_trigger,
            error_detected => error_detected,
            store_time  => store_time,
            clear_times => clear_times,
            op_avg      => op_avg,
            op_min      => op_min,
            op_max      => op_max,
            show_avg    => show_avg,
            show_min    => show_min,
            show_max    => show_max,
            use_stats   => use_stats
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: Reaction Time Storage
    ----------------------------------------------------------------------------
    storage_inst : entity work.reaction_time_storage
        port map (
            clk            => CLK100MHZ,
            reset          => clear_times, -- Controlled by FSM (BTNL in stats mode)
            store_trigger  => store_time,
            -- Connect live counter values directly to storage input
            time_thousands => thousands_count,
            time_hundreds  => hundreds_count,
            time_tens      => tens_count,
            time_ones      => ones_count,
            time1_thousands => time1_thousands,
            time1_hundreds  => time1_hundreds,
            time1_tens      => time1_tens,
            time1_ones      => time1_ones,
            time2_thousands => time2_thousands,
            time2_hundreds  => time2_hundreds,
            time2_tens      => time2_tens,
            time2_ones      => time2_ones,
            time3_thousands => time3_thousands,
            time3_hundreds  => time3_hundreds,
            time3_tens      => time3_tens,
            time3_ones      => time3_ones,
            valid_count    => valid_count
        );
        
    ----------------------------------------------------------------------------
    -- Component Instantiation: Statistics ALU
    ----------------------------------------------------------------------------
    alu_inst : entity work.statistics_alu
        port map (
            clk             => CLK100MHZ,
            time1_thousands => time1_thousands,
            time1_hundreds  => time1_hundreds,
            time1_tens      => time1_tens,
            time1_ones      => time1_ones,
            time2_thousands => time2_thousands,
            time2_hundreds  => time2_hundreds,
            time2_tens      => time2_tens,
            time2_ones      => time2_ones,
            time3_thousands => time3_thousands,
            time3_hundreds  => time3_hundreds,
            time3_tens      => time3_tens,
            time3_ones      => time3_ones,
            valid_count     => valid_count,
            op_avg          => op_avg,
            op_min          => op_min,
            op_max          => op_max,
            result_thousands => stat_thousands,
            result_hundreds  => stat_hundreds,
            result_tens      => stat_tens,
            result_ones      => stat_ones,
            result_valid     => stat_valid
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: BCD Counter (Ones place - 1ms)
    ----------------------------------------------------------------------------
    ones_counter_inst : entity work.Ones_counter
        port map (
            CLK_1MS  => slow_clk_ms, -- Clocked by the 1ms tick
            RESET    => counter_rst,
            EN       => counter_en,
            COUNT    => ones_count,
            ROLLOVER => ones_rollover
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: BCD Counter (Tens place - 10ms)
    ----------------------------------------------------------------------------
    tens_counter_inst : entity work.Tens_Counter
        port map (
            CLK       => CLK100MHZ,   -- Clocked by main system clock
            RESET     => counter_rst,
            EN        => counter_en,
            INC_TICK  => ones_rollover, -- Increments on rollover from ones_counter
            COUNT     => tens_count,
            ROLLOVER  => tens_rollover
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: BCD Counter (Hundreds place - 100ms)
    ----------------------------------------------------------------------------
    Hundreds_counter_inst : entity work.Hundreds_counter
        port map (
            CLK       => CLK100MHZ,   -- Clocked by main system clock
            RESET     => counter_rst,
            EN        => counter_en,
            INC_TICK  => tens_rollover, -- Increments on rollover from tens_counter
            COUNT     => hundreds_count,
            ROLLOVER  => hundreds_rollover
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: BCD Counter (Thousands place - 1s)
    ----------------------------------------------------------------------------
    thousands_counter_inst : entity work.Thousands_Counter
        port map (
            CLK       => CLK100MHZ,   -- Clocked by main system clock
            RESET     => counter_rst,
            EN        => counter_en,
            INC_TICK  => hundreds_rollover, -- Increments on rollover from hundreds_counter
            COUNT     => thousands_count,
            ROLLOVER  => open -- Thousands rollover is not currently used
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: Snapshot Capture
    -- Latches the live counter values when triggered by the FSM.
    ----------------------------------------------------------------------------
    snapshot_inst : entity work.snapshot_capture
        port map (
            clk             => CLK100MHZ,
            snapshot_trigger=> snapshot_trigger, -- From FSM
            ones_in         => ones_count,
            tens_in         => tens_count,
            hundreds_in     => hundreds_count,
            thousands_in    => thousands_count,
            ones_out        => snapshot_ones,
            tens_out        => snapshot_tens,
            hundreds_out    => snapshot_hundreds,
            thousands_out   => snapshot_thousands
        );

    ----------------------------------------------------------------------------
    -- Component Instantiation: Display Multiplexer
    -- Handles multiplexing of digits to the 7-segment display and anode control.
    ----------------------------------------------------------------------------
    display_mux_inst : entity work.display_mux
        port map (
            clk             => CLK100MHZ,
            reset           => counter_rst, -- Reset from FSM
            show_final      => show_final,
            error_detected  => error_detected,
            use_stats       => use_stats,
            stat_valid      => stat_valid,
            dp_sec          => dp_sec,
            dp_hundredms    => dp_hundredms,
            dp_tensms       => dp_tensms,
            live_thousands  => thousands_count,
            live_hundreds   => hundreds_count,
            live_tens       => tens_count,
            live_ones       => ones_count,
            snap_thousands  => snapshot_thousands,
            snap_hundreds   => snapshot_hundreds,
            snap_tens       => snapshot_tens,
            snap_ones       => snapshot_ones,
            stat_thousands  => stat_thousands,
            stat_hundreds   => stat_hundreds,
            stat_tens       => stat_tens,
            stat_ones       => stat_ones,
            AN              => AN(3 downto 0), -- Connect to lower 4 anodes
            CA              => CA,
            CB              => CB,
            CC              => CC,
            CD              => CD,
            CE              => CE,
            CF              => CF,
            CG              => CG,
            DP              => DP
        );

    -- Ensure upper anodes are disabled
    AN(7 downto 4) <= (others => ANODE_OFF); -- Ensure upper 4 anodes (unused) are off

    ----------------------------------------------------------------------------
    -- Component Instantiation: LED Controller
    -- Manages the status LEDs.
    ----------------------------------------------------------------------------
    led_controller_inst : entity work.led_controller
        port map (
            clk            => CLK100MHZ,
            valid_count    => valid_count,
            show_avg       => show_avg,
            show_max       => show_max,
            show_min       => show_min,
            error_detected => error_detected,
            LED            => LED
        );

end Structural;
