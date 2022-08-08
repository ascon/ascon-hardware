--===============================================================================================--
--! @file       PreProcessor.vhd
--! @brief      Pre-processor for NIST LWC API
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
--!
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             unrestricted)
---------------------------------------------------------------------------------------------------
--! Description
--!
--! VHDL standard compatibility: 1993, 2002, 2008
--!
--===============================================================================================--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.NIST_LWAPI_pkg.all;
use work.design_pkg.all;

entity PreProcessor is
   port(
      clk             : in  std_logic;
      rst             : in  std_logic;
      --! Public Data input (pdi) ===========================================
      pdi_data        : in  std_logic_vector(PDI_SHARES * W - 1 downto 0);
      pdi_valid       : in  std_logic;
      pdi_ready       : out std_logic;
      --! Secret Data input (sdi) ===========================================
      sdi_data        : in  std_logic_vector(SDI_SHARES * SW - 1 downto 0);
      sdi_valid       : in  std_logic;
      sdi_ready       : out std_logic;
      --! Crypto Core =======================================================
      key_data        : out std_logic_vector(SDI_SHARES * CCSW - 1 downto 0);
      key_valid       : out std_logic;
      key_ready       : in  std_logic;
      --
      key_update      : out std_logic;
      --
      bdi_data        : out std_logic_vector(PDI_SHARES * CCW - 1 downto 0);
      bdi_valid_bytes : out std_logic_vector(CCW / 8 - 1 downto 0);
      bdi_pad_loc     : out std_logic_vector(CCW / 8 - 1 downto 0);
      bdi_size        : out std_logic_vector(2 downto 0);
      bdi_eot         : out std_logic;
      bdi_eoi         : out std_logic;
      bdi_type        : out std_logic_vector(3 downto 0);
      bdi_valid       : out std_logic;
      bdi_ready       : in  std_logic;
      --
      decrypt         : out std_logic;
      hash            : out std_logic;
      ---! Instruction/Header FIFO ==========================================
      cmd_data        : out std_logic_vector(W - 1 downto 0);
      cmd_valid       : out std_logic;
      cmd_ready       : in  std_logic
   );

end entity PreProcessor;

