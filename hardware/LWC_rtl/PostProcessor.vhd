--===============================================================================================--
--! @file       PostProcessor.vhd
--! @brief      Post-processor for NIST LWC API
--!
--! @author     Michael Tempelmeier
--! @copyright  Copyright (c) 2019 Chair of Security in Information Technology
--!             ECE Department, Technical University of Munich, GERMANY
--!
--! @author     Farnoud Farahmand
--! @copyright  Copyright (c) 2019 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--!
--! @author     Kamyar Mohajerani
--! @copyright  Copyright (c) 2022 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--!
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             unrestricted)
--!
---------------------------------------------------------------------------------------------------
--! Description
--! bdo_type is not used at the moment.
--!
--! VHDL standard compatibility: 1993, 2002, 2008
--!
--===============================================================================================--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.NIST_LWAPI_pkg.all;
use work.design_pkg.all;

entity PostProcessor is
   port(
      clk             : in  std_logic;
      rst             : in  std_logic;
      --! Crypto Core =======================================================
      bdo_data        : in  std_logic_vector(PDI_SHARES * CCW - 1 downto 0);
      bdo_valid_bytes : in  std_logic_vector(CCW / 8 - 1 downto 0);
      bdo_last        : in  std_logic;
      bdo_type        : in  std_logic_vector(3 downto 0); -- not used ATM
      bdo_valid       : in  std_logic;
      bdo_ready       : out std_logic;
      --
      auth_success    : in  std_logic;
      auth_valid      : in  std_logic;
      auth_ready      : out std_logic;
      ---! Instruction/Header FIFO ==========================================
      cmd_data        : in  std_logic_vector(W - 1 downto 0);
      cmd_valid       : in  std_logic;
      cmd_ready       : out std_logic;
      --! Data Output (DO) ==================================================
      do_data         : out std_logic_vector(PDI_SHARES * W - 1 downto 0);
      do_last         : out std_logic;
      do_valid        : out std_logic;
      do_ready        : in  std_logic
   );

end PostProcessor;

architecture RTL of PostProcessor is
   --======================================== Constants ========================================--
   constant SEGLEN_BITS  : positive := 16;
   constant LOG2_W_DIV_8 : natural  := log2ceil(W / 8);
   constant HDR_LEN_BITS : positive := minimum(W, SEGLEN_BITS);
   constant DIGEST_BYTES : integer  := HASH_VALUE_SIZE / 8;
   constant TAG_BYTES    : integer  := TAG_SIZE / 8;

   --========================================== Types ==========================================--
   type t_state is (S_INIT, S_HDR_DIGEST, S_OUT_DIGEST, S_HDR_MSG, S_OUT_MSG,
                    S_HDR_TAG, S_OUT_TAG, S_VERIFY_TAG, S_STATUS);

   --======================================== Registers ========================================--
   -- FSM state
   signal state                                  : t_state;
   -- flags
   signal eot_flag, decrypt_flag, status_success : std_logic;
   signal seglen_counter                         : unsigned(SEGLEN_BITS - 1 downto 0);

   --========================================== Wires ==========================================--
   -- next state
   signal nx_state                               : t_state;
   -- PRE VHDL-2008 COMPATIBILITY: readable temporaries assigned to output ports
   signal cmd_ready_o, do_valid_o                : std_logic;
   signal bdo_cleared                            : std_logic_vector(PDI_SHARES * CCW - 1 downto 0);
   signal bdo_valid_p, bdo_ready_p, bdo_last_p   : std_logic;
   signal bdo_data_p                             : std_logic_vector(PDI_SHARES * W - 1 downto 0);
   signal seglen                                 : std_logic_vector(SEGLEN_BITS - 1 downto 0);
   signal nx_decrypt, nx_eot                     : std_logic;
   -- current header seglen part (8 bits for W=8) is zero
   -- full header seglen is zero 
   signal seglen_is_zero                         : boolean;
   -- x_fire := x_valid AND x_ready
   signal do_fire, cmd_fire, bdo_p_fire          : boolean;
   signal op_is_hash, op_is_decrypt              : boolean;
   signal reset_hdr_counter, hdr_first, hdr_last : boolean;
   signal sending_hdr                            : boolean;
   signal last_flit_of_segment                   : boolean;

   --========================================= Aliases =========================================--
   alias cmd_hdr_opcode    : std_logic_vector(3 downto 0) is cmd_data(W - 1 downto W - 4);
   alias cmd_hdr_seglen    : std_logic_vector(HDR_LEN_BITS - 1 downto 0) is cmd_data(HDR_LEN_BITS - 1 downto 0);
   alias cmd_hdr_eot       : std_logic is cmd_data(W - 7);
   alias do_hdr            : std_logic_vector(W - 1 downto 0) is do_data(do_data'length - 1 downto do_data'length - W);
   alias do_hdr_opcode     : std_logic_vector(3 downto 0) is do_hdr(W - 1 downto W - 4);
   alias do_hdr_eot        : std_logic is do_hdr(W - 7);
   alias do_hdr_last       : std_logic is do_hdr(W - 8);
   -- alias do_hdr_seglen  : std_logic_vector(HDR_LEN_BITS - 1 downto 0) is do_hdr(HDR_LEN_BITS - 1 downto 0);
   alias do_hdr_seglen     : std_logic_vector(HDR_LEN_BITS - 1 downto 0) is do_data(do_data'length - W + HDR_LEN_BITS - 1 downto do_data'length - W);
   alias seglen_counter_hi : unsigned(SEGLEN_BITS - LOG2_W_DIV_8 - 1 downto 0) is seglen_counter(SEGLEN_BITS - 1 downto LOG2_W_DIV_8);
   alias seglen_counter_lo : unsigned(LOG2_W_DIV_8 - 1 downto 0) is seglen_counter(LOG2_W_DIV_8 - 1 downto 0);

