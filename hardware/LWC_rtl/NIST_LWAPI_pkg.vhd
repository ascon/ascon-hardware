--===============================================================================================--
--! @file       NIST_LWAPI_pkg.vhd 
--! @brief      NIST lightweight API package
--! @author     Panasayya Yalla
--! @author     Ekawat (ice) Homsirikamol
--! @author     Kamyar Mohajerani
--! @copyright  Copyright (c) 2022 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, U.S.A.
--!             All rights Reserved.
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
--! @note       This is publicly available encryption source code that falls
--!             under the License Exception TSU (Technology and software-
--!             unrestricted)
---------------------------------------------------------------------------------------------------
--!
--!
--!                        DO NOT CHANGE ANYTHING ON THIS FILE!
--!
--!             User-configurable constants have moved to the `LWC_config` package
--!             All the changes to configuration are applied in `LWC_config`
--!
--!             As before, the package constants are available from this package (`NIST_LWAPI_pkg`)
--!               and can be made visible in the design via a 'use' clause. For example:
--!               
--!                  use work.NIST_LWAPI_pkg.all;
--!                  report "W times PDI_SHARES is " & integer'image(W*PDI_SHARES);
--!
--!
--!
--===============================================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.LWC_config;

package NIST_LWAPI_pkg is

    --===========================================================================================--
    --=                        DO NOT CHANGE ANYTHING ON THIS FILE!                             =--
    --===========================================================================================--

    --======================================== Constants ========================================--
    subtype T_LWC_SEGMENT is std_logic_vector(3 downto 0);
    subtype T_LWC_OPCODE is std_logic_vector(3 downto 0);

    --======================================== Constants ========================================--

    --! **** DO NOT CHANGE ANY OF THE CONSTANT VALUES HERE! *****
    --! to set design-specific values for these parameters, create LWC_config package file
    --! Please see 'LWC_config_template.vhd' for a functional template.
    --! Also examples for different LWC_config files are provided in the dummy_lwc directory
    --!
    --! External bus: supported values are 8, 16 and 32 bits
    constant W          : natural  := LWC_config.W;
    --! currently only W=SW is supported
    constant SW         : natural  := LWC_config.SW;
    --! Applicable only to protected implementations
    --! For unprotected implementations they are set to the default values of 
    --!     PDI_SHARES=SDI_SHARES=1, RW=0
    constant PDI_SHARES : positive := LWC_config.PDI_SHARES;
    constant SDI_SHARES : positive := LWC_config.SDI_SHARES;
    constant RW         : natural  := LWC_config.RW;
    --! Asynchronous and active-low reset.
    constant ASYNC_RSTN : boolean  := LWC_config.ASYNC_RSTN;

    constant Wdiv8  : natural;
    constant SWdiv8 : natural;

    --! INSTRUCTIONS (OPCODES)
    constant INST_HASH      : T_LWC_OPCODE;
    constant INST_ENC       : T_LWC_OPCODE;
    constant INST_DEC       : T_LWC_OPCODE;
    constant INST_LDKEY     : T_LWC_OPCODE;
    constant INST_ACTKEY    : T_LWC_OPCODE;
    constant INST_SUCCESS   : T_LWC_OPCODE;
    constant INST_FAILURE   : T_LWC_OPCODE;
    --! SEGMENT TYPE ENCODING
    --! Reserved := "0000";
    constant HDR_AD         : T_LWC_SEGMENT;
    constant HDR_NPUB_AD    : T_LWC_SEGMENT;
    constant HDR_AD_NPUB    : T_LWC_SEGMENT;
    constant HDR_PT         : T_LWC_SEGMENT;
    constant HDR_CT         : T_LWC_SEGMENT;
    constant HDR_CT_TAG     : T_LWC_SEGMENT;
    constant HDR_HASH_MSG   : T_LWC_SEGMENT;
    constant HDR_TAG        : T_LWC_SEGMENT;
    constant HDR_HASH_VALUE : T_LWC_SEGMENT;
    constant HDR_LENGTH     : T_LWC_SEGMENT;
    constant HDR_KEY        : T_LWC_SEGMENT;
    constant HDR_NPUB       : T_LWC_SEGMENT;
    --! Reserved := "1011";
    --NOT USED in NIST LWC
    constant HDR_NSEC       : T_LWC_SEGMENT;
    --NOT USED in NIST LWC
    constant HDR_ENSEC      : T_LWC_SEGMENT;

    --======================================== Functions ========================================--
    ---- Unused, kept commented in case used in user code
    --! expands input vector 8 times.
    -- function Byte_To_Bits_EXP(bytes_in : std_logic_vector) return std_logic_vector;
    -----

    --! clears invalid bytes from bdo_data
    function clear_invalid_bytes(bdo_data, bdo_valid_bytes : std_logic_vector) return std_logic_vector;

    --! Returns the number of bits required to represet positive integers strictly less than `n` (0 to n - 1 inclusive)
    --! Output is equal to ceil(log2(n))
    --! log2ceil(0) -> 0
    function log2ceil(n : natural) return natural;

    --! convert boolean to std_logic
    function to_std_logic(a : boolean) return std_logic;

    --! first TO_01 and then TO_INTEGER
    function TO_INT01(S : UNSIGNED) return INTEGER;
    function TO_INT01(S : std_logic_vector) return INTEGER;

    --! check if all bits are zero
    function is_zero(slv : std_logic_vector) return boolean;
    function is_zero(u : unsigned) return boolean;

    --! Reverse the Bit order of the input vector.
    function reverse_bits(slv : std_logic_vector) return std_logic_vector;
    function reverse_bits(u : unsigned) return unsigned;

    --! reverse byte endian-ness of the input vector
    function reverse_bytes(vec : std_logic_vector) return std_logic_vector;

    --! binary to one-hot encoder
    function to_1H(u : unsigned) return unsigned;
    function to_1H(slv : std_logic_vector) return std_logic_vector;
    function to_1H(u : unsigned; out_bits : positive) return unsigned;
    function to_1H(slv : std_logic_vector; out_bits : positive) return std_logic_vector;

    --! dynamic (u << sh) using an efficient barrel shifter
    function barrel_shift_left(u : unsigned; sh : unsigned) return unsigned;

    -- Compatibility functions to enable simulation and synthesis with VHDL standrad < 2008 WITHOUT editing the sources
    function minimum(a, b : integer) return integer;
    function maximum(a, b : integer) return integer;

    -- Used in simulation
    procedure lwc_hread(l : inout line; value : out std_logic_vector; good : out boolean);
    function lwc_or_reduce(l : std_logic_vector) return std_logic;
    function lwc_and_reduce(l : std_logic_vector) return std_logic;
    function lwc_or_reduce(u : unsigned) return std_logic;
    function lwc_and_reduce(u : unsigned) return std_logic;
    function lwc_to_hstring(value : std_logic_vector) return string;

    --! return n most significant bits of slv
    function high_bits(slv : std_logic_vector; n : integer) return std_logic_vector;

