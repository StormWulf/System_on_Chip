-------------------------------------------------------------------------------
-- access_buffer.vhd - entity/architecture pair
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
-- Filename:        access_buffer.vhd
-- Version:         v2.01a
-- Description:     This file contains the logic for interfacing to each
--                  channel in the defined MCH interface.  The MCH interface
--                  logic generates the buffers (FIFOs), channel control logic,
--                  and IPIC interface for each channel.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  -- mch_plbv46_slave_burst.vhd                  
--                      -- mch_interface.vhd
--                          -- access_buffer.vhd
--                          -- readdata_buffer.vhd
--                          -- chnl_logic.vhd
--                          -- addr_be_gen.vhd
--                          -- ipic_logic.vhd
--                      -- arb_mux_demux.vhd
--                          -- addr_data_mux_demux.vhd
--                          -- arbitration_logic.vhd
--                      -- plbv46_slave_burst.vhd
--                      
-------------------------------------------------------------------------------
-- Author:      VPK
-- History:
--  VPK         11/02/06        First Version
-- ^^^^^^
--  Integrated this code in mch_plbv46_slave_burst
-- ~~~~~~
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
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- proc common library is used for different function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.srl_fifo_f;
use proc_common_v3_00_a.proc_common_pkg.log2;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
--      C_FAMILY                 -- FPGA Family used
--      C_MCH_SPLB_DWIDTH        -- MCH channel data width
--      C_MCH_ACCESSBUF_DEPTH    -- Depth of Access buffer                                                                                           
--
-- Definition of Ports:
--
--  -- System signals
--      Sys_Clk                  -- System clock
--      Sys_Rst                  -- System reset
--
--  -- MCH Interface
--      MCH_Access_Control       -- Control bit indicating R/W transfer
--      MCH_Access_Data          -- Address/data for the transfer
--      MCH_Access_Write         -- Write control signal to the Access buffer

--      MCH_Access_Full          -- Full indicator from the Access buffer
--
--  -- Access Buffer Signals
--      Access_Ctrl              -- Control indicated R/W transfer
--      Access_Data              -- Address/data for transfer 
--      Access_Exists            -- Data exists in FIFO
--      Access_Read              -- Read data from Access buffer
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity access_buffer is
    generic (  
        C_MCH_SPLB_DWIDTH       : integer   := 32; 
        C_MCH_ACCESSBUF_DEPTH   : integer   := 16;
        C_FAMILY                : string    := "nofamily"
        );
         
    port (
        -- System Signals
        Sys_Clk                 : in   std_logic;
        Sys_Rst                 : in   std_logic;

        -- MCH Access Interface Signals
        MCH_Access_Control      : in   std_logic; 
        MCH_Access_Data         : in   std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);   
        MCH_Access_Write        : in   std_logic;    
        MCH_Access_Full         : out  std_logic;     
        
        -- Access Buffer Signals
        Access_Ctrl             : out  std_logic;
        Access_Data             : out  std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1); 
        Access_Exists           : out  std_logic;
        Access_Read             : in   std_logic
        );
  
end access_buffer;


-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of access_buffer is

-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------
constant C_FIFO_WIDTH       : integer := C_MCH_SPLB_DWIDTH + 1;
constant C_FIFO_DEPTH_LOG2X : integer := log2(C_MCH_ACCESSBUF_DEPTH);
constant C_FIFO_DEPTH       : integer := C_MCH_ACCESSBUF_DEPTH;

-------------------------------------------------------------------------------
-- Signal and Type Declarations
------------------------------------------------------------------------------- 
signal srl16_fifo_empty     : std_logic;

-- FIFO width is +1 for Access Buffer Control signal (MCH_Access_Control)
signal srl16_fifo_data_in   : std_logic_vector (0 to (C_MCH_SPLB_DWIDTH-1)+1);
signal srl16_fifo_data_out  : std_logic_vector (0 to (C_MCH_SPLB_DWIDTH-1)+1);

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin

    -- Change active level of Access_Exists
    Access_Exists <= not (srl16_fifo_empty);
       
    -- Assign FIFO data buses (Rd & Wr)
    srl16_fifo_data_in(0 to C_MCH_SPLB_DWIDTH-1) <= MCH_Access_Data;
    srl16_fifo_data_in(C_MCH_SPLB_DWIDTH) <= MCH_Access_Control;
    
    Access_Data <= srl16_fifo_data_out(0 to C_MCH_SPLB_DWIDTH-1);
    Access_Ctrl <= srl16_fifo_data_out(C_MCH_SPLB_DWIDTH);

    -- Use SRL16 FIFO
    ACCESS_FIFO : entity proc_common_v3_00_a.srl_fifo_f
    generic map (
            C_DWIDTH    =>  C_FIFO_WIDTH,
          --  C_DEPTH     =>  C_FIFO_DEPTH_LOG2X,
            C_DEPTH     =>  C_FIFO_DEPTH,
            C_FAMILY    =>  C_FAMILY
            )
        port map (
             Clk        =>   Sys_Clk            ,                  
             Reset      =>   Sys_Rst            ,     
             FIFO_Write =>   MCH_Access_Write   ,             
             Data_In    =>   srl16_fifo_data_in ,           
             FIFO_Read  =>   Access_Read        ,             
             Data_Out   =>   srl16_fifo_data_out,           
             FIFO_Full  =>   MCH_Access_Full    ,            
             FIFO_Empty =>   srl16_fifo_empty
             );

end imp;
