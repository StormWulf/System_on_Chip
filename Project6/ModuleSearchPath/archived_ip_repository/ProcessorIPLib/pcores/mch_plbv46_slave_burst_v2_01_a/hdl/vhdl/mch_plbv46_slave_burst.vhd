-------------------------------------------------------------------------------
-- mch_plbv46_slave_burst.vhd - entity/architecture pair
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
-- Filename:        mch_plbv46_slave_burst.vhd
-- Version:         v2.01a
-- Description:     Top level file for Multi-CHannel & PLB SLAVE BURST IPIF 
--                                                 (MCH_PLBV46_SLAVE_BURST)
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
--  PVK           10/06/06    First Version
-- ^^^^^^
--      First version of MCH_PLBV46_SLAVE_BURST IPIF
-- ~~~~~~
--  ALS           11/02/06
-- ^^^^^^
--  Modified generation of Bus2IP_Burst to be from a register based on the burst
--  length
-- ~~~~~~
--  PVK           02/26/07
-- ^^^^^^
--  Added generation of Bus2IP_AddrBurstLength and Bus2IP_AddrBurstCntLoad 
--  signal for Channels=0 case. Generated Bus2IP_WrReq and Bus2IP_RdReq from 
--  Bus2IP_WrCE and Bus2IP_RdCE.
--  Code Cleanup.
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
use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.calc_num_ce;
use proc_common_v3_00_a.ipif_pkg.XCL;
use proc_common_v3_00_a.ipif_pkg.DAG;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.family.all;

-------------------------------------------------------------------------------
-- mch_plbv46_slave_burst_v2_01_a library is used for mch_plbv46_slave_burst
-- component declarations
-------------------------------------------------------------------------------
library mch_plbv46_slave_burst_v2_01_a;
use mch_plbv46_slave_burst_v2_01_a.arb_mux_demux;
use mch_plbv46_slave_burst_v2_01_a.mch_interface;

-------------------------------------------------------------------------------
-- plbv46_slave_burst_v1_01_a library is used for plbv46_slave_burst_v1_01_a
-- component declarations
-------------------------------------------------------------------------------
library plbv46_slave_burst_v1_01_a;
use plbv46_slave_burst_v1_01_a.plbv46_slave_burst;

