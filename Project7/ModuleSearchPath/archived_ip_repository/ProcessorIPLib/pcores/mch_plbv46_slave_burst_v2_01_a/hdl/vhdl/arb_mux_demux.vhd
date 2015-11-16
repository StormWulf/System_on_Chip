-------------------------------------------------------------------------------
-- arb_mux_demux.vhd - entity/architecture pair
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
-- Filename:        arb_mux_demux.vhd
-- Version:         v2.01a
-- Description:     Arbitration logic and data/address multiplexors
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
-- Author:          VPK
-- History:
--  VPK         11/02/06       First Version
-- ^^^^^^
--  First version of mch_plbv46_slave_burst
--  Integrated this code in mch_plbv46_slave_burst
--  Removed retry logic
-- ~~~~~~
-- ALS          11/02/06
-- ^^^^^^
--  Modified generation of Bus2IP_Burst to be from a register based on the 
--  burst length
-- ~~~~~~
--  PVK         02/26/07  
-- ^^^^^^
-- Added logic to generate Bus2IP_BurstLength and Bus2IP_AddrBurstCntLoad for 
-- NUM_MASTERs=1 (C_INCLUDE_PLB_IPIF=0).
-- Removed ports Bus2IP_CE, PLB2IP_CE and Chnl2IP_CE. 
-- Code cleanup.
-- ~~~~~~
--  KSB         02/24/09  
-- ^^^^^^
-- Changed the pipe line stage for No PLB case to Fix CR#508291
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
-- library misc is used for or_reduce function
-------------------------------------------------------------------------------
use ieee.std_logic_misc.all;

-------------------------------------------------------------------------------
-- proc common library is used for different function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.mux_onehot_f;

