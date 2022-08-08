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

package LWC_config_ccw is
    constant CCW        : integer := 32; --! bdo/bdi width
    constant CCSW       : integer := CCW; --! key width
    constant CCWdiv8    : integer := CCW/8; -- derived from parameters above
end package;

