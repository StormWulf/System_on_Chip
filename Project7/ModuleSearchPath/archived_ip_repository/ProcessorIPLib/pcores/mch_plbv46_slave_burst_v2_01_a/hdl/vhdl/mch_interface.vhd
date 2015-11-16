-------------------------------------------------------------------------------
-- mch_interface.vhd - entity/architecture pair
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
-- Filename:        mch_interface.vhd
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
-- Author:      PVK
-- History:
--  PVK         11/02/06        First Version
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
-- The proc_common library is required to instantiate pselect_f component
-- MCH constants XCL and DAG are defined in ipif_pkg
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.XCL;
use proc_common_v3_00_a.ipif_pkg.DAG;

-------------------------------------------------------------------------------
-- mch_plbv46_slave_burst_v2_01_a library is used for mch_plbv46_slave_burst
-- component declarations
-------------------------------------------------------------------------------
library mch_plbv46_slave_burst_v2_01_a;
use mch_plbv46_slave_burst_v2_01_a.access_buffer;
use mch_plbv46_slave_burst_v2_01_a.readdata_buffer;
use mch_plbv46_slave_burst_v2_01_a.addr_be_gen;
use mch_plbv46_slave_burst_v2_01_a.chnl_logic;
use mch_plbv46_slave_burst_v2_01_a.ipic_logic;

-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_MCH_SPLB_DWIDTH               -- MCH channel data width
--      C_MCH_SPLB_AWIDTH               -- MCH channel address width
--      C_MCH_PROTOCOL                  -- MCH protocol (specifies type of 
--                                         channel)
--      C_MCH_USERIP_ADDRRANGE_ARRAY    -- Addresses of User IP accessible by 
--                                         MCH logic
--      C_MCH_ACCESSBUF_DEPTH           -- Depth of Access buffer
--      C_MCH_RDDATABUF_DEPTH           -- Depth of ReadData buffer
--      C_XCL_LINESIZE                  -- Size of cacheline for Cachelink channel
--      C_XCL_WRITEXFER                 -- Type of write transfer for Cachelink
--                                         channel
--      C_BRSTCNT_WIDTH                 -- Burst count width
--      C_FAMILY                        -- FPGA Family used
--
-- Definition of Ports:
--
--  -- System signals
--      Sys_Clk                 -- System clock
--      Sys_Rst                 -- System reset
--
--  -- MCH Interface
--      MCH_Access_Control      -- Control bit indicating R/W transfer
--      MCH_Access_Data         -- Address/data for the transfer
--      MCH_Access_Write        -- Write control signal to the Access buffer
--      MCH_Access_Full         -- Full indicator from the Access buffer
--
--      MCH_ReadData_Control    -- Control bit indicating if data is valid
--      MCH_ReadData_Data       -- Data returned from a read transfer
--      MCH_ReadData_Read       -- Read control signal to the ReadData buffer
--      MCH_ReadData_Exists     -- Non-empty indicator from the ReadData buffer
--
--  -- IPIC Signals
--      Chnl2IP_Addr            -- IPIC address bus     
--      Chnl2IP_Addrvalid       -- Indicates address is valid
--      Chnl2IP_BE              -- IPIC byte enables      
--      Chnl2IP_Data            -- IPIC data bus    
--      Chnl2IP_RNW             -- Read not write
--      Chnl2IP_CS              -- Chip select  
--      Chnl2IP_Burst           -- Indicates an active burst transaction   
--      Chnl2IP_BurstLength     -- Channel to IP burst length
--      Chnl2IP_RdReq           -- Indicates the availability of valid read
--                                 addresses
--      Chnl2IP_WrReq           -- Indicates the availability of valid write
--                                 addresses
--      Chnl2IP_CE              -- Chip enables      
--      Chnl2IP_Rdce            -- Read chip enables     
--      Chnl2IP_Wrce            -- Write chip enables
--      
--      IP2Chnl_Data            -- Data from IP logic to channel interface
--      IP2Chnl_AddrAck         -- Address acknowledge from IP logic
--      IP2Chnl_WrAck           -- Write data acknowledge from IP Logic
--      IP2Chnl_RdAck           -- Read data acknowledge from IP Logic
--
--
--   -- Signals to Arb Mux/De-Mux Logic
--      Chnl_Req                -- Indicates channel with active transaction
--      Chnl_Data_Almost_Done   -- Indicates channel data transaction almost
--                                 complete                            
--      Chnl_Addr_Almost_Done   -- Indicates channel address transaction almost
--                                 complete   
--      Addr_Master             -- Current master of the address phase
--      Data_Master             -- Current master of the data phase
--
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity mch_interface is
    generic (  
    
        C_MCH_SPLB_DWIDTH             : integer   := 32; 
        C_MCH_SPLB_AWIDTH             : integer   := 32;
        C_MCH_PROTOCOL                : integer   := 0;                                           
        C_MCH_USERIP_ADDRRANGE_ARRAY  : SLV64_ARRAY_TYPE
                                          := (x"0000_0000_0000_0000",
                                              x"0000_0000_0000_8FFF");
        C_MCH_ACCESSBUF_DEPTH         : integer   := 16;
        C_MCH_RDDATABUF_DEPTH         : integer   := 4;
        C_XCL_LINESIZE                : integer   := 4;
        C_XCL_WRITEXFER               : integer   := 1;
        C_BRSTCNT_WIDTH               : integer   := 6;
        C_FAMILY                      : string    := "nofamily"
        );
         
    port (
        -- System Signals
        Sys_Clk               : in  std_logic;
        Sys_Rst               : in  std_logic;
    
        -- MCH Access Interface Signals
        MCH_Access_Control    : in  std_logic; 
        MCH_Access_Data       : in  std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);   
        MCH_Access_Write      : in  std_logic;    
        MCH_Access_Full       : out std_logic;     
        
        -- MCH ReadData Interface Signals
        MCH_ReadData_Control  : out std_logic; 
        MCH_ReadData_Data     : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);   
        MCH_ReadData_Read     : in  std_logic;    
        MCH_ReadData_Exists   : out std_logic; 

        -- IPIC Signals
        Chnl2IP_Addr          : out std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);     
        Chnl2IP_Addrvalid     : out std_logic; 
        Chnl2IP_BE            : out std_logic_vector(0 to 
                                    C_MCH_SPLB_DWIDTH/8-1);      
        Chnl2IP_Data          : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);     
        Chnl2IP_RNW           : out std_logic; 
        Chnl2IP_CS            : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);  
        Chnl2IP_Burst         : out std_logic;  
        Chnl2IP_BurstLength   : out std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
        Chnl2IP_RdReq         : out std_logic;
        Chnl2IP_WrReq         : out std_logic;
        Chnl2IP_CE            : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);      
        Chnl2IP_Rdce          : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);   
        Chnl2IP_Wrce          : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);
        
        IP2Chnl_Data          : in  std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);
        IP2Chnl_AddrAck       : in  std_logic; 
        IP2Chnl_Ack           : in  std_logic; 
	
	--DXCL2 byte transfer 
        Dxcl2_byte_trfr	      : out std_logic;         
        
        -- Signals to Arb Mux/De-Mux Logic
        Chnl_Req              : out std_logic;
        Chnl_Data_Almost_Done : out std_logic;
        Chnl_Addr_Almost_Done : out std_logic;
        Addr_Master           : in  std_logic;
        Data_Master           : in  std_logic
        
        );
  