-------------------------------------------------------------------------------
-- mch_plbv46_slave_burst_v2_01_a library is used for mch_plbv46_slave_burst
-- component declarations
-------------------------------------------------------------------------------
library mch_plbv46_slave_burst_v2_01_a;
use mch_plbv46_slave_burst_v2_01_a.addr_data_mux_demux;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
--      C_MCH_SPLB_DWIDTH        -- data width of MCH and PLBV46 interfaces
--      C_MCH_SPLB_AWIDTH        -- address width of MCH and PLBV46 interfaces
--      C_PRIORITY_MODE          -- priority mode for the arbiter 
--      C_NUM_CHANNELS           -- number of MCH interfaces             
--      C_NUM_MCH_CS             -- number of chip selects generated by MCH                 
--                               -- interfaces 
--      C_NUM_PLB_CS             -- number of chip selects generated by PLBV46
--      C_NUM_PLB_CE             -- number of chip enables generated by PLBV46
--      C_INCLUDE_PLB_IPIF       -- include PLBV46
--      C_BRSTCNT_WIDTH          -- burst count width  
--      C_FAMILY                 -- target FPGA family
--
-- Definition of Ports:
--
--  -- System interface
--      Sys_Clk                 -- clock
--      Sys_Rst                 -- rst
--
--  -- Arbitration signals  
--      Chnl_Req                -- channel request for transaction               
--      Chnl_Data_Almost_Done   -- data transaction is almost complete
--      Chnl_Addr_Almost_Done   -- address transaction is almost complete
--      Chnl2IP_CS              -- CS of requested transaction
--      PLB2IP_CS               -- PLBV46 transaction request
--      Addr_master             -- current master of the address phase  
--      Data_master             -- current master of the data phase
--      Addr_arb_cycle          -- address phase arbitration cycle
--      Data_arb_cycle          -- data phase arbitration cycle
--      PLB_xfer_end            -- end of PLBV46 transaction
--
--  -- Address mux input signals
--      PLB2IP_Addr             -- IPIC signals from PLBV46              
--      PLB2IP_RdReq            
--      PLB2IP_WrReq            
--
--      Chnl2IP_Addr            -- IPIC signals from the channels           
--      Chnl2IP_RdReq           
--      Chnl2IP_WrReq           
--                              
--  -- Address mux output signals
--      Bus2IP_Addr             -- IPIC signals to the IP            
--      Bus2IP_RdReq            
--      Bus2IP_WrReq            
--
--  -- Address de-mux input signal
--      IP2Bus_AddrAck          -- IPIC signal from the IP        
--
--  -- Address de-mux output signals 
--      IP2PLB_AddrAck          -- IPIC signal to the PLBV46
--      IP2Chnl_AddrAck         -- IPIC signal to the channels
--
--  -- Data mux input signals
--      PLB2IP_Data             -- IPIC signals from PLBV46             
--      PLB2IP_BE               
--      PLB2IP_RNW              
--      PLB2IP_RdCE             
--      PLB2IP_WrCE             
--      PLB2IP_Burst            
--      PLB2IP_BurstLength
--                              
--      Chnl2IP_Data            -- IPIC signals from the channels            
--      Chnl2IP_BE              
--      Chnl2IP_RNW             
--      Chnl2IP_RdCE            
--      Chnl2IP_WrCE            
--      Chnl2IP_Burst 
--      Chnl2IP_BurstLength
--
--  -- Data mux output signals
--      Bus2IP_CS               -- IPIC signals to the IP             
--      Bus2IP_Data                         
--      Bus2IP_BE               
--      Bus2IP_RNW              
--      Bus2IP_RdCE             
--      Bus2IP_WrCE             
--      Bus2IP_Burst
--      Bus2IP_BurstLength
--      Bus2IP_AddrBurstLength
--      Bus2IP_AddrBurstCntLoad
--
--  -- Data de-mux input signals
--      IP2Bus_Data             -- IPIC signals from the IP            
--      IP2Bus_RdAck
--      IP2Bus_WrAck
--      IP2Bus_Error            
--
--  -- Data de-mux output signals
--      IP2PLB_Data             -- IPIC signals to the PLBV46             
--      IP2PLB_RdAck
--      IP2PLB_WrAck 
--      IP2PLB_Error            
--                              
--      IP2Chnl_Data            -- IPIC signals to the channels            
--      IP2Chnl_Ack             
--      IP2Chnl_Error           
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity arb_mux_demux is
    generic (
            C_MCH_SPLB_DWIDTH       : integer   := 32; 
            C_MCH_SPLB_AWIDTH       : integer   := 32;
            C_PRIORITY_MODE         : integer   := 0;
            C_NUM_CHANNELS          : integer   := 2;              
            C_NUM_MCH_CS            : integer   := 1;
            C_MCH_PROTOCOL	    : integer   := 0;
            C_NUM_PLB_CS            : integer   := 1;
            C_NUM_PLB_CE            : integer   := 1;
            C_INCLUDE_PLB_IPIF      : integer   := 0;
            C_BRSTCNT_WIDTH         : integer   := 6; 
            C_XCL0_WRITEXFER        : integer   := 1;
            C_FAMILY                : string    := "nofamily"
       );  

  port
    (
        -- system interface
        Sys_Clk                 : in  std_logic;
        Sys_Rst                 : in  std_logic;
                                      
        -- arbitration signals         
        Chnl_Req                : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        Chnl_Data_Almost_Done   : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        Chnl_Addr_Almost_Done   : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        Chnl2IP_CS              : in  std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_NUM_MCH_CS-1);
        PLB2IP_CS               : in  std_logic_vector(0 to C_NUM_PLB_CS-1);
        Addr_master             : out std_logic_vector(0 to 
                                        C_NUM_CHANNELS+C_INCLUDE_PLB_IPIF-1);
        Data_master             : out std_logic_vector(0 to 
                                        C_NUM_CHANNELS+C_INCLUDE_PLB_IPIF-1);
        Addr_arb_cycle          : out std_logic;
        Data_arb_cycle          : out std_logic;
        PLB_xfer_end            : out std_logic;
        
        -- address mux input signals
        PLB2IP_Addr             : in  std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);      
        PLB2IP_RdReq            : in  std_logic;
        PLB2IP_WrReq            : in  std_logic;
        
        Chnl2IP_Addr            : in  std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_MCH_SPLB_AWIDTH-1);     
        Chnl2IP_RdReq           : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        Chnl2IP_WrReq           : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
                                                    
        -- address mux output signals
        Bus2IP_Addr             : out std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);  
        Bus2IP_RdReq            : out std_logic;
        Bus2IP_WrReq            : out std_logic;

        -- address de-mux input signals
        IP2Bus_AddrAck          : in  std_logic;
        
        -- address de-mux output signals
        IP2PLB_AddrAck          : out std_logic;   
        IP2Chnl_AddrAck         : out std_logic_vector(0 to C_NUM_CHANNELS-1);  

        -- data mux input signals (CS signals listed under arbitration signals)
        PLB2IP_Data             : in  std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);  
        PLB2IP_BE               : in  std_logic_vector(0 to 
                                        C_MCH_SPLB_DWIDTH/8-1);        
        PLB2IP_RNW              : in  std_logic;   
        PLB2IP_RdCE             : in  std_logic_vector(0 to C_NUM_PLB_CE-1);  
        PLB2IP_WrCE             : in  std_logic_vector(0 to C_NUM_PLB_CE-1);  
        PLB2IP_Burst            : in  std_logic; 
        PLB2IP_BurstLength      : in  std_logic_vector(0 to C_BRSTCNT_WIDTH-1); 
                                                
        Chnl2IP_Data            : in  std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_MCH_SPLB_DWIDTH-1);
        Chnl2IP_BE              : in  std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_MCH_SPLB_DWIDTH/8-1);
        Chnl2IP_RNW             : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        Chnl2IP_RdCE            : in  std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_NUM_MCH_CS-1);
        Chnl2IP_WrCE            : in  std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_NUM_MCH_CS-1);      
        Chnl2IP_Burst           : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        Chnl2IP_BurstLength     : in  std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_BRSTCNT_WIDTH-1); 
    
        -- data mux output signals
        Bus2IP_CS               : out std_logic_vector(0 to C_NUM_PLB_CS-1);
        Bus2IP_Data             : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);
        Bus2IP_BE               : out std_logic_vector(0 to 
                                        C_MCH_SPLB_DWIDTH/8-1);
        Bus2IP_RNW              : out std_logic;   
        Bus2IP_RdCE             : out std_logic_vector(0 to C_NUM_PLB_CE-1);  
        Bus2IP_WrCE             : out std_logic_vector(0 to C_NUM_PLB_CE-1);  
        Bus2IP_Burst            : out std_logic; 
        Bus2IP_BurstLength      : out std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
        Bus2IP_AddrBurstLength  : out std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
        Bus2IP_AddrBurstCntLoad : out std_logic;                                

        -- data de-mux input signals
        IP2Bus_Data             : in  std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);   
        IP2Bus_RdAck            : in  std_logic;
        IP2Bus_WrAck            : in  std_logic;
        IP2Bus_Error            : in  std_logic;
        
        -- DXCL2 Byte transfer signals
        Dxcl2_byte_trfr         : in  std_logic;
    
        -- data de-mux output signals
        IP2PLB_Data             : out std_logic_vector(0 to 
                                        C_MCH_SPLB_DWIDTH-1);  
        IP2PLB_RdAck            : out std_logic;
        IP2PLB_WrAck            : out std_logic;
        IP2PLB_Error            : out std_logic;    
                                           
        IP2Chnl_Data            : out std_logic_vector(0 to 
                                        C_NUM_CHANNELS*C_MCH_SPLB_DWIDTH-1);  
        IP2Chnl_Ack             : out std_logic_vector(0 to C_NUM_CHANNELS-1);          
        IP2Chnl_Error           : out std_logic_vector(0 to C_NUM_CHANNELS-1)    
);    

