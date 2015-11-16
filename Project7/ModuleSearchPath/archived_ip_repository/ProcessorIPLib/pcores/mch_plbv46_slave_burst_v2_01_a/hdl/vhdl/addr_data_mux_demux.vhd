-------------------------------------------------------------------------------
-- addr_data_mux_demux.vhd - entity/architecture pair
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
-- Filename:        addr_data_mux_demux.vhd
-- Version:         v2.01a
-- Description:     Address phase and data phase multiplexors and de-multiplexors
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
-- Author:          PVK
-- History:
--  PVK         11/02/06        First Version
-- ^^^^^^
--  First version of mch_plbv46_slave_burst
--  Integrated this code in mch_plbv46_slave_burst
--  Removed CE muxing logic
-- ~~~~~~~
-- ALS          11/02/06
-- ^^^^^^
--  Added mux to load burst counter and generation of Bus2IP_Burst from a 
--  register
-- ~~~~~~
--  PVK		02/26/07
-- ^^^^^^
-- Removed port Hold_Burst, Burst_count,Bus2IP_CE, PLB2IP_CE and Chnl2IP_CE. 
-- Comment cleanup.
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
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

-------------------------------------------------------------------------------
-- proc common library is used for different function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.mux_onehot_f;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
--      C_MCH_SPLB_DWIDTH         -- data width of MCH and PLBV46 interfaces
--      C_MCH_SPLB_AWIDTH         -- address width of MCH and PLBV46 interfaces
--      C_NUM_CHANNELS            -- number of MCH interfaces             
--      C_NUM_MCH_CS              -- number of chip selects generated by MCH                 
--                                -- interfaces 
--      C_NUM_PLB_CS              -- number of chip selects generated by PLBV46
--      C_NUM_PLB_CE              -- number of chip enables generated by PLBV46
--      C_INCLUDE_PLB_IPIF        -- is PLBv46 required
--      C_NUM_MASTERS             -- PLBV46 + Number of MCH interfaces
--      C_BRSTCNT_WIDTH           -- burst count width
--      C_FAMILY                  -- target FPGA family
--
-- Definition of Ports:
--
--  -- System signals
--      Sys_Clk                 -- System clock
--      Sys_Rst                 -- System reset
--
--  -- Arbitration signals  
--      IPIC_Addr_Mux_Sel       -- select lines for the address mux 
--      Addr_Master             -- current master of address phase
--      IPIC_Data_Mux_Sel       -- select lines for the data mux
--      Data_Master             -- current master of data phase
--      Data_arb_cycle          -- data arbiter cycle
--      Addr_arb_cycle          -- address arbiter cycle
--
--  -- Concatenated PLBV46 and Channel chip select bus
--     CS_bus
--
--  -- Address mux input signals
--      PLB2IP_Addr             -- IPIC signals from PLBV46_SLAVE_BURST             
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
--      Addrphase_burst         -- special signal used by IPIC_PIPE
--
--  -- Address de-mux input signal
--      IP2Bus_AddrAck          -- IPIC signal from the IP        
--
--  -- Address de-mux output signals 
--      IP2PLB_AddrAck          -- IPIC signal to the PLBV46
--      IP2Chnl_AddrAck         -- IPIC signal to the channels
--
--  -- Data mux input signals
--      PLB2IP_CS               -- PLBv46 transaction request
--      PLB2IP_BE               -- IPIC signals from PLBV46 
--      PLB2IP_Data                         
--      PLB2IP_RNW              
--      PLB2IP_RdCE             
--      PLB2IP_WrCE             
--      PLB2IP_Burst
--      PLB2IP_BurstLength
--
--      Chnl2IP_CS              -- CS of requested transaction
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
entity addr_data_mux_demux is
    generic (
       C_MCH_SPLB_DWIDTH      : integer   := 32; 
       C_MCH_SPLB_AWIDTH      : integer   := 32;
       C_NUM_CHANNELS         : integer   := 2;              
       C_NUM_MCH_CS           : integer   := 1;
       C_NUM_PLB_CS           : integer   := 1;
       C_NUM_PLB_CE           : integer   := 1;
       C_INCLUDE_PLB_IPIF     : integer   := 0;            
       C_NUM_MASTERS          : integer   := 2;
       C_BRSTCNT_WIDTH        : integer   := 6;   
       C_FAMILY               : string    := "nofamily"
      );  

  port
    (
      -- System signals
      Sys_Clk                 : in  std_logic;
      Sys_Rst                 : in  std_logic;

      -- arbitration signals         
      IPIC_Addr_Mux_Sel       : in  std_logic_vector(0 to C_NUM_MASTERS-1);
      Addr_Master             : in  std_logic_vector(0 to C_NUM_MASTERS-1);
      IPIC_Data_Mux_Sel       : in  std_logic_vector(0 to C_NUM_MASTERS-1);
      Data_Master             : in  std_logic_vector(0 to C_NUM_MASTERS-1);
      Data_arb_cycle          : in  std_logic;    
      Addr_arb_cycle          : in  std_logic;    

      -- concatenated OPB and Channel chip select bus
      CS_Bus                  : out std_logic_vector
                                   (0 to C_NUM_MASTERS*C_NUM_MCH_CS-1);
      
      -- address mux input signals
      PLB2IP_Addr             : in  std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);      
      PLB2IP_RdReq            : in  std_logic;
      PLB2IP_WrReq            : in  std_logic;
      
      Chnl2IP_Addr            : in  std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_MCH_SPLB_AWIDTH-1);     
      Chnl2IP_RdReq           : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
      Chnl2IP_WrReq           : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
                                                  
      -- address mux output signals
      Bus2IP_Addr             : out std_logic_vector
                                   (0 to C_MCH_SPLB_AWIDTH-1);  
      Bus2IP_RdReq            : out std_logic;
      Bus2IP_WrReq            : out std_logic;
      Addrphase_burst         : out std_logic;
      
      -- address de-mux input signals
      IP2Bus_AddrAck          : in  std_logic;
      
      -- address de-mux output signals
      IP2PLB_AddrAck          : out std_logic;   
      IP2Chnl_AddrAck         : out std_logic_vector(0 to C_NUM_CHANNELS-1);  

      -- data mux input signals 
      PLB2IP_CS               : in  std_logic_vector(0 to C_NUM_PLB_CS-1);
      PLB2IP_BE               : in  std_logic_vector
                                   (0 to C_MCH_SPLB_DWIDTH/8-1);        
      PLB2IP_Data             : in  std_logic_vector
                                   (0 to C_MCH_SPLB_DWIDTH-1);  
      PLB2IP_RNW              : in  std_logic;   
      PLB2IP_RdCE             : in  std_logic_vector(0 to C_NUM_PLB_CE-1);  
      PLB2IP_WrCE             : in  std_logic_vector(0 to C_NUM_PLB_CE-1);  
      PLB2IP_Burst            : in  std_logic; 
      PLB2IP_BurstLength      : in  std_logic_vector(0 to C_BRSTCNT_WIDTH-1); 
      Chnl2IP_CS              : in  std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_NUM_MCH_CS-1);
      Chnl2IP_Data            : in  std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_MCH_SPLB_DWIDTH-1);
      Chnl2IP_BE              : in  std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_MCH_SPLB_DWIDTH/8-1);
      Chnl2IP_RNW             : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
      Chnl2IP_RdCE            : in  std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_NUM_MCH_CS-1);
      Chnl2IP_WrCE            : in  std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_NUM_MCH_CS-1);      
      Chnl2IP_Burst           : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
      Chnl2IP_BurstLength     : in  std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_BRSTCNT_WIDTH-1); 
    
      -- data mux output signals
      Bus2IP_CS               : out std_logic_vector(0 to C_NUM_PLB_CS-1);
      Bus2IP_Data             : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);
      Bus2IP_BE               : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH/8-1);
      Bus2IP_RNW              : out std_logic;   
      Bus2IP_RdCE             : out std_logic_vector(0 to C_NUM_PLB_CE-1);  
      Bus2IP_WrCE             : out std_logic_vector(0 to C_NUM_PLB_CE-1);  
      Bus2IP_Burst            : out std_logic; 
      Bus2IP_BurstLength      : out std_logic_vector(0 to C_BRSTCNT_WIDTH-1); 
      Bus2IP_AddrBurstLength  : out std_logic_vector(0 to C_BRSTCNT_WIDTH-1); 
      Bus2IP_AddrBurstCntLoad : out std_logic;                                

      -- data de-mux input signals
      IP2Bus_Data             : in  std_logic_vector
                                   (0 to C_MCH_SPLB_DWIDTH-1);   
      IP2Bus_RdAck            : in  std_logic;
      IP2Bus_WrAck            : in  std_logic;
      IP2Bus_Error            : in  std_logic;  
    
      -- data de-mux output signals
      IP2PLB_Data             : out std_logic_vector
                                   (0 to C_MCH_SPLB_DWIDTH-1);
      IP2PLB_RdAck            : out std_logic;        
      IP2PLB_WrAck            : out std_logic;        
      IP2PLB_Error            : out std_logic;    
                                         
      IP2Chnl_Data            : out std_logic_vector
                                   (0 to C_NUM_CHANNELS*C_MCH_SPLB_DWIDTH-1);  
      IP2Chnl_Ack             : out std_logic_vector(0 to C_NUM_CHANNELS-1);          
      IP2Chnl_Error           : out std_logic_vector(0 to C_NUM_CHANNELS-1)

);    


