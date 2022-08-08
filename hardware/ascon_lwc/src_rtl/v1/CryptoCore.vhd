--------------------------------------------------------------------------------
--! @file       CryptoCore.vhd
--! @brief      Implementation of Ascon-128, Ascon-128a and Ascon-Hash.
--!
--! @author     Robert Primas <rprimas@protonmail.com>
--! @copyright  Copyright (c) 2020 IAIK, Graz University of Technology, AUSTRIA
--!             All rights Reserved.
--! @license    This project is released under the GNU Public License.          
--!             The license and distribution terms for this file may be         
--!             found in the file LICENSE in this distribution or at            
--!             http://www.gnu.org/licenses/gpl-3.0.txt                         
--! @note       This is publicly available encryption source code that falls    
--!             under the License Exception TSU (Technology and software-       
--!             unrestricted)                                                  
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--     _                                    
--    / \   ___  ___ ___  _ __          _ __  
--   / _ \ / __|/ __/ _ \| '_ \  _____ | '_ \ 
--  / ___ \\__ \ (_| (_) | | | ||_____|| |_) |
-- /_/   \_\___/\___\___/|_| |_|       | .__/ 
--                                     |_|    
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;
USE work.NIST_LWAPI_pkg.ALL;
USE work.design_pkg.ALL;

ENTITY Asconp IS
    PORT (
        state_in : IN STD_LOGIC_VECTOR(319 DOWNTO 0);
        rcon : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        state_out : OUT STD_LOGIC_VECTOR(319 DOWNTO 0)
    );
END;

ARCHITECTURE behavior OF Asconp IS
    CONSTANT rounds_16 : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"F";
    CONSTANT rounds_12 : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"C";
BEGIN

    PROCESS (state_in, rcon)
        VARIABLE x0, x1, x2, x3, x4 : STD_LOGIC_VECTOR(63 DOWNTO 0);
        VARIABLE t0, t1 : STD_LOGIC_VECTOR(63 DOWNTO 0);
        VARIABLE t2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
        
    BEGIN
        ---------------------------------------------------------------------------
        --! Map bit vector to ascon state
        ---------------------------------------------------------------------------
        -- Map 320-bit vector to 5 x 64-bit lanes.
        x0 := state_in(63 + 0 * 64 DOWNTO 0 * 64);
        x1 := state_in(63 + 1 * 64 DOWNTO 1 * 64);
        x2 := state_in(63 + 2 * 64 DOWNTO 2 * 64);
        x3 := state_in(63 + 3 * 64 DOWNTO 3 * 64);
        x4 := state_in(63 + 4 * 64 DOWNTO 4 * 64);
        
        -- Endian swap.
        x0 := reverse_byte(x0);
        x1 := reverse_byte(x1);
        x2 := reverse_byte(x2);
        x3 := reverse_byte(x3);
        x4 := reverse_byte(x4);

        ---------------------------------------------------------------------------
        --! Ascon Round
        ---------------------------------------------------------------------------
        for r in 1 to UROL loop     

            -- Linear operations and addition of round constant.
            t2 := std_logic_vector(unsigned(rounds_12) - unsigned(rcon) + r -1);
            x0 := x0 XOR x4;
            x2(7 DOWNTO 0) := x2(7 DOWNTO 0) XOR x1(7 DOWNTO 0) XOR (std_logic_vector(unsigned(rounds_16) - unsigned(t2)) & t2);
            x2(63 DOWNTO 8) := x2(63 DOWNTO 8) XOR x1(63 DOWNTO 8);
            x4 := x4 XOR x3;
    
            -- Nonlinear operations, same as used in Keccak-Sbox
            t0 := x0;
            t1 := x1;
            x0 := x0 XOR (NOT x1 AND x2);
            x1 := x1 XOR (NOT x2 AND x3);
            x2 := x2 XOR (NOT x3 AND x4);
            x3 := x3 XOR (NOT x4 AND t0);
            x4 := x4 XOR (NOT t0 AND t1);
    
            -- Linear operations.
            x1 := x1 XOR x0;
            x3 := x3 XOR x2;
            x0 := x0 XOR x4;
            x2 := NOT x2;
    
            -- Lane rotations.
            x0 := x0 XOR (x0(18 DOWNTO 0) & x0(63 DOWNTO 19)) XOR (x0(27 DOWNTO 0) & x0(63 DOWNTO 28));
            x1 := x1 XOR (x1(60 DOWNTO 0) & x1(63 DOWNTO 61)) XOR (x1(38 DOWNTO 0) & x1(63 DOWNTO 39));
            x2 := x2 XOR (x2(0 DOWNTO 0) & x2(63 DOWNTO 1)) XOR (x2(5 DOWNTO 0) & x2(63 DOWNTO 6));
            x3 := x3 XOR (x3(9 DOWNTO 0) & x3(63 DOWNTO 10)) XOR (x3(16 DOWNTO 0) & x3(63 DOWNTO 17));
            x4 := x4 XOR (x4(6 DOWNTO 0) & x4(63 DOWNTO 7)) XOR (x4(40 DOWNTO 0) & x4(63 DOWNTO 41));
        
        end loop;
        
        ---------------------------------------------------------------------------
        --! Map ascon state to bit vector
        ---------------------------------------------------------------------------
        -- Endian swap.
        x0 := reverse_byte(x0);
        x1 := reverse_byte(x1);
        x2 := reverse_byte(x2);
        x3 := reverse_byte(x3);
        x4 := reverse_byte(x4);

        -- Map 5 x 64-bit lanes to 320-bit vector.
        state_out(63 + 0 * 64 DOWNTO 0 * 64) <= x0;
        state_out(63 + 1 * 64 DOWNTO 1 * 64) <= x1;
        state_out(63 + 2 * 64 DOWNTO 2 * 64) <= x2;
        state_out(63 + 3 * 64 DOWNTO 3 * 64) <= x3;
        state_out(63 + 4 * 64 DOWNTO 4 * 64) <= x4;
    END PROCESS;
