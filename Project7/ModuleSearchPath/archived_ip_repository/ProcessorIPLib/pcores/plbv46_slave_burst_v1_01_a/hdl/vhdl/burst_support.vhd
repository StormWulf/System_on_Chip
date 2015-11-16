-------------------------------------------------------------------------------
-- $Id: burst_support.vhd,v 1.1 2008/04/29 20:49:11 gburch Exp $
-------------------------------------------------------------------------------
-- burst_support.vhd
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This text/file contains proprietary, confidential                    **
--  **  information of Xilinx, Inc., is distributed under                    **
--  **  license from Xilinx, Inc., and may be used, copied                   **
--  **  and/or disclosed only pursuant to the terms of a valid               **
--  **  license agreement with Xilinx, Inc. Xilinx hereby                    **
--  **  grants you a license to use this text/file solely for                **
--  **  design, simulation, implementation and creation of                   **
--  **  design files limited to Xilinx devices or technologies.              **
--  **  Use with non-Xilinx devices or technologies is expressly             **
--  **  prohibited and immediately terminates your license unless            **
--  **  covered by a separate agreement.                                     **
--  **                                                                       **
--  **  Xilinx is providing this design, code, or information                **
--  **  "as-is" solely for use in developing programs and                    **
--  **  solutions for Xilinx devices, with no obligation on the              **
--  **  part of Xilinx to provide support. By providing this design,         **
--  **  code, or information as one possible implementation of               **
--  **  this feature, application or standard, Xilinx is making no           **
--  **  representation that this implementation is free from any             **
--  **  claims of infringement. You are responsible for obtaining            **
--  **  any rights you may require for your implementation.                  **
--  **  Xilinx expressly disclaims any warranty whatsoever with              **
--  **  respect to the adequacy of the implementation, including             **
--  **  but not limited to any warranties or representations that this       **
--  **  implementation is free from claims of infringement, implied          **
--  **  warranties of merchantability or fitness for a particular            **
--  **  purpose.                                                             **
--  **                                                                       **
--  **  Xilinx products are not intended for use in life support             **
--  **  appliances, devices, or systems. Use in such applications is         **
--  **  expressly prohibited.                                                **
--  **                                                                       **
--  **  Any modifications that are made to the Source Code are               **
--  **  done at the user’s sole risk and will be unsupported.                **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Hotline support of original source         **
--  **  code IP shall only address issues and questions related              **
--  **  to the standard Netlist version of the core (and thus                **
--  **  indirectly, the original core source).                               **
--  **                                                                       **
--  **  Copyright (c) 2008 Xilinx, Inc. All rights reserved.                 **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
-------------------------------------------------------------------------------
-- Filename:        burst_support.vhd
-- Version:         v1_00_a
-- Description:     
-- This VHDL design implements burst support features that are used for fixed
-- length bursts and cacheline transfers. Some indeterminate burst support  
-- logic is provided.                
--                  
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--                  plbv46_slave_burst.vhd
--                      -- data_mirror_128.vhd
--                      -- plb_slave_attachment.vhd
--                          -- plb_address_decoder.vhd
--                          -- addr_reg_cntr_brst_flex.vhd
--                              -- flex_addr_cntr.vhd
--                          -- wr_buffer.vhd
--                          -- be_reset_gen.vhd
--                          -- burst_support.vhd
--
-------------------------------------------------------------------------------
-- Author:          DET
-- Revision:        $Revision: 1.1 $
-- Date:            $5/15/2002$
--
-- History:
--     DET     6/12/2003     Initial
-- ~~~~~~
--     - This design was adapted from the determinate timer module.
-- ^^^^^^
--
--     DET     3/25/2004     plb ipif to  V1_00_f
-- ~~~~~~
--     - Removed reference to ipif_common_library
--     - Updated proc_common library reference to v2_00_a
-- ^^^^^^
--
--     DET     4/12/2004     IPIF to V1_00_f
-- ~~~~~~
--     - Updated unisim library reference to unisim.vcomponents.all
--     - Commented out Xilinx primitive component declarations
-- ^^^^^^
--    GAB      10/14/05      IPIF to plbv46_slave_v1_00_a
-- ~~~~~~
--     - Modified to support UserIP Burst Terminate
-- ^^^^^^
--    GAB      3/31/05      
-- ~~~~~~
--     - Compared MAX Burst size parameter to actually number of data beats
--       to set control and responce count values.
-- ^^^^^^
--      GAB    4/29/2008   v1.01.a     
-- ~~~~~~
--     - Updated to use proc_common_v3_00_a library
-- ^^^^^^
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
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.all;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.counter_f;

