--------------------------------------------------------------------------------
--! @file       design_pkg.vhd
--! @brief      Package for the Cipher Core.
--!
--! @author     Michael Tempelmeier <michael.tempelmeier@tum.de>
--! @author     Patrick Karl <patrick.karl@tum.de>
--! @copyright  Copyright (c) 2019 Chair of Security in Information Technology
--!             ECE Department, Technical University of Munich, GERMANY
--!             All rights Reserved.
--! @license    This project is released under the GNU Public License.
--!             The license and distribution terms for this file may be
--!             found in the file LICENSE in this distribution or at
--!             http://www.gnu.org/licenses/gpl-3.0.txt
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.LWC_config.all;
use work.LWC_config_ccw.all;

package design_pkg is

    constant UROL : INTEGER RANGE 0 TO 4 := 1; -- v1 or v2
    -- constant UROL : INTEGER RANGE 0 TO 4 := 2; -- v3 or v4
    -- constant UROL : INTEGER RANGE 0 TO 4 := 3; -- v5
    -- constant UROL : INTEGER RANGE 0 TO 4 := 4; -- v6

    ---------------------------------------------------------------------------
    --                              _ ____  ___  
    --   __ _ ___  ___ ___  _ __   / |___ \( _ ) 
    --  / _` / __|/ __/ _ \| '_ \  | | __) / _ \ 
    -- | (_| \__ \ (_| (_) | | | | | |/ __/ (_) |
    --  \__,_|___/\___\___/|_| |_| |_|_____\___/ 
    -- v1,v3,v5: ascon128v12                     
    ---------------------------------------------------------------------------
    CONSTANT IV_AEAD : std_logic_vector(63 DOWNTO 0) := X"80400c0600000000";
    CONSTANT ROUNDS_A : std_logic_vector(7 DOWNTO 0) := X"0C";
    CONSTANT ROUNDS_B : std_logic_vector(7 DOWNTO 0) := X"06";
    CONSTANT DBLK_SIZE : INTEGER := 64;
    CONSTANT IV_HASH : std_logic_vector(63 DOWNTO 0) := X"00400c0000000100";
    CONSTANT ROUNDS_HASH_A : std_logic_vector(7 DOWNTO 0) := X"0C";
    CONSTANT ROUNDS_HASH_B : std_logic_vector(7 DOWNTO 0) := X"0C";

    -----------------------------------------------------------------------------
    --                              _ ____  ___        
    --   __ _ ___  ___ ___  _ __   / |___ \( _ )  __ _ 
    --  / _` / __|/ __/ _ \| '_ \  | | __) / _ \ / _` |
    -- | (_| \__ \ (_| (_) | | | | | |/ __/ (_) | (_| |
    --  \__,_|___/\___\___/|_| |_| |_|_____\___/ \__,_|
    -- v2,v4,v6: ascon128av12                          
    -----------------------------------------------------------------------------
--    CONSTANT IV_AEAD : std_logic_vector(63 DOWNTO 0) := X"80800c0800000000";
--    CONSTANT ROUNDS_A : std_logic_vector(7 DOWNTO 0) := X"0C";
--    CONSTANT ROUNDS_B : std_logic_vector(7 DOWNTO 0) := X"08";
--    CONSTANT DBLK_SIZE : integer := 128;
--    CONSTANT IV_HASH : std_logic_vector(63 DOWNTO 0) := X"00400c0400000100";
--    CONSTANT ROUNDS_HASH_A : std_logic_vector(7 DOWNTO 0) := X"0C";
--    CONSTANT ROUNDS_HASH_B : std_logic_vector(7 DOWNTO 0) := X"08";

    --! design parameters needed by the PreProcessor, PostProcessor, LWC, and CryptoCore
    constant TAG_SIZE        : integer := 128; --! Tag size
    constant HASH_VALUE_SIZE : integer := 256; --! Hash value size
    constant NPUB_SIZE       : integer := 128; --! Npub size

    --! Calculate the number of I/O words for a particular size
    function get_words(
        size: integer;
        iowidth:integer
    ) return integer; 
    
    --! Reverse the Byte order of the input word.
    function reverse_byte(
        vec : std_logic_vector
    ) return std_logic_vector;
    
    --! Reverse the Bit order of the input vector.
    function reverse_bit(
        vec : std_logic_vector
    ) return std_logic_vector;
    
    --! Padding the current word.
    function pad_bdi(
        bdi,
        bdi_valid_bytes,
        bdi_pad_loc, state_word : std_logic_vector;
        pt_ct : std_logic
    ) return std_logic_vector;
    
    --! Return max value
    function max( a, b : integer) return integer;
    
    function dyn_slice(
        paddy : std_logic_vector;
        bdi_eot, bdi_partial_s : std_logic;
        ascon_state_s : std_logic_vector;
        word_idx_s : integer;
        hash_s : std_logic
    ) return std_logic_vector;
    
    -- State signals
    TYPE state_t IS (
        IDLE,
        STORE_KEY,
        STORE_NONCE,
        INIT_STATE_SETUP,
        -- AEAD
        INIT_PROCESS,
        INIT_KEY_ADD,
        ABSORB_AD,
        PROCESS_AD,
        PAD_AD,
        DOM_SEP,
        ABSORB_MSG,
        PROCESS_MSG,
        PAD_MSG,
        FINAL_KEY_ADD_1,
        FINAL_PROCESS,
        FINAL_KEY_ADD_2,
        EXTRACT_TAG,
        VERIFY_TAG,
        WAIT_ACK,
        -- HASH
        INIT_HASH,
        ABSORB_HASH_MSG,
        PROCESS_HASH,
        PAD_HASH_MSG,
        EXTRACT_HASH_VALUE
    );

end design_pkg;


package body design_pkg is

    --! Calculate the number of words
    function get_words(size: integer; iowidth:integer) return integer is
    begin
        if (size mod iowidth) > 0 then
            return size/iowidth + 1;
        else
            return size/iowidth;
        end if;
    end function get_words;

    --! Reverse the Byte order of the input word.
    function reverse_byte( vec : std_logic_vector ) return std_logic_vector is
        variable res : std_logic_vector(vec'length - 1 downto 0);
        constant n_bytes  : integer := vec'length/8;
    begin

        -- Check that vector length is actually byte aligned.
        assert (vec'length mod 8 = 0)
            report "Vector size must be in multiple of Bytes!" severity failure;

        -- Loop over every byte of vec and reorder it in res.
        for i in 0 to (n_bytes - 1) loop
            res(8*(i+1) - 1 downto 8*i) := vec(8*(n_bytes - i) - 1 downto 8*(n_bytes - i - 1));
        end loop;

        return res;
    end function reverse_byte;

    --! Reverse the Bit order of the input vector.
    function reverse_bit( vec : std_logic_vector ) return std_logic_vector is
        variable res : std_logic_vector(vec'length - 1 downto 0);
    begin
        for i in 0 to (vec'length - 1) loop
            res(i) := vec(vec'length - i - 1);
        end loop;
        return res;
    end function reverse_bit;

    --! Padd the data with 0x80 Byte if pad_loc is set.
    function pad_bdi( bdi, bdi_valid_bytes, bdi_pad_loc, state_word : std_logic_vector; pt_ct : std_logic) return std_logic_vector is
        variable res : std_logic_vector(bdi'length - 1 downto 0) := state_word;
    begin
        for i in 0 to (bdi_valid_bytes'length - 1) loop
            if (bdi_valid_bytes(i) = '1') then
                if (pt_ct = '0') then
                    res(8*(i+1) - 1 downto 8*i) := res(8*(i+1) - 1 downto 8*i) XOR bdi(8*(i+1) - 1 downto 8*i);
                else
                    res(8*(i+1) - 1 downto 8*i) := bdi(8*(i+1) - 1 downto 8*i);
                end if;
            elsif (bdi_pad_loc(i) = '1') then
                res(8*(i+1) - 1 downto 8*i) := res(8*(i+1) - 1 downto 8*i) XOR x"80";
            end if;
        end loop;
        return res;
    end function;

    function dyn_slice( paddy : std_logic_vector; bdi_eot, bdi_partial_s : std_logic; ascon_state_s : std_logic_vector ; word_idx_s : integer; hash_s : std_logic) return std_logic_vector is
        variable res : std_logic_vector(ascon_state_s'length - 1 downto 0) := ascon_state_s;
        variable last_word_idx : integer RANGE 0 TO DBLK_SIZE/CCW-1;
    begin
        IF (hash_s = '1') then
            last_word_idx := 64/CCW-1;
        else
            last_word_idx := DBLK_SIZE/CCW-1;
        end if;
        res(word_idx_s*CCW+CCW-1 downto word_idx_s*CCW) := paddy;
        IF (word_idx_s < (last_word_idx) and bdi_eot = '1' and bdi_partial_s = '0' ) THEN
            res(word_idx_s*CCW+CCW+7 downto word_idx_s*CCW+CCW) := res(word_idx_s*CCW+CCW+7 downto word_idx_s*CCW+CCW) XOR X"80";
        END IF;
        return res;
    end function;

    --! Return max value.
    function max( a, b : integer) return integer is
    begin
        if (a >= b) then
            return a;
        else
            return b;
        end if;
    end function;

end package body design_pkg;