architecture PreProcessor of PreProcessor is
   --======================================== Constants ========================================--
   constant SEGLEN_BITS  : positive := 16;
   constant LOG2_W_DIV_8 : natural  := log2ceil(W / 8);
   constant HDR_LEN_BITS : positive := minimum(W, SEGLEN_BITS);
   constant W_S          : positive := PDI_SHARES * W;
   constant SW_S         : positive := SDI_SHARES * SW;

   --========================================== Types ==========================================--
   type t_state is (S_INST, S_INST_KEY, S_HDR_KEY, S_LD_KEY, S_HDR, S_LD, S_LD_EMPTY);

   --======================================= Registers =========================================--
   signal state                         : t_state; -- FSM state
   signal seglen_counter                : unsigned(SEGLEN_BITS - 1 downto 0);
   signal eoi_flag, eot_flag, last_flag : std_logic;
   signal decrypt_op, hash_op           : boolean;
   signal hdr_type                      : std_logic_vector(bdi_type'range);

   --========================================= Wires ===========================================--
   signal bdi_eoi_p, bdi_eot_p     : std_logic;
   -- for reading 'out' ports in VHDL < 2008
   signal pdi_ready_o, sdi_ready_o : std_logic;
   signal bdi_valid_p, bdi_ready_p : std_logic;
   signal key_valid_p, key_ready_p : std_logic;
   signal bdi_size_p               : std_logic_vector(2 downto 0);
   signal bdi_pad_loc_p            : std_logic_vector(W / 8 - 1 downto 0);
   signal op_is_actkey, op_is_hash : boolean;
   -- If the current PDI input is a part of a segment header, it's the first (last) word of it
   -- NOTE: hdr_first/hdr_last are not always mutually exclusive, e.g. W=32
   signal hdr_first, hdr_last      : boolean;
   signal reading_pdi_hdr          : boolean;
   signal reading_sdi_hdr          : boolean;
   signal pdi_fire, sdi_fire       : boolean; -- fire = valid AND ready
   signal seglen                   : std_logic_vector(SEGLEN_BITS - 1 downto 0);
   signal hdr_seglen               : std_logic_vector(HDR_LEN_BITS - 1 downto 0);
   signal seglen_is_zero           : boolean;
   signal last_flit_of_segment     : boolean;
   signal relay_hdr_to_postproc    : boolean;
   signal bdi_valid_bytes_p        : std_logic_vector(W / 8 - 1 downto 0);
   signal nx_state                 : t_state; -- next FSM state
   signal cur_hdr_last             : std_logic;
   --! for simulation only
   signal received_wrong_header    : boolean;

   --========================================= Aliases =========================================--
   alias pdi_hdr           : std_logic_vector(W - 1 downto 0) is pdi_data(W_S - 1 downto W_S - W);
   alias pdi_hdr_type      : std_logic_vector(3 downto 0) is pdi_hdr(W - 1 downto W - 4);
   alias pdi_hdr_eoi       : std_logic is pdi_hdr(W - 6);
   alias pdi_hdr_eot       : std_logic is pdi_hdr(W - 7);
   alias pdi_hdr_last      : std_logic is pdi_hdr(W - 8);
   alias pdi_hdr_seglen    : std_logic_vector(HDR_LEN_BITS - 1 downto 0) is pdi_hdr(HDR_LEN_BITS - 1 downto 0);
   alias sdi_hdr           : std_logic_vector(W - 1 downto 0) is sdi_data(SW_S - 1 downto SW_S - SW);
   alias sdi_hdr_type      : std_logic_vector(3 downto 0) is sdi_hdr(SW - 1 downto SW - 4);
   alias sdi_hdr_seglen    : std_logic_vector(HDR_LEN_BITS - 1 downto 0) is sdi_hdr(HDR_LEN_BITS - 1 downto 0);
   alias seglen_counter_hi : unsigned(SEGLEN_BITS - LOG2_W_DIV_8 - 1 downto 0) is seglen_counter(SEGLEN_BITS - 1 downto LOG2_W_DIV_8);
   alias seglen_counter_lo : unsigned(LOG2_W_DIV_8 - 1 downto 0) is seglen_counter(LOG2_W_DIV_8 - 1 downto 0);

begin
   --======================================== Instances ========================================--
   keyPISO : entity work.KEY_PISO
      port map(
         clk          => clk,
         rst          => rst,
         -- PISO Input
         data_p       => sdi_data,
         data_valid_p => key_valid_p,
         data_ready_p => key_ready_p,
         -- PISO Output
         data_s       => key_data,
         data_valid_s => key_valid,
         data_ready_s => key_ready
      );

   bdiPISO : entity work.DATA_PISO
      port map(
         clk           => clk,
         rst           => rst,
         -- PISO Input
         data_p        => pdi_data,
         valid_bytes_p => bdi_valid_bytes_p,
         data_size_p   => bdi_size_p,
         pad_loc_p     => bdi_pad_loc_p,
         eot_p         => bdi_eot_p,
         eoi_p         => bdi_eoi_p,
         data_valid_p  => bdi_valid_p,
         data_ready_p  => bdi_ready_p,
         -- PISO Output
         data_s        => bdi_data,
         valid_bytes_s => bdi_valid_bytes,
         data_size_s   => bdi_size,
         pad_loc_s     => bdi_pad_loc,
         eot_s         => bdi_eot,
         eoi_s         => bdi_eoi,
         data_valid_s  => bdi_valid,
         data_ready_s  => bdi_ready
      );

   --===========================================================================================--
   --================================ Width-specific generation ================================--
   W32_GEN : if W = 32 generate
   begin
      hdr_first             <= true;
      hdr_last              <= true;
      cur_hdr_last          <= pdi_hdr_last;
      relay_hdr_to_postproc <= pdi_hdr_type = HDR_PT or pdi_hdr_type = HDR_CT;
   end generate;
   WNOT32_GEN : if W /= 32 generate
      signal pdi_hdr_pt, pdi_hdr_ct             : boolean;
      --============================ Registers ============================--
      signal pdi_hdr_pt_first, pdi_hdr_ct_first : boolean;
      signal hdr_counter                        : unsigned(log2ceil(32 / W) - 1 downto 0);
      --============================== Wires ==============================--
   begin
      pdi_hdr_pt            <= pdi_hdr_type = HDR_PT;
      pdi_hdr_ct            <= pdi_hdr_type = HDR_CT;
      process(clk)
      begin
         if rising_edge(clk) then
            case state is
               when S_INST =>
                  hdr_counter <= (others => '0');
               when others =>
                  if (reading_sdi_hdr and sdi_fire) or (reading_pdi_hdr and pdi_fire) then
                     hdr_counter <= hdr_counter + 1;
                  end if;
                  if hdr_first and pdi_fire then
                     pdi_hdr_pt_first <= pdi_hdr_pt;
                     pdi_hdr_ct_first <= pdi_hdr_ct;
                  end if;
            end case;
         end if;
      end process;
      hdr_first             <= hdr_counter = 0;
      hdr_last              <= hdr_counter = 32 / W - 1;
      cur_hdr_last          <= pdi_hdr_last when hdr_first else last_flag;
      relay_hdr_to_postproc <= pdi_hdr_pt or pdi_hdr_ct when hdr_first else pdi_hdr_pt_first or pdi_hdr_ct_first;
   end generate;
   --
   W8_GEN : if W = 8 generate
      --============================ Registers ============================--
      signal seglen_msb8 : std_logic_vector(7 downto 0);
   begin
      process(clk)
      begin
         if rising_edge(clk) then
            if sdi_fire or pdi_fire then
               seglen_msb8 <= hdr_seglen(7 downto 0);
            end if;
         end if;
      end process;
      seglen <= seglen_msb8 & hdr_seglen(7 downto 0);
   end generate;
   WNOT8_GEN : if W /= 8 generate
      seglen <= hdr_seglen;
   end generate;

   --============================================================================================--
   --! State register is the only register that requires reset
   GEN_SYNC_RST : if not ASYNC_RSTN generate
      process(clk)
      begin
         if rising_edge(clk) then
            if rst = '1' then
               state <= S_INST;
            else
               state <= nx_state;
            end if;
         end if;
      end process;
   end generate GEN_SYNC_RST;
   GEN_ASYNC_RSTN : if ASYNC_RSTN generate
      process(clk, rst)
      begin
         if rst = '0' then
            state <= S_INST;
         elsif rising_edge(clk) then
            state <= nx_state;
         end if;
      end process;
   end generate GEN_ASYNC_RSTN;

   process(clk)
   begin
      if rising_edge(clk) then
         case state is
            when S_INST =>
               hash_op    <= False;
               decrypt_op <= False;
               -- not really required:
               eoi_flag   <= '0';
               eot_flag   <= '0';
               last_flag  <= '0';

               if pdi_fire then
                  if op_is_actkey then
                  elsif op_is_hash then
                     hash_op <= TRUE;
                  else
                     decrypt_op <= pdi_hdr_type(0) = '1';
                  end if;
               end if;

            when S_HDR_KEY =>
               if sdi_fire then
                  if hdr_last then
                     seglen_counter <= unsigned(seglen);
                  end if;
               end if;

            when S_LD_KEY =>
               if sdi_fire then
                  seglen_counter_hi <= seglen_counter_hi - 1;
               end if;

            when S_HDR =>
               if pdi_fire then
                  if hdr_first then
                     eoi_flag  <= pdi_hdr_eoi;
                     eot_flag  <= pdi_hdr_eot;
                     last_flag <= pdi_hdr_last;
                     hdr_type  <= pdi_hdr_type;
                  end if;
                  if hdr_last then
                     seglen_counter <= unsigned(seglen);
                  end if;
               end if;

            when S_LD =>
               if pdi_fire then
                  seglen_counter_hi <= seglen_counter_hi - 1;
               end if;

            when others =>
               null;
         end case;
         --! for simulation only
         -- synthesis translate_off
         assert not received_wrong_header
         report "[PreProcessor] Received unexpected header at state: " & t_state'image(state)
         severity failure;
         -- synthesis translate_on
      end if;
   end process;

   --===========================================================================================--
   last_flit_of_segment <= is_zero(seglen_counter_hi(seglen_counter_hi'length - 1 downto 1)) and --
                           (seglen_counter_hi(0) = '0' or is_zero(seglen_counter_lo));

   -- bdi number of valid bytes as a binary integer
   bdi_size_p <= std_logic_vector(resize(seglen_counter_hi(0) & seglen_counter_lo, bdi_size_p'length)) when last_flit_of_segment else --
                 std_logic_vector(to_unsigned(W / 8, bdi_size_p'length));
   -- bdi padding location
   bdi_pad_loc_p     <= reverse_bits(to_1H(bdi_size_p, bdi_pad_loc_p'length));
   -- bdi valid bytes
   bdi_valid_bytes_p <= reverse_bits(std_logic_vector(unsigned(reverse_bits(bdi_pad_loc_p)) - 1));

   pdi_fire  <= pdi_valid = '1' and pdi_ready_o = '1';
   sdi_fire  <= sdi_valid = '1' and sdi_ready_o = '1';
   bdi_eoi_p <= eoi_flag and to_std_logic(last_flit_of_segment);
   bdi_eot_p <= eot_flag and to_std_logic(last_flit_of_segment);

   op_is_actkey   <= pdi_hdr_type = INST_ACTKEY;
   op_is_hash     <= pdi_hdr_type(3) = '1'; -- INST_HASH
   hdr_seglen     <= sdi_hdr_seglen when reading_sdi_hdr else pdi_hdr_seglen;
   seglen_is_zero <= is_zero(seglen);

   decrypt   <= to_std_logic(decrypt_op);
   hash      <= to_std_logic(hash_op);
   pdi_ready <= pdi_ready_o;
   sdi_ready <= sdi_ready_o;
   cmd_data  <= pdi_hdr;
   bdi_type  <= hdr_type;

   --===========================================================================================--
   --= When using VHDL 2008+ change to
   -- process(all)
   process(state, pdi_valid, pdi_fire, sdi_hdr, sdi_valid, sdi_fire, key_ready_p, --
      last_flit_of_segment, cmd_ready, bdi_ready_p, reading_pdi_hdr, reading_sdi_hdr, pdi_hdr, --
      seglen_is_zero, hdr_first, hdr_last, op_is_actkey, last_flag, hash_op, cur_hdr_last, --
      relay_hdr_to_postproc)
   begin
      -- Default Values
      sdi_ready_o           <= to_std_logic(reading_sdi_hdr);
      pdi_ready_o           <= to_std_logic(reading_pdi_hdr);
      key_valid_p           <= '0';
      key_update            <= '0';
      bdi_valid_p           <= '0';
      cmd_valid             <= '0';
      reading_pdi_hdr       <= false;
      reading_sdi_hdr       <= false;
      -- default input of registers: feedback of their current values
      nx_state              <= state;
      -- for simulation only
      received_wrong_header <= false;

      -- TODO: Parallel key loading not currently supported
      case state is
         -- receive PDI instruction
         when S_INST =>
            cmd_valid   <= pdi_valid and not to_std_logic(op_is_actkey);
            pdi_ready_o <= cmd_ready or to_std_logic(op_is_actkey);

            if pdi_fire then
               if op_is_actkey then
                  nx_state <= S_INST_KEY;
               else
                  nx_state <= S_HDR;
               end if;
            end if;

         -- receive SDI instruction
         when S_INST_KEY =>
            sdi_ready_o <= '1';
            if sdi_fire then
               received_wrong_header <= sdi_hdr_type /= INST_LDKEY;
               nx_state              <= S_HDR_KEY;
            end if;

         -- receive key header from SDI
         when S_HDR_KEY =>
            reading_sdi_hdr <= true;
            if sdi_fire then
               if hdr_first then
                  received_wrong_header <= sdi_hdr_type /= HDR_KEY;
               end if;
               if hdr_last then
                  nx_state <= S_LD_KEY;
               end if;
            end if;

         -- receive key data from SDI
         when S_LD_KEY =>
            sdi_ready_o <= key_ready_p;
            key_valid_p <= sdi_valid;
            key_update  <= '1';
            if sdi_fire then
               if last_flit_of_segment then
                  nx_state <= S_INST;
               end if;
            end if;

         -- Read segment header
         when S_HDR =>
            reading_pdi_hdr <= true;
            if relay_hdr_to_postproc then
               pdi_ready_o <= cmd_ready;
               cmd_valid   <= pdi_valid;
            end if;
            if pdi_fire then

               if hdr_last then
                  if seglen_is_zero then -- empty segment
                     if hash_op then
                        nx_state <= S_LD_EMPTY;
                     elsif cur_hdr_last = '1' then
                        nx_state <= S_INST;
                     else
                        nx_state <= S_HDR;
                     end if;
                  else
                     nx_state <= S_LD;
                  end if;
               end if;
            end if;

         -- Read segment data
         when S_LD =>
            pdi_ready_o <= bdi_ready_p;
            bdi_valid_p <= pdi_valid;
            if pdi_fire and last_flit_of_segment then
               if last_flag = '1' then
                  nx_state <= S_INST;
               else
                  nx_state <= S_HDR;
               end if;
            end if;

         -- An empty word is sent to CryptoCore
         when S_LD_EMPTY =>
            bdi_valid_p <= '1';
            if bdi_ready_p = '1' then
               if last_flag = '1' then  -- generalize
                  nx_state <= S_INST;
               else
                  nx_state <= S_HDR;
               end if;
            end if;

      end case;
   end process;

end PreProcessor;
