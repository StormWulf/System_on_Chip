-------------------------------------------------------------------------------
-- addr_counter_mux.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
-- ***************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2007, 2009 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
-- ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        addr_counter_mux.vhd
-- Description:     This file contains the addr_counter and mux for the EMC 
--                  design.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  emc.vhd
--                      -- ipic_if.vhd
--                      -- addr_counter_mux.vhd
--                      -- counters.vhd
--                      -- select_param.vhd
--                      -- mem_state_machine.vhd
--                      -- mem_steer.vhd
--                      -- io_registers.vhd
-------------------------------------------------------------------------------
-- Author:          NSK
-- History:
-- NSK             02/01/08    First Version
-- ^^^^^^^^^^
-- This file is same as in version v2_01_c - no change in the logic of this 
-- module. Deleted the history from version v2_01_c.
-- ~~~~~~
-- NSK         02/12/08    Updated
-- ^^^^^^^^
-- Removed the unused part of code (not supporting C_IPIF_DWIDTH = 64): -
-- 1. Deleted the generate block lebelled "CYCLE_END_CNT_64_GEN".
-- 2. In the process "ADDR_SUFFIX_PROCESS" deleted the part of code as 
--    C_ADDR_OFFSET = 3 is valid only when C_IPIF_DWIDTH = 64 is supported.
-- ~~~~~~~~
-- NSK         05/08/08    version v3_00_a
-- ^^^^^^^^
-- 1. This file is same as in version v2_02_a.
-- 2. Upgraded to version v3.00.a to have proper versioning to fix CR #472164.
-- 3. No change in design.
--
-- KSB         05/08/08    version v4_00_a
-- 1. Modified for Page mdoe read
-- 2. Modified for 64 Bit memory address align
-- ~~~~~~~~
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for ld_arith_reg
-- declaration
-------------------------------------------------------------------------------

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.all;

-------------------------------------------------------------------------------
-- vcomponents package of the unisim library is used for the FDR and FDCE
-- component declaration
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_ADDR_CNTR_WIDTH       -- Width of address counter
--      C_IPIF_AWIDTH           -- Width of IPIF address bus
--      C_IPIF_DWIDTH           -- Width of IPIF data bus
--      C_ADDR_OFFSET           -- Unused lower address bits based on data 
--                                 width
--      C_GLOBAL_DATAWIDTH_MATCH-- Indicates whether any memory bank is
--                                 supporting data width matching
--
-- Definition of Ports:
--      Bus2IP_Addr             -- Processor address bus
--      Bus2IP_BE               -- Processor bus byte enables
--      Address_strobe          -- Address strobe signal
--      Data_strobe             -- Data and BEs strobe signal
--      Mem_width_bytes         -- Width in bytes of currently addressed 
--                                 memory bank
--      Datawidth_match         -- Data width matching for currently addressed 
--                                 memory bank 
--      Addr_cnt_ce             -- Address counter count enable
--      Addr_cnt_rst            -- Address counter reset
--      Addr_cnt                -- Address count
--      Cycle_cnt_ld            -- Cycle end counter count load
--      Cycle_cnt_en            -- Cycle end counter count enable
--      Cycle_end               -- Current cycle end flag
--      Mem_addr                -- Address out to memory
--      Mem_Ben                 -- Memory byte enables
--      Clk                     -- System Clock
--      Rst                     -- System Reset
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity addr_counter_mux is
    generic( 
        C_ADDR_CNTR_WIDTH           : integer range 1 to 5;
        C_IPIF_AWIDTH               : integer;
        C_IPIF_DWIDTH               : integer;
        C_ADDR_OFFSET               : integer range 0 to 4;
        C_GLOBAL_DATAWIDTH_MATCH    : integer range 0 to 1
    );
    port(
        Bus2IP_Addr           : in  std_logic_vector(0 to C_IPIF_AWIDTH-1);
        Bus2IP_BE             : in  std_logic_vector(0 to C_IPIF_DWIDTH/8-1);
        Address_strobe        : in  std_logic;
        Data_strobe           : in  std_logic;

        Mem_width_bytes       : in  std_logic_vector(0 to 3);
        Datawidth_match       : in  std_logic;

        Addr_cnt_ce           : in  std_logic;
        Addr_cnt_rst          : in  std_logic;
        Addr_cnt              : out std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
        Addr_align            : out std_logic;
        
        Cycle_cnt_ld          : in  std_logic;
        Cycle_cnt_en          : in  std_logic; 
        Cycle_End             : out std_logic;
        
        Mem_addr              : out std_logic_vector(0 to C_IPIF_AWIDTH-1);
        Mem_Ben               : out std_logic_vector(0 to C_IPIF_DWIDTH/8-1);
        
        Clk                   : in  std_logic;
        Rst                   : in  std_logic
    );
