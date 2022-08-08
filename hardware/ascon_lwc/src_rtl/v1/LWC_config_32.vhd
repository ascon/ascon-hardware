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

package LWC_config is
    --! External bus: supported values are 8, 16 and 32 bits
    constant W          : positive := 32;
    --! currently only W=SW is supported
    constant SW         : positive := W;
    --! Change the default value ONLY in a masked implementation
    --! Number of PDI shares, 1 for a non-masked implementation
    constant PDI_SHARES : positive := 1;
    --! Number of SDI shares, 1 for a non-masked implementation
    --! Does not need to be the same as PDI_SHARES but this is the default
    constant SDI_SHARES : positive := PDI_SHARES;
    --! Width of RDI port in bits. Set to 0 if not used.
    constant RW         : natural  := 0;
    --! Assume an asynchronous and active-low reset.
    --! Can be set to `True` given that support for it is implemented in the CryptoCore
    constant ASYNC_RSTN : boolean := False;
end package;
