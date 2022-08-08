--------------------------------------------------------------------------------
--! @file       DATA_SIPO.vhd
--! @brief      Width converter for NIST LWC API
--!
--! @author     Michael Tempelmeier
--! @copyright  Copyright (c) 2019 Chair of Security in Information Technology     
--!             ECE Department, Technical University of Munich, GERMANY

--! @license    This project is released under the GNU Public License.          
--!             The license and distribution terms for this file may be         
--!             found in the file LICENSE in this distribution or at            
--!             http://www.gnu.org/licenses/gpl-3.0.txt                         
--! @note       This is publicly available encryption source code that falls    
--!             under the License Exception TSU (Technology and software-       
--!             unrestricted)                                                  
--------------------------------------------------------------------------------
--! Description
--! 
--! 
--! 
--! 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.design_pkg.all;
use work.NIST_LWAPI_pkg.all;

entity DATA_SIPO is

    port(
        clk          : in  std_logic;
        rst          : in  std_logic;
        -- Serial (width=CCW) input
        data_s       : in  STD_LOGIC_VECTOR(PDI_SHARES * CCW - 1 downto 0);
        end_of_input : in  STD_LOGIC;   -- last input word
        data_valid_s : in  STD_LOGIC;
        data_ready_s : out STD_LOGIC;
        -- Parallel (width=W) output (W >= CCW)
        data_p       : out STD_LOGIC_VECTOR(PDI_SHARES * W - 1 downto 0);
        data_valid_p : out STD_LOGIC;
        data_ready_p : in  STD_LOGIC
    );

end entity DATA_SIPO;

architecture behavioral of DATA_SIPO is

begin

    GEN_NONTRIVIAL : if W /= CCW generate
        type t_state is (LD_1, LD_2, LD_3, LD_4);
        signal nx_state, state : t_state;
        signal mux             : integer range 1 to 4;
        signal reg             : std_logic_vector(31 downto 8);
    begin
        assert PDI_SHARES = 1 and ((W = 32 and (CCW = 8 OR CCW = 16)) or (W = 16 and CCW = 8))
        report "[ERROR] Configuration is not supported! PDI_SHARES=" & integer'image(PDI_SHARES) & " W=" & integer'image(W) & " CCW=" & integer'image(CCW)
        severity failure;

        GEN_proc_SYNC_RST : if (not ASYNC_RSTN) generate
            process(clk)
            begin
                if rising_edge(clk) then
                    if (rst = '1') then
                        state <= LD_1;
                    else
                        state <= nx_state;
                    end if;
                end if;
            end process;
        end generate GEN_proc_SYNC_RST;
        GEN_proc_ASYNC_RSTN : if (ASYNC_RSTN) generate
            process(clk, rst)
            begin
                if (rst = '0') then
                    state <= LD_1;
                elsif rising_edge(clk) then
                    state <= nx_state;
                end if;
            end process;
        end generate GEN_proc_ASYNC_RSTN;

        CCW8 : if CCW = 8 generate
            process(state, data_valid_s, data_ready_p, end_of_input)
            begin
                case state is

                    when LD_1 =>
                        mux <= 1;
                        if (end_of_input = '1') then --last word
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_1;
                            end if;
                        else
                            data_ready_s <= '1';
                            data_valid_p <= '0';
                            if data_valid_s = '1' then
                                nx_state <= LD_2;
                            else
                                nx_state <= LD_1;
                            end if;
                        end if;

                    when LD_2 =>
                        mux <= 2;
                        if (end_of_input = '1') then --last word
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_2;
                            end if;
                        else
                            data_ready_s <= '1';
                            data_valid_p <= '0';
                            if data_valid_s = '1' then
                                nx_state <= LD_3;
                            else
                                nx_state <= LD_2;
                            end if;
                        end if;

                    when LD_3 =>
                        mux <= 3;
                        if (end_of_input = '1') then --last word
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_3;
                            end if;
                        else
                            data_ready_s <= '1';
                            data_valid_p <= '0';
                            if data_valid_s = '1' then
                                nx_state <= LD_4;
                            else
                                nx_state <= LD_3;
                            end if;
                        end if;

                    when LD_4 =>
                        mux <= 4;
                        if (end_of_input = '1') then --last word
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_4;
                            end if;
                        else
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_4;
                            end if;
                        end if;
                end case;
            end process;

            process(clk)
            begin
                if (rising_edge(clk)) then
                    case mux is
                        when 1 =>
                            reg(31 downto 24) <= data_s;
                        when 2 =>
                            reg(23 downto 16) <= data_s;
                        when 3 =>
                            reg(15 downto 8) <= data_s;
                        when 4 =>
                            null;
                    end case;
                end if;
            end process;

            data_p <= data_s & x"00_00_00" when (mux = 1) else
                      reg(31 downto 24) & data_s & x"00_00" when (mux = 2) else
                      reg(31 downto 16) & data_s & x"00" when (mux = 3) else
                      reg(31 downto 8) & data_s;

        end generate CCW8;

        CCW16 : if CCW = 16 generate
            process(state, data_valid_s, data_ready_p, end_of_input)
            begin
                case state is

                    when LD_1 =>
                        mux <= 1;
                        if (end_of_input = '1') then --last word
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_1;
                            end if;
                        else
                            data_ready_s <= '1';
                            data_valid_p <= '0';
                            if data_valid_s = '1' then
                                nx_state <= LD_2;
                            else
                                nx_state <= LD_1;
                            end if;
                        end if;

                    when LD_2 =>
                        mux <= 2;
                        if (end_of_input = '1') then --last word
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_2;
                            end if;
                        else
                            data_ready_s <= data_ready_p;
                            data_valid_p <= data_valid_s;
                            if data_valid_s = '1' AND data_ready_p = '1' then
                                nx_state <= LD_1;
                            else
                                nx_state <= LD_2;
                            end if;
                        end if;

                    when others =>
                        mux          <= 1;
                        nx_state     <= state;
                        data_valid_p <= '-';
                        data_ready_s <= '-';
                        report "FSM error!" severity failure;
                end case;
            end process;

            process(clk)
            begin
                if rising_edge(clk) then
                    case mux is
                        when 1 =>
                            reg(31 downto 16) <= data_s;
                        when 2 =>
                            null;
                        when others =>
                            report "MUX error!" severity failure;
                    end case;
                end if;
            end process;

            data_p <= data_s & x"00_00" when (mux = 1) else reg(31 downto 16) & data_s;

        end generate CCW16;

    end generate GEN_NONTRIVIAL;

    GEN_TRIVIAL : if W = CCW generate   --No PISO needed
        data_p       <= data_s;
        data_valid_p <= data_valid_s;
        data_ready_s <= data_ready_p;
    end generate GEN_TRIVIAL;

end behavioral;