END;

--------------------------------------------------------------------------------
--   ____                  _           ____               
--  / ___|_ __ _   _ _ __ | |_ ___    / ___|___  _ __ ___ 
-- | |   | '__| | | | '_ \| __/ _ \  | |   / _ \| '__/ _ \
-- | |___| |  | |_| | |_) | || (_) | | |__| (_) | | |  __/
--  \____|_|   \__, | .__/ \__\___/   \____\___/|_|  \___|
--	           |___/|_|                                   
--                                                        
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;
USE work.NIST_LWAPI_pkg.ALL;
USE work.design_pkg.ALL;

ENTITY CryptoCore IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        --PreProcessor===============================================
        ----!key----------------------------------------------------
        key : IN STD_LOGIC_VECTOR (CCSW - 1 DOWNTO 0);
        key_valid : IN STD_LOGIC;
        key_ready : OUT STD_LOGIC;
        ----!Data----------------------------------------------------
        bdi : IN STD_LOGIC_VECTOR (CCW - 1 DOWNTO 0);
        bdi_valid : IN STD_LOGIC;
        bdi_ready : OUT STD_LOGIC;
        bdi_pad_loc : IN STD_LOGIC_VECTOR (CCWdiv8 - 1 DOWNTO 0);
        bdi_valid_bytes : IN STD_LOGIC_VECTOR (CCWdiv8 - 1 DOWNTO 0);
        bdi_size : IN STD_LOGIC_VECTOR (3 - 1 DOWNTO 0);
        bdi_eot : IN STD_LOGIC;
        bdi_eoi : IN STD_LOGIC;
        bdi_type : IN STD_LOGIC_VECTOR (4 - 1 DOWNTO 0);
        decrypt_in : IN STD_LOGIC;
        key_update : IN STD_LOGIC;
        hash_in : IN std_logic;
        --!Post Processor=========================================
        bdo : OUT STD_LOGIC_VECTOR (CCW - 1 DOWNTO 0);
        bdo_valid : OUT STD_LOGIC;
        bdo_ready : IN STD_LOGIC;
        bdo_type : OUT STD_LOGIC_VECTOR (4 - 1 DOWNTO 0);
        bdo_valid_bytes : OUT STD_LOGIC_VECTOR (CCWdiv8 - 1 DOWNTO 0);
        end_of_block : OUT STD_LOGIC;
        msg_auth_valid : OUT STD_LOGIC;
        msg_auth_ready : IN STD_LOGIC;
        msg_auth : OUT STD_LOGIC
    );
END CryptoCore;

ARCHITECTURE behavioral OF CryptoCore IS

    ---------------------------------------------------------------------------
    --! Constant Values: Ascon
    ---------------------------------------------------------------------------
    CONSTANT TAG_SIZE : INTEGER := 128;
    CONSTANT STATE_SIZE : INTEGER := 320;
    CONSTANT IV_SIZE : INTEGER := 64;
    CONSTANT NPUB_SIZE : INTEGER := 128;
    CONSTANT DBLK_HASH_SIZE : INTEGER := 64;
    CONSTANT KEY_SIZE : INTEGER := 128;
    
    --! Constant to check for empty hash
    CONSTANT EMPTY_HASH_SIZE_C : std_logic_vector(2 DOWNTO 0) := (OTHERS => '0');

    -- Number of words the respective blocks contain.
    CONSTANT NPUB_WORDS_C : INTEGER := get_words(NPUB_SIZE, CCW);
    CONSTANT HASH_WORDS_C : INTEGER := get_words(HASH_VALUE_SIZE, CCW);
    CONSTANT BLOCK_WORDS_C : INTEGER := get_words(DBLK_SIZE, CCW);
    CONSTANT BLOCK_HASH_WORDS_C : INTEGER := get_words(DBLK_HASH_SIZE, CCW);
    CONSTANT KEY_WORDS_C : INTEGER := get_words(KEY_SIZE, CCW);
    CONSTANT TAG_WORDS_C : INTEGER := get_words(TAG_SIZE, CCW);
    CONSTANT STATE_WORDS_C : INTEGER := get_words(STATE_SIZE, CCW);
    
    SIGNAL n_state_s, state_s : state_t;

    -- Selection signal of the current word
    SIGNAL word_idx_s : INTEGER RANGE 0 TO HASH_WORDS_C - 1;
    SIGNAL word_idx_offset_s : INTEGER RANGE 0 TO HASH_WORDS_C - 1;

    -- Internal Port signals
    SIGNAL key_s : std_logic_vector(CCSW - 1 DOWNTO 0);
    SIGNAL key_ready_s : std_logic;
    SIGNAL bdi_ready_s : std_logic;
    SIGNAL bdi_s : std_logic_vector(CCW - 1 DOWNTO 0);
    SIGNAL bdi_valid_bytes_s : std_logic_vector(CCWdiv8 - 1 DOWNTO 0);
    SIGNAL bdi_pad_loc_s : std_logic_vector(CCWdiv8 - 1 DOWNTO 0);

    SIGNAL bdo_s : std_logic_vector(CCW - 1 DOWNTO 0);
    SIGNAL bdo_valid_bytes_s : std_logic_vector(CCWdiv8 - 1 DOWNTO 0);
    SIGNAL bdo_valid_s : std_logic;
    SIGNAL bdo_type_s : std_logic_vector(3 DOWNTO 0);
    SIGNAL end_of_block_s : std_logic;
    SIGNAL msg_auth_valid_s : std_logic;

    SIGNAL bdoo_s : std_logic_vector(CCW - 1 DOWNTO 0);

    -- Internal Flags
    SIGNAL n_decrypt_s, decrypt_s : std_logic;
    SIGNAL n_hash_s, hash_s : std_logic;
    SIGNAL n_empty_hash_s, empty_hash_s : std_logic;
    SIGNAL n_msg_auth_s, msg_auth_s : std_logic;
    SIGNAL n_eoi_s, eoi_s : std_logic;
    SIGNAL n_eot_s, eot_s : std_logic;
    SIGNAL n_update_key_s, update_key_s : std_logic;

    -- Utility Signals
    SIGNAL bdi_partial_s : std_logic;
    SIGNAL pad_added_s : std_logic;
    SIGNAL bit_pos_s : INTEGER RANGE 0 TO 511;

    -- Ascon Signals
    SIGNAL ascon_state_s : std_logic_vector(STATE_SIZE - 1 DOWNTO 0);
    SIGNAL ascon_state_n_s : std_logic_vector(STATE_SIZE - 1 DOWNTO 0);
    SIGNAL ascon_cnt_s : std_logic_vector(7 DOWNTO 0);
    SIGNAL ascon_key_s : std_logic_vector(KEY_SIZE - 1 DOWNTO 0);
    SIGNAL ascon_rcon_s : std_logic_vector(3 DOWNTO 0);
    SIGNAL ascon_hash_cnt_s : INTEGER RANGE 0 TO 3;

    -- Ascon-p
    SIGNAL asconp_out_s : std_logic_vector(STATE_SIZE - 1 DOWNTO 0);