end addr_data_mux_demux;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of addr_data_mux_demux is

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant BURST_MUX_SELECT_ZERO  : std_logic_vector(0 to C_NUM_MASTERS-1) 
                                   := (others => '0');

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
-- concatenated busses for the 1-hot muxes
signal address      : std_logic_vector
                        (0 to C_NUM_MASTERS*C_MCH_SPLB_AWIDTH-1);
signal be           : std_logic_vector
                        (0 to C_NUM_MASTERS*C_MCH_SPLB_DWIDTH/8-1);
signal addr_valid   : std_logic_vector(0 to C_NUM_MASTERS-1);
signal rdreq        : std_logic_vector(0 to C_NUM_MASTERS-1);
signal wrreq        : std_logic_vector(0 to C_NUM_MASTERS-1);
signal cs           : std_logic_vector(0 to C_NUM_MASTERS*C_NUM_MCH_CS-1);
signal bus_data     : std_logic_vector(0 to C_NUM_MASTERS*C_MCH_SPLB_DWIDTH-1);
signal rnw          : std_logic_vector(0 to C_NUM_MASTERS-1);
signal ce           : std_logic_vector
                        (0 to C_NUM_MASTERS*C_NUM_MCH_CS-1);
signal rdce         : std_logic_vector
                        (0 to C_NUM_MASTERS*C_NUM_MCH_CS-1);