end arb_mux_demux;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of arb_mux_demux is

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-- number of masters is the number of channels + the PLBV46 if it's included
constant NUM_MASTERS    : integer := C_NUM_CHANNELS + C_INCLUDE_PLB_IPIF;

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
-- PLBV46 request indicator
signal plb_request         : std_logic;
signal plb_request_gated   : std_logic;

-- arbitration cycle indicators
signal addr_arb_cycle_i    : std_logic;
signal data_arb_cycle_i    : std_logic;

signal addr_phase_idle     : std_logic;
signal data_phase_idle     : std_logic;

-- burst signal from address phase
signal addrphase_burst          : std_logic;

-- concatenated channel and PLBV46 chip select bus
signal cs_bus              : std_logic_vector(0 to NUM_MASTERS*C_NUM_MCH_CS-1);
-- one-hot mux selects for address and data muxes
signal ipic_addr_mux_sel   : std_logic_vector(0 to NUM_MASTERS-1);
signal ipic_data_mux_sel   : std_logic_vector(0 to NUM_MASTERS-1);

-- current masters of the address and data phases
signal addr_master_i       : std_logic_vector(0 to NUM_MASTERS-1);
signal data_master_i       : std_logic_vector(0 to NUM_MASTERS-1);


-- internal IPIC signals
signal bus2ip_burst_i      : std_logic;
signal bus2ip_cs_i         : std_logic_vector(0 to C_NUM_PLB_CS-1);
signal chnl2ip_cs_d1       : std_logic;


