--===============================================================================================--
--! @file       LWC_TB.vhd
--! @brief      NIST Lightweight Cryptography Testbench
--! @project    GMU LWC Package
--! @author     Ekawat (ice) Homsirikamol
--! @author     Kamyar Mohajerani
--! @copyright  Copyright (c) 2015, 2020, 2021, 2022 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--! @version    1.2.0
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             unrestricted)
--===============================================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.NIST_LWAPI_pkg.all;

entity LWC_TB IS
    generic(
        G_MAX_FAILURES     : natural  := 0; --! Maximum number of failures before stopping the simulation
        G_TEST_MODE        : natural  := 0; --! 0: normal, 1: stall both sdi/pdi_valid and do_ready, 2: stall sdi/pdi_valid, 3: stall do_ready, 4: Timing (cycle) measurement 
        G_PDI_STALLS       : natural  := 3; --! Number of cycles to stall pdi_valid
        G_SDI_STALLS       : natural  := 3; --! Number of cycles to stall sdi_valid
        G_DO_STALLS        : natural  := 3; --! Number of cycles to stall do_ready
        G_RDI_STALLS       : natural  := 3; --! Number of cycles to stall rdi_valid
        G_RANDOM_STALL     : boolean  := false; --! Stall for a random number of cycles in the range [0..G_xx_STALLS], when G_TEST_MODE = 4
        G_CLK_PERIOD_PS    : positive := 10_000; --! Simulation clock period in picoseconds
        G_FNAME_PDI        : string   := "KAT/v1/pdi.txt"; -- "../KAT/v1/pdi.txt"; --! Path to the input file containing cryptotvgen PDI testvector data
        G_FNAME_SDI        : string   := "KAT/v1/sdi.txt"; -- "../KAT/v1/sdi.txt"; --! Path to the input file containing cryptotvgen SDI testvector data
        G_FNAME_DO         : string   := "KAT/v1/do.txt"; -- "../KAT/v1/do.txt"; --! Path to the input file containing cryptotvgen DO testvector data
        G_FNAME_RDI        : string   := "KAT/v1/rdi.txt"; --! Path to the input file containing random data
        G_PRNG_RDI         : boolean  := true; --! Use testbench's internal PRNG to generate RDI input instead of the file `G_FNAME_RDI`
        G_RANDOM_SEED      : positive := 1; --! Internal PRNG seed, must be positive
        G_FNAME_LOG        : string   := "log.txt"; --! Path to the generated log file
        G_FNAME_TIMING     : string   := "timing.txt"; --! Path to the generated timing measurements (when G_TEST_MODE=4)
        G_FNAME_FAILED_TVS : string   := "failed_testvectors.txt"; --! Path to the generated log of failed testvector words
        G_FNAME_RESULT     : string   := "result.txt"; --! Path to the generated result file containing 0 or 1  -- REDUNDANT / NOT USED
        G_PRERESET_WAIT_NS : natural  := 0; --! Time (in nanoseconds) to wait before reseting UUT. Xilinx GSR takes 100ns, required for post-synth simulation
        G_INPUT_DELAY_NS   : natural  := 0; --! Input delay in nanoseconds
        G_TIMEOUT_CYCLES   : integer  := 0; --! Fail simulation after this many consecutive cycles of data I/O inactivity, 0: disable timeout
        G_VERBOSE_LEVEL    : integer  := 0 --! Verbosity level
    );
end LWC_TB;