signal wrce         : std_logic_vector
                        (0 to C_NUM_MASTERS*C_NUM_MCH_CS-1);
signal burst        : std_logic_vector(0 to C_NUM_MASTERS-1);

signal burst_length : std_logic_vector
                          (0 to C_NUM_MASTERS*C_BRSTCNT_WIDTH-1);   

-- concatenated busses for the de-mux operations
signal addrack      : std_logic_vector(0 to C_NUM_MASTERS-1);
signal dataack      : std_logic_vector(0 to C_NUM_MASTERS-1);
signal error        : std_logic_vector(0 to C_NUM_MASTERS-1);
signal ip_data      : std_logic_vector(0 to C_NUM_MASTERS*C_MCH_SPLB_DWIDTH-1);

-- 1-bit std logic vectors for mux outputs
signal bus2ip_rdreq_i        : std_logic_vector(0 to 0);
signal bus2ip_wrreq_i        : std_logic_vector(0 to 0);
signal bus2ip_rnw_i          : std_logic_vector(0 to 0);
signal bus2ip_burst_i        : std_logic_vector(0 to 0);
signal bus2ip_burstlength_i  : std_logic_vector(0 to C_BRSTCNT_WIDTH-1);


signal ip2bus_ack_i          : std_logic; 

-- internal bus2ip_cs signal
signal bus2ip_cs_i           : std_logic_vector(0 to C_NUM_PLB_CS-1);