begin
   -- optimized out if CCW=W
   bdoSIPO : entity work.DATA_SIPO
      port map(
         clk          => clk,
         rst          => rst,
         -- serial input (CCW)
         data_s       => bdo_cleared,
         end_of_input => bdo_last,
         data_valid_s => bdo_valid,
         data_ready_s => bdo_ready,
         -- parallel output (W)
         data_p       => bdo_data_p,
         data_valid_p => bdo_valid_p,
         data_ready_p => bdo_ready_p
      );

   --===========================================================================================--
   --================================ Width-specific generation ================================--
   W32_GEN : if W = 32 generate
   begin
      hdr_first <= true;
      hdr_last  <= true;
   end generate;
   WNOT32_GEN : if W /= 32 generate
      --============================== Wires ==============================--
      signal hdr_counter : unsigned(log2ceil(32 / W) - 1 downto 0);
   begin
      process(clk)
      begin
         if rising_edge(clk) then
            if reset_hdr_counter then
               hdr_counter <= (others => '0');
            elsif sending_hdr and do_fire then
               hdr_counter <= hdr_counter + 1;
            end if;

         end if;
      end process;
      hdr_first <= hdr_counter = 0;
      hdr_last  <= hdr_counter = 32 / W - 1;
   end generate;
   W8_GEN : if W = 8 generate
      --============================ Registers ============================--
      signal seglen_msb8 : std_logic_vector(7 downto 0);
      --============================= Aliases =============================--
      alias hdr_seglen   : std_logic_vector(7 downto 0) is cmd_hdr_seglen(7 downto 0);
   begin
      process(clk)
      begin
         if rising_edge(clk) then
            if cmd_fire then
               seglen_msb8 <= hdr_seglen;
            end if;
         end if;
      end process;
      seglen <= seglen_msb8 & hdr_seglen;
   end generate;
   WNOT8_GEN : if W /= 8 generate
      seglen <= cmd_hdr_seglen;
   end generate;

   --===========================================================================================--
   --===================================== register updates ====================================--
   --! State register is the only register that requires reset
   -- synchronous reset with positive polarity (active high)
   GEN_SYNC_RST : if not ASYNC_RSTN generate
      process(clk)
      begin
         if rising_edge(clk) then
            if rst = '1' then
               state <= S_INIT;
            else
               state <= nx_state;
            end if;
         end if;
      end process;
   end generate GEN_SYNC_RST;
   -- asynchronous reset with negative polarity (active low)
   GEN_ASYNC_RSTN : if ASYNC_RSTN generate
      process(clk, rst)
      begin
         if rst = '0' then
            state <= S_INIT;
         elsif rising_edge(clk) then
            state <= nx_state;
         end if;
      end process;
   end generate GEN_ASYNC_RSTN;

   process(clk)
   begin
      if rising_edge(clk) then
         eot_flag     <= nx_eot;
         decrypt_flag <= nx_decrypt;
         case state is
            when S_INIT =>
               status_success <= '1';
            when S_HDR_MSG =>
               if cmd_fire and hdr_last then
                  seglen_counter <= unsigned(seglen);
               end if;
            when S_HDR_TAG =>
               if hdr_last then
                  seglen_counter <= to_unsigned(TAG_BYTES, seglen_counter'length);
               end if;
            when S_OUT_MSG | S_OUT_TAG =>
               if do_fire then
                  seglen_counter_hi <= seglen_counter_hi - 1;
               end if;
            when S_VERIFY_TAG =>
               if auth_valid = '1' then
                  status_success <= auth_success;
               end if;
            when others =>
               null;
         end case;
      end if;
   end process;

   --===========================================================================================--
   do_fire              <= do_valid_o = '1' and do_ready = '1';
   cmd_fire             <= cmd_valid = '1' and cmd_ready_o = '1';
   bdo_p_fire           <= bdo_valid_p = '1' and bdo_ready_p = '1';
   -- set non-valid bytes to zero
   bdo_cleared          <= clear_invalid_bytes(bdo_data, bdo_valid_bytes);
   -- TODO avoid recomparison to zero by including a seglen_is_zero in cmd from PreProcessor
   -- NOTE: The following optimization needs to be changed if other operations are added
   -- possibilities: INST_HASH ("1000"), INST_DEC  ("0011"), or INST_DEC ("0010")
   op_is_hash           <= cmd_hdr_opcode(3) = '1'; -- INST_HASH
   op_is_decrypt        <= cmd_hdr_opcode(0) = '1'; -- INST_DEC
   -- temporary outputs
   do_valid             <= do_valid_o;
   cmd_ready            <= cmd_ready_o;
   seglen_is_zero       <= is_zero(seglen);
   last_flit_of_segment <= is_zero(seglen_counter_hi(seglen_counter_hi'length - 1 downto 1)) and --
                           (seglen_counter_hi(0) = '0' or is_zero(seglen_counter_lo));

   -- needs no delay as our last serial_in element is also the last parallel_out element ???
   -- TODO not true for a generic PISO as the input could be stored and out_fire happens after in_fire
   -- works for current DATA_SIPO implementation as it directly passes the last input fragment
   bdo_last_p <= bdo_last;

   --===========================================================================================--
   --= When using VHDL 2008+ change to
   -- process(all)
   process(state, op_is_hash, op_is_decrypt, do_ready, do_fire, decrypt_flag, seglen_is_zero, --
      eot_flag, cmd_valid, cmd_fire, hdr_first, hdr_last, auth_valid, status_success, --
      cmd_hdr_opcode, bdo_valid_p, bdo_data_p, bdo_p_fire, bdo_last_p, seglen, last_flit_of_segment)
   begin
      -- make sure we do not output intermediate data
      do_data           <= (others => '0');
      do_last           <= '0';
      do_valid_o        <= '0';
      bdo_ready_p       <= '0';
      auth_ready        <= '0';
      -- Header-FIFO
      cmd_ready_o       <= '0';
      sending_hdr       <= false;
      reset_hdr_counter <= false;
      -- default input of registers: feedback of their current values
      -- bad good coding style, but used to avoid duplicate state transition code for ASYNC_RSTN
      nx_state          <= state;
      nx_decrypt        <= decrypt_flag;
      nx_eot            <= eot_flag;

      case state is
         -- initial state
         when S_INIT =>
            reset_hdr_counter <= true;
            cmd_ready_o       <= '1';
            nx_decrypt        <= to_std_logic(op_is_decrypt);
            if cmd_fire then
               if op_is_hash then
                  nx_state <= S_HDR_DIGEST;
               else
                  nx_state <= S_HDR_MSG;
               end if;
            end if;

         -- CT/PT header
         when S_HDR_MSG =>
            sending_hdr <= true;
            cmd_ready_o <= do_ready;
            do_valid_o  <= cmd_valid;
            if hdr_first then
               nx_eot     <= cmd_hdr_eot;
               do_hdr_eot <= cmd_hdr_eot;
               if decrypt_flag = '1' then
                  -- output is plaintext
                  do_hdr_opcode <= HDR_PT;
                  -- if EOT=1 then last=1 as no TAG is sent after decryption.
                  do_hdr_last   <= cmd_hdr_eot;
               else
                  -- output is ciphertext
                  do_hdr_opcode <= HDR_CT;
                  -- last=0 as we will send a TAG afterwards
               end if;
               --  EOI=0 for output data (default do_data)
            end if;
            if hdr_last or not hdr_first then -- hdr_1 or hdr_2 or hdr_last
               -- W=8 && hdr_1      -> relay the 'reserved' byte
               -- hdr_2 || hdr_last -> relay seglen
               do_hdr_seglen <= cmd_hdr_seglen;
            end if;
            if cmd_fire and hdr_last then -- cmd_fire = do_fire
               if seglen_is_zero then
                  if decrypt_flag = '1' then
                     nx_state <= S_VERIFY_TAG;
                  else
                     nx_state <= S_HDR_TAG;
                  end if;
               else
                  nx_state <= S_OUT_MSG;
               end if;
            end if;

         -- relay CT/PT
         when S_OUT_MSG =>
            bdo_ready_p <= do_ready;
            do_valid_o  <= bdo_valid_p;
            do_data     <= bdo_data_p;
            if do_fire and last_flit_of_segment then
               if eot_flag = '1' then
                  if decrypt_flag = '1' then
                     nx_state <= S_VERIFY_TAG;
                  else
                     nx_state <= S_HDR_TAG;
                  end if;
               else
                  nx_state <= S_HDR_MSG;
               end if;
            end if;

         -- TAG header
         when S_HDR_TAG =>
            sending_hdr <= true;
            do_valid_o  <= '1';
            if hdr_first then
               do_hdr_opcode <= HDR_TAG;
               do_hdr_eot    <= '1';
               do_hdr_last   <= '1';
            end if;
            -- W=8, hdr_2 -> 0 as for TAG MSBs(seglen)=0
            if hdr_last then
               do_hdr_seglen <= std_logic_vector(to_unsigned(TAG_BYTES, HDR_LEN_BITS));
               if do_fire then
                  nx_state <= S_OUT_TAG;
               end if;
            end if;

         -- relay tag
         when S_OUT_TAG =>
            bdo_ready_p <= do_ready;
            do_valid_o  <= bdo_valid_p;
            do_data     <= bdo_data_p;
            if do_fire and last_flit_of_segment then
               if eot_flag = '1' then
                  nx_state <= S_STATUS;
               end if;
            end if;

         -- authentication done in CryptoCore
         when S_VERIFY_TAG =>
            auth_ready <= '1';
            if auth_valid = '1' then
               nx_state <= S_STATUS;
            end if;

         -- Hash header
         when S_HDR_DIGEST =>
            sending_hdr <= true;
            do_valid_o  <= '1';
            if hdr_first then
               do_hdr_opcode <= HDR_HASH_VALUE;
               do_hdr_eot    <= '1';
               do_hdr_last   <= '1';
            end if;
            if hdr_last then
               do_hdr_seglen <= std_logic_vector(to_unsigned(DIGEST_BYTES, HDR_LEN_BITS));
               if do_fire then
                  nx_state <= S_OUT_DIGEST;
               end if;
            end if;

         -- relay Hash digest data
         when S_OUT_DIGEST =>
            bdo_ready_p <= do_ready;
            do_valid_o  <= bdo_valid_p;
            do_data     <= bdo_data_p;
            if bdo_p_fire and bdo_last_p = '1' then
               nx_state <= S_STATUS;
            end if;

         -- send out status
         when S_STATUS =>
            do_valid_o <= '1';
            do_last    <= '1';
            if status_success = '1' then
               do_hdr_opcode <= INST_SUCCESS;
            else
               do_hdr_opcode <= INST_FAILURE;
            end if;
            if do_fire then
               nx_state <= S_INIT;
            end if;
      end case;
   end process;

end architecture RTL;