architecture TB of LWC_TB is
    --================================================== Constants ==================================================--
    constant W_S         : positive       := W * PDI_SHARES;
    constant SW_S        : positive       := SW * SDI_SHARES;
    constant input_delay : TIME           := G_INPUT_DELAY_NS * ns;
    constant clk_period  : TIME           := G_CLK_PERIOD_PS * ps;
    constant TB_HEAD     : string(1 to 6) := "# TB :";
    constant INS_HEAD    : string(1 to 6) := "INS = ";
    constant HDR_HEAD    : string(1 to 6) := "HDR = ";
    constant DAT_HEAD    : string(1 to 6) := "DAT = ";
    constant STT_HEAD    : string(1 to 6) := "STT = ";
    -- if placed anywhere in do.txt, subsequent testcases are skipped
    constant EOF_HEAD    : string(1 to 6) := "###EOF";

    constant TIMING_MODE : boolean := G_TEST_MODE = 4;

    --=================================================== Signals ===================================================--
    --! stop clock generation
    signal stop_clock          : boolean                             := False;
    --! initial reset of UUT is complete
    signal reset_done          : boolean                             := False;
    --=================================================== Wirings ===================================================--
    signal clk                 : std_logic                           := '0';
    signal rst                 : std_logic                           := '0';
    --! PDI
    signal pdi_data            : std_logic_vector(W_S - 1 downto 0)  := (others => '0');
    signal pdi_data_delayed    : std_logic_vector(W_S - 1 downto 0)  := (others => '0');
    signal pdi_valid           : std_logic                           := '0';
    signal pdi_valid_delayed   : std_logic                           := '0';
    signal pdi_ready           : std_logic;
    --! SDI
    signal sdi_data            : std_logic_vector(SW_S - 1 downto 0) := (others => '0');
    signal sdi_data_delayed    : std_logic_vector(SW_S - 1 downto 0) := (others => '0');
    signal sdi_valid           : std_logic                           := '0';
    signal sdi_valid_delayed   : std_logic                           := '0';
    signal sdi_ready           : std_logic;
    --! DO
    signal do_data             : std_logic_vector(W_S - 1 downto 0);
    signal do_valid            : std_logic;
    signal do_last             : std_logic;
    signal do_ready            : std_logic                           := '0';
    signal do_ready_delayed    : std_logic                           := '0';
    -- Used only for protected implementations:
    --   RDI
    signal rdi_data            : std_logic_vector(RW - 1 downto 0)   := (others => '0');
    signal rdi_data_delayed    : std_logic_vector(RW - 1 downto 0)   := (others => '0');
    signal rdi_valid           : std_logic                           := '0';
    signal rdi_valid_delayed   : std_logic                           := '0';
    signal rdi_ready           : std_logic;
    -- Counters
    signal pdi_operation_count : integer                             := 0;
    signal cycle_counter       : natural                             := 0;
    signal idle_counter        : natural                             := 0;
    signal num_rand_vectors    : natural                             := 0;
    --
    signal start_cycle         : natural;
    signal timing_started      : boolean                             := False;
    signal timing_stopped      : boolean                             := False;
    -- random number generation (requires VHDL 2000+)
    -- based on random package from VHDL-extras (http://github.com/kevinpt/vhdl-extras)
    use ieee.math_real.all;
    type rand_state is protected
        procedure seed(s : in positive);
        impure function random return real;
    end protected;
    type rand_state is protected body
        variable seed1 : positive;
        variable seed2 : positive;
        procedure seed(s : in positive) is
        begin
            seed1 := s;
            if s > 1 then
                seed2 := s - 1;
            else
                seed2 := s + 42;
            end if;
        end procedure;
        impure function random return real is
            variable result : real;
        begin
            uniform(seed1, seed2, result);
            return result;
        end function;
    end protected body;
    --
    shared variable prng       : rand_state;
    --
    impure function random return real is
    begin
        return prng.random;
    end function;
    procedure seed(s : positive) is
    begin
        prng.seed(s);
    end procedure;
    ----- End VHDL 2000+ -----
    --
    impure function random(min, max : integer) return integer is
    begin
        return integer(trunc(real(max - min + 1) * random)) + min;
    end function;
    --
    impure function random(size : natural) return std_logic_vector is
        -- 30-bit chunks to stay within integer range limit
        constant seg_size  : natural := 30;
        constant segments  : natural := size / seg_size;
        constant remainder : natural := size - segments * seg_size;
        variable result    : std_logic_vector(size - 1 downto 0);
    begin
        if segments > 0 then
            for s in 0 to segments - 1 loop
                result((s + 1) * seg_size - 1 downto s * seg_size) := std_logic_vector(to_unsigned(random(0, 2 ** seg_size - 1), seg_size));
            end loop;
        end if;
        if remainder > 0 then
            result(size - 1 downto size - remainder) := std_logic_vector(to_unsigned(random(0, 2 ** remainder - 1), remainder));
        end if;
        return result;
    end function;

    --================================================== I/O files ==================================================--
    -- cryptotvgen KAT files
    file pdi_file      : TEXT open READ_MODE is G_FNAME_PDI; -- always required
    file sdi_file      : TEXT;
    file do_file       : TEXT open READ_MODE is G_FNAME_DO; -- always required
    file rdi_file      : TEXT;
    -- output files
    file log_file      : TEXT;
    file timing_file   : TEXT;
    file result_file   : TEXT open WRITE_MODE is G_FNAME_RESULT;
    file failures_file : TEXT open WRITE_MODE is G_FNAME_FAILED_TVS;

    --================================================== functions ==================================================--
    -- compare received word against expected word
    -- returns true if they match or if the unmatched bit was a don't-care
    function words_match(actual, expected : std_logic_vector) return boolean is
    begin
        for i in expected'range loop
            if actual(i) /= expected(i) and expected(i) /= 'X' and expected(i) /= '-' then
                return False;
            end if;
        end loop;
        return True;
    end function;

    -- sum up all shares. Returns do_data if num_shares=1)
    function xor_shares(slv : std_logic_vector; num_shares : positive) return std_logic_vector is
        constant share_width : natural                                    := slv'length / num_shares;
        variable ret         : std_logic_vector(share_width - 1 downto 0) := slv(share_width - 1 downto 0);
    begin
        for i in 1 to num_shares - 1 loop
            ret := ret xor slv((i + 1) * share_width - 1 downto i * share_width);
        end loop;
        return ret;
    end function;

    impure function get_stalls(max_stalls : natural) return natural is
    begin
        if G_TEST_MODE = 0 or TIMING_MODE then
            return 0;
        elsif G_RANDOM_STALL then
            return random(0, 1) * random(1, max_stalls); -- 50%: no stall. 50%: 1..max_stalls
        else
            return max_stalls;
        end if;
    end function;