-- signals for generation of Bus2IP_Burst 
signal burst_count_mux       : std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
signal addr_burst_count_mux  : std_logic_vector(0 to C_BRSTCNT_WIDTH-1);

type BURST_CNTHOLD_STATE_TYPE is (BURSTCNT_IDLE, BURSTCNT_BUSY, 
                                                      WAIT_FOR_DATA_ARB);
signal burst_cnthold_ns      : BURST_CNTHOLD_STATE_TYPE := BURSTCNT_IDLE;
signal burst_cnthold_cs      : BURST_CNTHOLD_STATE_TYPE := BURSTCNT_IDLE;

signal Chnl2IP_CS_d1         : std_logic_vector
                                 (0 to C_NUM_CHANNELS*C_NUM_MCH_CS-1);
signal PLB2IP_CS_d1          : std_logic_vector(0 to C_NUM_PLB_CS-1);
signal PLB2IP_BurstLength_d1 : std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
begin -- architecture IMP

-- assign output signals to internal signals
ip2bus_ack_i  <= IP2Bus_RdAck or IP2Bus_WrAck;

CS_Bus  <= cs;

-------------------------------------------------------------------------------
-- INC_PLB_GEN : Included only when  C_INCLUDE_PLB_IPIF = 1
-- perform the signal manipulation needed if the PLBV46 interface is included
-- note that it is assumed that the PLBV46 interface may have additional CSs 
-- and CEs but that these additional CSs and CEs are at the lower end of the 
-- CS and CE busses the PLBV46 additional CSs and CEs do not need to be 
-- multiplexed, but can be passed to the IP when the PLBV46 has won arbitration
-------------------------------------------------------------------------------
INC_PLB_GEN: if C_INCLUDE_PLB_IPIF = 1 generate
begin
    -- signals for address phase multiplexor
    address     <= Chnl2IP_Addr & PLB2IP_Addr;

    -- Bus2IP_RdReq and Bus2IP_WrReq have to be generated from the Channel 
    -- read/write requests, but from the PLB read/write CEs
    rdreq       <= Chnl2IP_RdReq & or_reduce(PLB2IP_RdCE(0 to C_NUM_MCH_CS-1));
    wrreq       <= Chnl2IP_WrReq & or_reduce(PLB2IP_WrCE(0 to C_NUM_MCH_CS-1));

    -- signals for data phase multiplexor
    -- only use the PLBV46 CS that correspond to the Channel CS
    -- cs are registered before muxing to break long timing path 
    cs          <= Chnl2IP_CS_d1 & PLB2IP_CS_d1(0 to C_NUM_MCH_CS-1);
    bus_data    <= Chnl2IP_Data & PLB2IP_Data;
    be          <= Chnl2IP_BE & PLB2IP_BE;
    rnw         <= Chnl2IP_RNW & PLB2IP_RNW;

    -- only use the PLBV46 CEs that correspond to the Channel CEs
    -- channel CEs always match the CSs
    rdce        <= Chnl2IP_RdCE & PLB2IP_RdCE(0 to C_NUM_MCH_CS-1);
    wrce        <= Chnl2IP_WrCE & PLB2IP_WrCE(0 to C_NUM_MCH_CS-1);
    burst       <= Chnl2IP_Burst & PLB2IP_Burst;

    -- Using registered version of PLB2IP_BurstLength to break long timing path
    --burst_length <= Chnl2IP_BurstLength & PLB2IP_BurstLength;   
    burst_length <= Chnl2IP_BurstLength & PLB2IP_BurstLength_d1;     

    ---------------------------------------------------------------------------
    -- CTRL_SIG_REG : 
    -- Register control signals from channel and plb to IP to break long data
    -- path
    ---------------------------------------------------------------------------
    CTRL_SIG_REG: process (Sys_Clk)
    begin
        if Sys_Clk'event and Sys_Clk = '1' then
            if Sys_Rst = '1'  then
                PLB2IP_CS_d1  <= (others => '0');
                PLB2IP_BurstLength_d1 <= (others => '0');
                Chnl2IP_CS_d1 <= (others => '0');
            else 
                PLB2IP_CS_d1  <= PLB2IP_CS;
                PLB2IP_BurstLength_d1 <= PLB2IP_BurstLength;
                Chnl2IP_CS_d1 <= Chnl2IP_CS;
            end if;
        end if;
    end process CTRL_SIG_REG;

    ---------------------------------------------------------------------------
    -- PLBCS_GT_MCHCS_GEN : Included only when C_NUM_PLB_CS > C_NUM_MCH_CS
    ---------------------------------------------------------------------------
    PLBCS_GT_MCHCS_GEN: if C_NUM_PLB_CS > C_NUM_MCH_CS generate
    begin
        -- use PLBV46 CSs and CEs when PLBV46 wins arbitration, otherwise
        -- set these signals to zero
        PLB_CS_MUX: process ( IPIC_Data_Mux_Sel,
                                 PLB2IP_CS
                            )
        begin
            if IPIC_Data_Mux_Sel(C_NUM_MASTERS-1)='1' then
                -- PLB has won arbitration, send out additional PLBV46 CSs
                bus2ip_cs_i(C_NUM_MCH_CS to C_NUM_PLB_CS-1) <= 
                                     PLB2IP_CS(C_NUM_MCH_CS to C_NUM_PLB_CS-1);
            else
                -- PLB has not won arbitration, zero out additional PLBV46 CSs 
                -- and CEs
                bus2ip_cs_i(C_NUM_MCH_CS to C_NUM_PLB_CS-1) <= (others => '0');
            end if;
       end process PLB_CS_MUX;
       
    end generate PLBCS_GT_MCHCS_GEN;
    
    ---------------------------------------------------------------------------
    -- PLBCE_GT_MCHCE_GEN : Included only when C_NUM_PLB_CE > C_NUM_MCH_CS 
    ---------------------------------------------------------------------------
    PLBCE_GT_MCHCE_GEN: if C_NUM_PLB_CE > C_NUM_MCH_CS generate
    begin
        -- use PLBV46 CSs and CEs when PLBV46 wins arbitration, otherwise
        -- set these signals to zero
        PLB_CE_MUX: process ( IPIC_Data_Mux_Sel,
                                 PLB2IP_RdCE,
                                 PLB2IP_WrCE  )
        begin
            if IPIC_Data_Mux_Sel(C_NUM_MASTERS-1)='1' then
                -- PLBV46 has won arbitration, send out additional PLBV46 CSs 
                -- and CEs
                Bus2IP_RdCE(C_NUM_MCH_CS to C_NUM_PLB_CE-1) <= 
                                   PLB2IP_RdCE(C_NUM_MCH_CS to C_NUM_PLB_CE-1);
                Bus2IP_WrCE(C_NUM_MCH_CS to C_NUM_PLB_CE-1) <= 
                                   PLB2IP_WrCE(C_NUM_MCH_CS to C_NUM_PLB_CE-1);
            else
                -- PLBV46 has not won arbitration, zero out additional PLBV46 
                -- CSs and CEs
                Bus2IP_RdCE(C_NUM_MCH_CS to C_NUM_PLB_CE-1) <= (others => '0');
                Bus2IP_WrCE(C_NUM_MCH_CS to C_NUM_PLB_CE-1) <= (others => '0');  
            end if;
       end process PLB_CE_MUX;
       
    end generate PLBCE_GT_MCHCE_GEN;
            