end entity addr_counter_mux;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture imp of addr_counter_mux is

-------------------------------------------------------------------------------
-- Constant declarations
-------------------------------------------------------------------------------
-- reset values

constant ZERO_CYCLE_CNT : std_logic_vector(0 to (log2(C_IPIF_DWIDTH/8)-1)) 
                            := (others => '0');

-------------------------------------------------------------------------------
-- Signal declarations
-------------------------------------------------------------------------------
signal addr_cnt_i       : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
signal addr_suffix      : std_logic_vector(0 to C_ADDR_OFFSET-1) 
                            := (others => '0');

signal addr_cnt_val     : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
signal cycle_cnt        : std_logic_vector(0 to (log2(C_IPIF_DWIDTH/8)-1)); 
signal cycle_end_cnt    : std_logic_vector(0 to (log2(C_IPIF_DWIDTH/8)-1));
signal int_addr         : std_logic_vector(0 to C_IPIF_AWIDTH-1);
signal Mem_Ben_i        : std_logic_vector(0 to C_IPIF_DWIDTH/8-1);

signal mem_addr_cmb     : std_logic_vector(0 to C_IPIF_AWIDTH-1);
signal addr_cnt_cmb     : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);

signal addr_align_32_64 : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin 

    ---------------------------------------------------------------------------
    -- Store the address coming from bus as address ack and data ack are issued 
    -- early to make burst appear as continuous on memory side.
    ---------------------------------------------------------------------------

    Mem_Ben  <= Mem_Ben_i;

    ADDRESS_STORE_GEN: for i in 0 to C_IPIF_AWIDTH - 1 generate
    begin
        ADDRESS_REG: FDRE
        port map (
            Q   => int_addr(i),       --[out]
            C   => Clk,               --[in]
            CE  => Data_strobe,       --[in]
            D   => Bus2IP_Addr(i),    --[in]
            R   => Rst                --[in]
            );
    end generate ADDRESS_STORE_GEN;
    
    ---------------------------------------------------------------------------
    -- Store the Byte Enables coming from bus as address ack and data ack are 
    -- issued early to make burst appear as continuous one on memory side.
    ---------------------------------------------------------------------------

    BEN_STORE_GEN: for i in 0 to C_IPIF_DWIDTH/8-1 generate
    begin
      BEN_REG: FDRE
        port map (
            Q   => Mem_Ben_i(i),      --[out]
            C   => Clk,               --[in]
            CE  => Data_strobe,       --[in]
            D   => Bus2IP_BE(i),      --[in]
            R   => Rst                --[in]
            );       
    end generate BEN_STORE_GEN;

    ---------------------------------------------------------------------------
    -- Address and address count generation logic.
    ---------------------------------------------------------------------------

    Mem_addr  <= mem_addr_cmb;
    Addr_cnt  <= addr_cnt_cmb;

    ---------------------------------------------------------------------------
    ---------------------------- NO DATAWIDTH MATCHING ------------------------
    -- If datawidth matching has not been turned on for any memory banks, 
    -- simplify the logic.
    ---------------------------------------------------------------------------

    NO_DATAWIDTH_MATCH_GEN: if C_GLOBAL_DATAWIDTH_MATCH = 0 generate
    begin
        addr_cnt_cmb <= (others => '0');
        mem_addr_cmb <= int_addr;
        Cycle_End    <= '1';
    end generate NO_DATAWIDTH_MATCH_GEN;

    ---------------------------------------------------------------------------
    ---------------------------- DATAWIDTH MATCHING ---------------------------
    -- If datawidth matching has been turned on at least 1 memory bank, 
    -- implement the data width matching logic. Note that an individual bank 
    -- with datawidth matching turned off will still use this logic.
    ---------------------------------------------------------------------------

    DATAWIDTH_MATCH_GEN: if C_GLOBAL_DATAWIDTH_MATCH = 1 generate
    begin

        -----------------------------------------------------------------------
        -- Assign output signals
        -----------------------------------------------------------------------
        addr_cnt_cmb <= (others => '0') when Datawidth_match = '0' else
                        addr_cnt_i;
        
        ADDR_CNT_PROCESS : process(Clk)
        begin
            if(Clk'EVENT and Clk = '1') then
                if(Rst = '1')then
                    addr_cnt_i  <= (others=>'0');
                elsif Addr_cnt_rst = '1' then
                    addr_cnt_i  <= addr_cnt_val;
                elsif Addr_cnt_ce = '1' then
                addr_cnt_i  <= addr_cnt_i + 1;
                end if;   
            end if;     
        end process ADDR_CNT_PROCESS;

        -----------------------------------------------------------------------
        -- Create cycle termination logic for C_IPIF_DWIDTH  = 64.
        -----------------------------------------------------------------------

        CYCLE_END_CNT_64_GEN : if C_IPIF_DWIDTH  = 64 generate
        begin
            mem_addr_cmb <= int_addr when Datawidth_match = '0' else
                            int_addr(0 to C_IPIF_AWIDTH-C_ADDR_OFFSET-1) 
                            & addr_suffix;
            Addr_align   <= '0';

            ---------------------------------------------------------------------
            -- Create the address suffix.
            ---------------------------------------------------------------------

            ADDR_SUFFIX_PROCESS_64: process(Mem_width_bytes,Bus2IP_Addr,
                                                                        addr_cnt_i)
            begin
                addr_suffix <= (others => '0');
                addr_cnt_val<= (others => '0');
                case Mem_width_bytes is
                  when "0001" =>   
                      addr_suffix    <= addr_cnt_i;
                      addr_cnt_val   <= Bus2IP_Addr(C_IPIF_AWIDTH-C_ADDR_OFFSET 
                                                    to C_IPIF_AWIDTH - 1);
                  when "0010" =>
                      addr_suffix    <= addr_cnt_i(1 to C_ADDR_CNTR_WIDTH-1) & '0';
                      addr_cnt_val   <= '0' & Bus2IP_Addr(C_IPIF_AWIDTH-
                                        C_ADDR_OFFSET to C_IPIF_AWIDTH - 2);
                  when "0100" =>
                      addr_suffix <= addr_cnt_i(2 to C_ADDR_CNTR_WIDTH-1) & "00";
                      addr_cnt_val<= "00" & Bus2IP_Addr(C_IPIF_AWIDTH-C_ADDR_OFFSET
                                                  to C_IPIF_AWIDTH - 3);
                  when "1000" =>
                      addr_suffix <= (others => '0');
                      addr_cnt_val<= (others => '0');
                  when others=>   
                      addr_suffix <= (others => '0');
                      addr_cnt_val<= (others => '0');
                end case;
            end process ADDR_SUFFIX_PROCESS_64;
            ---------------------------------------------------------------------
            -- Create the  cycle_end_cnt
            ---------------------------------------------------------------------
            CYCLE_END_CNT_PROCESS_64 : process(Mem_width_bytes, Bus2IP_BE)
            begin
                case Mem_width_bytes is
                  when "0001" =>            
                    if (Bus2IP_BE = "11111111") then
                        cycle_end_cnt <= "111";
                    elsif (Bus2IP_BE = "01111111" or Bus2IP_BE = "11111110") 
                            then
                        cycle_end_cnt <= "110";
                    elsif (Bus2IP_BE = "01111110" or Bus2IP_BE = "11111100" or
                           Bus2IP_BE = "00111111") then
                        cycle_end_cnt <= "101";
                    elsif (Bus2IP_BE = "11111000" or Bus2IP_BE = "01111100" or
                           Bus2IP_BE = "00111110" or Bus2IP_BE = "00011111") 
                            then
                        cycle_end_cnt <= "100";
                    elsif (Bus2IP_BE = "00001111" or Bus2IP_BE = "11110000" or 
                           Bus2IP_BE = "01111000" or Bus2IP_BE = "00111100" or
                           Bus2IP_BE = "00011110") then
                        cycle_end_cnt <= "011";
                    elsif (Bus2IP_BE = "11100000" or Bus2IP_BE = "01110000" or
                           Bus2IP_BE = "00111000" or Bus2IP_BE = "00011100" or
                           Bus2IP_BE = "00001110" or Bus2IP_BE = "00000111") 
                            then
                        cycle_end_cnt <= "010";   
                    elsif (Bus2IP_BE = "00000011" or Bus2IP_BE = "00001100" or
                           Bus2IP_BE = "00110000" or Bus2IP_BE = "11000000" or 
                           Bus2IP_BE = "01100000" or Bus2IP_BE = "00011000" or
                           Bus2IP_BE = "00000110") then
                        cycle_end_cnt <= "001";
                    else
                        cycle_end_cnt <= "000";
                    end if;
                  when "0010" =>                
                    if (Bus2IP_BE = "11111111" or Bus2IP_BE = "01111111" or 
                        Bus2IP_BE = "11111110" or Bus2IP_BE = "01111110") then 
                        cycle_end_cnt <= "011";
                    elsif (Bus2IP_BE = "11111100" or Bus2IP_BE = "01111100" or
                           Bus2IP_BE = "01111000" or Bus2IP_BE = "00111111" or
                           Bus2IP_BE = "11111000" or Bus2IP_BE = "00111110" or 
                           Bus2IP_BE = "00011111" or Bus2IP_BE = "00011110") 
                           then
                        cycle_end_cnt <= "010";   
                    elsif (Bus2IP_BE = "00001111" or Bus2IP_BE = "11110000" or
                           Bus2IP_BE = "11100000" or Bus2IP_BE = "01110000" or
                           Bus2IP_BE = "00111000" or Bus2IP_BE = "00011100" or
                           Bus2IP_BE = "00001110" or Bus2IP_BE = "00000111" or
                           Bus2IP_BE = "01100000" or Bus2IP_BE = "00011000" or
                           Bus2IP_BE = "00000110" or Bus2IP_BE = "00111100") 
                            then
                        cycle_end_cnt <= "001";
                    else
                        cycle_end_cnt <= "000";
                    end if;                    
                  when "0100" =>
                    if (Bus2IP_BE = "11111111" or Bus2IP_BE = "11111110" or
                        Bus2IP_BE = "01111111" or Bus2IP_BE = "00111111" or
                        Bus2IP_BE = "00011111" or Bus2IP_BE = "11111100" or
                        Bus2IP_BE = "11111000" or Bus2IP_BE(3 to 4) = "11") 
                           then
                        cycle_end_cnt <= "001";
                    else
                        cycle_end_cnt <= "000";
                    end if;
                  when "1000" =>
                          cycle_end_cnt <= "000" ;                  
                  when others =>   
                          cycle_end_cnt <= "000" ;                     
                end case;      
            end process CYCLE_END_CNT_PROCESS_64;
        end generate CYCLE_END_CNT_64_GEN;

        -----------------------------------------------------------------------
        -- Create cycle termination logic for C_IPIF_DWIDTH  = 32.
        -----------------------------------------------------------------------

        CYCLE_END_CNT_32_GEN : if C_IPIF_DWIDTH  = 32 generate
        begin
            Addr_align <= addr_align_32_64;

            -------------------------------------------------------------------
            -- Create the address suffix.
            -------------------------------------------------------------------
            ADDR_SUFFIX_PROCESS_32: process(Mem_width_bytes, Bus2IP_Addr, 
                                                      addr_cnt_i, int_addr)
            begin
                  addr_suffix      <= (others => '0');
                  addr_cnt_val     <= (others => '0');
                  addr_align_32_64 <= '0';
                  case Mem_width_bytes is
                    when "0001" =>   
                        addr_suffix  <= addr_cnt_i;
                        addr_cnt_val <= Bus2IP_Addr(C_IPIF_AWIDTH-C_ADDR_OFFSET 
                                                      to C_IPIF_AWIDTH - 1);
                    when "0010" =>
                        addr_suffix  <= addr_cnt_i(1 to C_ADDR_CNTR_WIDTH-1) & '0';
                        addr_cnt_val <= '0' & Bus2IP_Addr(C_IPIF_AWIDTH-
                                          C_ADDR_OFFSET to C_IPIF_AWIDTH - 2);
                    when "0100" =>
                        addr_suffix  <= (others => '0');
                        addr_cnt_val <= (others => '0');
                    when "1000" =>
                        addr_suffix  <= (others => '0');
                        addr_cnt_val <= (others => '0');
                    addr_align_32_64 <=int_addr(C_IPIF_AWIDTH-C_ADDR_OFFSET-1);
                    when others=>   
                        addr_suffix  <= (others => '0');
                        addr_cnt_val <= (others => '0');
                  end case;
            end process ADDR_SUFFIX_PROCESS_32;
            ---------------------------------------------------------------------
            -- Create the  cycle_end_cnt
            ---------------------------------------------------------------------
            MEM_ADDR_PROCESS: process(Mem_width_bytes, int_addr, 
                                                 Datawidth_match, addr_suffix)
            begin
              case Mem_width_bytes is
                when "1000" =>
                  if (Datawidth_match = '0') then
                    mem_addr_cmb <= int_addr; 
                  else
                    mem_addr_cmb <= int_addr(0 to C_IPIF_AWIDTH-
                                                    C_ADDR_OFFSET-2) & "000";
                  end if;

                when others =>
                  if (Datawidth_match = '0') then
                    mem_addr_cmb <= int_addr; 
                  else
                    mem_addr_cmb <= int_addr(0 to C_IPIF_AWIDTH-
                                            C_ADDR_OFFSET-1) & addr_suffix;
                  end if;  
                end case;
            end process MEM_ADDR_PROCESS;
          ---------------------------------------------------------------------
          -- Create the  cycle_end_cnt
          ---------------------------------------------------------------------
            CYCLE_END_CNT_PROCESS_32 : process(Mem_width_bytes, Bus2IP_BE)
            begin          
                case Mem_width_bytes is
                    when "0001" =>                  
                        if (Bus2IP_BE = "1111") then
                            cycle_end_cnt <= "11";
                        elsif (Bus2IP_BE = "0111" or Bus2IP_BE = "1110") then
                            cycle_end_cnt <= "10";   
                        elsif (Bus2IP_BE = "0011" or Bus2IP_BE = "1100" or
                               Bus2IP_BE = "0110") then
                            cycle_end_cnt <= "01";
                        else
                            cycle_end_cnt <= "00";
                        end if;                 
                    when "0010" =>
                        if (Bus2IP_BE = "1111" or Bus2IP_BE = "0111" or  
                            Bus2IP_BE = "0110" or Bus2IP_BE = "1110") then
                            cycle_end_cnt <= "01";
                        else
                            cycle_end_cnt <= "00";
                        end if;                
                    when "0100" =>                
                            cycle_end_cnt <= "00" ;                       
                    when "1000" =>
                            cycle_end_cnt <= "00" ;                  
                    when others =>   
                            cycle_end_cnt <= "00" ;                     
                end case;
            end process CYCLE_END_CNT_PROCESS_32;
        end generate CYCLE_END_CNT_32_GEN;

        -----------------------------------------------------------------------
        -- Instantiate the cycle_end_counter.
        -----------------------------------------------------------------------

        CYCLE_END_CNTR_I:entity proc_common_v3_00_a.ld_arith_reg
        generic map (
             C_ADD_SUB_NOT  => false,
             C_REG_WIDTH    => C_ADDR_CNTR_WIDTH,
             C_RESET_VALUE  => ZERO_CYCLE_CNT,
             C_LD_WIDTH     => C_ADDR_CNTR_WIDTH,
             C_LD_OFFSET    => 0,
             C_AD_WIDTH     => 1,
             C_AD_OFFSET    => 0
            )
        port map (   
             CK             => Clk,
             RST            => Rst,
             Q              => cycle_cnt,   
             LD             => cycle_end_cnt, 
             AD             => "1",  
             LOAD           => Cycle_cnt_ld,
             OP             => Cycle_cnt_en
             );

        Cycle_End <=  '1'  when cycle_cnt = ZERO_CYCLE_CNT else
              '0';
    end generate DATAWIDTH_MATCH_GEN;
end imp;
-------------------------------------------------------------------------------
-- End of File addr_counter_mux.vhd.
-------------------------------------------------------------------------------