--================================= Component Declarations ==================================--
    -- component declarations make mixed-language simulation possible

    component LWC
        port(
            clk       : in  std_logic;
            rst       : in  std_logic;
            pdi_data  : in  std_logic_vector(PDI_SHARES * W - 1 downto 0);
            pdi_valid : in  std_logic;
            pdi_ready : out std_logic;
            sdi_data  : in  std_logic_vector(SDI_SHARES * SW - 1 downto 0);
            sdi_valid : in  std_logic;
            sdi_ready : out std_logic;
            do_data   : out std_logic_vector(PDI_SHARES * W - 1 downto 0);
            do_last   : out std_logic;
            do_valid  : out std_logic;
            do_ready  : in  std_logic
        );
    end component;

    component LWC_SCA
        port(
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
            do_ready  : in  std_logic;
            do_valid  : out std_logic;
            --! Random Input
            rdi_data  : in  std_logic_vector(RW - 1 downto 0);
            rdi_valid : in  std_logic;
            rdi_ready : out std_logic
        );
    end component;

    component LWC_2pass
        port(
            --! Global ports
            clk       : in  std_logic;
            rst       : in  std_logic;
            --! Publica data ports
            pdi_data  : in  std_logic_vector(W - 1 downto 0);
            pdi_valid : in  std_logic;
            pdi_ready : out std_logic;
            --! Secret data ports
            -- NOTE for future dev: this G_W is really SW!
            sdi_data  : in  std_logic_vector(W - 1 downto 0);
            sdi_valid : in  std_logic;
            sdi_ready : out std_logic;
            --! Data out ports
            do_data   : out std_logic_vector(W - 1 downto 0);
            do_ready  : in  std_logic;
            do_valid  : out std_logic;
            do_last   : out std_logic;
            --! Tow-pass FIFO interface
            fdi_data  : in  std_logic_vector(W - 1 downto 0);
            fdi_valid : in  std_logic;
            fdi_ready : out std_logic;
            fdo_data  : out std_logic_vector(W - 1 downto 0);
            fdo_valid : out std_logic;
            fdo_ready : in  std_logic
        );
    end component;

end package;