end generate INC_PLB_GEN;

-------------------------------------------------------------------------------
-- NO_INC_PLB_GEN : Included only when C_INCLUDE_PLB_IPIF = 0
-- create the concatenated busses for the one hot muxes
-------------------------------------------------------------------------------
NO_INC_PLB_GEN: if C_INCLUDE_PLB_IPIF = 0 generate
begin
    -- signals for address phase multiplexor
    address      <= Chnl2IP_Addr;
    rdreq        <= Chnl2IP_RdReq;
    wrreq        <= Chnl2IP_WrReq;

    -- signals for data phase multiplexor
    cs           <= Chnl2IP_CS;
    bus_data     <= Chnl2IP_Data;
    be           <= Chnl2IP_BE;
    rnw          <= Chnl2IP_RNW;
    rdce         <= Chnl2IP_RdCE;
    wrce         <= Chnl2IP_WrCE;
    burst        <= Chnl2IP_Burst;
    burst_length <= Chnl2IP_BurstLength; 
    
end generate NO_INC_PLB_GEN;

----
-- Address Phase Multiplexors
----

BUS2IP_ADDR_MUX_I: entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_MCH_SPLB_AWIDTH,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => address,
                S => IPIC_Addr_Mux_Sel,
                Y => Bus2IP_Addr
             );


