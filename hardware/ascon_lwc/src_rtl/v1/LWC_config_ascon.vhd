--===============================================================================================--
--! @file       LWC_config.vhd
--! 
--! @brief      Template for LWC package configuration (LWC_config)
--!
--! @author     Kamyar Mohajerani
--! @copyright  Copyright (c) 2022 Cryptographic Engineering Research Group
--!             ECE Department, George Mason University Fairfax, VA, USA
--!             All rights Reserved.
--! @license    This work is dual-licensed under Solderpad Hardware License v2.1 (SHL-2.1) and 
--!                GNU General Public License v3.0 (GPL-3.0)
--!             For more information please see:
--!                Solderpad Hardware License v2.1:  https://spdx.org/licenses/SHL-2.1.html and
--!                GNU General Public License v3.0:  https://spdx.org/licenses/GPL-3.0.html
--!
--!
--! @note       This package is used in the NIST_LWAPI_pkg package, and therefore the file 
--!               containing this package (LWC_config.vhd) should go _before_ NIST_LWAPI_pkg.vhd
--!               in the compilation order.
--!
--! @note       All configurable LWC package parameters (W, SW, ASYNC_RSTN, etc) should only be
--!               change in this package.
--!
--! @note       Make a copy of this file to your source folder.
--!             The recommended naming for the file is `LWC_config.vhd` (or `LWC_config_XX.vhd`)
--!
--===============================================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package LWC_config_ascon is

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

end package;