end mch_interface;


-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of mch_interface is

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
-- Access buffer signals
signal access_ctrl     : std_logic;
signal access_data     : std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);
signal access_exists   : std_logic;
signal access_read     : std_logic;

-- ReadData buffer signals
signal readdata_ctrl   : std_logic;
signal readdata_write  : std_logic;
signal readdata_full   : std_logic;

--DXCL2 single transfer signal
signal dxcl2_byte_txr  : std_logic;

-- Channel logic signals
signal chnl_select            : std_logic;
signal chnl_addr_valid        : std_logic;
signal chnl_byte_wr           : std_logic;
signal chnl_data_valid        : std_logic;
signal chnl_start_data_valid  : std_logic;
signal chnl_rnw               : std_logic;
signal chnl_rdce              : std_logic;
signal chnl_wrce              : std_logic;
signal chnl_rdreq             : std_logic;
signal chnl_wrreq             : std_logic;
signal chnl_burst             : std_logic;
signal chnl_burstlength       : std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
signal chnl_addr              : std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);
signal ipic_addr_valid        : std_logic;

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin

Dxcl2_byte_trfr <= dxcl2_byte_txr;
    ---------------------------------------------------------------------------
    -- Generate Access Buffer
    ---------------------------------------------------------------------------
    ACCESS_BUF_I: entity mch_plbv46_slave_burst_v2_01_a.access_buffer
    generic map (
        C_MCH_SPLB_DWIDTH       =>  C_MCH_SPLB_DWIDTH       ,
        C_MCH_ACCESSBUF_DEPTH   =>  C_MCH_ACCESSBUF_DEPTH   ,
        C_FAMILY                =>  C_FAMILY                
        )
    port map (
        Sys_Clk                 =>  Sys_Clk                 ,
        Sys_Rst                 =>  Sys_Rst                 ,
        MCH_Access_Control      =>  MCH_Access_Control      ,
        MCH_Access_Data         =>  MCH_Access_Data         ,
        MCH_Access_Write        =>  MCH_Access_Write        ,
        MCH_Access_Full         =>  MCH_Access_Full         ,
        Access_Ctrl             =>  access_ctrl             ,
        Access_Data             =>  access_data             ,
        Access_Exists           =>  access_exists           ,
        Access_Read             =>  access_read             
        );


    ---------------------------------------------------------------------------
    -- Generate ReadData Buffer
    ---------------------------------------------------------------------------
    RD_BUF_I: entity mch_plbv46_slave_burst_v2_01_a.readdata_buffer
    generic map (
        C_MCH_SPLB_DWIDTH       =>  C_MCH_SPLB_DWIDTH       ,
        C_MCH_RDDATABUF_DEPTH   =>  C_MCH_RDDATABUF_DEPTH   ,
        C_FAMILY                =>  C_FAMILY                
        )
    port map (
        Sys_Clk                 =>  Sys_Clk                 ,
        Sys_Rst                 =>  Sys_Rst                 ,
        MCH_ReadData_Control    =>  MCH_ReadData_Control    ,
        MCH_ReadData_Data       =>  MCH_ReadData_Data       ,
        MCH_ReadData_Read       =>  MCH_ReadData_Read       ,
        MCH_ReadData_Exists     =>  MCH_ReadData_Exists     ,
        ReadData_Ctrl           =>  readdata_ctrl           ,
        ReadData_Data           =>  IP2Chnl_Data            ,
        ReadData_Write          =>  readdata_write          ,
        ReadData_Full           =>  readdata_full           
        );


    ---------------------------------------------------------------------------
    -- Channel Control Logic
    ---------------------------------------------------------------------------
    CHNL_LOGIC_I: entity mch_plbv46_slave_burst_v2_01_a.chnl_logic
    generic map (    
        C_MCH_SPLB_DWIDTH       =>  C_MCH_SPLB_DWIDTH       ,        
        C_MCH_SPLB_AWIDTH       =>  C_MCH_SPLB_AWIDTH       ,       
        C_MCH_PROTOCOL          =>  C_MCH_PROTOCOL          ,                                                
        C_XCL_LINESIZE          =>  C_XCL_LINESIZE          ,      
        C_XCL_WRITEXFER         =>  C_XCL_WRITEXFER         ,
        C_BRSTCNT_WIDTH         =>  C_BRSTCNT_WIDTH
        )
    port map (        
        Sys_Clk                 =>  Sys_Clk                 ,        
        Sys_Rst                 =>  Sys_Rst                 ,
        Access_Ctrl             =>  access_ctrl             ,
        Access_Exists           =>  access_exists           ,
        Access_Read             =>  access_read             ,
        Access_data             =>  access_data             ,
        ReadData_Ctrl           =>  readdata_ctrl           ,
        ReadData_Write          =>  readdata_write          ,
        ReadData_Full           =>  readdata_full           ,
        Dxcl2_byte_txr		=>  dxcl2_byte_txr	    ,	
        Chnl_select             =>  chnl_select             ,
        Chnl_addr_valid         =>  chnl_addr_valid         ,
        Chnl_byte_wr            =>  chnl_byte_wr            ,        
        Chnl_data_valid         =>  chnl_data_valid         ,
        Chnl_start_data_valid   =>  chnl_start_data_valid   ,
        Chnl_rnw                =>  chnl_rnw                ,
        Chnl_rdce               =>  chnl_rdce               ,
        Chnl_wrce               =>  chnl_wrce               ,
        Chnl_rdreq              =>  chnl_rdreq              ,
        Chnl_wrreq              =>  chnl_wrreq              ,
        Chnl_burst              =>  chnl_burst              ,
        Chnl_BurstLength        =>  chnl_burstlength        ,
        
        IPIC_addr_valid         =>  ipic_addr_valid         ,
        IP2Chnl_AddrAck         =>  IP2Chnl_AddrAck         ,   
        IP2Chnl_Ack             =>  IP2Chnl_Ack             ,          
        Chnl_Req                =>  Chnl_Req                ,
        Chnl_Data_Almost_Done   =>  Chnl_Data_Almost_Done   ,
        Chnl_Addr_Almost_Done   =>  Chnl_Addr_Almost_Done   ,
        Addr_Master             =>  Addr_Master             ,
        Data_Master             =>  Data_Master             
        );
    
    
    ---------------------------------------------------------------------------
    -- Address & BE Generation Logic
    ---------------------------------------------------------------------------
    ADDR_BE_I: entity mch_plbv46_slave_burst_v2_01_a.addr_be_gen
    generic map (    
        C_MCH_SPLB_DWIDTH       =>  C_MCH_SPLB_DWIDTH       ,        
        C_MCH_SPLB_AWIDTH       =>  C_MCH_SPLB_AWIDTH       ,       
        C_MCH_PROTOCOL          =>  C_MCH_PROTOCOL          ,
        C_XCL_LINESIZE          =>  C_XCL_LINESIZE          ,      
        C_XCL_WRITEXFER         =>  C_XCL_WRITEXFER         
        )
    port map (    
        Sys_Clk                 =>  Sys_Clk                 ,        
        Sys_Rst                 =>  Sys_Rst                 ,
        Chnl_data               =>  access_data             , 
        Chnl_select             =>  chnl_select             , 
        Chnl_addr_valid         =>  chnl_addr_valid         , 
        Chnl_data_valid         =>  chnl_data_valid         ,   
        Chnl_byte_wr            =>  chnl_byte_wr            ,
        Chnl_rnw                =>  chnl_rnw                ,
        Chnl2IP_Addr            =>  chnl_addr               ,
        Chnl2IP_BE              =>  Chnl2IP_BE              ,
        Dxcl2_byte_txr		=>  dxcl2_byte_txr	    ,	        
        IP2Chnl_AddrAck         =>  IP2Chnl_AddrAck         
        );

    Chnl2IP_Addr <= chnl_addr;

    ---------------------------------------------------------------------------
    -- IPIC Interface Logic
    ---------------------------------------------------------------------------
    IPIC_I: entity mch_plbv46_slave_burst_v2_01_a.ipic_logic
    generic map (        
        C_MCH_SPLB_DWIDTH               =>  C_MCH_SPLB_DWIDTH            ,        
        C_MCH_SPLB_AWIDTH               =>  C_MCH_SPLB_AWIDTH            ,     
        C_MCH_USERIP_ADDRRANGE_ARRAY    =>  C_MCH_USERIP_ADDRRANGE_ARRAY ,
        C_MCH_PROTOCOL          	=>  C_MCH_PROTOCOL          	 ,        
        C_XCL_WRITEXFER                 =>  C_XCL_WRITEXFER              ,
        C_BRSTCNT_WIDTH                 =>  C_BRSTCNT_WIDTH              ,
        C_FAMILY                        =>  C_FAMILY
        )
    port map (    
        Sys_Clk                 =>  Sys_Clk                 ,        
        Sys_Rst                 =>  Sys_Rst                 , 
        Chnl_data               =>  access_data             ,
        Chnl_select             =>  chnl_select             ,
        Chnl_data_valid         =>  chnl_data_valid         ,  
        Chnl_start_data_valid   =>  chnl_start_data_valid   ,
        Chnl_rnw                =>  chnl_rnw                ,
        Chnl_rdce               =>  chnl_rdce               ,
        Chnl_wrce               =>  chnl_wrce               ,
        Chnl_rdreq              =>  chnl_rdreq              ,
        Chnl_wrreq              =>  chnl_wrreq              ,
        Chnl_burst              =>  chnl_burst              ,
        Chnl_BurstLength        =>  chnl_burstlength        ,
        Chnl_addr               =>  chnl_addr               ,
        IPIC_addr_valid         =>  ipic_addr_valid         ,
        Dxcl2_byte_txr		=>  dxcl2_byte_txr	    ,	        
        Chnl2IP_Addrvalid       =>  Chnl2IP_Addrvalid       ,
        Chnl2IP_Data            =>  Chnl2IP_Data            ,
        Chnl2IP_RNW             =>  Chnl2IP_RNW             ,
        Chnl2IP_CS              =>  Chnl2IP_CS              ,
        Chnl2IP_Burst           =>  Chnl2IP_Burst           ,
        Chnl2IP_BurstLength     =>  Chnl2IP_BurstLength     ,
        Chnl2IP_RdReq           =>  Chnl2IP_RdReq           ,
        Chnl2IP_WrReq           =>  Chnl2IP_WrReq           ,
        Chnl2IP_CE              =>  Chnl2IP_CE              ,
        Chnl2IP_Rdce            =>  Chnl2IP_Rdce            ,
        Chnl2IP_Wrce            =>  Chnl2IP_Wrce                    
        );

end imp;