BUS2IP_RDREQ_MUX_I : entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => 1,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => rdreq,
                S => IPIC_Addr_Mux_Sel,
                Y => bus2ip_rdreq_i
             );
Bus2IP_RdReq <= bus2ip_rdreq_i(0);             

BUS2IP_WRREQ_MUX_I : entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => 1,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => wrreq,
                S => IPIC_Addr_Mux_Sel,
                Y => bus2ip_wrreq_i
             );
Bus2IP_WrReq <= bus2ip_wrreq_i(0);             


----
-- Address Phase De-Multiplexors
----
IP2BUS_ADDRACK_DEMUX_GEN : for i in 0 to C_NUM_MASTERS-1 generate
        addrack(i)  <= Addr_master(i) and IP2Bus_AddrAck;
end generate IP2BUS_ADDRACK_DEMUX_GEN;

IP2Chnl_AddrAck <= addrack(0 to C_NUM_CHANNELS-1);
IP2PLB_AddrAck  <= addrack(C_NUM_MASTERS-1) when C_INCLUDE_PLB_IPIF=1
                   else '0';
----
-- Data Phase Multiplexors
----

BUS2IP_CS_MUX_I: entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_NUM_MCH_CS,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => cs,
                S => IPIC_Data_Mux_Sel,
                Y => bus2ip_cs_i(0 to C_NUM_MCH_CS-1)
             );

Bus2IP_CS <= bus2ip_cs_i;

BUS2IP_DATA_MUX_I: entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_MCH_SPLB_DWIDTH,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => bus_data,
                S => IPIC_Data_Mux_Sel,
                Y => Bus2IP_Data
             );

BUS2IP_BE_MUX_I : entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_MCH_SPLB_DWIDTH/8,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => be,
                S => IPIC_Data_Mux_Sel,
                Y => Bus2IP_BE
             );

BUS2IP_RNW_MUX_I : entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => 1,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => rnw,
                S => IPIC_Data_Mux_Sel,
                Y => bus2ip_rnw_i
             );
Bus2IP_RNW <= bus2ip_rnw_i(0);


BUS2IP_RDCE_MUX_I: entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_NUM_MCH_CS,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => rdce,
                S => IPIC_Data_Mux_Sel,
                Y => Bus2IP_RdCE(0 to C_NUM_MCH_CS-1)
             );
             
BUS2IP_WRCE_MUX_I: entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_NUM_MCH_CS,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => wrce,
                S => IPIC_Data_Mux_Sel,
                Y => Bus2IP_WrCE(0 to C_NUM_MCH_CS-1)
             );

ADDRBURSTCNT_MUX_I : entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_BRSTCNT_WIDTH,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => burst_length,   
                S => IPIC_Addr_Mux_Sel,
                Y => addr_burst_count_mux
             );