-------------------------------------------------------------------------------
-- Definition of Generics:
--  -- General Generics
--      C_FAMILY                     -- Target FPGA family
--      C_INCLUDE_PLB_IPIF           -- Iinclude PLBv46 slave burst interface
--      C_SPLB_DWIDTH                -- Data width of PLBV46 interfaces
--      C_MCH_SPLB_AWIDTH            -- Address width of MCH and PLBV46 
--                                      interfaces
--      C_MCH_SIPIF_DWIDTH           -- Address width of slave interfaces
--      C_SPLB_SMALLEST_MASTER       -- Data width of the smallest master
--      C_PRIORITY_MODE              -- Priority mode for the arbiter 
--
--  -- MCH Generics
--      C_NUM_CHANNELS               -- Number of MCH interfaces, allowable 
--                                      value 
--                                   -- Includes ZERO also. Zero means only PLB
--                                      interface is supported    
--      C_MCH_PROTOCOL_ARRAY         -- Protocol of each MCH interface
--      C_MCH_USERIP_ADDRRANGE_ARRAY -- Address ranges of User IP accessible                  
--                                      via MCH interfaces                                 
--      C_MCH_ACCESSBUF_DEPTH_ARRAY  -- Depth of the Access buffer for each 
--                                      channel                 
--      C_MCH_RDDATABUF_DEPTH_ARRAY  -- Depth of the ReadData buffer for each 
--                                      channel
--
--  -- XCL Channel Generics
--      C_XCL_LINESIZE_ARRAY         -- Cacheline size for each channel             
--      C_XCL_WRITEXFER_ARRAY        -- Type of write tranfers requested by 
--                                      channel            
--                                                                               
--  -- DAG Channel Generics          -- UNUSED FOR THIS RELEASE
--      C_DAG_BURSTSIZE_ARRAY        -- Burst size of each channel                     
--      C_DAG_ADDR_STEP_ARRAY        -- Address increment for each channel               
--      C_DAG_ADDR_WRAP_ARRAY        -- Address wrap-around value for each 
--                                      channel
--
--  -- PLB SLAVE BURST IPIF Generics -- UNUSED if C_INCLUDE_PLB_IPIF = 0
--      C_PLB_ARD_ADDR_RANGE_ARRAY   -- Base/high address pairs for each ID                    
--      C_PLB_ARD_NUM_CE_ARRAY       -- Number of CEs for each ID 
--
--      C_SPLB_P2P                   -- Selects point-to-point bus topology
--      C_CACHLINE_ADDR_MODE         -- Selects cacheline addressing mode
--      C_WR_BUFFER_DEPTH            -- Write buffer depth.
--      C_SPLB_MID_WIDTH             -- PLB Master ID Bus width
--      C_SPLB_NUM_MASTERS           -- Number of PLB Masters
-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Ports:
--
--  -- System interface
--      SPLB_Clk                -- Clock input
--      SPLB_Rst                -- Reset input
--      Bus2IP_Clk              -- Clock output to IP
--      Bus2IP_Reset            -- Reset output to IP
--
--  -- MCH interface
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
--  PLB v46 Bus interface
--      PLB_ABus        -- Each master is required to provide a valid 32-bit 
--                         address when its request signal is asserted. The PLB
--                         will then arbitrate the requests and allow the  
--                         highest priority master’s address to be gated onto 
--                         the PLB_ABus
--      PLB_UABus       -- Slave upper address bits.
--      PLB_PAValid     -- This signal is asserted by the PLB arbiter in  
--                         response to the assertion of Mn_request and to 
--                         indicate that there is a valid primary address and 
--                         transfer qualifiers on the PLB outputs
--      PLB_SAValid     -- PLB secondary address valid only for 66 MHz.
--      PLB_rdPrim      -- PLB secondary to primary read request indicator
--      PLB_wrPrim      -- PLB secondary to primary write request indicator
--      PLB_masterID    -- These signals indicate to the slaves the  
--                         identificationof the master of the current transfer
--      PLB_abort       -- PLB abort bus request indicator
--      PLB_busLock     -- PLB bus lock
--      PLB_RNW         -- This signal is driven by the master and is used to 
--                         indicate whether the request is for a read or a 
--                         writetransfer
--      PLB_BE          -- These signals are driven by the master. For a  
--                         non-line and non-burst transfer they identify which
--                         bytes of the target being addressed are to be read 
--                         from or written to. Each bit corresponds to a byte
--                         lane on the read or write data bus
--      PLB_MSize       -- PLB data bus port width indicator
--      PLB_size        -- The PLB_size(0:3) signals are driven by the master 
--                         to indicate the size of the requested transfer.
--      PLB_type        -- The Mn_type signals are driven by the master and are
--                         used to indicate to the slave, via the PLB_type
--                         signals, the type of transfer being requested
--      PLB_lockErr     -- PLB lock indicator
--      PLB_wrDBus      -- This data bus is used to transfer data between a 
--                         master and a slave during a PLB write transfer
--                         slave response signals
--      PLB_wrBurst     -- PLB burst write transfer indicator
--      PLB_rdBurst     -- PLB burst read transfer indicator
--      PLB_wrPendReq   -- PLB pending burst write request indicator  
--      PLB_rdPendReq   -- PLB pending burst read request indicator   
--      PLB_wrPendPri   -- PLB pending write request priority  
--      PLB_rdPendPri   -- PLB pending read request priority   
--      PLB_reqPri      -- PLB current request priority
--      PLB_TAttribute  -- PLB transfer attribute  
--
--      Sl_addrAck      -- This signal is asserted to indicate that the 
--                         slave has acknowledged the address and will 
--                         latch the address
--      Sl_SSize        -- The Sl_SSize(0:1) signals are outputs of all 
--                         non 32-bit PLB slaves. These signals are 
--                         activated by the slave with the assertion of 
--                         PLB_PAValid or SAValid and a valid slave 
--                         address decode and must remain negated at 
--                         all other times.           
--      Sl_wait         -- This signal is asserted to indicate that the slave
--                         has recognized the PLB address as a valid address
--      Sl_rearbitrate  -- This signal is asserted to indicate that the 
--                         slave is unable to perform the currently 
--                         requested transfer and require the PLB arbiter
--                         to re-arbitrate the bus
--      Sl_wrDAck       -- This signal is driven by the slave for a write 
--                         transfer to indicate that the data currently on the
--                         PLB_wrDBus bus is no longer required by the slave 
--                         i.e. data is latched
--      Sl_wrComp       -- This signal is asserted by the slave to 
--                         indicate the end of the current write transfer.
--      Sl_wrBTerm      -- Slave terminate write burst transfer
--      Sl_rdDBus       -- Slave read data bus
--      Sl_rdWdAddr     -- Slave read word address
--      Sl_rdDAck       -- This signal is driven by the slave to indicate 
--                         that the data on the Sl_rdDBus bus is valid and 
--                         must be latched at the end of the current clock cycle
--      Sl_rdComp       -- This signal is driven by the slave and is used
--                         to indicate to the PLB arbiter that the read 
--                         transfer is either complete, or will be complete 
--                         by the end of the next clock cycle
--      Sl_rdBTerm      -- Slave terminate read burst transfer 
--      Sl_MBusy        -- These signals are driven by the slave and 
--                         are used to indicate that the slave is either 
--                         busy performing a read or a write transfer, or
--                         has a read or write transfer pending
--      Sl_MWrErr       -- These signals are driven by the slave and 
--                         are used to indicate that the slave has encountered
--                         an error during a write transfer that was initiated 
--                         by this master
--      Sl_MRdErr       -- These signals are driven by the slave and are 
--                         used to indicate that the slave has encountered an
--                         error during a read transfer that was initiated 
--                         by this master
--      Sl_MIRQ         -- Master interrupt request(one per master at each slave)
--                         Gives a slave the ability to indicate that it has 
--                         encountered an event it deems important to master
--  -- Interrupts
--
--  -- IPIC interface
--      Bus2IP_Clk              -- Bus to slave IP clock
--      Bus2IP_Reset            -- Bus to slabe IP reset
--      IP2Bus_Data             -- Read data from IP
--      IP2Bus_WrAck            -- Write data acknowledge from IP
--      IP2Bus_RdAck            -- Read data acknowledge from IP
--      IP2Bus_AddrAck          -- Address acknowledge from IP
--      IP2Bus_Error            -- Error indicator from IP
--      Bus2IP_Addr             -- Address to IP
--      Bus2IP_Data             -- Write data to IP
--      Bus2IP_RNW              -- Read/write control to IP
--      Bus2IP_BE               -- Byte enables to IP
--      Bus2IP_Burst            -- Burst transaction control to IP
--      Bus2IP_BurstLength      -- Burst transaction length aligned with 
--                                 data phase
--      Bus2IP_AddrBurstLength  -- Burst transaction length aligned with 
--                                 address phase
--      Bus2IP_AddrBurstCntLoad -- Burst count load signal
--      Bus2IP_WrReq            -- Indicator that there are more available  
--                                 write addresses
--      Bus2IP_RdReq            -- Indicator that there are more available  
--                                 read addresses
--      Bus2IP_CS               -- Chip selects for the address ranges
--      Bus2IP_RdCE             -- Read CEs within an address range
--      Bus2IP_WrCE             -- Write CEs within an address range
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity mch_plbv46_slave_burst is
    generic (
            C_FAMILY                        : string  := "virtex5";                       
            C_INCLUDE_PLB_IPIF              : integer range 0 to 1    := 1;
            C_SPLB_DWIDTH                   : integer range 32 to 128 := 32; 
            C_MCH_SPLB_AWIDTH               : integer range 32 to 32  := 32;
            C_MCH_SIPIF_DWIDTH              : integer range 32 to 64  := 32;
            C_SPLB_SMALLEST_MASTER          : integer range 32 to 128 := 32;
            
            C_PRIORITY_MODE                 : integer range 0 to 0 := 0;             
            C_NUM_CHANNELS                  : integer range 0 to 4 := 2;              
            C_MCH_PROTOCOL_ARRAY            : INTEGER_ARRAY_TYPE
                                                := (0 => 0,
                                                    1 => 1 );
            C_MCH_USERIP_ADDRRANGE_ARRAY    : SLV64_ARRAY_TYPE
                                                := (x"0000_0000_0000_0000",
                                                    x"0000_0000_0000_8FFF");
            C_MCH_ACCESSBUF_DEPTH_ARRAY     : INTEGER_ARRAY_TYPE
                                                := (0 => 16,
                                                    1 => 16 );
            C_MCH_RDDATABUF_DEPTH_ARRAY     : INTEGER_ARRAY_TYPE
                                                := (0 => 0,
                                                    1 => 4 );
            C_XCL_LINESIZE_ARRAY            : INTEGER_ARRAY_TYPE
                                                := (0 => 4,
                                                    1 => 4 );
            C_XCL_WRITEXFER_ARRAY           : INTEGER_ARRAY_TYPE
                                                := (0 => 0,
                                                    1 => 1 );           
            C_DAG_BURSTSIZE_ARRAY           : INTEGER_ARRAY_TYPE
                                                := (0 => 16,
                                                    1 => 16 );
            C_DAG_ADDR_STEP_ARRAY           : INTEGER_ARRAY_TYPE
                                                := (0 => 4,
                                                    1 => 4 );      
            C_DAG_ADDR_WRAP_ARRAY           : SLV64_ARRAY_TYPE
                                                := (x"0000_0000_0000_FFFF",
                                                    x"0000_0000_0000_FFFF");
            C_PLB_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE           
                                                :=( x"0000_0000_0000_0000",
                                                    x"0000_0000_0000_8FFF");
            C_PLB_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE         
                                                :=(0 => 1 );
            C_SPLB_P2P                      : integer range 0 to 1 := 0;
                  -- Optimize slave interface for a point to point connection
              
            C_CACHLINE_ADDR_MODE            : integer range 0 to 1 := 0;
                  -- Selects the addressing mode to use for Cacheline Read
                  -- operations.
                  -- 0 = Legacy Read mode (target word first)
                  -- 1 = Realign target word address to Cacheline aligned and
                  --     then do a linear incrementing addressing from start  
                  --     to end of the Cacheline (PCI Bridge enhancement).
                  
            C_WR_BUFFER_DEPTH               : integer range 0 to 64 := 16;
                  -- The number of storage locations for the write buffer
                  -- Setting to 0 removes the buffer.
  
            C_SPLB_MID_WIDTH                : integer range 0 to 4 := 1;
                  -- The width of the Master ID bus
                  -- This is set to log2(C_SPLB_NUM_MASTERS)
  
            C_SPLB_NUM_MASTERS              : integer range 1 to 16 := 1
                  -- The number of Master Devices connected to the PLB bus
                  -- Research this to find out default value
     );  

  port
      (
        -- System interface      
        SPLB_Clk                : in  std_logic;                  
        SPLB_Rst                : in  std_logic; 
      
        -- MCH interface      
        MCH_Access_Control      : in  std_logic_vector(0 to C_NUM_CHANNELS-1); 
        MCH_Access_Data         : in  std_logic_vector(0 to 
                                         C_NUM_CHANNELS*C_MCH_SIPIF_DWIDTH-1);
        MCH_Access_Write        : in  std_logic_vector(0 to C_NUM_CHANNELS-1);         
        MCH_Access_Full         : out std_logic_vector(0 to C_NUM_CHANNELS-1);

        MCH_ReadData_Control    : out std_logic_vector(0 to C_NUM_CHANNELS-1);    
        MCH_ReadData_Data       : out std_logic_vector(0 to 
                                         C_NUM_CHANNELS*C_MCH_SIPIF_DWIDTH-1);
        MCH_ReadData_Read       : in  std_logic_vector(0 to C_NUM_CHANNELS-1);
        MCH_ReadData_Exists     : out std_logic_vector(0 to C_NUM_CHANNELS-1);
    
        -- Bus Slave signals 
        PLB_ABus                : in  std_logic_vector(0 to 31);
        PLB_UABus               : in  std_logic_vector(0 to 31);
        PLB_PAValid             : in  std_logic;
        PLB_SAValid             : in  std_logic;
        PLB_rdPrim              : in  std_logic;
        PLB_wrPrim              : in  std_logic;
        PLB_masterID            : in  std_logic_vector
                                    (0 to C_SPLB_MID_WIDTH-1);
        PLB_abort               : in  std_logic;    
        PLB_busLock             : in  std_logic;
        PLB_RNW                 : in  std_logic;
        PLB_BE                  : in  std_logic_vector
                                    (0 to (C_SPLB_DWIDTH/8)-1);
        PLB_MSize               : in  std_logic_vector(0 to 1);
        PLB_size                : in  std_logic_vector(0 to 3);
        PLB_type                : in  std_logic_vector(0 to 2);
        PLB_lockErr             : in  std_logic;
        PLB_wrDBus              : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
        PLB_wrBurst             : in  std_logic;
        PLB_rdBurst             : in  std_logic;
        PLB_wrPendReq           : in  std_logic; 
        PLB_rdPendReq           : in  std_logic; 
        PLB_wrPendPri           : in  std_logic_vector(0 to 1); 
        PLB_rdPendPri           : in  std_logic_vector(0 to 1); 
        PLB_reqPri              : in  std_logic_vector(0 to 1);
        PLB_TAttribute          : in  std_logic_vector(0 to 15); 
        
        -- Slave Responce Signals
        Sl_addrAck              : out std_logic;
        Sl_SSize                : out std_logic_vector(0 to 1);
        Sl_wait                 : out std_logic;
        Sl_rearbitrate          : out std_logic;
        Sl_wrDAck               : out std_logic;
        Sl_wrComp               : out std_logic;
        Sl_wrBTerm              : out std_logic;
        Sl_rdDBus               : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
        Sl_rdWdAddr             : out std_logic_vector(0 to 3);
        Sl_rdDAck               : out std_logic;
        Sl_rdComp               : out std_logic;
        Sl_rdBTerm              : out std_logic;
        Sl_MBusy                : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1);
        Sl_MWrErr               : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1);                     
        Sl_MRdErr               : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1);                     
        Sl_MIRQ                 : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1);                     
            
        -- IP Interconnect (IPIC) port signals 
        Bus2IP_Clk              : out std_logic;
        Bus2IP_Reset            : out std_logic;
        IP2Bus_Data             : in  std_logic_vector
                                    (0 to C_MCH_SIPIF_DWIDTH-1); 
        IP2Bus_WrAck            : in  std_logic;
        IP2Bus_RdAck            : in  std_logic;
        IP2Bus_AddrAck          : in  std_logic;  
        IP2Bus_Error            : in  std_logic;
        Bus2IP_Addr             : out std_logic_vector
                                    (0 to C_MCH_SPLB_AWIDTH-1);
        Bus2IP_Data             : out std_logic_vector
                                    (0 to C_MCH_SIPIF_DWIDTH-1);  
        Bus2IP_RNW              : out std_logic;
        Bus2IP_BE               : out std_logic_vector
                                    (0 to (C_MCH_SIPIF_DWIDTH/8)-1);  
        Bus2IP_Burst            : out std_logic;
        Bus2IP_BurstLength      : out std_logic_vector
                                    (0 to log2(16 * (C_SPLB_DWIDTH/8)));
        Bus2IP_AddrBurstLength  : out std_logic_vector
                                    (0 to log2(16 * (C_SPLB_DWIDTH/8)));
        Bus2IP_AddrBurstCntLoad : out std_logic; 
        Bus2IP_WrReq            : out std_logic;
        Bus2IP_RdReq            : out std_logic;
        Bus2IP_CS               : out std_logic_vector(0 to 
                                    ((C_PLB_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
        Bus2IP_RdCE             : out std_logic_vector(0 to 
                                    calc_num_ce(C_PLB_ARD_NUM_CE_ARRAY)-1);
        Bus2IP_WrCE             : out std_logic_vector(0 to 
                                    calc_num_ce(C_PLB_ARD_NUM_CE_ARRAY)-1)
     );

    attribute REGISTER_DUPLICATION : string; 
    attribute REGISTER_DUPLICATION of Bus2IP_RdReq : signal is "yes"; 
    attribute REGISTER_DUPLICATION of Bus2IP_WrReq : signal is "yes"; 
    attribute REGISTER_DUPLICATION of Bus2IP_Burst : signal is "yes"; 
    attribute REGISTER_DUPLICATION of Bus2IP_Addr  : signal is "yes"; 

end mch_plbv46_slave_burst;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of mch_plbv46_slave_burst is

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-- No PLB MIR        
constant ZERO_DEV_BLK_ID     : integer := 0;
constant ZERO_DEV_MIR_ENABLE : integer := 0;

-- Number of MCH chip selects
constant NUM_MCH_CS          : integer := C_MCH_USERIP_ADDRRANGE_ARRAY'length/2;

-- Number of PLB chip selects and CEs 
constant NUM_PLB_CS          : integer := C_PLB_ARD_ADDR_RANGE_ARRAY'LENGTH/2;
constant NUM_PLB_CE          : integer := calc_num_ce(C_PLB_ARD_NUM_CE_ARRAY);

-- This is set at a constant value for now
-- May need to be calculated from PLB_DWIDTH and SIPIF DWIDTH in the future
constant BRSTCNT_WIDTH       : integer := log2(16 * (C_SPLB_DWIDTH/8));


-- Dont include Data phase timout counter when chaneels are present in the
-- system as plb transactions may take longer time to complete when the 
-- channels transactions are going on.
constant INCLUDE_DPHASE_TIMER : integer := 0;
-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
-- PLB IPIC Signals
signal ip2plb_ack          : std_logic;
signal ip2plb_wrack        : std_logic;
signal ip2plb_rdack        : std_logic;
signal ip2plb_addrack      : std_logic;
signal ip2plb_error        : std_logic;
signal ip2plb_data         : std_logic_vector(0 to C_MCH_SIPIF_DWIDTH - 1);
signal plb2ip_addr         : std_logic_vector(0 to C_MCH_SPLB_AWIDTH - 1);
signal plb2ip_addrvalid    : std_logic;
signal plb2ip_data         : std_logic_vector(0 to C_MCH_SIPIF_DWIDTH - 1);
signal plb2ip_rnw          : std_logic;
signal plb2ip_rdreq        : std_logic;
signal plb2ip_wrreq        : std_logic;
signal plb2ip_cs           : std_logic_vector(0 to NUM_PLB_CS-1);
signal plb2ip_ce           : std_logic_vector(0 to NUM_PLB_CE-1);
signal plb2ip_rdce         : std_logic_vector(0 to NUM_PLB_CE-1);
signal plb2ip_wrce         : std_logic_vector(0 to NUM_PLB_CE-1);
signal plb2ip_be           : std_logic_vector(0 to (C_MCH_SIPIF_DWIDTH / 8) - 1);
signal plb2ip_burst        : std_logic;
signal plb2ip_burstlength  : std_logic_vector(0 to 
                               log2(16 * (C_SPLB_DWIDTH/8)));
signal bus2ip_rdreq_i      : std_logic;
signal bus2ip_wrreq_i      : std_logic;
signal bus2ip_rdce_i       : std_logic_vector(0 to 
                               calc_num_ce(C_PLB_ARD_NUM_CE_ARRAY)-1);
signal bus2ip_wrce_i       : std_logic_vector(0 to 
                               calc_num_ce(C_PLB_ARD_NUM_CE_ARRAY)-1);
signal bus2ip_cs_i         : std_logic_vector(0 to 
                               (C_PLB_ARD_ADDR_RANGE_ARRAY'LENGTH/2)-1);
signal bus2ip_clk_i        : std_logic;
signal bus2ip_reset_i      : std_logic;
signal bus2ip_cs_d1        : std_logic;

signal bus2ip_burstlength_i  : std_logic_vector(0 to 
                                log2(16 * (C_SPLB_DWIDTH/8)));
-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
begin -- architecture IMP

-------------------------------------------------------------------------------
-- Instantiate PLBV46 Slave Burst based on value of C_INCLUDE_PLB_IPIF generic
-- and C_NUM_CHANNELS
-------------------------------------------------------------------------------
NO_CHNL_IF_GEN: if C_NUM_CHANNELS=0 generate

    Bus2IP_Clk      <= bus2ip_clk_i;
    Bus2IP_Reset    <= bus2ip_reset_i;  
    Bus2IP_CS       <= bus2ip_cs_i;      
    Bus2IP_WrReq    <= or_reduce(bus2ip_wrce_i);
    Bus2IP_RdReq    <= or_reduce(bus2ip_rdce_i);
    Bus2IP_BurstLength      <= bus2ip_burstlength_i;
    Bus2IP_AddrBurstLength  <= bus2ip_burstlength_i;
    
    -----------------------------------------------------------------------------
    -- REG_BUS2IP_CS_GEN
    -- Register Bus2ip_cs which is used to generate Bus2IP_AddrBurstCntLoad 
    -- signal
    -----------------------------------------------------------------------------
    REG_BUS2IP_CS_GEN:process(SPLB_Clk)
    begin 
        if (SPLB_Clk'event and SPLB_Clk='1') then
            if (SPLB_Rst = '1' ) then
                bus2ip_cs_d1 <= '0';
            else    
                bus2ip_cs_d1 <= bus2ip_cs_i(0);
            end if;
        end if;
    end process; -- REG_BUS2IP_CS_GEN
    
    Bus2IP_AddrBurstCntLoad <= not bus2ip_cs_d1;
    
    PLBV46_SLAVE_BURST_I : entity plbv46_slave_burst_v1_01_a.plbv46_slave_burst
    generic map
      (
        C_ARD_ADDR_RANGE_ARRAY    =>  C_PLB_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY        =>  C_PLB_ARD_NUM_CE_ARRAY,
        C_SPLB_P2P                =>  C_SPLB_P2P,
        C_CACHLINE_ADDR_MODE      =>  C_CACHLINE_ADDR_MODE,      
        C_WR_BUFFER_DEPTH         =>  C_WR_BUFFER_DEPTH,
        C_SPLB_MID_WIDTH          =>  C_SPLB_MID_WIDTH,      
        C_SPLB_NUM_MASTERS        =>  C_SPLB_NUM_MASTERS,
        C_SPLB_AWIDTH             =>  C_MCH_SPLB_AWIDTH,
        C_SPLB_DWIDTH             =>  C_SPLB_DWIDTH,
        C_SIPIF_DWIDTH            =>  C_MCH_SIPIF_DWIDTH,
        C_SPLB_SMALLEST_MASTER    =>  C_SPLB_SMALLEST_MASTER,
        C_BURSTLENGTH_TYPE        =>  1,
        C_INCLUDE_DPHASE_TIMER    =>  INCLUDE_DPHASE_TIMER,
        C_FAMILY                  =>  C_FAMILY      
      )
    port map
      (
        -- System signals 
        SPLB_Clk            =>  SPLB_Clk,
        SPLB_Rst            =>  SPLB_Rst,
  
        -- Bus Slave signals   
        PLB_ABus            =>  PLB_ABus,                          
        PLB_UABus           =>  PLB_UABus, 
        PLB_PAValid         =>  PLB_PAValid,
        PLB_SAValid         =>  PLB_SAValid,
        PLB_rdPrim          =>  PLB_rdPrim,
        PLB_wrPrim          =>  PLB_wrPrim,
        PLB_masterID        =>  PLB_masterID,                             
        PLB_abort           =>  PLB_abort,
        PLB_busLock         =>  PLB_busLock,
        PLB_RNW             =>  PLB_RNW,
        PLB_BE              =>  PLB_BE,                             
        PLB_MSize           =>  PLB_MSize,             
        PLB_size            =>  PLB_size,             
        PLB_type            =>  PLB_type,             
        PLB_lockErr         =>  PLB_lockErr,
        PLB_wrDBus          =>  PLB_wrDBus,                          
        PLB_wrBurst         =>  PLB_wrBurst,
        PLB_rdBurst         =>  PLB_rdBurst,
        PLB_wrPendReq       =>  PLB_wrPendReq,
        PLB_rdPendReq       =>  PLB_rdPendReq,
        PLB_wrPendPri       =>  PLB_wrPendPri,
        PLB_rdPendPri       =>  PLB_rdPendPri, 
        PLB_reqPri          =>  PLB_reqPri,             
        PLB_TAttribute      =>  PLB_TAttribute,
                                   
        -- Slave Responce Signals  
        Sl_addrAck          =>  Sl_addrAck,
        Sl_SSize            =>  Sl_SSize,             
        Sl_wait             =>  Sl_wait,
        Sl_rearbitrate      =>  Sl_rearbitrate,
        Sl_wrDAck           =>  Sl_wrDAck,
        Sl_wrComp           =>  Sl_wrComp,
        Sl_wrBTerm          =>  Sl_wrBTerm,
        Sl_rdDBus           =>  Sl_rdDBus,                          
        Sl_rdWdAddr         =>  Sl_rdWdAddr,             
        Sl_rdDAck           =>  Sl_rdDAck,
        Sl_rdComp           =>  Sl_rdComp,
        Sl_rdBTerm          =>  Sl_rdBTerm,
        Sl_MBusy            =>  Sl_MBusy,                               
        Sl_MWrErr           =>  Sl_MWrErr,               
        Sl_MRdErr           =>  Sl_MRdErr,
        Sl_MIRQ             =>  Sl_MIRQ,
      
        -- IP Interconnect (IPIC) port signals
        --System Signals
        Bus2IP_Clk          =>  bus2ip_clk_i,        
        Bus2IP_Reset        =>  bus2ip_reset_i,        
                                   
        -- IP Slave signals        
        IP2Bus_Data         =>  ip2bus_data,                                
        IP2Bus_WrAck        =>  ip2bus_wrack,                                
        IP2Bus_RdAck        =>  ip2bus_rdack,        
        IP2Bus_Error        =>  ip2bus_error,
        IP2Bus_AddrAck      =>  ip2bus_addrack,
                               
        Bus2IP_Addr         =>  bus2ip_addr,                               
        Bus2IP_Data         =>  bus2ip_data,                                
        Bus2IP_RNW          =>  bus2ip_rnw,             
        Bus2IP_BE           =>  bus2ip_be,        
        Bus2IP_Burst        =>  bus2ip_burst, 
        Bus2IP_BurstLength  =>  bus2ip_burstlength_i,
        Bus2IP_WrReq        =>  bus2ip_wrreq_i,        
        Bus2IP_RdReq        =>  bus2ip_rdreq_i, 
        Bus2IP_CS           =>  bus2ip_cs_i,        
        Bus2IP_RdCE         =>  bus2ip_rdce_i,                                                                 
        Bus2IP_WrCE         =>  bus2ip_wrce_i                                                          
      );
  
  
    -- Tied MCH signals to 0 as Channel logic is not present 
    MCH_Access_Full      <= (others=>'0'); 
    MCH_ReadData_Control <= (others=>'0');
    MCH_ReadData_Data    <= (others=>'0');
    MCH_ReadData_Exists  <= (others=>'0');
  
end generate NO_CHNL_IF_GEN;
      
      
-------------------------------------------------------------------------------
-- Instantiate PLB Slave Burst if the parameter C_INCLUDE_PLB_IPIF = 1 
-- and C_NUM_CHANNELS > 0
-------------------------------------------------------------------------------
INCLUDE_PLB_IPIF_GEN: if (C_NUM_CHANNELS > 0 and C_INCLUDE_PLB_IPIF = 1) generate
begin

    Bus2IP_Clk    <= bus2ip_clk_i;
    Bus2IP_Reset  <= bus2ip_reset_i;  


    PLBV46_SLAVE_BURST_I : entity plbv46_slave_burst_v1_01_a.plbv46_slave_burst
    generic map
      (
        C_ARD_ADDR_RANGE_ARRAY    =>  C_PLB_ARD_ADDR_RANGE_ARRAY,
        C_ARD_NUM_CE_ARRAY        =>  C_PLB_ARD_NUM_CE_ARRAY,
        C_SPLB_P2P                =>  C_SPLB_P2P,
        C_CACHLINE_ADDR_MODE      =>  C_CACHLINE_ADDR_MODE,      
        C_WR_BUFFER_DEPTH         =>  C_WR_BUFFER_DEPTH,
        C_SPLB_MID_WIDTH          =>  C_SPLB_MID_WIDTH,      
        C_SPLB_NUM_MASTERS        =>  C_SPLB_NUM_MASTERS,
        C_SPLB_AWIDTH             =>  C_MCH_SPLB_AWIDTH,
        C_SPLB_DWIDTH             =>  C_SPLB_DWIDTH,
        C_SIPIF_DWIDTH            =>  C_MCH_SIPIF_DWIDTH,
        C_SPLB_SMALLEST_MASTER    =>  C_SPLB_SMALLEST_MASTER,
        C_BURSTLENGTH_TYPE        =>  1,   
        C_INCLUDE_DPHASE_TIMER    =>  INCLUDE_DPHASE_TIMER,
        C_FAMILY                  =>  C_FAMILY      
    )
    port map
      (
        -- System signals 
        SPLB_Clk            =>  SPLB_Clk,
        SPLB_Rst            =>  SPLB_Rst,
                                   
        -- Bus Slave signals        
        PLB_ABus            =>  PLB_ABus,                          
        PLB_UABus           =>  PLB_UABus,
        PLB_PAValid         =>  PLB_PAValid,
        PLB_SAValid         =>  PLB_SAValid,
        PLB_rdPrim          =>  PLB_rdPrim,
        PLB_wrPrim          =>  PLB_wrPrim,
        PLB_masterID        =>  PLB_masterID,                             
        PLB_abort           =>  PLB_abort,
        PLB_busLock         =>  PLB_busLock,
        PLB_RNW             =>  PLB_RNW,
        PLB_BE              =>  PLB_BE,                             
        PLB_MSize           =>  PLB_MSize,             
        PLB_size            =>  PLB_size,             
        PLB_type            =>  PLB_type,             
                               
        PLB_lockErr         =>  PLB_lockErr,
        PLB_wrDBus          =>  PLB_wrDBus,                          
        PLB_wrBurst         =>  PLB_wrBurst,
        PLB_rdBurst         =>  PLB_rdBurst,
        PLB_wrPendReq       =>  PLB_wrPendReq,
        PLB_rdPendReq       =>  PLB_rdPendReq,
        PLB_wrPendPri       =>  PLB_wrPendPri,
        PLB_rdPendPri       =>  PLB_rdPendPri, 
        PLB_reqPri          =>  PLB_reqPri,             
        PLB_TAttribute      =>  PLB_TAttribute,
                                   
        -- Slave Responce Signals  
        Sl_addrAck          =>  Sl_addrAck,
        Sl_SSize            =>  Sl_SSize,             
        Sl_wait             =>  Sl_wait,
        Sl_rearbitrate      =>  Sl_rearbitrate,
        Sl_wrDAck           =>  Sl_wrDAck,
        Sl_wrComp           =>  Sl_wrComp,
        Sl_wrBTerm          =>  Sl_wrBTerm,
        Sl_rdDBus           =>  Sl_rdDBus,                          
        Sl_rdWdAddr         =>  Sl_rdWdAddr,             
        Sl_rdDAck           =>  Sl_rdDAck,
        Sl_rdComp           =>  Sl_rdComp,
        Sl_rdBTerm          =>  Sl_rdBTerm,
        Sl_MBusy            =>  Sl_MBusy,                               
                               
        Sl_MWrErr           =>  Sl_MWrErr,               
        Sl_MRdErr           =>  Sl_MRdErr,
        Sl_MIRQ             =>  Sl_MIRQ,
    
        -- IP Interconnect (IPIC) port signals
        --System Signals
        Bus2IP_Clk          =>  bus2ip_clk_i,        
        Bus2IP_Reset        =>  bus2ip_reset_i,        
                               
        -- IP Slave signals    
        IP2Bus_Data         =>  ip2plb_data,                                
        IP2Bus_WrAck        =>  ip2plb_wrack,                                
        IP2Bus_RdAck        =>  ip2plb_rdack,        
        IP2Bus_Error        =>  ip2plb_error,
        IP2Bus_AddrAck      =>  ip2plb_addrack,
                               
        Bus2IP_Addr         =>  plb2ip_addr,                               
        Bus2IP_Data         =>  plb2ip_data,                                
        Bus2IP_RNW          =>  plb2ip_rnw,             
        Bus2IP_BE           =>  plb2ip_be,        
        Bus2IP_Burst        =>  plb2ip_burst, 
        Bus2IP_BurstLength  =>  plb2ip_burstlength,
        Bus2IP_WrReq        =>  plb2ip_wrreq,        
        Bus2IP_RdReq        =>  plb2ip_rdreq, 
        Bus2IP_CS           =>  plb2ip_cs,        
        Bus2IP_RdCE         =>  plb2ip_rdce,                                                                 
        Bus2IP_WrCE         =>  plb2ip_wrce                                                          
    );


end generate INCLUDE_PLB_IPIF_GEN;

-------------------------------------------------------------------------------
-- NO_PLB_IPIF_GEN : When plb interface is not included, reset all the signals 
-- going to the arb_mux_demux block
-------------------------------------------------------------------------------
NO_PLB_IPIF_GEN: if C_INCLUDE_PLB_IPIF = 0 generate
begin
    -- zero all signals that would go to the arb_mux_demux block
    plb2ip_addr         <= (others => '0');
    plb2ip_rdreq        <= '0';
    plb2ip_wrreq        <= '0';
    plb2ip_data         <= (others => '0');
    plb2ip_rnw          <= '0';
    plb2ip_cs           <= (others => '0');
    plb2ip_rdce         <= (others => '0');
    plb2ip_wrce         <= (others => '0');
    plb2ip_be           <= (others => '0');
    plb2ip_burst        <= '0';
    plb2ip_burstlength  <= (others => '0');
    Sl_addrAck          <= '0'; 
    Sl_SSize            <= (others => '0');
    Sl_wait             <= '0';
    Sl_rearbitrate      <= '0';
    Sl_wrDAck           <= '0';
    Sl_wrComp           <= '0';
    Sl_wrBTerm          <= '0';
    Sl_rdDBus           <= (others => '0');
    Sl_rdWdAddr         <= (others => '0');
    Sl_rdDAck           <= '0';
    Sl_rdComp           <= '0';
    Sl_rdBTerm          <= '0';
    Sl_MBusy            <= (others => '0');
    Sl_MWrErr           <= (others => '0');
    Sl_MRdErr           <= (others => '0');
    Sl_MIRQ             <= (others => '0');
    Bus2IP_Clk          <= SPLB_Clk;
    Bus2IP_Reset        <= SPLB_Rst;  
end generate NO_PLB_IPIF_GEN;    

-------------------------------------------------------------------------------
-- Instantiate Arbiter and Channel Logic  if the parameter C_NUM_CHANNELS > 0 
-- Arbiter and Channle logic are only included if C_NUM_CHANNELS > 0
-------------------------------------------------------------------------------
INCLUDE_MCH_ARBITER_GEN: if C_NUM_CHANNELS > 0 generate

-- Channel IPIC signals
signal ip2chnl_ack        : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal ip2chnl_addrack    : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal ip2chnl_data       : std_logic_vector(0 to 
                              C_NUM_CHANNELS*C_MCH_SIPIF_DWIDTH - 1);
signal ip2chnl_error      : std_logic_vector(0 to C_NUM_CHANNELS-1);

signal chnl2ip_addr       : std_logic_vector(0 to 
                              C_NUM_CHANNELS*C_MCH_SPLB_AWIDTH - 1);
signal chnl2ip_addrvalid  : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal chnl2ip_data       : std_logic_vector(0 to 
                              C_NUM_CHANNELS*C_MCH_SIPIF_DWIDTH - 1);
signal chnl2ip_rnw        : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal chnl2ip_cs         : std_logic_vector(0 to C_NUM_CHANNELS*NUM_MCH_CS-1);
signal chnl2ip_ce         : std_logic_vector(0 to C_NUM_CHANNELS*NUM_MCH_CS-1);
signal chnl2ip_rdce       : std_logic_vector(0 to C_NUM_CHANNELS*NUM_MCH_CS-1);
signal chnl2ip_wrce       : std_logic_vector(0 to C_NUM_CHANNELS*NUM_MCH_CS-1);
signal chnl2ip_be         : std_logic_vector(0 to 
                              C_NUM_CHANNELS*(C_MCH_SIPIF_DWIDTH / 8) - 1);
signal chnl2ip_burst      : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal chnl2ip_rdreq      : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal chnl2ip_wrreq      : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal plb_xfer_end       : std_logic;
signal chnl2ip_burstlength    : std_logic_vector(0 to 
                                  C_NUM_CHANNELS*BRSTCNT_WIDTH-1);
-- arbitration signals
signal chnl_req               : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal chnl_addr_almost_done  : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal chnl_data_almost_done  : std_logic_vector(0 to C_NUM_CHANNELS-1);
signal addr_master            : std_logic_vector(0 to 
                                  C_NUM_CHANNELS+C_INCLUDE_PLB_IPIF-1);
signal data_master            : std_logic_vector(0 to 
                                  C_NUM_CHANNELS+C_INCLUDE_PLB_IPIF-1);
--DXCL2 signals
signal dxcl2_byte_trfr	   :  std_logic_vector(0 to C_NUM_CHANNELS-1);
                                  
begin
    -----------------------------------------------------------------------------
    -- Arbitration and Mux/De-Mux Logic
    -----------------------------------------------------------------------------
    ARB_MUX_DEMUX_I: entity mch_plbv46_slave_burst_v2_01_a.arb_mux_demux
    generic map 
      (       
        C_MCH_SPLB_DWIDTH       =>  C_MCH_SIPIF_DWIDTH,            
        C_MCH_SPLB_AWIDTH       =>  C_MCH_SPLB_AWIDTH,            
        C_PRIORITY_MODE         =>  C_PRIORITY_MODE,             
        C_NUM_CHANNELS          =>  C_NUM_CHANNELS, 
        C_MCH_PROTOCOL          =>  C_MCH_PROTOCOL_ARRAY(0),
        C_NUM_MCH_CS            =>  NUM_MCH_CS,
        C_NUM_PLB_CS            =>  NUM_PLB_CS,
        C_NUM_PLB_CE            =>  NUM_PLB_CE,
        C_INCLUDE_PLB_IPIF      =>  C_INCLUDE_PLB_IPIF,
        C_BRSTCNT_WIDTH         =>  BRSTCNT_WIDTH,
        C_XCL0_WRITEXFER        =>  C_XCL_WRITEXFER_ARRAY(0),
        C_FAMILY                =>  C_FAMILY
      )                          
    port map                   
      (                          
        -- System Signals
        Sys_Clk                 =>  SPLB_Clk,
        Sys_Rst                 =>  SPLB_Rst,
        
        -- arbitration signals        
        Chnl_Req                =>  chnl_req,
        Chnl_Data_Almost_Done   =>  chnl_data_almost_done,
        Chnl_Addr_Almost_Done   =>  chnl_addr_almost_done,
        Chnl2IP_CS              =>  chnl2ip_cs,
        PLB2IP_CS               =>  plb2ip_cs,
        Addr_master             =>  addr_master,
        Data_master             =>  data_master,
        PLB_xfer_end            => plb_xfer_end,
 
        -- address mux input signals
        PLB2IP_Addr             =>  plb2ip_addr,      
        PLB2IP_RdReq            =>  plb2ip_rdreq,
        PLB2IP_WrReq            =>  plb2ip_wrreq,
                                   
        Chnl2IP_Addr            =>  chnl2ip_addr,     
        Chnl2IP_RdReq           =>  chnl2ip_rdreq,
        Chnl2IP_WrReq           =>  chnl2ip_wrreq,
                                                                                                        
        -- address mux output signals
        Bus2IP_Addr             =>  Bus2IP_Addr,     
        Bus2IP_RdReq            =>  Bus2IP_RdReq,
        Bus2IP_WrReq            =>  Bus2IP_WrReq,
        
        -- address de-mux input signals
        IP2Bus_AddrAck          =>  IP2Bus_AddrAck,
                                                             
        -- address de-mux input signals
        IP2PLB_AddrAck          =>  ip2plb_addrack,   
        IP2Chnl_AddrAck         =>  ip2chnl_addrack,  
  
        -- data mux input signals 
        PLB2IP_Data             =>  plb2ip_data,  
        PLB2IP_BE               =>  plb2ip_be,        
        PLB2IP_RNW              =>  plb2ip_rnw,   
        PLB2IP_RdCE             =>  plb2ip_rdce,  
        PLB2IP_WrCE             =>  plb2ip_wrce,  
        PLB2IP_Burst            =>  plb2ip_burst, 
        PLB2IP_BurstLength      =>  plb2ip_burstlength((log2(16*
                                     (C_SPLB_DWIDTH/8))-BRSTCNT_WIDTH)+1 to 
                                      log2(16 * (C_SPLB_DWIDTH/8))),
                                                   
        Chnl2IP_Data            =>  chnl2ip_data, 
        Chnl2IP_BE              =>  chnl2ip_be,
        Chnl2IP_RNW             =>  chnl2ip_rnw,  
        Chnl2IP_RdCE            =>  chnl2ip_rdce, 
        Chnl2IP_WrCE            =>  chnl2ip_wrce,       
        Chnl2IP_Burst           =>  chnl2ip_burst,
        Chnl2IP_BurstLength     =>  chnl2ip_burstlength,
      
        -- data mux output signals 
        Bus2IP_CS               =>  Bus2IP_CS,
        Bus2IP_Data             =>  Bus2IP_Data, 
        Bus2IP_BE               =>  Bus2IP_BE,       
        Bus2IP_RNW              =>  Bus2IP_RNW,  
        Bus2IP_RdCE             =>  Bus2IP_RdCE, 
        Bus2IP_WrCE             =>  Bus2IP_WrCE, 
        Bus2IP_Burst            =>  Bus2IP_Burst,
        Bus2IP_BurstLength      =>  Bus2IP_BurstLength((log2(16*
                                    (C_SPLB_DWIDTH/8))-BRSTCNT_WIDTH)+1 to 
                                     log2(16 * (C_SPLB_DWIDTH/8))),
        Bus2IP_AddrBurstLength  =>  Bus2IP_AddrBurstLength((log2(16*
                                    (C_SPLB_DWIDTH/8))-BRSTCNT_WIDTH)+1 to 
                                     log2(16 * (C_SPLB_DWIDTH/8))),
        Bus2IP_AddrBurstCntLoad =>  Bus2IP_AddrBurstCntLoad,

        Dxcl2_byte_trfr	        =>  dxcl2_byte_trfr(0),
        -- data de-mux input signals
        IP2Bus_Data             =>  IP2Bus_Data,   
        IP2Bus_WrAck            =>  IP2Bus_WrAck,    
        IP2Bus_RdAck            =>  IP2Bus_RdAck,    
        IP2Bus_Error            =>  IP2Bus_Error,  
      
        -- data de-mux output signals
        IP2PLB_Data             =>  ip2plb_data,   
        IP2PLB_WrAck            =>  ip2plb_wrack,    
        IP2PLB_RdAck            =>  ip2plb_rdack,    
        IP2PLB_Error            =>  ip2plb_error,  
                                          
        IP2Chnl_Data            =>  IP2Chnl_Data,  
        IP2Chnl_Ack             =>  IP2Chnl_Ack,   
        IP2Chnl_Error           =>  IP2Chnl_Error 
    );    
    
    -----------------------------------------------------------------------------
    -- MCH Interface
    -----------------------------------------------------------------------------
    MCH_LOGIC: for i in 0 to C_NUM_CHANNELS-1 generate
        
        CH_I: entity mch_plbv46_slave_burst_v2_01_a.mch_interface
        generic map 
          (
            C_MCH_SPLB_DWIDTH             =>  C_MCH_SIPIF_DWIDTH,
            C_MCH_SPLB_AWIDTH             =>  C_MCH_SPLB_AWIDTH,
            C_MCH_PROTOCOL                =>  C_MCH_PROTOCOL_ARRAY(i),                                                                                                    
            C_MCH_USERIP_ADDRRANGE_ARRAY  =>  C_MCH_USERIP_ADDRRANGE_ARRAY,                                                                                            
            C_MCH_ACCESSBUF_DEPTH         =>  C_MCH_ACCESSBUF_DEPTH_ARRAY(i),                                                                                            
            C_MCH_RDDATABUF_DEPTH         =>  C_MCH_RDDATABUF_DEPTH_ARRAY(i),                                                                                            
            C_XCL_LINESIZE                =>  C_XCL_LINESIZE_ARRAY(i),                                                                                                    
            C_XCL_WRITEXFER               =>  C_XCL_WRITEXFER_ARRAY(i),
            C_BRSTCNT_WIDTH               =>  BRSTCNT_WIDTH,
            C_FAMILY                      =>  C_FAMILY
          )        
        port map 
          (
            -- Ststem Signals
            Sys_Clk                =>  SPLB_Clk,
            Sys_Rst                =>  SPLB_Rst,
    
            -- MCH Access Interface Signals
            MCH_Access_Control     =>  MCH_Access_Control(i),  
            MCH_Access_Data        =>  MCH_Access_Data(i*C_MCH_SIPIF_DWIDTH  
                                         to (i+1)*C_MCH_SIPIF_DWIDTH-1),     
            MCH_Access_Write       =>  MCH_Access_Write(i),    
            MCH_Access_Full        =>  MCH_Access_Full(i),     
            
            -- MCH ReadData Interface Signals
            MCH_ReadData_Control   =>  MCH_ReadData_Control(i),
            MCH_ReadData_Data      =>  MCH_ReadData_Data(i*C_MCH_SIPIF_DWIDTH 
                                         to (i+1)*C_MCH_SIPIF_DWIDTH-1),   
            MCH_ReadData_Read      =>  MCH_ReadData_Read(i),   
            MCH_ReadData_Exists    =>  MCH_ReadData_Exists(i), 
                                      
            -- IPIC Signals           
            Chnl2IP_Addr           =>  chnl2ip_addr(i*C_MCH_SPLB_AWIDTH to
                                         (i+1)*C_MCH_SPLB_AWIDTH-1),     
            Chnl2IP_Addrvalid      =>  chnl2ip_addrvalid(i),
            Chnl2IP_BE             =>  chnl2ip_be(i*C_MCH_SIPIF_DWIDTH/8 to
                                         (i+1)*C_MCH_SIPIF_DWIDTH/8-1),       
            Chnl2IP_Data           =>  chnl2ip_data(i*C_MCH_SIPIF_DWIDTH to
                                         (i+1)*C_MCH_SIPIF_DWIDTH-1),     
            Chnl2IP_RNW            =>  chnl2ip_rnw(i), 
            Chnl2IP_CS             =>  chnl2ip_cs(i*NUM_MCH_CS to 
                                         (i+1)*NUM_MCH_CS-1),  
            Chnl2IP_Burst          =>  chnl2ip_burst(i),  
            Chnl2IP_BurstLength    =>  chnl2ip_burstlength(i*BRSTCNT_WIDTH to
                                         (i+1)*BRSTCNT_WIDTH-1),
            Chnl2IP_RdReq          =>  chnl2ip_rdreq(i),    
            Chnl2IP_WrReq          =>  chnl2ip_wrreq(i),             
            Chnl2IP_CE             =>  open,       
            Chnl2IP_Rdce           =>  chnl2ip_rdce(i*NUM_MCH_CS to 
                                         (i+1)*NUM_MCH_CS-1),
            Chnl2IP_Wrce           =>  chnl2ip_wrce(i*NUM_MCH_CS to 
                                         (i+1)*NUM_MCH_CS-1),
            IP2Chnl_Data           =>  ip2chnl_data(i*C_MCH_SIPIF_DWIDTH to
                                         (i+1)*C_MCH_SIPIF_DWIDTH-1),
            IP2Chnl_AddrAck        =>  ip2chnl_addrack(i),
            IP2Chnl_Ack            =>  ip2chnl_ack(i),
            Dxcl2_byte_trfr	   =>  dxcl2_byte_trfr(i),	
            
            -- Signals to Arb Mux/De-Mux Logic
            Chnl_Req               =>  chnl_req(i),
            Chnl_Addr_Almost_Done  =>  chnl_addr_almost_done(i),
            Chnl_Data_Almost_Done  =>  chnl_data_almost_done(i),
            Addr_Master            =>  addr_master(i),
            Data_Master            =>  data_master(i)
            -- Signal from Timeout/Error Logic                       
        );
    end generate MCH_LOGIC;
  
end generate INCLUDE_MCH_ARBITER_GEN;

end imp;