-- Xilinx Primitive Library
library unisim;
use unisim.vcomponents.all;


-------------------------------------------------------------------------------

entity burst_support is
  generic (
    -- Generics
    C_MAX_DBEAT_CNT     : integer := 16         ;
    C_FAMILY            : string  := "virtex4"
    );
  port (
    -- Input ports
    Bus_reset           : in std_logic          ;
    Bus_clk             : in std_logic          ;
    RNW                 : in std_logic          ;
    Req_Init            : in std_logic          ;

    Num_Data_Beats      : in integer            ;
    Target_AddrAck      : in std_logic          ;
    Target_DataAck      : in std_logic          ;
    WrBuf_wen           : in std_logic          ;
    
    -- Output signals
    Control_Ack         : out std_logic         ;
    Control_Done        : out std_logic         ;
    Response_Ack        : out std_logic         ;
    Response_AlmostDone : out std_logic         ;
    Response_Done       : out std_logic
    );

end entity burst_support;


architecture implementation of burst_support is

  -- functions
    -- none
 
  
  -- Constants
  --Constant COUNTER_SIZE     : integer := 5;
  constant DBEAT_CNTR_SIZE  : integer := log2(C_MAX_DBEAT_CNT)+1;
  Constant LOGIC_LOW        : std_logic := '0';
  Constant LOGIC_HIGH       : std_logic := '1';
  Constant ZERO             : integer := 0;
  Constant ONE              : integer := 1;
  
  
                          
  Constant COUNT_ZERO     : std_logic_vector(0 to DBEAT_CNTR_SIZE-1)
                            := std_logic_vector(to_unsigned(ZERO, DBEAT_CNTR_SIZE));
                          
  Constant CYCLE_CNT_ZERO : std_logic_vector(0 to DBEAT_CNTR_SIZE-1)
                            := std_logic_vector(to_unsigned(ZERO, DBEAT_CNTR_SIZE));
                          
  Constant CYCLE_CNT_ONE  : std_logic_vector(0 to DBEAT_CNTR_SIZE-1)
                            := std_logic_vector(to_unsigned(ONE, DBEAT_CNTR_SIZE));
                    
  -- Types
  
  
   
  -- Signals
  
   -- Control Counter
   Signal cntl_dbeat_count      : std_logic_vector(0 to DBEAT_CNTR_SIZE-1);
   Signal cntl_db_load_value    : std_logic_vector(0 to DBEAT_CNTR_SIZE-1);
   Signal cntl_db_cnten         : std_logic;
   Signal Control_Done_i        : std_logic;
   Signal cntl_done_reg         : std_logic;
   
   -- Response Counter
   Signal resp_dbeat_count      : std_logic_vector(0 to DBEAT_CNTR_SIZE-1);
   Signal resp_db_load_value    : std_logic_vector(0 to DBEAT_CNTR_SIZE-1);
   Signal resp_db_cnten         : std_logic;
   Signal Response_Done_i       : std_logic;
   Signal Response_AlmostDone_i : std_logic;
   Signal resp_done_reg         : std_logic;
   
   