BURSTCNT_MUX_I : entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => C_BRSTCNT_WIDTH,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => burst_length,   
                S => IPIC_Data_Mux_Sel,
                Y => burst_count_mux
             );

BUS2IP_BURST_MUX_I : entity proc_common_v3_00_a.mux_onehot_f(imp)
    generic map (
                    C_DW     => 1,
                    C_NB     => C_NUM_MASTERS,
                    C_FAMILY => C_FAMILY
                 )
    port map (
                D => burst,
                S => IPIC_Data_Mux_Sel,
                Y => bus2ip_burst_i
             );
Bus2IP_Burst <= bus2ip_burst_i(0);
             

-------------------------------------------------------------------------------
-- BUS2IP_BURSTLEN_REG : Generating bus2ip_burstlength_i from burst_count_mux 
-------------------------------------------------------------------------------
BUS2IP_BURSTLEN_REG: process (Sys_Clk)
begin
    if Sys_Clk'event and Sys_Clk = '1' then
        if Sys_Rst = '1' then
            bus2ip_burstlength_i <= (others => '0');
        else 
            bus2ip_burstlength_i <= burst_count_mux;
        end if;
    end if;
end process BUS2IP_BURSTLEN_REG;


Bus2IP_BurstLength <= bus2ip_burstlength_i;
Bus2IP_AddrBurstLength <= addr_burst_count_mux;

-- The IP burst counter needs to be loaded on clock after the addr arb cycle
BUS2IP_ADDRBURSTCNTLOAD_REG: process (Sys_Clk)
    begin
        if Sys_Clk'event and Sys_Clk = '1' then
            if Sys_Rst = '1' then
                Bus2IP_AddrBurstCntLoad <=  '0';
            else 
                Bus2IP_AddrBurstCntLoad <= Addr_arb_cycle;                    
            end if;
        end if;
    end process BUS2IP_ADDRBURSTCNTLOAD_REG;



-------------------------------------------------------------------------------
-- Data Phase De-Multiplexors
--
-- NOTE: only the acknowledge and error signals are de-muxed
-- the data doesn't need to be de-muxed as it is only considered
-- valid when the acknowledge asserts, so all channels and the 
-- PLBV46 see the incoming data
-------------------------------------------------------------------------------
IP2BUS_ACKERR_DEMUX_GEN : for i in 0 to C_NUM_MASTERS-1 generate
    dataack(i)  <= Data_master(i) and ip2bus_ack_i;
    error(i)    <= Data_master(i) and IP2Bus_Error;
    ip_data(i*C_MCH_SPLB_DWIDTH to (i+1)*C_MCH_SPLB_DWIDTH-1) <= IP2Bus_Data;
end generate IP2BUS_ACKERR_DEMUX_GEN;

IP2Chnl_Ack     <= dataack(0 to C_NUM_CHANNELS-1);
IP2Chnl_Error   <= error(0 to C_NUM_CHANNELS-1);
IP2Chnl_Data    <= ip_data(0 to C_NUM_CHANNELS*C_MCH_SPLB_DWIDTH-1);

IP2PLB_RdAck    <= (dataack(C_NUM_MASTERS-1) and IP2Bus_RdAck) 
                   when C_INCLUDE_PLB_IPIF=1 else '0';

IP2PLB_WrAck    <= (dataack(C_NUM_MASTERS-1) and IP2Bus_WrAck) 
                   when C_INCLUDE_PLB_IPIF=1 else '0';
                   
IP2PLB_Error    <= error(C_NUM_MASTERS-1) when C_INCLUDE_PLB_IPIF=1
                   else '0';

IP2PLB_Data     <= ip_data((C_NUM_MASTERS-1)*C_MCH_SPLB_DWIDTH to 
                            C_NUM_MASTERS*C_MCH_SPLB_DWIDTH-1)
                   when C_INCLUDE_PLB_IPIF=1
                   else (others => '0');

end imp;