signal chnl2ip_rdreq_re    : std_logic;
signal chnl2ip_wrreq_re    : std_logic;
signal Chnl2IP_RdReq_d1    : std_logic;
signal Chnl2IP_WrReq_d1    : std_logic;

signal bus2ip_addr_d1      : std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);
signal bus2ip_wrreq_d1     : std_logic;
signal bus2ip_cs_i_d1      : std_logic_vector(0 to C_NUM_PLB_CS-1);
signal bus2ip_wrce_d1      : std_logic_vector(0 to C_NUM_PLB_CE-1);
signal bus2ip_rdce_d1      : std_logic_vector(0 to C_NUM_PLB_CE-1);
signal Chnl2IP_RNW_d1      : std_logic; 
-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

begin -- architecture IMP
-------------------------------------------------------------------------------
-- Assign outputs to internal signals
-------------------------------------------------------------------------------
Bus2IP_Burst     <= bus2ip_burst_i;
Bus2IP_CS        <= bus2ip_cs_i;

Addr_master      <= addr_master_i;
Data_master      <= data_master_i;

Addr_arb_cycle   <= addr_arb_cycle_i;
Data_arb_cycle   <= data_arb_cycle_i;

-------------------------------------------------------------------------------
-- Component Instantiations
-------------------------------------------------------------------------------
-- NOTE: if there is only one MCH interface and no PLBV46 IPIF, then no 
-- arbitration logic or mux/de-mux logic is required
--------------------------------------------------------------------------------
ONE_MASTER_GEN: if NUM_MASTERS=1 generate

    NO_PLB_IPIF: if C_INCLUDE_PLB_IPIF=0 generate
        
        -----------------------------------------------------------------------
        -- Generate statement to delay the address and CS, so as to align to
        -- data, which is not registered anywhere.This the case only for 
        -- XFER=1
        -----------------------------------------------------------------------
        
        XCL_CHNL0_XFER_1_GEN: if C_MCH_PROTOCOL=0 generate
          CHNL0_XFER_1_GEN: if C_XCL0_WRITEXFER=2 generate
           Bus2IP_Addr            <=  Chnl2IP_Addr;
	   Bus2IP_WrReq           <=  bus2ip_wrreq_d1;
	   Bus2IP_RdCE            <=  bus2ip_rdce_d1;
	   Bus2IP_WrCE            <=  bus2ip_wrce_d1;
           bus2ip_cs_i            <=  bus2ip_cs_i_d1;
           --------------------------------------------------------------------
           -- REG_WRITE_ALL_PROC
           -- Register the signals such that the CS, RdCE, WrCE and Addr
           -- are aligned to the data 
           --------------------------------------------------------------------
           REG_WRITE_ALL_PROC:process(Sys_Clk)
             begin 
                 if (Sys_Clk'event and Sys_Clk='1') then
                     if (Sys_Rst = '1' ) then
                         bus2ip_addr_d1 <= (others => '0');
                         bus2ip_wrreq_d1<= '0'; 
                         bus2ip_cs_i_d1 <= (others => '0');  
                         bus2ip_wrce_d1 <= (others => '0'); 
                         bus2ip_rdce_d1 <= (others => '0'); 
                      else    
                         bus2ip_addr_d1 <= Chnl2IP_Addr;
               	         bus2ip_wrreq_d1<= Chnl2IP_WrReq(0); 
              	         bus2ip_cs_i_d1 <= Chnl2IP_CS;  
                         bus2ip_wrce_d1 <= Chnl2IP_WrCE; 
                         bus2ip_rdce_d1 <= Chnl2IP_RdCE; 
                     end if;
                 end if;
            end process REG_WRITE_ALL_PROC;
           end generate CHNL0_XFER_1_GEN; 
         end generate XCL_CHNL0_XFER_1_GEN; 
         
         
        XCL2_CHNL0_XFER_1_GEN: if C_MCH_PROTOCOL=1 generate
          CHNL0_XFER_1_GEN: if C_XCL0_WRITEXFER=2 generate
           Bus2IP_Addr            <=  bus2ip_addr_d1 when (Chnl2IP_RNW(0)='0' 
           				or Dxcl2_byte_trfr = '0')
           				else Chnl2IP_Addr;
	   Bus2IP_WrReq           <=  bus2ip_wrreq_d1 when Dxcl2_byte_trfr ='0'
	   				else Chnl2IP_WrReq(0);
	   Bus2IP_RdCE            <=  bus2ip_rdce_d1 when Dxcl2_byte_trfr = '0'
	   				else  Chnl2IP_RdCE;  
	   Bus2IP_WrCE            <=  bus2ip_wrce_d1 when Dxcl2_byte_trfr = '0'
	   				else  Chnl2IP_WrCE;
           bus2ip_cs_i            <=  bus2ip_cs_i_d1 when Dxcl2_byte_trfr = '0'
	   				else  Chnl2IP_CS;
           --------------------------------------------------------------------
           -- REG_WRITE_ALL_PROC
           -- Register the signals such that the CS, RdCE, WrCE and Addr
           -- are aligned to the data 
           --------------------------------------------------------------------
           REG_WRITE_ALL_PROC:process(Sys_Clk)
             begin 
                 if (Sys_Clk'event and Sys_Clk='1') then
                     if (Sys_Rst = '1' ) then
                         bus2ip_addr_d1 <= (others => '0');
                         bus2ip_wrreq_d1<= '0'; 
                         bus2ip_cs_i_d1 <= (others => '0');  
                         bus2ip_wrce_d1 <= (others => '0'); 
                         bus2ip_rdce_d1 <= (others => '0'); 
                      else    
                         bus2ip_addr_d1 <= Chnl2IP_Addr;
               	         bus2ip_wrreq_d1<= Chnl2IP_WrReq(0); 
              	         bus2ip_cs_i_d1 <= Chnl2IP_CS;  
                         bus2ip_wrce_d1 <= Chnl2IP_WrCE; 
                         bus2ip_rdce_d1 <= Chnl2IP_RdCE; 
                     end if;
                 end if;
            end process REG_WRITE_ALL_PROC;
           end generate CHNL0_XFER_1_GEN; 
         end generate XCL2_CHNL0_XFER_1_GEN;          
         
         ----------------------------------------------------------------------
         -- Generate statement for XFER=2, the data and address are aligned 
         -- so no need of any extra delay's
         ----------------------------------------------------------------------
         
         CHNL0_NO_XFER_1_GEN: if C_XCL0_WRITEXFER=1 or C_XCL0_WRITEXFER=0 
         							       generate
             Bus2IP_Addr <= Chnl2IP_Addr;
             Bus2IP_WrReq<= Chnl2IP_WrReq(0);
             bus2ip_cs_i <= Chnl2IP_CS;  
             Bus2IP_WrCE <= Chnl2IP_WrCE; 
             Bus2IP_RdCE <= Chnl2IP_RdCE; 
         end generate CHNL0_NO_XFER_1_GEN;
         
         Bus2IP_RdReq           <=  Chnl2IP_RdReq(0);    
         Bus2IP_Data            <=  Chnl2IP_Data;
         Bus2IP_BE              <=  Chnl2IP_BE;
         Bus2IP_RNW             <=  Chnl2IP_RNW(0);
         bus2ip_burst_i         <=  Chnl2IP_Burst(0);
         Bus2IP_BurstLength     <=  Chnl2IP_BurstLength;
         Bus2IP_AddrBurstLength <=  Chnl2IP_BurstLength;
          
         IP2Chnl_Data           <=  IP2Bus_Data;
         IP2Chnl_Ack(0)         <=  IP2Bus_RdAck or IP2Bus_WrAck;  
         IP2Chnl_Error(0)       <=  IP2Bus_Error;
         IP2Chnl_AddrAck(0)     <=  IP2Bus_AddrAck;
                                
         IP2PLB_Data            <=  (others => '0');
         IP2PLB_RdAck           <=  '0';
         IP2PLB_WrAck           <=  '0';
         IP2PLB_Error           <=  '0';
         IP2PLB_AddrAck         <=  '0';
         
         addr_master_i          <=  "1";
         data_master_i          <=  "1";
          
         
         -----------------------------------------------------------------------
         -- REG_BUS2IP_CS_GEN
         -- Register Bus2ip_cs which is used to generate Bus2IP_AddrBurstCntLoad 
         -- signal
         -----------------------------------------------------------------------
         REG_BUS2IP_CS_GEN:process(Sys_Clk)
           begin 
               if (Sys_Clk'event and Sys_Clk='1') then
                   if (Sys_Rst = '1' ) then
                       chnl2ip_cs_d1 <= '0';
                       Bus2IP_AddrBurstCntLoad <= '0';
                   elsif (chnl2ip_rdreq_re = '1' or chnl2ip_wrreq_re = '1')then
                       Bus2IP_AddrBurstCntLoad <= '1'; 
                   else
                       chnl2ip_cs_d1 <= chnl2ip_cs(0);
                       Bus2IP_AddrBurstCntLoad <= not chnl2ip_cs_d1;
                   end if;
               end if;
         end process REG_BUS2IP_CS_GEN;
       
         REG_CS_GEN:process(Sys_Clk)
           begin 
               if (Sys_Clk'event and Sys_Clk='1') then
                   if (Sys_Rst = '1' ) then
                       Chnl2IP_RdReq_d1 <= '0';
                       Chnl2IP_WrReq_d1 <= '0';
                   else
                       Chnl2IP_RdReq_d1 <= Chnl2IP_RdReq(0);
                       Chnl2IP_WrReq_d1 <= Chnl2IP_WrReq(0);
                   end if;
               end if;
         end process REG_CS_GEN;

         chnl2ip_rdreq_re <=  Chnl2IP_RdReq(0) and not Chnl2IP_RdReq_d1;
         chnl2ip_wrreq_re <=  Chnl2IP_WrReq(0) and not Chnl2IP_WrReq_d1;

    end generate NO_PLB_IPIF;
   
end generate ONE_MASTER_GEN;

-------------------------------------------------------------------------------
-- If there is at least one MCH interface and an PLBV46 IPIF or multiple MCH 
-- interfaces, arbitration logic and mux/de-mux logic is needed.
-------------------------------------------------------------------------------
MULTI_MASTER_GEN: if NUM_MASTERS > 1 generate
    ---------------------------------------------------------------------------
    -- Arbitration Logic
    ---------------------------------------------------------------------------
    ARB_LOGIC_I: entity mch_plbv46_slave_burst_v2_01_a.arbitration_logic
        generic map (
                        C_NUM_MASTERS           =>  NUM_MASTERS, 
                        C_NUM_CHANNELS          =>  C_NUM_CHANNELS,
                        C_PRIORITY_MODE         =>  C_PRIORITY_MODE,
                        C_NUM_MCH_CS            =>  C_NUM_MCH_CS,
                        C_NUM_PLB_CS            =>  C_NUM_PLB_CS,
                        C_INCLUDE_PLB_IPIF      =>  C_INCLUDE_PLB_IPIF,
                        C_BRSTCNT_WIDTH         =>  C_BRSTCNT_WIDTH,
                        C_FAMILY                =>  C_FAMILY
                     )
        port map    (
                        Sys_Clk                 =>  Sys_Clk,    
                        Sys_Rst                 =>  Sys_Rst, 
                        Chnl_Req                =>  Chnl_Req, 
                        PLB2IP_CS               =>  PLB2IP_CS,
                        Chnl_Data_Almost_Done   =>  Chnl_Data_Almost_Done, 
                        Chnl_Addr_Almost_Done   =>  Chnl_Addr_Almost_Done, 
                        Bus2IP_Burst            =>  bus2ip_burst_i, 
                        PLB2IP_Burst            =>  PLB2IP_Burst,
                        IP2Bus_AddrAck          =>  IP2Bus_AddrAck,
                        IP2Bus_RdAck            =>  IP2Bus_RdAck,
                        IP2Bus_WrAck            =>  IP2Bus_WrAck,
                        IP2Bus_Error            =>  IP2Bus_Error, 
                        CS_Bus                  =>  cs_bus,
                        Bus2IP_CS               =>  bus2ip_cs_i,
                        PLB_Request             =>  plb_request,
                        PLB_Request_Gated       =>  plb_request_gated,
                        PLB_xfer_end            =>  plb_xfer_end,
                        IPIC_Addr_Mux_Sel       =>  ipic_addr_mux_sel, 
                        IPIC_Data_Mux_Sel       =>  ipic_data_mux_sel, 
                        Addr_Master             =>  addr_master_i, 
                        Data_Master             =>  data_master_i,
                        Addr_arb_cycle          =>  addr_arb_cycle_i,
                        Data_arb_cycle          =>  data_arb_cycle_i,
                        Addr_phase_idle         =>  addr_phase_idle,
                        Data_phase_idle         =>  data_phase_idle  
                    );

    ---------------------------------------------------------------------------
    -- Address and Data Phase Multiplexors
    ---------------------------------------------------------------------------
    ADDR_DATA_MUX_DEMUX_I: entity mch_plbv46_slave_burst_v2_01_a.
                                                            addr_data_mux_demux
        generic map (
                        C_MCH_SPLB_DWIDTH       =>  C_MCH_SPLB_DWIDTH,          
                        C_MCH_SPLB_AWIDTH       =>  C_MCH_SPLB_AWIDTH,  
                        C_NUM_CHANNELS          =>  C_NUM_CHANNELS,    
                        C_NUM_MCH_CS            =>  C_NUM_MCH_CS,
                        C_NUM_PLB_CS            =>  C_NUM_PLB_CS,
                        C_NUM_PLB_CE            =>  C_NUM_PLB_CE,
                        C_INCLUDE_PLB_IPIF      =>  C_INCLUDE_PLB_IPIF,
                        C_NUM_MASTERS           =>  NUM_MASTERS,
                        C_BRSTCNT_WIDTH         =>  C_BRSTCNT_WIDTH,
                        C_FAMILY                =>  C_FAMILY
                    )                           
        port map (                              
                    Sys_Clk                     =>  Sys_Clk,
                    Sys_Rst                     =>  Sys_Rst,
                                                
                    IPIC_Addr_Mux_Sel           =>  ipic_addr_mux_sel,
                    Addr_Master                 =>  addr_master_i,
                    IPIC_Data_Mux_Sel           =>  ipic_data_mux_sel,
                    Data_Master                 =>  data_master_i,
                    Data_arb_cycle              =>  data_arb_cycle_i,
                    Addr_arb_cycle              =>  addr_arb_cycle_i,
                    CS_Bus                      =>  cs_bus,
                                               
                    PLB2IP_Addr                 =>  PLB2IP_Addr,
                    PLB2IP_RdReq                =>  PLB2IP_RdReq,
                    PLB2IP_WrReq                =>  PLB2IP_WrReq,
                    Chnl2IP_Addr                =>  Chnl2IP_Addr,
                    Chnl2IP_RdReq               =>  Chnl2IP_RdReq,
                    Chnl2IP_WrReq               =>  Chnl2IP_WrReq,
                    Bus2IP_Addr                 =>  Bus2IP_Addr,
                    Bus2IP_RdReq                =>  Bus2IP_RdReq,
                    Bus2IP_WrReq                =>  Bus2IP_WrReq,
                    Addrphase_burst             =>  addrphase_burst, 
                                                
                    IP2Bus_AddrAck              =>  IP2Bus_AddrAck,
                    IP2PLB_AddrAck              =>  IP2PLB_AddrAck,
                    IP2Chnl_AddrAck             =>  IP2Chnl_AddrAck,
                                                
                    PLB2IP_CS                   =>  PLB2IP_CS,
                    PLB2IP_Data                 =>  PLB2IP_Data,
                    PLB2IP_BE                   =>  PLB2IP_BE,
                    PLB2IP_RNW                  =>  PLB2IP_RNW,
                    PLB2IP_RdCE                 =>  PLB2IP_RdCE,
                    PLB2IP_WrCE                 =>  PLB2IP_WrCE,
                    PLB2IP_Burst                =>  PLB2IP_Burst,
                    PLB2IP_BurstLength          =>  PLB2IP_BurstLength, 
                    Chnl2IP_CS                  =>  Chnl2IP_CS,
                    Chnl2IP_Data                =>  Chnl2IP_Data,
                    Chnl2IP_BE                  =>  Chnl2IP_BE,
                    Chnl2IP_RNW                 =>  Chnl2IP_RNW,
                    Chnl2IP_RdCE                =>  Chnl2IP_RdCE,
                    Chnl2IP_WrCE                =>  Chnl2IP_WrCE,
                    Chnl2IP_Burst               =>  Chnl2IP_Burst,
                    Chnl2IP_BurstLength         =>  Chnl2IP_BurstLength,
                    Bus2IP_CS                   =>  bus2ip_cs_i,
                    Bus2IP_Data                 =>  Bus2IP_Data,
                    Bus2IP_BE                   =>  Bus2IP_BE,
                    Bus2IP_RNW                  =>  Bus2IP_RNW,
                    Bus2IP_RdCE                 =>  Bus2IP_RdCE,
                    Bus2IP_WrCE                 =>  Bus2IP_WrCE,
                    Bus2IP_Burst                =>  bus2ip_burst_i,
                    Bus2IP_BurstLength          =>  Bus2IP_BurstLength,
                    Bus2IP_AddrBurstLength      =>  Bus2IP_AddrBurstLength,
                    Bus2IP_AddrBurstCntLoad     =>  Bus2IP_AddrBurstCntLoad,                      
                                                
                    IP2Bus_Data                 =>  IP2Bus_Data,
                    IP2Bus_RdAck                =>  IP2Bus_RdAck,
                    IP2Bus_WrAck                =>  IP2Bus_WrAck,
                    IP2Bus_Error                =>  IP2Bus_Error,
                    IP2PLB_Data                 =>  IP2PLB_Data,
                    IP2PLB_RdAck                =>  IP2PLB_RdAck,
                    IP2PLB_WrAck                =>  IP2PLB_WrAck,
                    IP2PLB_Error                =>  IP2PLB_Error,
                    IP2Chnl_Data                =>  IP2Chnl_Data,
                    IP2Chnl_Ack                 =>  IP2Chnl_Ack,
                    IP2Chnl_Error               =>  IP2Chnl_Error    
                );

end generate MULTI_MASTER_GEN;

end imp;