begin
    --===========================================================================================--
    -- generate clock
    Clock_PROCESS : process
    begin
        if not stop_clock then
            clk <= '1';
            wait for clk_period / 2;
            clk <= '0';
            wait for clk_period / 2;
        else
            wait;
        end if;
    end process;

    -- generate reset
    Reset_PROCESS : process
    begin
        report LF & " -- Testvectors:  " & G_FNAME_PDI & " " & G_FNAME_SDI & " " & G_FNAME_DO & LF &
        " -- Clock Period:  " & integer'image(G_CLK_PERIOD_PS) & " ps" & LF &
        " -- Max Failures:  " & integer'image(G_MAX_FAILURES) & LF & 
        " -- Timout Cycles: " & integer'image(G_TIMEOUT_CYCLES) & LF &
        " -- Test Mode:     " & integer'image(G_TEST_MODE) & LF &
        " -- Random Seed:   " & integer'image(G_RANDOM_SEED) & LF &
        " -- Test Mode:     " & integer'image(G_TEST_MODE) & LF &
        CR severity note;

        seed(G_RANDOM_SEED);
        wait for G_PRERESET_WAIT_NS * ns;
        if ASYNC_RSTN then
            rst <= '0';
            wait for 2 * clk_period;
            rst <= '1';
        else
            rst <= '1';
            wait for 2 * clk_period + input_delay;
            rst <= '0';
        end if;
        wait until rising_edge(clk);
        wait for clk_period;            -- optional
        reset_done <= True;
        wait;
    end process;

    Cycle_Counter_PROCESS : process(clk)
    begin
        if reset_done and rising_edge(clk) then
            cycle_counter <= cycle_counter + 1;
        end if;
    end process;

    -- terminates simulation
    Timeout_Watchdog_PROCESS : process(clk)
    begin
        if G_TIMEOUT_CYCLES > 0 and reset_done and rising_edge(clk) then
            if (pdi_valid and pdi_ready) = '1' --
                or (sdi_valid and sdi_ready) = '1' or (do_valid and do_ready) = '1' then
                idle_counter <= 0;
            else
                idle_counter <= idle_counter + 1;
                assert idle_counter < G_TIMEOUT_CYCLES --
                report "[FAIL] Timeout after " & integer'image(idle_counter) & " cycles!"
                severity failure;
            end if;
        end if;
    end process;

    --===========================================================================================--
    -- LWC is instantiated as a component to enable mixed language simulation
    --*** SCA ***--
    --/+
    -- uut : LWC_SCA
    --/-
    uut : LWC
        port map(
            clk       => clk,
            rst       => rst,
            pdi_data  => pdi_data_delayed,
            pdi_valid => pdi_valid_delayed,
            pdi_ready => pdi_ready,
            sdi_data  => sdi_data_delayed,
            sdi_valid => sdi_valid_delayed,
            sdi_ready => sdi_ready,
            do_data   => do_data,
            do_last   => do_last,
            do_valid  => do_valid,
            do_ready  => do_ready_delayed
--            ,
--            rdi_data  => rdi_data_delayed,
--            rdi_valid => rdi_valid_delayed,
--            rdi_ready => rdi_ready
        );
    --***********--

    --===========================================================================================--

    pdi_data_delayed  <= transport pdi_data after input_delay;
    pdi_valid_delayed <= transport pdi_valid after input_delay;
    sdi_data_delayed  <= transport sdi_data after input_delay;
    sdi_valid_delayed <= transport sdi_valid after input_delay;
    do_ready_delayed  <= transport do_ready after input_delay;

    GEN_RDI : if RW > 0 generate
    begin
        rdi_data_delayed  <= transport rdi_data after input_delay;
        rdi_valid_delayed <= transport rdi_valid after input_delay;
        rdi_proc : process
            variable rdi_line : line;
            variable rdi_vec  : std_logic_vector(RW - 1 downto 0);
            variable read_ok  : boolean;
        begin
            report LF & "RW=" & integer'image(RW);
            wait until reset_done and rising_edge(clk);
            if G_PRNG_RDI then
                while not stop_clock loop
                    for i in 0 to get_stalls(G_RDI_STALLS) - 1 loop
                        rdi_valid <= '0';
                        wait until rising_edge(clk);
                    end loop;
                    rdi_data         <= random(RW);
                    rdi_valid        <= '1';
                    wait until rising_edge(clk) and rdi_ready = '1' and rdi_valid_delayed = '1';
                    num_rand_vectors <= num_rand_vectors + 1;
                end loop;
            else
                file_open(rdi_file, G_FNAME_RDI, READ_MODE);
                while not stop_clock loop
                    loop
                        if endfile(rdi_file) then
                            assert num_rand_vectors > 0 report "RDI file is empty!" severity failure;
                            if G_VERBOSE_LEVEL > 2 then
                                report "Reached end of " & G_FNAME_RDI & ", reading from the begining.";
                            end if;
                            -- re-read from the biginging
                            file_close(rdi_file);
                            file_open(rdi_file, G_FNAME_RDI, READ_MODE);
                        end if;
                        readline(rdi_file, rdi_line);
                        if rdi_line'length > 0 then
                            exit;
                        end if;
                    end loop;
                    if rdi_line'length * 4 < RW then
                        report "Error: RDI line is shorter than RW " severity failure;
                        exit;           -- exit the loop
                    end if;
                    lwc_hread(rdi_line, rdi_vec, read_ok);
                    if not read_ok then
                        report "Error while reading " & G_FNAME_RDI severity failure;
                        exit;           -- exit the loop
                    end if;
                    for i in 0 to get_stalls(G_RDI_STALLS) - 1 loop
                        rdi_valid <= '0';
                        wait until rising_edge(clk);
                    end loop;
                    rdi_data         <= rdi_vec;
                    rdi_valid        <= '1';
                    wait until rising_edge(clk) and rdi_ready = '1' and rdi_valid_delayed = '1';
                    num_rand_vectors <= num_rand_vectors + 1;
                end loop;
                file_close(rdi_file);
            end if;
            wait;                       -- until simulation ends
        end process;
    end generate;

    --===========================================================================================--
    --====================================== PDI Stimulus =======================================--
    tb_read_pdi : process
        variable line_data  : LINE;
        variable word_block : std_logic_vector(W_S - 1 downto 0) := (others => '0');
        variable read_ok    : boolean;
        variable line_head  : string(1 to 6);
        variable actkey_ins : boolean;
        variable hash_ins   : boolean;
        -- instruction other than actkey or hash was already sent
        variable op_sent    : boolean                            := False;
    begin
        -- wait for the clock edge after reset is complete
        wait until reset_done;
        wait until rising_edge(clk);
        --
        while not endfile(pdi_file) loop
            readline(pdi_file, line_data);
            read(line_data, line_head, read_ok); --! read line header
            if read_ok and (line_head = INS_HEAD) then
                pdi_operation_count <= pdi_operation_count + 1;
            end if;
            if read_ok and (line_head = INS_HEAD or line_head = HDR_HEAD or line_head = DAT_HEAD) then
                loop
                    lwc_hread(line_data, word_block, read_ok);
                    if not read_ok then
                        exit;
                    end if;
                    actkey_ins := (line_head = INS_HEAD) and (word_block(W - 1 downto W - 4) = INST_ACTKEY);
                    hash_ins   := (line_head = INS_HEAD) and (word_block(W - 1 downto W - 4) = INST_HASH);
                    for i in 0 to get_stalls(G_PDI_STALLS) - 1 loop
                        pdi_valid <= '0';
                        wait until rising_edge(clk);
                    end loop;
                    if TIMING_MODE and line_head = INS_HEAD and (actkey_ins or hash_ins or op_sent) and timing_started then
                        if not timing_stopped then
                            pdi_valid <= '0';
                            wait until rising_edge(clk) and timing_stopped; -- wait for tb_verify_do process to complete timed operation
                        end if;
                        timing_started <= False; -- ACK receiving timing_stopped = '1' to tb_verify_do process
                    end if;

                    pdi_valid <= '1';
                    pdi_data  <= word_block;
                    wait until rising_edge(clk) and pdi_ready = '1';
                    -- NOTE: should never stall here
                    if TIMING_MODE and line_head = INS_HEAD then
                        op_sent := not actkey_ins and not hash_ins;
                        if not timing_started then
                            start_cycle    <= cycle_counter;
                            timing_started <= True;
                            wait for 0 ns; -- yield to update timing_started signal as there could be no wait before next read
                        end if;
                    end if;
                end loop;
            end if;
        end loop;
        --
        pdi_valid <= '0';
        if timing_started and not timing_stopped then
            wait until timing_stopped;
            timing_started <= False;
        end if;
        wait;                           -- until simulation ends
    end process;

    --===========================================================================================--
    --====================================== SDI Stimulus =======================================--
    tb_read_sdi : process
        variable line_data  : LINE;
        variable word_block : std_logic_vector(SW_S - 1 downto 0);
        variable read_ok    : boolean;
        variable line_head  : string(1 to 6);
    begin
        wait until reset_done;
        wait until rising_edge(clk);
        if TRUE then                    -- set to FALSE if sdi is not used (i.e., hash)
            file_open(sdi_file, G_FNAME_SDI, READ_MODE);

            while not endfile(sdi_file) loop
                readline(sdi_file, line_data);
                read(line_data, line_head, read_ok);
                if read_ok and (line_head = INS_HEAD or line_head = HDR_HEAD or line_head = DAT_HEAD) then
                    loop
                        lwc_hread(line_data, word_block, read_ok);
                        if not read_ok then
                            exit;
                        end if;
                        if TIMING_MODE and not timing_started then
                            sdi_valid <= '0';
                            wait until timing_started;
                        end if;
                        for i in 0 to get_stalls(G_SDI_STALLS) - 1 loop
                            sdi_valid <= '0';
                            wait until rising_edge(clk);
                        end loop;
                        sdi_valid <= '1';
                        sdi_data  <= word_block;
                        wait until rising_edge(clk) and sdi_ready = '1';
                    end loop;
                end if;
            end loop;
        end if;
        sdi_valid <= '0';
        wait;                           -- until simulation ends
    end process;

    --===========================================================================================--
    --=================================== DO Verification =======================================--
    tb_verify_do : process
        variable line_no      : integer := 0;
        variable line_data    : LINE;
        variable logMsg       : LINE;
        variable logMsg2      : LINE;
        variable failMsg      : LINE;
        variable tb_block     : std_logic_vector(20 - 1 downto 0);
        variable golden_word  : std_logic_vector(W - 1 downto 0);
        variable read_ok      : boolean;
        variable preamble     : string(1 to 6);
        variable word_count   : integer := 1;
        variable force_exit   : boolean := FALSE;
        variable msgid        : integer;
        variable keyid        : integer;
        variable opcode       : std_logic_vector(3 downto 0);
        variable num_failures : integer := 0;
        variable current_fail : boolean := FALSE;
        variable testcase     : integer := 0;
        variable cycles       : integer;
        variable end_cycle    : natural;
        variable end_time     : TIME;
        variable do_sum       : std_logic_vector(W - 1 downto 0);
    begin
        wait until reset_done;
        wait until rising_edge(clk);
        if TIMING_MODE then
            file_open(timing_file, G_FNAME_TIMING, WRITE_MODE);
        end if;
        file_open(log_file, G_FNAME_LOG, WRITE_MODE);
        while not endfile(do_file) and not force_exit loop
            loop
                if endfile(do_file) then
                    report "Reached the end of " & G_FNAME_DO;
                    read_ok := False;
                    exit;
                end if;
                readline(do_file, line_data);
                line_no := line_no + 1;
                if line_data'length > 0 then
                    read(line_data, preamble, read_ok);
                    if read_ok then
                        exit;
                    end if;
                end if;
            end loop;
            if not read_ok then
                exit;
            end if;
            if preamble = EOF_HEAD then
                report "Reached EOF marker in " & G_FNAME_DO severity note;
                force_exit := True;
                exit;
            elsif preamble = HDR_HEAD or preamble = DAT_HEAD or preamble = STT_HEAD then -- header, data, or status lines
                loop                    -- processing single line
                    lwc_hread(line_data, golden_word, read_ok); -- read the rest of the line to word_block
                    word_count := 1;
                    if not read_ok then
                        exit;
                    end if;
                    for i in 0 to get_stalls(G_DO_STALLS) - 1 loop
                        do_ready <= '0';
                        wait until rising_edge(clk);
                    end loop;
                    if TIMING_MODE and not timing_started then
                        -- stall until timing has started from PDI
                        do_ready       <= '0';
                        timing_stopped <= False;
                        wait until timing_started;
                    end if;
                    do_ready   <= '1';
                    wait until rising_edge(clk) and do_valid = '1';
                    assert preamble /= STT_HEAD or do_last = '1' report "Status word received, but do_last was not '1'" severity error;
                    do_sum     := xor_shares(do_data, PDI_SHARES);
                    if not words_match(do_sum, golden_word) then
                        write(failMsg, string'("Test #") & integer'image(testcase) & " MsgID: " & integer'image(msgid) & " Line: " & integer'image(line_no) & " Word: " & integer'image(word_count));
                        write(failMsg, string'(" Expected: ") & lwc_to_hstring(golden_word) & "   Received: " & lwc_to_hstring(do_data));
                        if PDI_SHARES > 1 then
                            write(failMsg, "   Received sum: " & lwc_to_hstring(do_sum));
                        end if;
                        write(logMsg, string'("[Error] ") & failMsg.all);
                        report LF & logMsg.all & LF severity error;
                        writeline(log_file, logMsg);
                        writeline(failures_file, failMsg);
                        num_failures := num_failures + 1;
                        current_fail := True;
                        if num_failures >= G_MAX_FAILURES then
                            force_exit := True;
                            exit;
                        end if;
                    else
                        write(logMsg, string'("[Log]     Expected: ") & lwc_to_hstring(golden_word) & string'(" Received: ") & lwc_to_hstring(do_data) & string'(" Matched!"));
                        writeline(log_file, logMsg);
                    end if;
                    word_count := word_count + 1;
                    if preamble = STT_HEAD then -- last line of this testcase
                        if current_fail then
                            report " [FAILED] Testcase #" & integer'image(testcase) & " failed!" severity error;
                            current_fail := False;
                        elsif G_VERBOSE_LEVEL > 0 then
                            report " [OK]" severity note;
                        end if;
                        if TIMING_MODE then
                            assert timing_started;
                            cycles         := cycle_counter - start_cycle;
                            timing_stopped <= True;
                            do_ready       <= '0'; -- needed as we wait for de-assertion of timing_started
                            wait until not timing_started;
                            write(logMsg, integer'image(msgid) & "," & integer'image(cycles));
                            writeline(timing_file, logMsg);
                            if G_VERBOSE_LEVEL > 0 then
                                report "[Timing] MsgId: " & integer'image(msgid) & ", cycles: " & integer'image(cycles) severity note;
                            end if;
                        end if;
                    end if;
                end loop;               -- end of this line
            elsif preamble = TB_HEAD then
                current_fail := False;
                testcase     := testcase + 1;
                lwc_hread(line_data, tb_block, read_ok);
                if not read_ok then
                    exit;
                end if;
                opcode       := tb_block(19 downto 16);
                msgid        := to_integer(unsigned(tb_block(7 downto 0)));
                write(logMsg, "Testcase #" & integer'image(testcase) & " MsgID:" & integer'image(testcase) & " Op:");
                if (opcode = INST_HASH) then
                    write(logMsg, string'("HASH"));
                else
                    if opcode = INST_ENC then
                        write(logMsg, string'("ENC"));
                    elsif opcode = INST_DEC then
                        write(logMsg, string'("DEC"));
                    else
                        write(logMsg, string'("UNKNOWN opcode=") & lwc_to_hstring(opcode));
                    end if;
                    keyid := to_integer(unsigned(tb_block(15 downto 8)));
                    write(logMsg, string'(" KeyID:") & integer'image(keyid));
                end if;
                report logMsg.all severity note;
                writeline(log_file, logMsg);
            end if;
        end loop;
        --
        end_cycle  := cycle_counter;
        end_time   := now;
        do_ready   <= '0';
        wait until rising_edge(clk);
        if RW > 0 then
            report "Number of consumed random words: " & integer'image(num_rand_vectors) severity note;
        end if;
        --
        if num_failures > 0 then
            write(logMsg, string'("[FAIL] "));
        else
            write(logMsg, string'("[PASS] "));
        end if;
        file_close(do_file);
        write(logMsg, string'("Simulation completed in ") & integer'image(end_cycle) & " cycles.");
        write(logMsg2, string'(" Simulation time: ") & time'image(end_time));
        writeline(log_file, logMsg2);
        --
        if TIMING_MODE then
            file_close(timing_file);
        end if;
        file_close(log_file);
        --
        if num_failures > 0 then
            write(result_file, "1");
            report LF & LF & logMsg.all & LF severity failure;
        else
            write(result_file, "0");
            report LF & LF & logMsg.all & LF severity note;
        end if;
        file_close(result_file);
        --
        stop_clock <= True;
        -- Do not use a 'failure' to end the simulation.
        -- Simulators usually exit when there are no event scheduled.
        wait;
    end process;

end architecture;
