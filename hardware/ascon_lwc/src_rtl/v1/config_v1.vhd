library IEEE;
use IEEE.STD_LOGIC_1164.all;

package config_pkg is

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
    constant CCW             : integer := 32; --! bdo/bdi width
    constant CCSW            : integer := 32; --! key width
    constant CCWdiv8         : integer := CCW/8; -- derived from parameters above
    constant NPUB_SIZE       : integer := 128; --! Npub size
    constant W               : integer := 32;
    constant SW              : integer := W;

end config_pkg;

