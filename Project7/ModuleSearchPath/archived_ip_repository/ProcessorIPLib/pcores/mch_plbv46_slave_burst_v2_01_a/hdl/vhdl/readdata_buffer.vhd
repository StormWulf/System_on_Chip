-------------------------------------------------------------------------------
-- readdata_buffer.vhd - entity/architecture pair
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
-- Filename:        readdata_buffer.vhd
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
--  First version of mch_plbv46_slave_burst
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
-- library proc_common_v3_00_a is used for srl_fifo_f component
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.srl_fifo_f;

-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_MCH_SPLB_DWIDTH      -- MCH channel data width
--      C_MCH_RDDATABUF_DEPTH  -- Depth of ReadData buffer
--      C_FAMILY               -- FPGA Family used
--
-- Definition of Ports:
--
--  -- System signals
--      Sys_Clk                -- System clock
--      Sys_Rst                -- System reset
--
--  -- MCH Interface
--      MCH_ReadData_Control   -- Control bit indicating if data is valid
--      MCH_ReadData_Data      -- Data returned from a read transfer
--      MCH_ReadData_Read      -- Read control signal to the ReadData buffer
--      MCH_ReadData_Exists    -- Non-empty indicator from the ReadData buffer
--
--  -- ReadData Buffer Signals
--      ReadData_Ctrl          -- Control bit indicating if data is valid
--      ReadData_Data          -- Data returned for read transfer
--      ReadData_Write         -- Control signal to write data to ReadData
--                                buffer
--      ReadData_Full          -- Signal indicating if ReadData buffer is full
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity readdata_buffer is
    generic (  
    
        C_MCH_SPLB_DWIDTH       : integer   := 32; 
        C_MCH_RDDATABUF_DEPTH   : integer   := 4;
        C_FAMILY                : string    := "nofamily"
        
        );
         
    port (
        -- System Signals
        Sys_Clk               : in  std_logic;
        Sys_Rst               : in  std_logic;

        -- MCH ReadData Interface Signals
        MCH_ReadData_Control  : out std_logic; 
        MCH_ReadData_Data     : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);   
        MCH_ReadData_Read     : in  std_logic;    
        MCH_ReadData_Exists   : out std_logic; 
        
        -- ReadData Buffer Signals
        ReadData_Ctrl         : in  std_logic;
        ReadData_Data         : in  std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1); 
        ReadData_Write        : in  std_logic;
        ReadData_Full         : out std_logic
        );
  
end readdata_buffer;


-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture implementation of readdata_buffer is

-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------
constant C_FIFO_WIDTH       : integer := C_MCH_SPLB_DWIDTH + 1;
constant C_FIFO_DEPTH_LOG2X : integer := log2(C_MCH_RDDATABUF_DEPTH);

-------------------------------------------------------------------------------
-- Signal and Type Declarations
------------------------------------------------------------------------------- 
signal srl16_fifo_empty     : std_logic;

-- FIFO width is +1 for ReadData Buffer Control signal (ReadData_Ctrl)
signal srl16_fifo_data_in   : std_logic_vector (0 to (C_MCH_SPLB_DWIDTH-1)+1);
signal srl16_fifo_data_out  : std_logic_vector (0 to (C_MCH_SPLB_DWIDTH-1)+1);
signal MCH_ReadData_Read_cmb: std_logic;    

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin

    ---------------------------------------------------------------------------
    -- RDBUF_DEPTH_ZERO_GEN Generate
    ---------------------------------------------------------------------------  
    RDBUF_DEPTH_ZERO_GEN : if C_MCH_RDDATABUF_DEPTH = 0 generate
    
        -- ReadData Buffer will be set = 0 when logic reading FIFO is 
        -- expecting data immediately (no pass through delay)
        MCH_ReadData_Data    <= ReadData_Data;
        MCH_ReadData_Control <= ReadData_Ctrl;
        MCH_ReadData_Exists  <= ReadData_Write;
        
        -- Since no FIFO exists, full signal default = '0'
        ReadData_Full <= '0';
    
    end generate RDBUF_DEPTH_ZERO_GEN;

    ---------------------------------------------------------------------------
    -- RDBUF_DEPTH_NOT_ZERO_GEN Generate
    ---------------------------------------------------------------------------  
    RDBUF_DEPTH_NOT_ZERO_GEN : if C_MCH_RDDATABUF_DEPTH /= 0 generate
    
        MCH_ReadData_Exists <= not (srl16_fifo_empty);        
    
        -- Assign FIFO data buses (Rd & Wr)
        srl16_fifo_data_in(0 to C_MCH_SPLB_DWIDTH-1) <= ReadData_Data;
        srl16_fifo_data_in(C_MCH_SPLB_DWIDTH) <= ReadData_Ctrl;
        
        MCH_ReadData_Data <= srl16_fifo_data_out(0 to C_MCH_SPLB_DWIDTH-1);
        MCH_ReadData_Control <= srl16_fifo_data_out(C_MCH_SPLB_DWIDTH);
        MCH_ReadData_Read_cmb <= MCH_ReadData_Read and ( not (srl16_fifo_empty));
        
        -- Use SRL16 FIFO
        READDATA_FIFO : entity proc_common_v3_00_a.srl_fifo_f
        generic map (
            C_DWIDTH    =>  C_FIFO_WIDTH,
            C_DEPTH     =>  C_FIFO_DEPTH_LOG2X,
            C_FAMILY    =>  C_FAMILY
            )
        port map (
             Clk        =>   Sys_Clk,                  
             Reset      =>   Sys_Rst,     
             FIFO_Write =>   ReadData_Write,             
             Data_In    =>   srl16_fifo_data_in,          
             FIFO_Read  =>   MCH_ReadData_Read_cmb,             
             Data_Out   =>   srl16_fifo_data_out,           
             FIFO_Full  =>   ReadData_Full,            
             FIFO_Empty =>   srl16_fifo_empty
         );
                          
    end generate RDBUF_DEPTH_NOT_ZERO_GEN;

end implementation;