-------------------------------------------------------------------------------
begin --(architecture implementation)

  -- Misc assignments
     Control_Done        <= Control_Done_i;
     Response_Done       <= Response_Done_i;
     Response_AlmostDone <= Response_AlmostDone_i;
 
   
     Control_Ack <= Target_AddrAck and 
                    not(cntl_done_reg);

     Response_Ack <= Target_DataAck and 
                     not(resp_done_reg);

   ----------------------------------------------------------------------------
   -- Response Data Beat Counter Logic
   ----------------------------------------------------------------------------
          
   RESP_LOAD_VALUE : process(Num_Data_Beats)
    begin
        if(C_MAX_DBEAT_CNT > Num_Data_Beats)then
            resp_db_load_value <= std_logic_vector(to_unsigned(Num_Data_Beats, DBEAT_CNTR_SIZE));
        else
            resp_db_load_value <= std_logic_vector(to_unsigned(C_MAX_DBEAT_CNT-1,DBEAT_CNTR_SIZE));
        end if;
    end process RESP_LOAD_VALUE;
   
   resp_db_cnten <= Target_DataAck and 
                    not(Response_Done_i);
                    

    RESPONSE_DBEAT_CNTR_I : entity proc_common_v3_00_a.counter_f 
        generic map(
            C_NUM_BITS      => DBEAT_CNTR_SIZE,
            C_FAMILY        => C_FAMILY
            )
        port map (
            Clk             => Bus_clk,
            Rst             => Bus_reset,
            Load_In         => resp_db_load_value,
            Count_Enable    => resp_db_cnten,
            Count_Load      => Req_Init,
            Count_Down      => '1',
            Count_Out       => resp_dbeat_count,
            Carry_Out       => open
            );

    
   
   Response_Done_i <= '1'
      When  (resp_dbeat_count = CYCLE_CNT_ZERO)            
      Else '0';
   
   Response_AlmostDone_i <= '1'
      When  (resp_dbeat_count = CYCLE_CNT_ONE)
      Else '0';
   
   -------------------------------------------------------------
   -- Synchronous Process
   --
   -- Label: REG_RESP_DONE_STATUS
   --
   -- Process Description:
   -- This process registers the response cycle done signal
   --
   -------------------------------------------------------------
   REG_RESP_DONE_STATUS : process (bus_clk)
      begin
        if (bus_clk'event and bus_clk = '1') then
           if (bus_reset = '1' or Req_Init = '1') then
             resp_done_reg <= '0';
           else
             resp_done_reg <=  Response_Done_i and 
                               Target_DataAck;                 
           end if;        
        end if;
      end process REG_RESP_DONE_STATUS; 
   
   
   ----------------------------------------------------------------------------
   -- Control Data Beat Counter Logic
   ----------------------------------------------------------------------------
   CNTL_LOAD_VALUE : process(Num_Data_Beats)
    begin
        if(C_MAX_DBEAT_CNT > Num_Data_Beats)then
            cntl_db_load_value <= std_logic_vector(to_unsigned(Num_Data_Beats, DBEAT_CNTR_SIZE));
        else
            cntl_db_load_value <= std_logic_vector(to_unsigned(C_MAX_DBEAT_CNT-1,DBEAT_CNTR_SIZE));
        end if;
    end process CNTL_LOAD_VALUE;
   
   cntl_db_cnten    <= Target_AddrAck and 
                       not(Control_Done_i);
                       
    CONTROL_DBEAT_CNTR_I : entity proc_common_v3_00_a.counter_f 
        generic map(
            C_NUM_BITS      => DBEAT_CNTR_SIZE,
            C_FAMILY        => C_FAMILY
            )
        port map (
            Clk             =>  Bus_clk,
            Rst             =>  Bus_reset,
            Load_In         => cntl_db_load_value,
            Count_Enable    => cntl_db_cnten,
            Count_Load      => Req_Init,
            Count_Down      => '1',
            Count_Out       => cntl_dbeat_count,
            Carry_Out       => open
            );



   
   Control_Done_i <= '1'
      When  (cntl_dbeat_count = CYCLE_CNT_ZERO)
      Else '0';
   
   -------------------------------------------------------------
   -- Synchronous Process
   --
   -- Label: REG_CNTL_DONE_STATUS
   --
   -- Process Description:
   -- This process registers the control cycle done signal
   --
   -------------------------------------------------------------
   REG_CNTL_DONE_STATUS : process (bus_clk)
      begin
        if (bus_clk'event and bus_clk = '1') then
           
           if (bus_reset   = '1'  or 
               Req_Init    = '1') then
             cntl_done_reg <= '0';
           else
              cntl_done_reg <= Control_Done_i and 
                               Target_AddrAck;
           end if;        
        end if;
      end process REG_CNTL_DONE_STATUS; 
   

end implementation;
