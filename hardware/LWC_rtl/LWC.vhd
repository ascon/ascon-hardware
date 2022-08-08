--===============================================================================================--
--! @file       LWC.vhd (CAESAR API for Lightweight)
--!
--! @brief      LWC top level file
--!
--! @author     Panasayya Yalla
--!             Ekawat (ice) Homsirikamol
--!             Kamyar Mohajerani
--!
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
--!             TOP-level RTL module of an LWC implementation
--!
--!                               .------------.
--!                            .->| HeaderFifo |--.
--!          .--------------.  |  '------------'  |  .---------------.
--!          |              |--'                  '->|               |
--!    PDI-->|              |     .------------.     |               |  .----.
--!          | PreProcessor |---->|            |     | PostProcessor |--|FIFO|->DO
--!    SDI-->|              |     | CryptoCore |---->|               |  '----'
--!          |              |---->|            |     |               | optional
--!          '--------------'     '------------'     '---------------'
--!
--!
--!           The optional (but recommended) output (DO) FIFO serves to ease timing closure and
--!                to prevent any glitch-induced leakage of the internal state.
--!           It is enabled if G_DO_FIFO_DEPTH is greater than 0.
--!
--===============================================================================================--

library ieee;
use ieee.std_logic_1164.all;

use work.design_pkg.all;
use work.NIST_LWAPI_pkg.all;

--*** SCA ***--
--/+
-- entity LWC_SCA is
--/-
entity LWC is
    generic(
        G_DO_FIFO_DEPTH : natural := 1  -- 0: disable output FIFO, 1 or 2 (elastic FIFO)
    );
    port(
        --! Global ports
        clk       : in  std_logic;
        rst       : in  std_logic;
        --! Public data input
        pdi_data  : in  std_logic_vector(PDI_SHARES * W - 1 downto 0);
        pdi_valid : in  std_logic;
        pdi_ready : out std_logic;
        --! Secret data input
        sdi_data  : in  std_logic_vector(SDI_SHARES * SW - 1 downto 0);
        sdi_valid : in  std_logic;
        sdi_ready : out std_logic;
        --! Data out ports
        do_data   : out std_logic_vector(PDI_SHARES * W - 1 downto 0);
        do_last   : out std_logic;
        do_valid  : out std_logic;
        do_ready  : in  std_logic
        --! Random Input
--        ;
--        rdi_data  : in  std_logic_vector(RW - 1 downto 0);
--        rdi_valid : in  std_logic;
--        rdi_ready : out std_logic
    );
end entity;