package body NIST_LWAPI_pkg is
    constant Wdiv8  : natural := W / 8;
    constant SWdiv8 : natural := SW / 8;

    --! INSTRUCTIONS (OPCODES)
    constant INST_HASH      : T_LWC_OPCODE  := "1000";
    constant INST_ENC       : T_LWC_OPCODE  := "0010";
    constant INST_DEC       : T_LWC_OPCODE  := "0011";
    constant INST_LDKEY     : T_LWC_OPCODE  := "0100";
    constant INST_ACTKEY    : T_LWC_OPCODE  := "0111";
    constant INST_SUCCESS   : T_LWC_OPCODE  := "1110";
    constant INST_FAILURE   : T_LWC_OPCODE  := "1111";
    --! SEGMENT TYPE ENCODING
    --! Reserved := "0000";
    constant HDR_AD         : T_LWC_SEGMENT := "0001";
    constant HDR_NPUB_AD    : T_LWC_SEGMENT := "0010";
    constant HDR_AD_NPUB    : T_LWC_SEGMENT := "0011";
    constant HDR_PT         : T_LWC_SEGMENT := "0100";
    constant HDR_CT         : T_LWC_SEGMENT := "0101";
    constant HDR_CT_TAG     : T_LWC_SEGMENT := "0110";
    constant HDR_HASH_MSG   : T_LWC_SEGMENT := "0111";
    constant HDR_TAG        : T_LWC_SEGMENT := "1000";
    constant HDR_HASH_VALUE : T_LWC_SEGMENT := "1001";
    constant HDR_LENGTH     : T_LWC_SEGMENT := "1010";
    constant HDR_KEY        : T_LWC_SEGMENT := "1100";
    constant HDR_NPUB       : T_LWC_SEGMENT := "1101";
    --! Reserved := "1011";
    --NOT USED in NIST LWC
    constant HDR_NSEC       : T_LWC_SEGMENT := "1110";
    --NOT USED in NIST LWC
    constant HDR_ENSEC      : T_LWC_SEGMENT := "1111";

    --======================================== Functions ========================================--
    -- function Byte_To_Bits_EXP(
    --     bytes_in : std_logic_vector
    -- ) return std_logic_vector is

    --     variable bits : std_logic_vector((8 * bytes_in'length) - 1 downto 0);
    -- begin
    --     for i in 0 to bytes_in'length - 1 loop
    --         if (bytes_in(i) = '1') then
    --             bits(8 * (i + 1) - 1 downto 8 * i) := (others => '1');
    --         else
    --             bits(8 * (i + 1) - 1 downto 8 * i) := (others => '0');
    --         end if;
    --     end loop;
    --     return bits;
    -- end Byte_To_Bits_EXP;

    function clear_invalid_bytes(bdo_data, bdo_valid_bytes : std_logic_vector) return std_logic_vector is
        variable bdo_cleared : std_logic_vector(bdo_data'range) := (others => '0');
        constant in_bytes    : natural                          := bdo_data'length / 8;
        constant share_bytes : natural                          := bdo_valid_bytes'length;
        constant num_shares  : natural                          := in_bytes / share_bytes;
        variable k           : natural;
    begin
        assert (share_bytes * num_shares * 8) = bdo_data'length severity failure;
        for i in 0 to num_shares - 1 loop
            for j in 0 to share_bytes - 1 loop
                k := (i * share_bytes + j) * 8;
                if bdo_valid_bytes(j) = '1' then
                    bdo_cleared(k + 7 downto k) := bdo_data(k + 7 downto k);
                end if;
            end loop;
        end loop;

        return bdo_cleared;

    end function;

    --! Returns the number of bits required to represet values less than n (0 to n - 1 inclusive)
    function log2ceil(n : natural) return natural is
        variable pow2 : positive := 1;
        variable r    : natural  := 0;
    begin
        while n > pow2 loop
            pow2 := pow2 * 2;
            r    := r + 1;
        end loop;
        return r;
    end function;

    function to_std_logic(a : boolean) return std_logic is
    begin
        if a then
            return '1';
        else
            return '0';
        end if;
    end function;

    function TO_INT01(S : UNSIGNED) return INTEGER is
    begin
        return to_integer(to_01(S));

    end function TO_INT01;

    function TO_INT01(S : std_logic_vector) return INTEGER is
    begin
        return TO_INT01(unsigned(S));

    end function TO_INT01;

    function is_zero(u : unsigned) return boolean is
    begin
        if u'length <= 0 then
            return True;
        end if;
        return u = 0;
    end function;

    function is_zero(slv : std_logic_vector) return boolean is
    begin
        return is_zero(unsigned(slv));
    end function;

    --! Reverse the Byte order of the input word.
    function reverse_bytes(vec : std_logic_vector) return std_logic_vector is
        variable res     : std_logic_vector(vec'length - 1 downto 0);
        constant n_bytes : integer := vec'length / 8;
    begin
        -- Check that vector length is actually byte aligned.
        -- assert (vec'length mod 8 = 0)
        -- report "Vector size must be in multiple of Bytes!" severity failure;
        for i in 0 to (n_bytes - 1) loop
            res(8 * (i + 1) - 1 downto 8 * i) := vec(8 * (n_bytes - i) - 1 downto 8 * (n_bytes - i - 1));
        end loop;
        return res;
    end function;

    --! Reverse the bit-order of the input
    function reverse_bits(slv : std_logic_vector) return std_logic_vector is
        variable res : std_logic_vector(slv'range);
    begin
        for i in res'range loop
            res(i) := slv(slv'length - i - 1);
        end loop;
        return res;
    end function;

    function reverse_bits(u : unsigned) return unsigned is
    begin
        return unsigned(reverse_bits(std_logic_vector(u)));
    end function;

    --! binary to one-hot encoder
    function to_1H(u : unsigned) return unsigned is
    begin
        return to_1H(u, 2 ** u'length);
    end function;

    --! binary to one-hot encoder
    function to_1H(u : unsigned; out_bits : positive) return unsigned is
        variable ret : unsigned(out_bits - 1 downto 0) := (others => '0');
    begin
        for i in 0 to out_bits - 1 loop
            if u = to_unsigned(i, u'length) then
                ret(i) := '1';
            end if;
        end loop;
        return ret;
    end function;

    function to_1H(slv : std_logic_vector; out_bits : positive) return std_logic_vector is
    begin
        return std_logic_vector(to_1H(unsigned(slv), out_bits));
    end function;

    function to_1H(slv : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(to_1H(unsigned(slv)));
    end function;

    function barrel_shift_left(u : unsigned; sh : unsigned) return unsigned is
        variable ret : unsigned(u'length + (2 ** sh'length) - 1 downto 0) := u;
    begin
        for i in 0 to sh'length - 1 loop
            if sh(i) = '1' then
                ret := shift_left(ret, 2 ** i);
            end if;
        end loop;
        return ret;
    end function;

    function high_bits(slv : std_logic_vector; n : integer) return std_logic_vector is
    begin
        if slv'left >= slv'right then
            return slv(slv'length - 1 downto slv'length - n);
        else
            return slv(slv'length - n to slv'length - 1);
        end if;
    end function;

    function minimum(a, b : integer) return integer is
    begin
        if a < b then
            return a;
        else
            return b;
        end if;
    end function;

    function maximum(a, b : integer) return integer is
    begin
        if not (a < b) then
            return a;
        else
            return b;
        end if;
    end function;

    function lwc_or_reduce(l : std_logic_vector) return std_logic is
        variable result : std_logic := '0'; -- return 0 on input with empty range
    begin
        for i in l'reverse_range loop
            result := l(i) or result;
        end loop;
        return result;
    end function;

    function lwc_and_reduce(l : std_logic_vector) return std_logic is
        variable result : std_logic := '1'; -- return 1 on input with empty range
    begin
        for i in l'reverse_range loop
            result := l(i) and result;
        end loop;
        return result;
    end function;

    function lwc_or_reduce(u : unsigned) return std_logic is
    begin
        return lwc_or_reduce(std_logic_vector(u));
    end function;

    function lwc_and_reduce(u : unsigned) return std_logic is
    begin
        return lwc_and_reduce(std_logic_vector(u));
    end function;


    --=================================== BEGIN openieee code ===================================--
    --- Following code is based on OpenIEEE library
    --- needed for VHDL < 2008 compatibility
    --- Copyright (C) 2015-2021 Tristan Gingold

    ---- INTERNAL used by hread
    procedure trim(l : inout line; left : natural) is
        variable nl : line;
    begin
        if l'ascending then
            nl     := new string(left to l'right);
            nl.all := l(left to l'right);
        else
            nl     := new string(left downto l'right);
            nl.all := l(left downto l'right);
        end if;
        deallocate(l);
        l := nl;
    end trim;

    procedure hread(l : inout line; value : out std_logic_vector; good : out boolean) is
        constant NBSP             : character := character'val(160);
        variable p                : positive;
        variable i                : natural;
        variable dir              : integer;
        constant ndigits          : natural   := (value'length + 3) / 4;
        variable v                : std_logic_vector(1 to ndigits * 4);
        variable allow_underscore : boolean;
        variable c                : character;
        variable d                : std_logic_vector(3 downto 0);
    begin
        good  := value'length = 0;
        value := (value'range => 'U');
        if l = null or l'length = 0 then
            --  Return now for empty line.
            return;
        end if;

        if l'ascending then
            dir := 1;
        else
            dir := -1;
        end if;
        p := l'left;

        --  Skip blanks.
        p := l'left;
        loop
            case l(p) is
                when ' ' | NBSP | HT =>
                    null;
                when others =>
                    exit;
            end case;
            if p = l'right then
                --  End of string.
                deallocate(l);
                l := new string'("");
                return;
            end if;
            p := p + dir;
        end loop;

        if value'length = 0 then
            --  Nothing to read.
            trim(l, p);
            return;
        end if;

        --  Extract value
        i                := 0;
        allow_underscore := False;
        good             := false;
        loop
            c := l(p);
            case c is
                when '0'       => d := "0000";
                when '1'       => d := "0001";
                when '2'       => d := "0010";
                when '3'       => d := "0011";
                when '4'       => d := "0100";
                when '5'       => d := "0101";
                when '6'       => d := "0110";
                when '7'       => d := "0111";
                when '8'       => d := "1000";
                when '9'       => d := "1001";
                when 'A' | 'a' => d := "1010";
                when 'B' | 'b' => d := "1011";
                when 'C' | 'c' => d := "1100";
                when 'D' | 'd' => d := "1101";
                when 'E' | 'e' => d := "1110";
                when 'F' | 'f' => d := "1111";
                when 'Z'       => d := "ZZZZ";
                when 'X'       => d := "XXXX";
                when others =>
                    if c = '_' and allow_underscore then
                        allow_underscore := false;
                    else
                        --  Invalid character, double or leading '_'.
                        trim(l, p);
                        return;
                    end if;
            end case;
            if c /= '_' then
                allow_underscore          := true;
                v(i * 4 + 1 to i * 4 + 4) := d;
                i                         := i + 1;
                if i = ndigits then
                    --  Done.
                    if lwc_or_reduce(v(1 to ndigits * 4 - value'length)) /= '1' then
                        --  No truncated digit is a '1'.
                        value := v(ndigits * 4 - value'length + 1 to v'right);
                        good  := true;
                    end if;
                    trim(l, p + dir);
                    return;
                end if;
            end if;
            if p = l'right then
                --  End of string.
                trim(l, p + dir);
                deallocate(l);
                l := new string'("");
                return;
            end if;
            p := p + dir;
        end loop;
    end procedure;

    function lwc_to_hstring(value : std_logic_vector) return STRING is
        constant NUS    : STRING(2 to 1) := (others => ' '); -- null STRING
        constant ne     : INTEGER        := (value'length + 3) / 4;
        variable pad    : std_logic_vector(0 to (ne * 4 - value'length) - 1);
        variable ivalue : std_logic_vector(0 to ne * 4 - 1);
        variable result : STRING(1 to ne);
        variable quad   : std_logic_vector(0 to 3);
    begin
        if value'length < 1 then
            return NUS;
        else
            if value(value'left) = 'Z' then
                pad := (others => 'Z');
            else
                pad := (others => '0');
            end if;
            ivalue := pad & value;
            for i in 0 to ne - 1 loop
                quad := To_X01Z(ivalue(4 * i to 4 * i + 3));
                case quad is
                    when x"0"   => result(i + 1) := '0';
                    when x"1"   => result(i + 1) := '1';
                    when x"2"   => result(i + 1) := '2';
                    when x"3"   => result(i + 1) := '3';
                    when x"4"   => result(i + 1) := '4';
                    when x"5"   => result(i + 1) := '5';
                    when x"6"   => result(i + 1) := '6';
                    when x"7"   => result(i + 1) := '7';
                    when x"8"   => result(i + 1) := '8';
                    when x"9"   => result(i + 1) := '9';
                    when x"A"   => result(i + 1) := 'A';
                    when x"B"   => result(i + 1) := 'B';
                    when x"C"   => result(i + 1) := 'C';
                    when x"D"   => result(i + 1) := 'D';
                    when x"E"   => result(i + 1) := 'E';
                    when x"F"   => result(i + 1) := 'F';
                    when "ZZZZ" => result(i + 1) := 'Z';
                    when others => result(i + 1) := 'X';
                end case;
            end loop;
            return result;
        end if;
    end function;

    --==================================== End openieee code ====================================--

    procedure lwc_hread(l : inout line; value : out std_logic_vector; good : out boolean) is
        variable ivalue : std_logic_vector(value'range);
    begin
        hread(l => l, value => ivalue, good => good);
        value := std_logic_vector(ivalue);
    end procedure;

end package body;