BEGIN

    ----------------------------------------------------------------------------
    -- I/O Mappings
    -- Algorithm is specified in Big Endian. However, this is a Little Endian
    -- implementation so reverse_byte/bit functions are used to reorder affected signals.
    ----------------------------------------------------------------------------
    key_s <= reverse_byte(key);
    bdi_s <= reverse_byte(bdi);
    bdi_valid_bytes_s <= reverse_bit(bdi_valid_bytes);
    bdi_pad_loc_s <= reverse_bit(bdi_pad_loc);
    key_ready <= key_ready_s;
    bdi_ready <= bdi_ready_s;
    bdo <= reverse_byte(bdo_s);
    bdo_valid_bytes <= reverse_bit(bdo_valid_bytes_s);
    bdo_valid <= bdo_valid_s;
    bdo_type <= bdo_type_s;
    end_of_block <= end_of_block_s;
    msg_auth <= msg_auth_s;
    msg_auth_valid <= msg_auth_valid_s;

    ---------------------------------------------------------------------------
    --! Utility Signals
    ---------------------------------------------------------------------------

    -- Used to determine whether 0x80 padding word can be inserted into this last word.
    bdi_partial_s <= or_reduce(bdi_pad_loc_s);

    -- Lowest bit index in state that is currently used for data absorption/extraction.
    bit_pos_s <= (word_idx_s MOD (DBLK_SIZE/CCW)) * CCW;

    -- Round constant for Ascon-p.
    ascon_rcon_s <= ascon_cnt_s(3 DOWNTO 0);

    ---------------------------------------------------------------------------
    --! Ascon-p instantiation
    ---------------------------------------------------------------------------
    i_asconp : ENTITY work.asconp
        PORT MAP(
            state_in => ascon_state_s,
            rcon => ascon_rcon_s,
            state_out => asconp_out_s
        );
    
    -- bdo dynamic slicing
    p_dynslice_bdo : process (word_idx_s,ascon_state_s,word_idx_offset_s)
        variable sel : INTEGER RANGE 0 TO STATE_WORDS_C-1;
    begin
        sel := word_idx_s + word_idx_offset_s;
        bdoo_s <= ascon_state_s(CCW-1+CCW*sel DOWNTO CCW*sel);
    end process;

    -- bdi dynamic slicing
    p_dynslice_bdi : process (word_idx_s,ascon_state_s,word_idx_offset_s,state_s,bdi_s,decrypt_s,bdi_valid_bytes_s,bdi_pad_loc_s,bdoo_s,bdi_eot,bdi_partial_s,n_hash_s)
        variable pad1 : STD_LOGIC_VECTOR(CCW-1 DOWNTO 0);
        variable pad2 : STD_LOGIC_VECTOR(CCW-1 DOWNTO 0);
    begin
        pad1 := pad_bdi(bdi_s, bdi_valid_bytes_s, bdi_pad_loc_s, bdoo_s, '0');
        pad2 := pad_bdi(bdi_s, bdi_valid_bytes_s, bdi_pad_loc_s, bdoo_s, decrypt_s);
    case state_s is
        when ABSORB_AD | ABSORB_HASH_MSG =>
            ascon_state_n_s <= dyn_slice(pad1,bdi_eot,bdi_partial_s,ascon_state_s,word_idx_s,hash_s);
        when ABSORB_MSG =>
            ascon_state_n_s <= dyn_slice(pad2,bdi_eot,bdi_partial_s,ascon_state_s,word_idx_s,hash_s);
        when others =>
            ascon_state_n_s <= ascon_state_s;
    end case;
    end process;

    -- Word idx  offset process
    asdf_CASE : process (word_idx_s,state_s)
    begin
        word_idx_offset_s <= 0;
        CASE state_s IS
            WHEN EXTRACT_TAG =>
                word_idx_offset_s <= 192/CCW;
            WHEN VERIFY_TAG =>
                word_idx_offset_s <= 192/CCW;
            WHEN others =>
                null;
    end case;
    end process;

    ----------------------------------------------------------------------------
    --! Bdo multiplexer
    ----------------------------------------------------------------------------
    bdo_mux : PROCESS (state_s, bdi_s, word_idx_s, bdi_ready_s,
        bdi_valid_bytes_s, bdi_valid, bdi_eot, decrypt_s, ascon_state_s,
        hash_s, bit_pos_s, ascon_hash_cnt_s, bdoo_s)
    BEGIN

        -- Directly connect bdi and bdo signals and encryp/decrypt data.
        -- No default values so each signal requires an assignment in each case.
        CASE state_s IS

            WHEN ABSORB_MSG =>
                bdo_s <= bdoo_s XOR bdi_s;
                bdo_valid_bytes_s <= bdi_valid_bytes_s;
                bdo_valid_s <= bdi_ready_s;
                end_of_block_s <= bdi_eot;
                IF (decrypt_s = '1') THEN
                    bdo_type_s <= HDR_PT;
                ELSE
                    bdo_type_s <= HDR_CT;
                END IF;

            WHEN EXTRACT_TAG =>
                bdo_s <= bdoo_s;
                bdo_valid_bytes_s <= (OTHERS => '1');
                bdo_valid_s <= '1';
                bdo_type_s <= HDR_TAG;
                IF (word_idx_s = TAG_WORDS_C - 1 AND hash_s = '0')
                    OR (word_idx_s >= HASH_WORDS_C - 1 AND hash_s = '1') THEN
                    end_of_block_s <= '1';
                ELSE
                    end_of_block_s <= '0';
                END IF;

            WHEN EXTRACT_HASH_VALUE =>
                bdo_s <= bdoo_s;
                bdo_valid_bytes_s <= (OTHERS => '1');
                bdo_valid_s <= '1';
                bdo_type_s <= HDR_HASH_VALUE;
                IF (word_idx_s >= BLOCK_HASH_WORDS_C - 1 AND ascon_hash_cnt_s = 3) THEN
                    end_of_block_s <= '1';
                ELSE
                    end_of_block_s <= '0';
                END IF;

            WHEN OTHERS =>
                bdo_s <= (OTHERS => '0');
                bdo_valid_bytes_s <= (OTHERS => '0');
                bdo_valid_s <= '0';
                end_of_block_s <= '0';
                bdo_type_s <= (OTHERS => '0');

        END CASE;
    END PROCESS bdo_mux;

    ----------------------------------------------------------------------------
    --! Registers for state and internal signals
    ----------------------------------------------------------------------------
    p_reg : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (rst = '1') THEN
                msg_auth_s <= '1';
                eoi_s <= '0';
                eot_s <= '0';
                update_key_s <= '0';
                decrypt_s <= '0';
                hash_s <= '0';
                empty_hash_s <= '0';
                state_s <= IDLE;
            ELSE
                msg_auth_s <= n_msg_auth_s;
                eoi_s <= n_eoi_s;
                eot_s <= n_eot_s;
                update_key_s <= n_update_key_s;
                decrypt_s <= n_decrypt_s;
                hash_s <= n_hash_s;
                empty_hash_s <= n_empty_hash_s;
                state_s <= n_state_s;
            END IF;
        END IF;
    END PROCESS p_reg;

    ----------------------------------------------------------------------------
    --! Next_state FSM
    ----------------------------------------------------------------------------
    p_next_state : PROCESS (state_s, key_valid, key_ready_s, key_update, bdi_valid,
        bdi_ready_s, bdi_eot, bdi_eoi, eoi_s, eot_s, bdi_type, bdi_pad_loc_s,
        word_idx_s, hash_in, decrypt_s, bdo_valid_s, bdo_ready,
        msg_auth_valid_s, msg_auth_ready, bdi_partial_s, ascon_cnt_s, hash_s, pad_added_s, bdi_ready_s, ascon_hash_cnt_s)
    BEGIN

        -- Default values preventing latches
        n_state_s <= state_s;

        CASE state_s IS

            WHEN IDLE =>
                -- Wakeup as soon as valid bdi or key is signaled.
                IF (key_valid = '1' OR bdi_valid = '1') THEN
                    IF (hash_in = '1') THEN
                        n_state_s <= INIT_HASH;
                    ELSE
                        n_state_s <= STORE_KEY;
                    END IF;
                END IF;

            WHEN INIT_HASH =>
                n_state_s <= INIT_PROCESS;

            WHEN STORE_KEY =>
                -- Wait until the new key is received.
                -- It is assumed that key is only updated if Npub follows.
                IF (((key_valid = '1' AND key_ready_s = '1') OR key_update = '0') AND word_idx_s >= KEY_WORDS_C - 1) THEN
                    n_state_s <= STORE_NONCE;
                END IF;

            WHEN STORE_NONCE =>
                -- Wait until the whole nonce block is received.
                IF (bdi_valid = '1' AND bdi_ready_s = '1' AND word_idx_s >= NPUB_WORDS_C - 1) THEN
                    n_state_s <= INIT_STATE_SETUP;
                END IF;

            WHEN INIT_STATE_SETUP =>
                n_state_s <= INIT_PROCESS;

            WHEN INIT_PROCESS =>
                -- After state initialization jump to aead or hash routine.
                IF (ascon_cnt_s = std_logic_vector(to_unsigned(UROL,ascon_cnt_s'length))) THEN
                    IF (hash_s = '1') THEN
                        IF (eoi_s = '1') THEN
                            n_state_s <= PAD_HASH_MSG;
                        ELSE
                            n_state_s <= ABSORB_HASH_MSG;
                        END IF;
                    ELSE
                        n_state_s <= INIT_KEY_ADD;
                    END IF;
                END IF;

            WHEN INIT_KEY_ADD =>
                -- If ad length is zero then domain seperation follows directly after.
                IF (eoi_s = '1') THEN
                    n_state_s <= DOM_SEP;
                ELSE
                    n_state_s <= ABSORB_AD;
                END IF;

            WHEN ABSORB_AD =>
                -- Absorb and process ad then perform domain seperation.
                IF (bdi_valid = '1' AND bdi_type /= HDR_AD) THEN
                    n_state_s <= DOM_SEP;
                ELSIF (bdi_valid = '1' AND bdi_ready_s = '1' AND (bdi_eot = '1' OR word_idx_s >= BLOCK_WORDS_C - 1)) THEN
                    n_state_s <= PROCESS_AD;
                END IF;

            WHEN PROCESS_AD =>
                -- Absorb ad blocks until rate is reached or end of type is signaled.
                -- Then check whether padding is necessary or not.
                IF (ascon_cnt_s = std_logic_vector(to_unsigned(UROL,ascon_cnt_s'length))) THEN
                    IF (pad_added_s = '0') THEN
                        IF (eot_s = '1') THEN
                            n_state_s <= PAD_AD;
                        ELSE
                            n_state_s <= ABSORB_AD;
                        END IF;
                    ELSE
                        n_state_s <= DOM_SEP;
                    END IF;
                END IF;

            WHEN PAD_AD =>
                -- Absorb empty block with padding.
                n_state_s <= PROCESS_AD;

            WHEN DOM_SEP =>
                -- Perform domain separation.
                -- If there is no more input absorb empty block with padding.
                IF (eoi_s = '1') THEN
                    n_state_s <= PAD_MSG;
                ELSE
                    n_state_s <= ABSORB_MSG;
                END IF;

            WHEN ABSORB_MSG =>
                -- Absorb msb blocks until rate is reached or end of type is signaled.
                -- Then check whether padding is necessary or not.
                IF (bdi_ready_s = '1') THEN
                    IF (eoi_s = '1') THEN
                        n_state_s <= FINAL_KEY_ADD_1;
                    ELSE
                        IF (bdi_eot = '1') THEN
                            IF (word_idx_s < BLOCK_WORDS_C - 1 OR bdi_partial_s = '1') THEN
                                n_state_s <= FINAL_KEY_ADD_1;
                            ELSE
                                n_state_s <= PROCESS_MSG;
                            END IF;
                        ELSIF (word_idx_s >= BLOCK_WORDS_C - 1) THEN
                            n_state_s <= PROCESS_MSG;
                        END IF;
                    END IF;
                END IF;

            WHEN PROCESS_MSG =>
                -- Process state after absorbing msg block.
                IF (ascon_cnt_s = std_logic_vector(to_unsigned(UROL,ascon_cnt_s'length))) THEN
                    IF (eoi_s = '1') THEN
                        n_state_s <= PAD_MSG;
                    ELSE
                        n_state_s <= ABSORB_MSG;
                    END IF;
                END IF;

            WHEN PAD_MSG =>
                -- Absorb empty block with padding.
                n_state_s <= FINAL_KEY_ADD_1;

            WHEN FINAL_KEY_ADD_1 =>
                -- Second to last key addition.
                n_state_s <= FINAL_PROCESS;

            WHEN FINAL_PROCESS =>
                -- Process state during finalization.
                IF (ascon_cnt_s = std_logic_vector(to_unsigned(UROL,ascon_cnt_s'length))) THEN
                    n_state_s <= FINAL_KEY_ADD_2;
                END IF;

            WHEN FINAL_KEY_ADD_2 =>
                -- After last key addition, either verify or extract the tag.
                IF (decrypt_s = '1') THEN
                    n_state_s <= VERIFY_TAG;
                ELSE
                    n_state_s <= EXTRACT_TAG;
                END IF;

            WHEN EXTRACT_TAG =>
                -- Wait until the whole tag block is transferred, then go back to IDLE.
                IF (bdo_valid_s = '1' AND bdo_ready = '1' AND word_idx_s >= TAG_WORDS_C - 1) THEN
                    n_state_s <= IDLE;
                END IF;

            WHEN VERIFY_TAG =>
                -- Wait until the tag being verified is received, continue
                -- with waiting for acknowledgement on msg_auth_valis.
                IF (bdi_valid = '1' AND bdi_ready_s = '1' AND word_idx_s >= TAG_WORDS_C - 1) THEN
                    n_state_s <= WAIT_ACK;
                END IF;

            WHEN WAIT_ACK =>
                -- Wait until message authentication is acknowledged.
                IF (msg_auth_valid_s = '1' AND msg_auth_ready = '1') THEN
                    n_state_s <= IDLE;
                END IF;

            WHEN ABSORB_HASH_MSG =>
                -- Absorb msg words until either the rate is reached or the end of hash input is signaled.
                -- Then process the state.
                IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                    IF (bdi_eoi = '1' OR word_idx_s >= BLOCK_HASH_WORDS_C - 1) THEN
                        n_state_s <= PROCESS_HASH;
                    END IF;
                END IF;

            WHEN PAD_HASH_MSG =>
                -- Absorb empty block with padding.
                n_state_s <= PROCESS_HASH;

            WHEN PROCESS_HASH =>
                -- Perform ROUNDS_B permutation rounds.
                -- Afterwards, absorb more msg blocks, absorb padding or start extracting the hash value.
                IF (ascon_cnt_s = std_logic_vector(to_unsigned(UROL,ascon_cnt_s'length))) THEN
                    IF (eoi_s = '1') THEN
                        IF (pad_added_s = '1') THEN
                            n_state_s <= EXTRACT_HASH_VALUE;
                        ELSE
                            n_state_s <= PAD_HASH_MSG;
                        END IF;
                    ELSE
                        n_state_s <= ABSORB_HASH_MSG;
                    END IF;
                END IF;

            WHEN EXTRACT_HASH_VALUE =>
                -- Wait until the whole hash is transferred, then go back to IDLE.
                IF (bdo_valid_s = '1' AND bdo_ready = '1' AND word_idx_s >= BLOCK_HASH_WORDS_C - 1) THEN
                    IF (ascon_hash_cnt_s < 3) THEN
                        n_state_s <= PROCESS_HASH;
                    ELSE
                        n_state_s <= IDLE;
                    END IF;
                END IF;

            WHEN OTHERS =>
                n_state_s <= IDLE;

        END CASE;
    END PROCESS p_next_state;

    ----------------------------------------------------------------------------
    --! Decoder process for control logic
    ----------------------------------------------------------------------------
    p_decoder : PROCESS (state_s, key_valid, key_update, update_key_s, eot_s,
        bdi_s, bdi_valid, bdi_ready_s, bdi_eoi, bdi_eot,
        bdi_size, bdi_type, eoi_s, hash_in, hash_s, empty_hash_s, decrypt_in, decrypt_s,
        bdo_ready, word_idx_s, msg_auth_s, msg_auth_valid_s,bdoo_s)
    BEGIN

        -- Default values preventing latches
        key_ready_s <= '0';
        bdi_ready_s <= '0';
        msg_auth_valid_s <= '0';
        n_msg_auth_s <= msg_auth_s;
        n_eoi_s <= eoi_s;
        n_eot_s <= eot_s;
        n_update_key_s <= update_key_s;
        n_hash_s <= hash_s;
        n_empty_hash_s <= empty_hash_s;
        n_decrypt_s <= decrypt_s;

        CASE state_s IS

            WHEN IDLE =>
                -- Default values.
                n_msg_auth_s <= '1';
                n_eoi_s <= '0';
                n_eot_s <= '0';
                n_update_key_s <= '0';
                n_hash_s <= '0';
                n_empty_hash_s <= '0';
                n_decrypt_s <= '0';
                IF (key_valid = '1' AND key_update = '1') THEN
                    n_update_key_s <= '1';
                END IF;
                IF (bdi_valid = '1' AND hash_in = '1') THEN
                    n_hash_s <= '1';
                    IF (bdi_size = EMPTY_HASH_SIZE_C) THEN
                        n_empty_hash_s <= '1';
                        n_eoi_s <= '1';
                        n_eot_s <= '1';
                    END IF;
                END IF;

            WHEN STORE_KEY =>
                -- If key must be updated, assert key_ready.
                IF (update_key_s = '1') THEN
                    key_ready_s <= '1';
                END IF;

            WHEN STORE_NONCE =>
                -- Store bdi_eoi (will only be effective on last word) and decrypt_in flag.
                bdi_ready_s <= '1';
                n_eoi_s <= bdi_eoi;
                n_decrypt_s <= decrypt_in;

                -- If pt or ct is detected, don't assert bdi_ready, otherwise first word gets lost.
                -- Remember if eoi and eot were raised during a valid transfer. 
            WHEN ABSORB_AD =>
                IF (bdi_valid = '1' AND bdi_type = HDR_AD) THEN
                    bdi_ready_s <= '1';
                    n_eoi_s <= bdi_eoi;
                    n_eot_s <= bdi_eot;
                END IF;

            WHEN ABSORB_MSG =>
                -- Only signal bdi_ready if bdo can receive data.
                -- Remember if eoi or eot were raised during a valid transfer.
                IF (bdi_valid = '1' AND (bdi_type = HDR_PT OR bdi_type = HDR_CT)) THEN
                    bdi_ready_s <= bdo_ready;
                    IF (bdi_ready_s = '1') THEN
                        n_eoi_s <= bdi_eoi;
                        n_eot_s <= bdi_eot;
                    END IF;
                END IF;

            WHEN VERIFY_TAG =>
                -- As soon as bdi input doesn't match with calculated tag, reset msg_auth.
                bdi_ready_s <= '1';
                IF (bdi_valid = '1' AND bdi_ready_s = '1' AND bdi_type = HDR_TAG) THEN
                    IF (bdi_s /= bdoo_s) THEN
                        n_msg_auth_s <= '0';
                    END IF;
                END IF;

            WHEN WAIT_ACK =>
                -- Signal msg auth valid.
                msg_auth_valid_s <= '1';

            WHEN INIT_HASH =>
                -- If empty hash is detected, acknowledge with one cycle bdi_ready.
                -- Afterwards empty_hash_s flag can be deasserted, it's not needed anymore.
                IF (empty_hash_s = '1') THEN
                    bdi_ready_s <= '1';
                    n_empty_hash_s <= '0';
                END IF;

            WHEN ABSORB_HASH_MSG =>
                -- Set bdi_ready and connect the valid hash_msg bytes to tag_ram for absorption.
                IF (bdi_valid = '1' AND bdi_type = HDR_HASH_MSG AND eoi_s = '0') THEN
                    bdi_ready_s <= '1';
                    n_eoi_s <= bdi_eoi;
                    n_eot_s <= bdi_eot;
                END IF;

            WHEN OTHERS =>
                NULL;

        END CASE;
    END PROCESS p_decoder;

    ----------------------------------------------------------------------------
    --! Word counters
    ----------------------------------------------------------------------------
    p_counters : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (rst = '1') THEN
                word_idx_s <= 0;
            ELSE
                CASE state_s IS

                    WHEN IDLE =>
                        -- Nothing to do here, reset counters
                        word_idx_s <= 0;

                    WHEN STORE_KEY =>
                        -- If key is to be updated, increase counter on every successful
                        -- data transfer (valid and ready), else just count the cycles.
                        IF (key_update = '1') THEN
                            IF (key_valid = '1' AND key_ready_s = '1') THEN
                                IF (word_idx_s >= KEY_WORDS_C - 1) THEN
                                    word_idx_s <= 0;
                                ELSE
                                    word_idx_s <= word_idx_s + 1;
                                END IF;
                            END IF;
                        ELSE
                            IF (word_idx_s >= KEY_WORDS_C - 1) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1; -- todo necessary?
                            END IF;
                        END IF;

                    WHEN STORE_NONCE =>
                        -- Every time a nonce word is transferred, increase counter
                        IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                            IF (word_idx_s >= NPUB_WORDS_C - 1) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1;
                            END IF;
                        END IF;

                    WHEN ABSORB_AD =>
                        -- On valid transfer, increase word counter until either
                        -- the block size is reached or the last ad word is obtained.
                        IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                            IF (word_idx_s >= BLOCK_WORDS_C - 1 OR (bdi_eot = '1' AND bdi_partial_s = '1')) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1;
                            END IF;
                        END IF;

                    WHEN PAD_AD =>
                        word_idx_s <= 0;

                    WHEN DOM_SEP =>
                        word_idx_s <= 0;

                    WHEN ABSORB_MSG =>
                        -- On valid transfer, increase word counter until either
                        -- the block size is reached or the last msg word is obtained.
                        IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                            IF (word_idx_s >= BLOCK_WORDS_C - 1 OR (bdi_eot = '1' AND bdi_partial_s = '1')) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1;
                            END IF;
                        END IF;

                    WHEN PAD_MSG =>
                        word_idx_s <= 0;

                    WHEN FINAL_PROCESS | FINAL_KEY_ADD_2 =>
                        word_idx_s <= 0;

                    WHEN EXTRACT_TAG =>
                        -- Increase word counter on valid bdo transfer until tag size is reached.
                        IF (bdo_valid_s = '1' AND bdo_ready = '1') THEN
                            IF (word_idx_s >= TAG_WORDS_C - 1) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1;
                            END IF;
                        END IF;

                    WHEN VERIFY_TAG =>
                        -- Increase word counter when transferring the tag.
                        IF (bdi_valid = '1' AND bdi_ready_s = '1' AND bdi_type = HDR_TAG) THEN
                            IF (n_state_s = WAIT_ACK) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1;
                            END IF;
                        END IF;

                    WHEN INIT_HASH =>
                        word_idx_s <= 0;

                    WHEN ABSORB_HASH_MSG =>
                        -- Increase word counter when transferring data until either the block size
                        -- for hash msg is reached or the last word is transferred.
                        IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                            IF (n_state_s = PROCESS_HASH) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1;
                            END IF;
                        END IF;

                    WHEN PAD_HASH_MSG =>
                        word_idx_s <= 0;

                    WHEN EXTRACT_HASH_VALUE =>
                        -- Increase word counter on valid bdo transfer until hash size is reached.
                        IF (bdo_valid_s = '1' AND bdo_ready = '1') THEN
                            IF (n_state_s /= EXTRACT_HASH_VALUE) THEN
                                word_idx_s <= 0;
                            ELSE
                                word_idx_s <= word_idx_s + 1;
                            END IF;
                        END IF;

                    WHEN OTHERS =>
                        NULL;

                END CASE;
            END IF;
        END IF;
    END PROCESS p_counters;

    ----------------------------------------------------------------------------
    --! Ascon FSM
    ----------------------------------------------------------------------------
    p_ascon_fsm : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (rst = '1') THEN
                NULL;
            ELSE
                CASE state_s IS

                    WHEN IDLE =>
                        NULL;

                    WHEN STORE_KEY =>
                        -- Update key register.
                        IF (key_update = '1') THEN
                            IF (key_valid = '1' AND key_ready_s = '1') THEN
                                ascon_key_s(CCW * word_idx_s + CCW - 1 DOWNTO CCW * word_idx_s) <= key_s;
                            END IF;
                        END IF;

                    WHEN STORE_NONCE =>
                        -- Update nonce register.
                        IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                            ascon_state_s(IV_SIZE + KEY_SIZE + CCW*word_idx_s + CCW - 1 DOWNTO IV_SIZE + KEY_SIZE + CCW*word_idx_s) <= bdi_s;
                        END IF;

                    WHEN INIT_STATE_SETUP =>
                        -- Setup state with IV||K||N.
                        ascon_state_s(IV_SIZE - 1 DOWNTO 0) <= reverse_byte(IV_AEAD);
                        ascon_state_s(IV_SIZE + KEY_SIZE - 1 DOWNTO IV_SIZE) <= ascon_key_s;
                        ascon_cnt_s <= ROUNDS_A;
                        pad_added_s <= '0';

                    WHEN INIT_PROCESS =>
                        -- Perform ROUNDS_A permutation rounds.
                        ascon_state_s <= asconp_out_s;
                        ascon_cnt_s <= std_logic_vector(unsigned(ascon_cnt_s) - to_unsigned(UROL,ascon_cnt_s'length));

                    WHEN ABSORB_AD =>
                        -- Absorb ad blocks for aead.
                        IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                            -- Absorb ad into the state.
                            ascon_state_s <= ascon_state_n_s; -- todo new
                            IF (bdi_eot = '1') THEN
                                -- Last absorbed ad block.
                                ascon_cnt_s <= ROUNDS_B;
                                IF (bdi_partial_s = '1') THEN
                                    pad_added_s <= '1';
                                ELSIF (word_idx_s < BLOCK_WORDS_C - 1) THEN
                                    pad_added_s <= '1';
                                END IF;
                            END IF;
                            IF (word_idx_s >= BLOCK_WORDS_C - 1) THEN
                                ascon_cnt_s <= ROUNDS_B;
                            END IF;
                        END IF;

                    WHEN INIT_KEY_ADD =>
                        -- Perform the key addition after initialization.
                        ascon_cnt_s <= ROUNDS_B;
                        ascon_state_s(STATE_SIZE - 1 DOWNTO STATE_SIZE - KEY_SIZE) <= ascon_state_s(STATE_SIZE - 1 DOWNTO STATE_SIZE - KEY_SIZE) XOR ascon_key_s(KEY_SIZE - 1 DOWNTO 0);

                    WHEN PROCESS_AD =>
                        -- Perform ROUNDS_A permutation rounds.
                        ascon_state_s <= asconp_out_s;
                        ascon_cnt_s <= std_logic_vector(unsigned(ascon_cnt_s) - to_unsigned(UROL,ascon_cnt_s'length));

                    WHEN PAD_AD =>
                        -- Absorb empty block with padding.
                        -- (state is only reached if not yet inserted).
                        ascon_state_s(7 DOWNTO 0) <= ascon_state_s(7 DOWNTO 0) XOR X"80";
                        pad_added_s <= '1';
                        ascon_cnt_s <= ROUNDS_B;

                    WHEN DOM_SEP =>
                        -- Perform domain separation.
                        ascon_state_s(STATE_SIZE - 8) <= ascon_state_s(STATE_SIZE - 8) XOR '1';
                        pad_added_s <= '0';

                    WHEN ABSORB_MSG =>
                        -- Absorb msg blocks for aead.
                        IF (bdi_valid = '1' AND bdi_ready_s = '1') THEN
                            ascon_state_s <= ascon_state_n_s;
                            IF (bdi_eot = '1') THEN
                                -- Last absorbed msg block.
                                ascon_cnt_s <= ROUNDS_B;
                                IF (bdi_partial_s = '1') THEN
                                    pad_added_s <= '1';
                                ELSIF (word_idx_s < BLOCK_WORDS_C - 1) THEN
                                    pad_added_s <= '1';
                                END IF;
                            ELSIF (word_idx_s >= BLOCK_WORDS_C - 1) THEN
                                ascon_cnt_s <= ROUNDS_B;
                            END IF;
                        END IF;

                    WHEN PROCESS_MSG =>
                        -- Perform ROUNDS_A permutation rounds.
                        ascon_state_s <= asconp_out_s;
                        ascon_cnt_s <= std_logic_vector(unsigned(ascon_cnt_s) - to_unsigned(UROL,ascon_cnt_s'length));

                    WHEN PAD_MSG =>
                        -- Absorb empty block with padding.
                        -- (state is only reached if not yet inserted).
                        ascon_state_s(7 DOWNTO 0) <= ascon_state_s(7 DOWNTO 0) XOR X"80";
                        pad_added_s <= '1';

                    WHEN FINAL_KEY_ADD_1 =>
                        -- Second to last key addition.
                        ascon_state_s(KEY_SIZE + DBLK_SIZE - 1 DOWNTO DBLK_SIZE) <= ascon_state_s(KEY_SIZE + DBLK_SIZE - 1 DOWNTO DBLK_SIZE) XOR ascon_key_s;
                        ascon_cnt_s <= ROUNDS_A;

                    WHEN FINAL_PROCESS =>
                        -- Perform ROUNDS_A permutation rounds.
                        ascon_state_s <= asconp_out_s;
                        ascon_cnt_s <= std_logic_vector(unsigned(ascon_cnt_s) - to_unsigned(UROL,ascon_cnt_s'length));

                    WHEN FINAL_KEY_ADD_2 =>
                        -- Last key addition.
                        ascon_state_s(STATE_SIZE - 1 DOWNTO STATE_SIZE - KEY_SIZE) <= ascon_state_s(STATE_SIZE - 1 DOWNTO STATE_SIZE - KEY_SIZE) XOR ascon_key_s(KEY_SIZE - 1 DOWNTO 0);

                    WHEN INIT_HASH =>
                        -- Setup state with IV||0*.
                        ascon_state_s(IV_SIZE - 1 DOWNTO 0) <= reverse_byte(IV_HASH);
                        ascon_state_s(STATE_SIZE - 1 DOWNTO IV_SIZE) <= (OTHERS => '0');
                        ascon_cnt_s <= ROUNDS_HASH_A;
                        pad_added_s <= '0';
                        ascon_hash_cnt_s <= 0;

                    WHEN ABSORB_HASH_MSG =>
                        -- Absorb blocks for hashing.
                        IF (bdi_ready_s = '1') THEN
                            -- Absorb full or partial block and add padding if there is space.
                            ascon_state_s <= ascon_state_n_s;
                            IF (bdi_eot = '1') THEN
                                -- Last absorbed block.
                                IF (bdi_partial_s = '1') THEN
                                    pad_added_s <= '1';
                                    ascon_cnt_s <= ROUNDS_HASH_A;
                                ELSIF (word_idx_s < BLOCK_HASH_WORDS_C - 1) THEN
                                    pad_added_s <= '1';
                                    ascon_cnt_s <= ROUNDS_HASH_A;
                                ELSE
                                    ascon_cnt_s <= ROUNDS_HASH_B;
                                END IF;
                            ELSIF (word_idx_s >= BLOCK_HASH_WORDS_C - 1) THEN
                                ascon_cnt_s <= ROUNDS_HASH_B;
                            END IF;
                        END IF;

                    WHEN PAD_HASH_MSG =>
                        -- Absorb empty block with padding.
                        -- (state is only reached if not yet inserted).
                        ascon_state_s(7 DOWNTO 0) <= ascon_state_s(7 DOWNTO 0) XOR X"80";
                        ascon_cnt_s <= ROUNDS_HASH_A;
                        pad_added_s <= '1';

                    WHEN PROCESS_HASH =>
                        -- Perform ROUNDS_A permutation rounds.
                        ascon_state_s <= asconp_out_s;
                        ascon_cnt_s <= std_logic_vector(unsigned(ascon_cnt_s) - to_unsigned(UROL,ascon_cnt_s'length));

                    WHEN EXTRACT_HASH_VALUE =>
                        -- If the current hash block is not the last, set counters accordingly.
                        IF (n_state_s = PROCESS_HASH) THEN
                            ascon_cnt_s <= ROUNDS_HASH_B;
                            ascon_hash_cnt_s <= ascon_hash_cnt_s + 1;
                        END IF;

                    WHEN OTHERS =>
                        NULL;

                END CASE;
            END IF;
        END IF;
    END PROCESS p_ascon_fsm;

END behavioral;