--/+
-- architecture structure of LWC_SCA is
--/-
architecture structure of LWC is
    ------!Pre-Processor to CryptoCore (Key PISO)
    signal key_cipher_in              : std_logic_vector(SDI_SHARES * CCSW - 1 downto 0);
    signal key_valid_cipher_in        : std_logic;
    signal key_ready_cipher_in        : std_logic;
    ------!Pre-Processor to CryptoCore (DATA PISO)
    signal bdi_cipher_in              : std_logic_vector(PDI_SHARES * CCW - 1 downto 0);
    signal bdi_valid_cipher_in        : std_logic;
    signal bdi_ready_cipher_in        : std_logic;
    --
    signal bdi_pad_loc_cipher_in      : std_logic_vector(CCW / 8 - 1 downto 0);
    signal bdi_valid_bytes_cipher_in  : std_logic_vector(CCW / 8 - 1 downto 0);
    signal bdi_size_cipher_in         : std_logic_vector(3 - 1 downto 0);
    signal bdi_eot_cipher_in          : std_logic;
    signal bdi_eoi_cipher_in          : std_logic;
    signal bdi_type_cipher_in         : std_logic_vector(4 - 1 downto 0);
    signal decrypt_cipher_in          : std_logic;
    signal hash_cipher_in             : std_logic;
    signal key_update_cipher_in       : std_logic;
    ------!CryptoCore(DATA SIPO) to Post-Processor
    signal bdo_cipher_out             : std_logic_vector(PDI_SHARES * CCW - 1 downto 0);
    signal bdo_valid_cipher_out       : std_logic;
    signal bdo_ready_cipher_out       : std_logic;
    ------!CryptoCore to Post-Processor
    signal bdo_last_cipher_out        : std_logic;
    signal bdo_valid_bytes_cipher_out : std_logic_vector(CCW / 8 - 1 downto 0);
    signal bdo_type_cipher_out        : std_logic_vector(4 - 1 downto 0);
    signal msg_auth_valid             : std_logic;
    signal msg_auth_ready             : std_logic;
    signal msg_auth                   : std_logic;
    ------!Pre-Processor to FIFO
    signal cmd_FIFO_in                : std_logic_vector(W - 1 downto 0);
    signal cmd_valid_FIFO_in          : std_logic;
    signal cmd_ready_FIFO_in          : std_logic;
    ------!FIFO to Post_Processor
    signal cmd_FIFO_out               : std_logic_vector(W - 1 downto 0);
    signal cmd_valid_FIFO_out         : std_logic;
    signal cmd_ready_FIFO_out         : std_logic;
    ------! Optional output FIFO
    signal do_fifo_in_valid           : std_logic;
    signal do_fifo_in_ready           : std_logic;
    signal do_fifo_in_data            : std_logic_vector(do_data'length - 1 downto 0);
    signal do_fifo_in_last            : std_logic;
    signal do_fifo_in, do_fifo_out    : std_logic_vector(do_data'length downto 0); -- data + last

    --============================================ Component Declarations ===========================================--
    --/+
    -- component CryptoCore_SCA
    --/-
    component CryptoCore
        port(
            clk             : in  std_logic;
            rst             : in  std_logic;
            key             : in  std_logic_vector(SDI_SHARES * CCSW - 1 downto 0);
            key_valid       : in  std_logic;
            key_ready       : out std_logic;
            --
            key_update      : in  std_logic;
            --
            bdi             : in  std_logic_vector(PDI_SHARES * CCW - 1 downto 0);
            bdi_valid       : in  std_logic;
            bdi_ready       : out std_logic;
            bdi_pad_loc     : in  std_logic_vector(CCW / 8 - 1 downto 0);
            bdi_valid_bytes : in  std_logic_vector(CCW / 8 - 1 downto 0);
            bdi_size        : in  std_logic_vector(3 - 1 downto 0);
            bdi_eot         : in  std_logic;
            bdi_eoi         : in  std_logic;
            bdi_type        : in  std_logic_vector(4 - 1 downto 0);
            --
            decrypt_in      : in  std_logic;
            hash_in         : in  std_logic;
            --
            bdo             : out std_logic_vector(PDI_SHARES * CCW - 1 downto 0);
            bdo_valid       : out std_logic;
            bdo_ready       : in  std_logic;
            bdo_type        : out std_logic_vector(4 - 1 downto 0);
            bdo_valid_bytes : out std_logic_vector(CCW / 8 - 1 downto 0);
            -- The last word of BDO of the currect outout type (i.e., "bdo_eot")
            end_of_block    : out std_logic;
            --
            msg_auth_valid  : out std_logic;
            msg_auth_ready  : in  std_logic;
            msg_auth        : out std_logic
            --! Random Input
--            ;
--             rdi             : in  std_logic_vector(CCRW - 1 downto 0);
--             rdi_valid       : in  std_logic;
--             rdi_ready       : out std_logic
        );
    end component;

begin
    -- synthesis translate_off
    assert false report "[LWC]" & LF & "  GW=" & integer'image(W) & "  SW=" & --
    integer'image(SW) & LF & "  CCW=" & integer'image(CCW) & " CCSW=" & integer'image(CCSW) --
    severity note;
    -- synthesis translate_on

    -- The following combinations (W, CCW) are supported in the current version
    -- of the Development Package: (32, 32), (32, 16), (32, 8), (16, 16), and (8, 8).
    -- The following combinations (SW, CCSW) are supported: (32, 32), (32, 16),
    -- (32, 8), (16, 16), and (8, 8). In addition, W and SW must be always the same.

    assert ((W = 32 and (CCW = 32 or CCW = 16 or CCW = 8)) or (W = 16 and CCW = 16) or (W = 8 and CCW = 8))
    report "[LWC] Invalid combination of (G_W, CCW)" severity failure;
    --
    assert ((SW = 32 and (CCSW = 32 or CCSW = 16 or CCSW = 8)) or (SW = 16 and CCSW = 16) or (SW = 8 and CCSW = 8))
    report "[LWC] Invalid combination of (SW, CCSW)" severity failure;
    --
    assert W = SW report "[LWC] SW /= W" severity failure;

    -- ASYNC_RSTN notification
    assert not ASYNC_RSTN report "[LWC] ASYNC_RSTN=True: reset is configured as asynchronous and active-low" severity note;

    --/-
    assert PDI_SHARES = 1 and SDI_SHARES = 1 report "For non-protected LWC instance PDI/SDI_SHARES should be 1" severity failure;

    Inst_PreProcessor : entity work.PreProcessor
        port map(
            clk             => clk,
            rst             => rst,
            --
            pdi_data        => pdi_data,
            pdi_valid       => pdi_valid,
            pdi_ready       => pdi_ready,
            --
            sdi_data        => sdi_data,
            sdi_valid       => sdi_valid,
            sdi_ready       => sdi_ready,
            --
            key_data        => key_cipher_in,
            key_valid       => key_valid_cipher_in,
            key_ready       => key_ready_cipher_in,
            --
            key_update      => key_update_cipher_in,
            --
            bdi_data        => bdi_cipher_in,
            bdi_valid_bytes => bdi_valid_bytes_cipher_in,
            bdi_pad_loc     => bdi_pad_loc_cipher_in,
            bdi_size        => bdi_size_cipher_in,
            bdi_eot         => bdi_eot_cipher_in,
            bdi_eoi         => bdi_eoi_cipher_in,
            bdi_type        => bdi_type_cipher_in,
            bdi_valid       => bdi_valid_cipher_in,
            bdi_ready       => bdi_ready_cipher_in,
            --
            decrypt         => decrypt_cipher_in,
            hash            => hash_cipher_in,
            --
            cmd_data        => cmd_FIFO_in,
            cmd_valid       => cmd_valid_FIFO_in,
            cmd_ready       => cmd_ready_FIFO_in
        );
    --/+
    -- Inst_CryptoCore : CryptoCore_SCA
    --/-
    Inst_CryptoCore : CryptoCore
        port map(
            clk             => clk,
            rst             => rst,
            key             => key_cipher_in,
            key_valid       => key_valid_cipher_in,
            key_ready       => key_ready_cipher_in,
            bdi             => bdi_cipher_in,
            bdi_valid       => bdi_valid_cipher_in,
            bdi_ready       => bdi_ready_cipher_in,
            bdi_pad_loc     => bdi_pad_loc_cipher_in,
            bdi_valid_bytes => bdi_valid_bytes_cipher_in,
            bdi_size        => bdi_size_cipher_in,
            bdi_eot         => bdi_eot_cipher_in,
            bdi_eoi         => bdi_eoi_cipher_in,
            bdi_type        => bdi_type_cipher_in,
            decrypt_in      => decrypt_cipher_in,
            key_update      => key_update_cipher_in,
            hash_in         => hash_cipher_in,
            bdo             => bdo_cipher_out,
            bdo_valid       => bdo_valid_cipher_out,
            bdo_ready       => bdo_ready_cipher_out,
            bdo_type        => bdo_type_cipher_out,
            bdo_valid_bytes => bdo_valid_bytes_cipher_out,
            end_of_block    => bdo_last_cipher_out,
            msg_auth_valid  => msg_auth_valid,
            msg_auth_ready  => msg_auth_ready,
            msg_auth        => msg_auth
            --/++++
--             ,
--             rdi             => rdi_data,
--             rdi_valid       => rdi_valid,
--             rdi_ready       => rdi_ready
        );

    Inst_PostProcessor : entity work.PostProcessor
        port map(
            clk             => clk,
            rst             => rst,
            bdo_data        => bdo_cipher_out,
            bdo_valid_bytes => bdo_valid_bytes_cipher_out,
            bdo_last        => bdo_last_cipher_out,
            bdo_type        => bdo_type_cipher_out,
            bdo_valid       => bdo_valid_cipher_out,
            bdo_ready       => bdo_ready_cipher_out,
            auth_success    => msg_auth,
            auth_valid      => msg_auth_valid,
            auth_ready      => msg_auth_ready,
            cmd_data        => cmd_FIFO_out,
            cmd_valid       => cmd_valid_FIFO_out,
            cmd_ready       => cmd_ready_FIFO_out,
            do_data         => do_fifo_in_data,
            do_last         => do_fifo_in_last,
            do_valid        => do_fifo_in_valid,
            do_ready        => do_fifo_in_ready
        );

    Inst_HeaderFifo : entity work.FIFO
        generic map(
            G_W     => W,
            G_DEPTH => 1
        )
        port map(
            clk        => clk,
            rst        => rst,
            din        => cmd_FIFO_in,
            din_valid  => cmd_valid_FIFO_in,
            din_ready  => cmd_ready_FIFO_in,
            dout       => cmd_FIFO_out,
            dout_valid => cmd_valid_FIFO_out,
            dout_ready => cmd_ready_FIFO_out
        );

    Inst_DoutFifo : entity work.FIFO
        generic map(
            G_W         => (do_data'length + 1),
            G_DEPTH     => G_DO_FIFO_DEPTH,
            G_ELASTIC_2 => TRUE
        )
        port map(
            clk        => clk,
            rst        => rst,
            din        => do_fifo_in,
            din_valid  => do_fifo_in_valid,
            din_ready  => do_fifo_in_ready,
            dout       => do_fifo_out,
            dout_valid => do_valid,
            dout_ready => do_ready
        );

    do_fifo_in <= do_fifo_in_last & do_fifo_in_data;
    do_data    <= do_fifo_out(do_data'length - 1 downto 0);
    do_last    <= do_fifo_out(do_data'length);

end architecture;
--***********--