-------------------------------------------------------------------------------
-- xps_mch_emc.vhd - entity/architecture pair
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
-- Filename:    xps_mch_emc.vhd
-- Version:     v3.01a
-- Description: Top level file for Multi-CHannel & PLB External memory
--              controller XPS_MCH_EMC
--
-- VHDL-Standard: VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  -- xps_mch_emc.vhd
--                      -- mch_plbv46_slave_burst.vhd
--                      -- emc.vhd
--
-------------------------------------------------------------------------------
-- Author:          NSK
-- History:
-- NSK             02/01/08    First Version
-- ^^^^^^^^^^
-- This file is based on version v1_00_a updated to fixed CR #466745: -
--     Added generic C_MEM_DQ_CAPTURE_NEGEDGE. The same generic is mapped to 
--     component emc from emc_common_v2_02_a.
-- ~~~~~~~~~
-- NSK             03/07/08    Updated
-- ^^^^^^^^^^
-- 1. Removed the generic C_MEM_DQ_CAPTURE_NEGEDGE.
-- 2. Added port RdClk - used to read the data from memory.
-- 3. Added port RdClk in the instantiation of emc_common.
-- ~~~~~~~~~
-- NSK         05/08/08    version v2_00_a
-- ^^^^^^^^
-- 1. This file is same as in version v1_01_a.
-- 2. Upgraded to version v2.00.a to have proper versioning to fix CR #472164.
-- 3. No change in design.
-- ~~~~~~~~
-- KSB         05/20/08    version v3_00_a
-- ^^^^^^^^                                                                    
-- 1. This file is based on version v2_00_a updated for new features
--    implementation
--      64 Bit interface
--      Page mode flash support
-- 2. Upgraded to version v3.00.a to have new features upgrade
-- 3. Port names MCH_PLB_Rst & MCH_PLB_Clk names has been changed to
--    MCH_SPLB_Rst & MCH_SPLB_Clk to support MPD generation using psfutil
-- 4. Helper library emc_common is changed from version emc_common_v3_00_a to
--    emc_common_v4_00_a
-- 5. Helper library proc_common is changed from version proc_common_v2_00_a to
--    proc_common_v3_00_a
-- 6. Helper library mch_plbv46_slave_burst is changed from version 
--    mch_plbv46_slave_burst_v1_00_a to mch_plbv46_slave_burst_v2_00_a
-- ~~~~~~~~
-- KSB         06/29/09    version v3_01_a
-- ^^^^^^^^                                                                    
-- 1. Fix for CR#523388, updated the channel_logic
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
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- vcomponents package of the unisim library is used for different component 
-- declarations
-------------------------------------------------------------------------------
library unisim;
use unisim.all;

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for different 
-- function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.family.all;
use proc_common_v3_00_a.all;

use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.calc_num_ce;
use proc_common_v3_00_a.ipif_pkg.XCL;
use proc_common_v3_00_a.ipif_pkg.all;

-------------------------------------------------------------------------------
-- mch_opb_ipif_v1_00_c library is used for mch_opb_ipif component declarations
-------------------------------------------------------------------------------
library mch_plbv46_slave_burst_v2_01_a;
use mch_plbv46_slave_burst_v2_01_a.mch_plbv46_slave_burst;

-------------------------------------------------------------------------------
-- emc_common_v4_01_a library is used for emc_common component declarations
-------------------------------------------------------------------------------
library emc_common_v4_01_a;
use emc_common_v4_01_a.emc;

-------------------------------------------------------------------------------
-- Definition of Generics:
-- -- General Generics
--    C_FAMILY                   -- target FPGA family
--    C_NUM_BANKS_MEM            -- number of memory banks (1-4)
--    C_NUM_CHANNELS             -- number of MCH interfaces (0-4)
--    C_PRIORITY_MODE            -- arbitration priority mode (ONLY=0)
--    C_INCLUDE_PLB_IPIF         -- include PLB slave burst interface
--    C_INCLUDE_WRBUF            -- includes write buffer in PLB slave
--                               -- burst interface
--
--    C_SPLB_MID_WIDTH           -- PLB Master ID Bus width
--    C_SPLB_NUM_MASTERS         -- Number of PLB Masters
--    C_SPLB_P2P                 -- selects point-to-point bus topology
--
--    C_SPLB_DWIDTH              -- data width of PLB interfaces
--    C_MCH_SPLB_AWIDTH          -- address width of MCH and PLB interfaces
--    C_MCH_NATIVE_DWIDTH        -- data width of slave interfaces
--    C_SPLB_SMALLEST_MASTER     -- data width of the smallest master
--    C_MCH_SPLB_CLK_PERIOD_PS   -- clock period of MCH_PLB clock in 
--                                  pico-seconds
--    C_MEM(0:3)_BASEADDR        -- memory bank (0:3) base address
--    C_MEM(0:3)_HIGHADDR        -- memory bank (0:3) high address
--
--    EMC Generics
--    C_PAGEMODE_FLASH_(0:3)     -- Whether using a PAGEMODE Flash device 
--    C_INCLUDE_NEGEDGE_IOREGS   -- Include negative edge IO registers
--    C_MEM(0:3)_WIDTH           -- Memory bank (0:3) data width
--    C_MAX_MEM_WIDTH            -- Maximum data width of all memory banks
--    C_INCLUDE_DATAWIDTH_MATCHING_(0:3)  -- Support data width matching for
--                                           memory bank (0:3)
--    C_SYNCH_MEM_(0:3)          -- Memory bank (0:3) type
--    C_SYNCH_PIPEDELAY_(0:3)    -- Memory bank (0:3) synchronous pipe delay
--    C_TCEDV_PS_MEM_(0:3)       -- Chip Enable to Data Valid Time
--                                  (Maximum of TCEDV and TAVDV applied
--                                   as read cycle start to first data valid)
--    C_TAVDV_PS_MEM_(0:3)       -- Address Valid to Data Valid Time
--                               -- (Maximum of TCEDV and TAVDV applied
--                                    as read cycle start to first data valid)
--    C_TPACC_PS_FLASH_(0:3)     -- Address Valid to Data Valid Time for a
--                               -- PAGE Read transaction
--    C_THZCE_PS_MEM_(0:3)       -- Chip Enable High to Data Bus High 
--                               -- Impedance(Maximum of THZCE and THZOE 
--                                  applied as  Read Recovery before Write)
--    C_THZOE_PS_MEM_(0:3)       -- Output Enable High to Data Bus High
--                                  Impedance(Maximum of THZCE and THZOE
--                                  applied as Read Recovery before Write)
--    C_TWC_PS_MEM_(0:3)         -- Write Cycle Time
--                                  (Maximum of TWC and TWP applied as write
--                                   enable pulse width)
--    C_TWP_PS_MEM_(0:3)         -- Write Enable Minimum Pulse Width
--                                  (Maximum of TWC and TWP applied as write
--                                   enable pulse width)
--    C_TLZWE_PS_MEM_(0:3)       -- Write Enable High to Data Bus Low Impedance
--                                  (Applied as Write Recovery before Read)
--    MCH Generics
--
--    C_MCHx_PROTOCOL            -- protocol of each MCH interface
--    C_MCHx_ACCESSBUF_DEPTH     -- depth of the Access buffer for each channel
--    C_MCHx_RDDATABUF_DEPTH     -- depth of the ReadData buffer for each 
--                                  channel
--
--    XCL Channel Generics
--
--    C_XCLx_LINESIZE            -- cacheline size for each channel
--    C_XCLx_WRITEXFER           -- type of write tranfers requested by channel
--
-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
-- Definition of Ports:
--
--  Clocks and reset signals
--      MCH_SPLB_Clk         -- MCH / PLB clock
--      RdClk                -- Read clock to capture the data from memory
--      MCH_SPLB_Rst         -- MCH / PLB reset
--
--  -- MCH interface
--      MCHx_Access_Control  -- control bit indicating R/W transfer
--      MCHx_Access_Data     -- address/data for the transfer
--      MCHx_Access_Write    -- write control signal to the Access buffer
--      MCHx_Access_Full     -- full indicator from the Access buffer
--
--      MCHx_ReadData_Control-- control bit indicating if data is valid
--      MCHx_ReadData_Data   -- data returned from a read transfer
--      MCHx_ReadData_Read   -- read control signal to the ReadData buffer
--      MCHx_ReadData_Exists -- non-empty indicator from the ReadData buffer
--
--  PLB v46 Bus interface
--      PLB_ABus             -- PLB 32-bit address bus
--      PLB_UABus            -- slave upper address bits.
--      PLB_PAValid          -- indicates that there is a valid primary
--                              address and transfer qualifiers on the
--                              PLB Bus
--      PLB_SAValid          -- PLB secondary address valid 
--      PLB_rdPrim           -- PLB secondary to primary read req indicator
--      PLB_wrPrim           -- PLB secondary to primary write req indicator
--      PLB_masterID         -- identification of the master of the current
--                              transfer
--      PLB_abort            -- PLB abort bus request indicator
--      PLB_busLock          -- PLB bus lock
--      PLB_RNW              -- indicate read or a write transfer
--      PLB_BE               -- For a non-line and non-burst transfer identify
--                              which bytes of the target being addressed
--      PLB_MSize            -- PLB data bus port width indicator
--      PLB_size             -- Indicate the size of the requested transfer.
--      PLB_type             -- Indicate the type of transfer being requested
--      PLB_lockErr          -- PLB lock indicator
--      PLB_wrDBus           -- Write data bus
--      PLB_wrBurst          -- PLB burst write transfer indicator
--      PLB_rdBurst          -- PLB burst read transfer indicator
--      PLB_wrPendReq        -- PLB pending burst write request indicator
--      PLB_rdPendReq        -- PLB pending burst read request indicator
--      PLB_wrPendPri        -- PLB pending write request priority
--      PLB_rdPendPri        -- PLB pending read request priority
--      PLB_reqPri           -- PLB current request priority
--      PLB_TAttribute       -- PLB transfer attribute
--
--      Sl_addrAck           -- Indicates slave has acknowledged the address
--                           -- and will latch the address
--      Sl_SSize             -- Slave data bus size
--      Sl_wait              -- Slave wait indication
--      Sl_rearbitrate       -- Indicate that the slave is unable to perform 
--                              the currently requested transfer and require 
--                              the PLB arbiter to re-arbitrate the bus
--      Sl_wrDAck            -- Indicates data on write dbus is accepted
--      Sl_wrComp            -- Indicate the end of the current write transfer.
--      Sl_wrBTerm           -- Slave terminate write burst transfer
--      Sl_rdDBus            -- Slave read data bus
--      Sl_rdWdAddr          -- Slave read word address
--      Sl_rdDAck            -- indicate that the data on the Sl_rdDBus bus 
--                              is valid
--      Sl_rdComp            -- indicate to the PLB arbiter that the read
--                              is complete
--      Sl_rdBTerm           -- Slave terminate read burst transfer
--      Sl_MBusy             -- indicate that the slave is busy
--      Sl_MWrErr            -- indicate that the slave has encountered
--                              an error during a write transfer
--      Sl_MRdErr            -- indicate that the slave has encountered an
--                              error during a read transfer
--      Sl_MIRQ              -- Master interrupt request(one per master at 
--                              each slave)Gives a slave the ability to  
--                              indicate that it has encountered an event 
--                              it deems important to master
-- -- Memory Signals
--      Mem_DQ_I             -- Memory Input Data Bus
--      Mem_DQ_O             -- Memory Output Data Bus
--      Mem_DQ_T             -- Memory Data Output Enable
--      Mem_A                -- Memory address inputs
--      Mem_RPN              -- Memory Reset/Power Down
--      Mem_CEN              -- Memory Chip Select
--      Mem_OEN              -- Memory Output Enable
--      Mem_WEN              -- Memory Write Enable
--      Mem_QWEN             -- Memory Qualified Write Enable
--      Mem_BEN              -- Memory Byte Enables
--      Mem_CE               -- Memory chip enable
--      Mem_ADV_LDN          -- Memory counter advance/load (=0)
--      Mem_LBON             -- Memory linear/interleaved burst order(=0)
--      Mem_CKEN             -- Memory clock enable (=0)
--      Mem_RNW              -- Memory read not write
--
-----------------------------------------------------------------------------

 ------------------------------------------------------------------------------
 -- Start of PSFUtil MPD attributes
 ------------------------------------------------------------------------------ 
-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------
entity xps_mch_emc is
   -- Generics to be set by user
   generic (
    -- General Generics
        C_FAMILY                       : string    := "virtex5";
        C_NUM_BANKS_MEM                : integer range 1 to 4   := 1;
        C_NUM_CHANNELS                 : integer range 0 to 4   := 2;
        C_PRIORITY_MODE                : integer range 0 to 0   := 0;
        C_INCLUDE_PLB_IPIF             : integer range 0 to 1   := 1;
        C_INCLUDE_WRBUF                : integer range 0 to 1   := 1;

        C_SPLB_MID_WIDTH               : integer range 1 to 4   := 1;
        C_SPLB_NUM_MASTERS             : integer range 1 to 16  := 1;
        C_SPLB_P2P                     : integer range 0 to 1   := 0;

        C_SPLB_DWIDTH                  : integer range 32 to 128 := 32;
        C_MCH_SPLB_AWIDTH              : integer range 32 to 32  := 32;
        C_SPLB_SMALLEST_MASTER         : integer range 32 to 128 := 32;
        C_MCH_NATIVE_DWIDTH            : integer range 32 to 64  := 32;
        C_MCH_SPLB_CLK_PERIOD_PS       : integer   := 10000;

        C_MEM0_BASEADDR                : std_logic_vector := x"FFFFFFFF";
        C_MEM0_HIGHADDR                : std_logic_vector := x"00000000";
        C_MEM1_BASEADDR                : std_logic_vector := x"FFFFFFFF";
        C_MEM1_HIGHADDR                : std_logic_vector := x"00000000";
        C_MEM2_BASEADDR                : std_logic_vector := x"FFFFFFFF";
        C_MEM2_HIGHADDR                : std_logic_vector := x"00000000";
        C_MEM3_BASEADDR                : std_logic_vector := x"FFFFFFFF";
        C_MEM3_HIGHADDR                : std_logic_vector := x"00000000";
  
        -- EMC generics
        C_PAGEMODE_FLASH_0             : integer range 0 to 1   := 0;
        C_PAGEMODE_FLASH_1             : integer range 0 to 1   := 0;
        C_PAGEMODE_FLASH_2             : integer range 0 to 1   := 0;
        C_PAGEMODE_FLASH_3             : integer range 0 to 1   := 0;
        C_INCLUDE_NEGEDGE_IOREGS       : integer range 0 to 1   := 0;

        C_MEM0_WIDTH                   : integer range 8 to 64  := 32;
        C_MEM1_WIDTH                   : integer range 8 to 64  := 32;
        C_MEM2_WIDTH                   : integer range 8 to 64  := 32;
        C_MEM3_WIDTH                   : integer range 8 to 64  := 32;

        C_MAX_MEM_WIDTH                : integer range 8 to 64  := 32;
        
        C_INCLUDE_DATAWIDTH_MATCHING_0 : integer range 0 to 1   := 0;
        C_INCLUDE_DATAWIDTH_MATCHING_1 : integer range 0 to 1   := 0;
        C_INCLUDE_DATAWIDTH_MATCHING_2 : integer range 0 to 1   := 0;
        C_INCLUDE_DATAWIDTH_MATCHING_3 : integer range 0 to 1   := 0;

        -- Memory read and write access times for all memory banks

        C_SYNCH_MEM_0                  : integer range 0 to 1   := 0;
        C_SYNCH_PIPEDELAY_0            : integer range 1 to 2   := 2;
        C_TCEDV_PS_MEM_0               : integer := 15000;
        C_TAVDV_PS_MEM_0               : integer := 15000;
        C_TPACC_PS_FLASH_0             : integer := 25000;
        C_THZCE_PS_MEM_0               : integer := 7000;
        C_THZOE_PS_MEM_0               : integer := 7000;
        C_TWC_PS_MEM_0                 : integer := 15000;
        C_TWP_PS_MEM_0                 : integer := 12000;
        C_TLZWE_PS_MEM_0               : integer := 0;

        C_SYNCH_MEM_1                  : integer range 0 to 1   := 0;
        C_SYNCH_PIPEDELAY_1            : integer range 1 to 2   := 2;
        C_TCEDV_PS_MEM_1               : integer := 15000;
        C_TAVDV_PS_MEM_1               : integer := 15000;
        C_TPACC_PS_FLASH_1             : integer := 25000;        
        C_THZCE_PS_MEM_1               : integer := 7000;
        C_THZOE_PS_MEM_1               : integer := 7000;
        C_TWC_PS_MEM_1                 : integer := 15000;
        C_TWP_PS_MEM_1                 : integer := 12000;
        C_TLZWE_PS_MEM_1               : integer := 0;

        C_SYNCH_MEM_2                  : integer range 0 to 1   := 0;
        C_SYNCH_PIPEDELAY_2            : integer range 1 to 2   := 2;
        C_TCEDV_PS_MEM_2               : integer := 15000;
        C_TAVDV_PS_MEM_2               : integer := 15000;
        C_TPACC_PS_FLASH_2             : integer := 25000;
        C_THZCE_PS_MEM_2               : integer := 7000;
        C_THZOE_PS_MEM_2               : integer := 7000;
        C_TWC_PS_MEM_2                 : integer := 15000;
        C_TWP_PS_MEM_2                 : integer := 12000;
        C_TLZWE_PS_MEM_2               : integer := 0;

        C_SYNCH_MEM_3                  : integer range 0 to 1   := 0;
        C_SYNCH_PIPEDELAY_3            : integer range 1 to 2   := 2;
        C_TCEDV_PS_MEM_3               : integer := 15000;
        C_TAVDV_PS_MEM_3               : integer := 15000;
        C_TPACC_PS_FLASH_3             : integer := 25000;
        C_THZCE_PS_MEM_3               : integer := 7000;
        C_THZOE_PS_MEM_3               : integer := 7000;
        C_TWC_PS_MEM_3                 : integer := 15000;
        C_TWP_PS_MEM_3                 : integer := 12000;
        C_TLZWE_PS_MEM_3               : integer := 0;

        -- MCH Generics
        C_MCH0_PROTOCOL                : integer range 0 to 1   := 0;
        C_MCH0_ACCESSBUF_DEPTH         : integer range 4 to 16  := 16;
        C_MCH0_RDDATABUF_DEPTH         : integer range 0 to 16  := 16;

        C_MCH1_PROTOCOL                : integer range 0 to 1   := 0;
        C_MCH1_ACCESSBUF_DEPTH         : integer range 4 to 16  := 16;
        C_MCH1_RDDATABUF_DEPTH         : integer range 0 to 16  := 16;

        C_MCH2_PROTOCOL                : integer range 0 to 1   := 0;
        C_MCH2_ACCESSBUF_DEPTH         : integer range 4 to 16  := 16;
        C_MCH2_RDDATABUF_DEPTH         : integer range 0 to 16  := 16;

        C_MCH3_PROTOCOL                : integer range 0 to 1   := 0;
        C_MCH3_ACCESSBUF_DEPTH         : integer range 4 to 16  := 16;
        C_MCH3_RDDATABUF_DEPTH         : integer range 0 to 16  := 16;

        C_XCL0_LINESIZE                : integer range 1 to 16  := 4;
        C_XCL0_WRITEXFER               : integer range 0 to 2   := 1;

        C_XCL1_LINESIZE                : integer range 1 to 16  := 4;
        C_XCL1_WRITEXFER               : integer range 0 to 2   := 1;

        C_XCL2_LINESIZE                : integer range 1 to 16  := 4;
        C_XCL2_WRITEXFER               : integer range 0 to 2   := 1;

        C_XCL3_LINESIZE                : integer range 1 to 16  := 4;
        C_XCL3_WRITEXFER               : integer range 0 to 2   := 1
   
        );

   port (

       -- System interface
       MCH_SPLB_Clk          : in  std_logic;
       RdClk                 : in  std_logic;
       MCH_SPLB_Rst          : in  std_logic;

       -- MCH 0 Interface
       MCH0_Access_Control   : in  std_logic;
       MCH0_Access_Data      : in  std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH0_Access_Write     : in  std_logic;
       MCH0_Access_Full      : out std_logic;
       MCH0_ReadData_Control : out std_logic;
       MCH0_ReadData_Data    : out std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH0_ReadData_Read    : in  std_logic;
       MCH0_ReadData_Exists  : out std_logic;

       -- MCH 1 Interface
       MCH1_Access_Control   : in  std_logic;
       MCH1_Access_Data      : in  std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH1_Access_Write     : in  std_logic;
       MCH1_Access_Full      : out std_logic;
       MCH1_ReadData_Control : out std_logic;
       MCH1_ReadData_Data    : out std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH1_ReadData_Read    : in  std_logic;
       MCH1_ReadData_Exists  : out std_logic;

       -- MCH 2 Interface
       MCH2_Access_Control   : in  std_logic;
       MCH2_Access_Data      : in  std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH2_Access_Write     : in  std_logic;
       MCH2_Access_Full      : out std_logic;
       MCH2_ReadData_Control : out std_logic;
       MCH2_ReadData_Data    : out std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH2_ReadData_Read    : in  std_logic;
       MCH2_ReadData_Exists  : out std_logic;

       -- MCH 3 Interface
       MCH3_Access_Control   : in  std_logic;
       MCH3_Access_Data      : in  std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH3_Access_Write     : in  std_logic;
       MCH3_Access_Full      : out std_logic;
       MCH3_ReadData_Control : out std_logic;
       MCH3_ReadData_Data    : out std_logic_vector
                                       (0 to C_MCH_NATIVE_DWIDTH-1);
       MCH3_ReadData_Read    : in  std_logic;
       MCH3_ReadData_Exists  : out std_logic;

       ----- Bus Slave signals ------
       PLB_ABus              : in  std_logic_vector(0 to 31);
       PLB_UABus             : in  std_logic_vector(0 to 31);
       PLB_PAValid           : in  std_logic;
       PLB_SAValid           : in  std_logic;
       PLB_rdPrim            : in  std_logic;
       PLB_wrPrim            : in  std_logic;
       PLB_masterID          : in  std_logic_vector
                                       (0 to C_SPLB_MID_WIDTH-1);
       PLB_abort             : in  std_logic;
       PLB_busLock           : in  std_logic;
       PLB_RNW               : in  std_logic;
       PLB_BE                : in  std_logic_vector
                                       (0 to (C_SPLB_DWIDTH/8)-1);
       PLB_MSize             : in  std_logic_vector(0 to 1);
       PLB_size              : in  std_logic_vector(0 to 3);
       PLB_type              : in  std_logic_vector(0 to 2);
       PLB_lockErr           : in  std_logic;
       PLB_wrDBus            : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
       PLB_wrBurst           : in  std_logic;
       PLB_rdBurst           : in  std_logic;
       PLB_wrPendReq         : in  std_logic;
       PLB_rdPendReq         : in  std_logic;
       PLB_wrPendPri         : in  std_logic_vector(0 to 1);
       PLB_rdPendPri         : in  std_logic_vector(0 to 1);
       PLB_reqPri            : in  std_logic_vector(0 to 1);
       PLB_TAttribute        : in  std_logic_vector(0 to 15);

        -- Slave Responce Signals
       Sl_addrAck            : out std_logic;
       Sl_SSize              : out std_logic_vector(0 to 1);
       Sl_wait               : out std_logic;
       Sl_rearbitrate        : out std_logic;
       Sl_wrDAck             : out std_logic;
       Sl_wrComp             : out std_logic;
       Sl_wrBTerm            : out std_logic;
       Sl_rdDBus             : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
       Sl_rdWdAddr           : out std_logic_vector(0 to 3);
       Sl_rdDAck             : out std_logic;
       Sl_rdComp             : out std_logic;
       Sl_rdBTerm            : out std_logic;
       Sl_MBusy              : out std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);
       Sl_MWrErr             : out std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);
       Sl_MRdErr             : out std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);
       Sl_MIRQ               : out std_logic_vector
                                       (0 to C_SPLB_NUM_MASTERS-1);

       -- Memory signals
       Mem_DQ_I              : in  std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
       Mem_DQ_O              : out std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
       Mem_DQ_T              : out std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
       Mem_A                 : out std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);
       Mem_RPN               : out std_logic;
       Mem_CEN               : out std_logic_vector(0 to C_NUM_BANKS_MEM-1);
       Mem_OEN               : out std_logic_vector(0 to C_NUM_BANKS_MEM-1);
       Mem_WEN               : out std_logic;
       Mem_QWEN              : out std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
       Mem_BEN               : out std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
       Mem_CE                : out std_logic_vector(0 to C_NUM_BANKS_MEM-1);
       Mem_ADV_LDN           : out std_logic;
       Mem_LBON              : out std_logic;
       Mem_CKEN              : out std_logic;
       Mem_RNW               : out std_logic

     );

     -- Fan-out attributes for XST
     attribute MAX_FANOUT                             : string;
     attribute MAX_FANOUT of MCH_SPLB_Clk              : signal is "10000";
     attribute MAX_FANOUT of MCH_SPLB_Rst              : signal is "10000";

     -- Added attribute to FIX CR CR204317. The following attribute prevent
     -- the tools from optimizing the tristate control down to a single 
     -- registered signal and to pack input, output, and tri-state registers 
     -- into the IOB.

     attribute EQUIVALENT_REGISTER_REMOVAL            : string;
     attribute EQUIVALENT_REGISTER_REMOVAL of Mem_DQ_T: signal is "no";

     attribute IOB                                    : string;
     attribute IOB of Mem_DQ_T                        : signal is "true";
     attribute IOB of Mem_DQ_I                        : signal is "true";
     attribute IOB of Mem_DQ_O                        : signal is "true";

     -- SIGIS attribute for specifying clocks,interrrupts,resets for EDK
     attribute SIGIS                                  : string;    
     attribute SIGIS of MCH_SPLB_Clk                   : signal is "Clk" ;
     attribute SIGIS of MCH_SPLB_Rst                   : signal is "Rst" ;
     attribute SIGIS of RdClk                     : signal is "Clk" ;

     -- Minimum size attribute for EDK
     attribute MIN_SIZE                               : string;
     attribute MIN_SIZE of C_MEM0_BASEADDR            : constant is "0x08";
     attribute MIN_SIZE of C_MEM1_BASEADDR            : constant is "0x08";
     attribute MIN_SIZE of C_MEM2_BASEADDR            : constant is "0x08";
     attribute MIN_SIZE of C_MEM3_BASEADDR            : constant is "0x08";

    -- Assignment attribute for EDK
    attribute ASSIGNMENT                             : string;
    attribute ASSIGNMENT of C_MEM0_BASEADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MEM0_HIGHADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MEM1_BASEADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MEM1_HIGHADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MEM2_BASEADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MEM2_HIGHADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MEM3_BASEADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MEM3_HIGHADDR          : constant is "REQUIRE";
    attribute ASSIGNMENT of C_MCH_SPLB_AWIDTH        : constant is "CONSTANT";
     
    -- ADDR_TYPE attribute for EDK
    attribute ADDR_TYPE                              : string;
    attribute ADDR_TYPE of C_MEM0_BASEADDR           : constant is "MEMORY";
    attribute ADDR_TYPE of C_MEM0_HIGHADDR           : constant is "MEMORY";
    attribute ADDR_TYPE of C_MEM1_BASEADDR           : constant is "MEMORY";
    attribute ADDR_TYPE of C_MEM1_HIGHADDR           : constant is "MEMORY";
    attribute ADDR_TYPE of C_MEM2_BASEADDR           : constant is "MEMORY";
    attribute ADDR_TYPE of C_MEM2_HIGHADDR           : constant is "MEMORY";
    attribute ADDR_TYPE of C_MEM3_BASEADDR           : constant is "MEMORY";
    attribute ADDR_TYPE of C_MEM3_HIGHADDR           : constant is "MEMORY";

 ------------------------------------------------------------------------------
 -- end of PSFUtil MPD attributes
 ------------------------------------------------------------------------------ 
end xps_mch_emc;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture implementation of xps_mch_emc is

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

constant IPIF_AWIDTH    : integer := C_MCH_SPLB_AWIDTH;
constant IPIF_DWIDTH    : integer := C_MCH_NATIVE_DWIDTH;
-- addresses for plbv46_slave_burst are  64-bits wide - create constants to
-- zero the most significant address bits
constant ZERO_ADDR_PAD  : std_logic_vector(0 to 64-C_MCH_SPLB_AWIDTH-1)
                      := (others => '0');
-- only fixed priority is supported in this version of 
-- MCH PLBV46 SLAVE BURST
constant PRIORITY_MODE  : integer := 0;
---------------------------------------------------------------------------
-- MCH and XCL channel constants
---------------------------------------------------------------------------
-- set the max number of channels
constant MAX_NUM_CHANNELS : integer := 4;
-- create the MCH protocol array
constant MCH_PROTOCOL_ARRAY : INTEGER_ARRAY_TYPE :=
        (   0 => C_MCH0_PROTOCOL,
            1 => C_MCH1_PROTOCOL,
            2 => C_MCH2_PROTOCOL,
            3 => C_MCH3_PROTOCOL
         );
-- create the MCH_ACCESSBUF_DEPTH array
constant MCH_ACCESSBUF_DEPTH_ARRAY : INTEGER_ARRAY_TYPE :=
        (   0 => C_MCH0_ACCESSBUF_DEPTH,
            1 => C_MCH1_ACCESSBUF_DEPTH,
            2 => C_MCH2_ACCESSBUF_DEPTH,
            3 => C_MCH3_ACCESSBUF_DEPTH
         );
-- create the MCH_RDDATABUF_DEPTH array
constant MCH_RDDATABUF_DEPTH_ARRAY : INTEGER_ARRAY_TYPE :=
        (   0 => C_MCH0_RDDATABUF_DEPTH,
            1 => C_MCH1_RDDATABUF_DEPTH,
            2 => C_MCH2_RDDATABUF_DEPTH,
            3 => C_MCH3_RDDATABUF_DEPTH
         );
-- create the XCL_LINESIZE array
constant XCL_LINESIZE_ARRAY : INTEGER_ARRAY_TYPE :=
        (   0 => C_XCL0_LINESIZE,
            1 => C_XCL1_LINESIZE,
            2 => C_XCL2_LINESIZE,
            3 => C_XCL3_LINESIZE
         );
-- create the XCL_WRITEXFER array
constant XCL_WRITEXFER_ARRAY : INTEGER_ARRAY_TYPE :=
        (   0 => C_XCL0_WRITEXFER,
            1 => C_XCL1_WRITEXFER,
            2 => C_XCL2_WRITEXFER,
            3 => C_XCL3_WRITEXFER
         );

-----------------------------------------------------------------------------
-- Function: get_plb_ard_addr_range_array
-- Purpose: Fill PLB_ARD_ADDR_RANGE_ARRAY based on input parameters
-----------------------------------------------------------------------------
function get_plb_ard_addr_range_array return SLV64_ARRAY_TYPE is
variable plb_ard_addr_range_array_v : SLV64_ARRAY_TYPE 
                                        (0 to C_NUM_BANKS_MEM*2-1);
begin
    if (C_NUM_BANKS_MEM = 1) then
       plb_ard_addr_range_array_v(0) := ZERO_ADDR_PAD&C_MEM0_BASEADDR;
       plb_ard_addr_range_array_v(1) := ZERO_ADDR_PAD&C_MEM0_HIGHADDR;
    elsif (C_NUM_BANKS_MEM = 2) then
       plb_ard_addr_range_array_v(0) := ZERO_ADDR_PAD&C_MEM0_BASEADDR;
       plb_ard_addr_range_array_v(1) := ZERO_ADDR_PAD&C_MEM0_HIGHADDR;
       plb_ard_addr_range_array_v(2) := ZERO_ADDR_PAD&C_MEM1_BASEADDR;
       plb_ard_addr_range_array_v(3) := ZERO_ADDR_PAD&C_MEM1_HIGHADDR;
    elsif (C_NUM_BANKS_MEM = 3) then
       plb_ard_addr_range_array_v(0) := ZERO_ADDR_PAD&C_MEM0_BASEADDR;
       plb_ard_addr_range_array_v(1) := ZERO_ADDR_PAD&C_MEM0_HIGHADDR;
       plb_ard_addr_range_array_v(2) := ZERO_ADDR_PAD&C_MEM1_BASEADDR;
       plb_ard_addr_range_array_v(3) := ZERO_ADDR_PAD&C_MEM1_HIGHADDR;
       plb_ard_addr_range_array_v(4) := ZERO_ADDR_PAD&C_MEM2_BASEADDR;
       plb_ard_addr_range_array_v(5) := ZERO_ADDR_PAD&C_MEM2_HIGHADDR;
    else
       plb_ard_addr_range_array_v(0) := ZERO_ADDR_PAD&C_MEM0_BASEADDR;
       plb_ard_addr_range_array_v(1) := ZERO_ADDR_PAD&C_MEM0_HIGHADDR;
       plb_ard_addr_range_array_v(2) := ZERO_ADDR_PAD&C_MEM1_BASEADDR;
       plb_ard_addr_range_array_v(3) := ZERO_ADDR_PAD&C_MEM1_HIGHADDR;
       plb_ard_addr_range_array_v(4) := ZERO_ADDR_PAD&C_MEM2_BASEADDR;
       plb_ard_addr_range_array_v(5) := ZERO_ADDR_PAD&C_MEM2_HIGHADDR;
       plb_ard_addr_range_array_v(6) := ZERO_ADDR_PAD&C_MEM3_BASEADDR;
       plb_ard_addr_range_array_v(7) := ZERO_ADDR_PAD&C_MEM3_HIGHADDR;
    end if;
    return plb_ard_addr_range_array_v;
end function get_plb_ard_addr_range_array;

constant PLB_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE 
                                      := get_plb_ard_addr_range_array;
-----------------------------------------------------------------------------
-- Function: get_plb_ard_num_ce_array
-- Purpose:  Fill PLB_NUM_CE_ARRAY based on input parameters
-----------------------------------------------------------------------------
function get_plb_ard_num_ce_array return INTEGER_ARRAY_TYPE is
variable plb_ard_num_ce_array_v : 
                    INTEGER_ARRAY_TYPE(0 to C_NUM_BANKS_MEM-1);
begin
    if (C_NUM_BANKS_MEM = 1) then
        plb_ard_num_ce_array_v(0) := 1;      -- memories have only 1 CE
    elsif (C_NUM_BANKS_MEM = 2) then
        plb_ard_num_ce_array_v(0) := 1;
        plb_ard_num_ce_array_v(1) := 1;
    elsif (C_NUM_BANKS_MEM = 3) then
        plb_ard_num_ce_array_v(0) := 1;
        plb_ard_num_ce_array_v(1) := 1;
        plb_ard_num_ce_array_v(2) := 1;
    else
        plb_ard_num_ce_array_v(0) := 1;
        plb_ard_num_ce_array_v(1) := 1;
        plb_ard_num_ce_array_v(2) := 1;
        plb_ard_num_ce_array_v(3) := 1;
    end if;
    return plb_ard_num_ce_array_v;
end function get_plb_ard_num_ce_array;

constant PLB_ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE 
                                    := get_plb_ard_num_ce_array;
-----------------------------------------------------------------------------
-- Function: get_wrbuf_depth
-- Purpose :  Calculate write buffer depth based on input parameter
-----------------------------------------------------------------------------

function get_wrbuf_depth return integer is
variable wr_buffer_depth_v : integer;
begin
    if C_INCLUDE_WRBUF = 1 then
      wr_buffer_depth_v := 16;
    else
      wr_buffer_depth_v := 0;
    end if;
    return wr_buffer_depth_v;
end function get_wrbuf_depth;

constant WR_BUFFER_DEPTH    : integer := get_wrbuf_depth;
constant CACHLINE_ADDR_MODE : integer := 0;

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
-- IPIC Used Signals
signal ip2bus_rdack         : std_logic;
signal ip2bus_wrack         : std_logic;
signal ip2bus_addrack       : std_logic;
signal ip2bus_errack        : std_logic;
signal ip2bus_data          : std_logic_vector(0 to IPIF_DWIDTH - 1);
--IPIC request and qualifier signals
signal bus2ip_addr          : std_logic_vector(0 to IPIF_AWIDTH - 1);
signal bus2ip_data          : std_logic_vector(0 to IPIF_DWIDTH - 1);
signal bus2ip_rnw           : std_logic;
signal bus2ip_rdreq_i       : std_logic;
signal bus2ip_wrreq_i       : std_logic;
signal bus2ip_cs            : std_logic_vector
                              (0 to ((PLB_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
signal bus2ip_rdce          : std_logic_vector
                              (0 to calc_num_ce(PLB_ARD_NUM_CE_ARRAY)-1);
signal bus2ip_wrce          : std_logic_vector
                              (0 to calc_num_ce(PLB_ARD_NUM_CE_ARRAY)-1);
signal bus2ip_be            : std_logic_vector(0 to (IPIF_DWIDTH / 8) - 1);
signal bus2ip_burst         : std_logic;
-- External memory signals
signal mem_dq_o_i           : std_logic_vector(0 to C_MAX_MEM_WIDTH -1);
signal mem_dq_t_i           : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal mem_cen_i            : std_logic_vector(0 to C_NUM_BANKS_MEM -1);
signal mem_oen_i            : std_logic_vector(0 to C_NUM_BANKS_MEM -1);
signal mem_wen_i            : std_logic;
signal mem_qwen_i           : std_logic_vector(0 to C_MAX_MEM_WIDTH/8 -1);
signal mem_ben_i            : std_logic_vector(0 to C_MAX_MEM_WIDTH/8 -1);
signal mem_adv_ldn_i        : std_logic;
signal mem_cken_i           : std_logic;
signal mem_ce_i             : std_logic_vector(0 to C_NUM_BANKS_MEM -1);
signal mem_a_i              : std_logic_vector(0 to C_MCH_SPLB_AWIDTH -1);
-- MCH signals
signal mch_access_control   : std_logic_vector(0 to MAX_NUM_CHANNELS-1); 
signal mch_access_data      : std_logic_vector
                              (0 to (MAX_NUM_CHANNELS*C_MCH_NATIVE_DWIDTH)-1);
signal mch_access_write     : std_logic_vector(0 to MAX_NUM_CHANNELS-1);
signal mch_access_full      : std_logic_vector(0 to MAX_NUM_CHANNELS-1);
signal mch_readdata_control : std_logic_vector(0 to MAX_NUM_CHANNELS-1);
signal mch_readdata_data    : std_logic_vector
                              (0 to (MAX_NUM_CHANNELS*C_MCH_NATIVE_DWIDTH)-1);
signal mch_readdata_read    : std_logic_vector(0 to MAX_NUM_CHANNELS-1);
signal mch_readdata_exists  : std_logic_vector(0 to MAX_NUM_CHANNELS-1);
signal bus2ip_burstlength   : std_logic_vector
                                (0 to log2(16 * (C_SPLB_DWIDTH/8)));

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

begin -- architecture IMP

-- Populate MCH signals based on C_NUM_CHANNELS parameter

    -- Inputs
    mch_access_control    <= (MCH0_Access_Control & MCH1_Access_Control &
                              MCH2_Access_Control & MCH3_Access_Control);
    mch_access_data       <= (MCH0_Access_Data & MCH1_Access_Data &
                              MCH2_Access_Data & MCH3_Access_Data);
    mch_access_write      <= (MCH0_Access_Write & MCH1_Access_Write &
                              MCH2_Access_Write & MCH3_Access_Write);
    mch_readdata_read     <= (MCH0_ReadData_Read & MCH1_ReadData_Read &
                              MCH2_ReadData_Read & MCH3_ReadData_Read) ;

    -- Outputs
    MCH0_Access_Full      <= mch_access_full(0);
    MCH0_ReadData_Exists  <= mch_readdata_exists(0);
    MCH0_ReadData_Control <= mch_readdata_control(0);
    MCH0_ReadData_Data    <= mch_readdata_data(0 to C_MCH_NATIVE_DWIDTH-1);
    --
    MCH1_Access_Full      <= mch_access_full(1);
    MCH1_ReadData_Exists  <= mch_readdata_exists(1);
    MCH1_ReadData_Control <= mch_readdata_control(1);
    MCH1_ReadData_Data    <= mch_readdata_data
                            (C_MCH_NATIVE_DWIDTH to 2*C_MCH_NATIVE_DWIDTH-1);
    --
    MCH2_Access_Full      <= mch_access_full(2);
    MCH2_ReadData_Exists  <= mch_readdata_exists(2);
    MCH2_ReadData_Control <= mch_readdata_control(2);
    MCH2_ReadData_Data    <= mch_readdata_data
                            (2*C_MCH_NATIVE_DWIDTH to 3*C_MCH_NATIVE_DWIDTH-1);
    --
    MCH3_Access_Full      <= mch_access_full(3);
    MCH3_ReadData_Exists  <= mch_readdata_exists(3);
    MCH3_ReadData_Control <= mch_readdata_control(3);
    MCH3_ReadData_Data    <= mch_readdata_data
                            (3*C_MCH_NATIVE_DWIDTH to 4*C_MCH_NATIVE_DWIDTH-1);
--
-------------------------------------------------------------------------------
-- ZERO_UNUSED_OUTPUTS_GEN generate
-------------------------------------------------------------------------------
--Fixing unused MCH CHANNELS output signals to Zeros
-------------------------------------------------------------------------------
    ZERO_UNUSED_OUTPUTS_GEN: if C_NUM_CHANNELS < MAX_NUM_CHANNELS generate
    begin

    mch_access_full(C_NUM_CHANNELS to MAX_NUM_CHANNELS-1)
                                                <= (others => '0');
    mch_readdata_exists(C_NUM_CHANNELS to MAX_NUM_CHANNELS-1)
                                                <= (others => '0');
    mch_readdata_control(C_NUM_CHANNELS to MAX_NUM_CHANNELS-1)
                                                <= (others => '0');
    mch_readdata_data(C_NUM_CHANNELS*C_MCH_NATIVE_DWIDTH to 
                        MAX_NUM_CHANNELS*C_MCH_NATIVE_DWIDTH-1)
                                                <= (others => '0');

    end generate ZERO_UNUSED_OUTPUTS_GEN;

---- EMC memory read/write access times assignments
    Mem_A       <= mem_a_i    ;
    Mem_DQ_O    <= mem_dq_o_i ;
    Mem_DQ_T    <= mem_dq_t_i ;
    Mem_CEN     <= mem_cen_i  ;
    Mem_OEN     <= mem_oen_i  ;
    Mem_WEN     <= mem_wen_i  ;
    Mem_QWEN    <= mem_qwen_i ;
    Mem_BEN     <= mem_ben_i  ;
    Mem_CE      <= mem_ce_i   ;
    Mem_ADV_LDN <= mem_adv_ldn_i;
    Mem_CKEN    <= mem_cken_i  ;
-------------------------------------------------------------------------------
-- Component Instantiations
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Instantiate MCH_PLBV46_SLAVE_BURST
-------------------------------------------------------------------------------
    MCH_PLB_IPIF_I:entity mch_plbv46_slave_burst_v2_01_a.mch_plbv46_slave_burst
        generic map (
            C_FAMILY                     => C_FAMILY,
            C_INCLUDE_PLB_IPIF           => C_INCLUDE_PLB_IPIF,

            C_SPLB_DWIDTH                => C_SPLB_DWIDTH,
            C_MCH_SPLB_AWIDTH            => C_MCH_SPLB_AWIDTH,
            C_SPLB_SMALLEST_MASTER       => C_SPLB_SMALLEST_MASTER,
            C_MCH_SIPIF_DWIDTH           => C_MCH_NATIVE_DWIDTH,

            C_PRIORITY_MODE              => PRIORITY_MODE,
            C_NUM_CHANNELS               => C_NUM_CHANNELS,
            C_MCH_PROTOCOL_ARRAY         => MCH_PROTOCOL_ARRAY,
            C_MCH_USERIP_ADDRRANGE_ARRAY => PLB_ARD_ADDR_RANGE_ARRAY,
            C_MCH_ACCESSBUF_DEPTH_ARRAY  => MCH_ACCESSBUF_DEPTH_ARRAY,
            C_MCH_RDDATABUF_DEPTH_ARRAY  => MCH_RDDATABUF_DEPTH_ARRAY,
            C_XCL_LINESIZE_ARRAY         => XCL_LINESIZE_ARRAY,
            C_XCL_WRITEXFER_ARRAY        => XCL_WRITEXFER_ARRAY,    
            C_DAG_BURSTSIZE_ARRAY        => open, -- DAG is not supported 
            C_DAG_ADDR_STEP_ARRAY        => open,
            C_DAG_ADDR_WRAP_ARRAY        => open,

            C_PLB_ARD_ADDR_RANGE_ARRAY   => PLB_ARD_ADDR_RANGE_ARRAY,
            C_PLB_ARD_NUM_CE_ARRAY       => PLB_ARD_NUM_CE_ARRAY,
            C_SPLB_P2P                   => C_SPLB_P2P,
            C_CACHLINE_ADDR_MODE         => CACHLINE_ADDR_MODE,
            C_WR_BUFFER_DEPTH            => WR_BUFFER_DEPTH,
            C_SPLB_MID_WIDTH             => C_SPLB_MID_WIDTH,
            C_SPLB_NUM_MASTERS           => C_SPLB_NUM_MASTERS
         ) 
        port map
        (
            SPLB_Clk            => MCH_SPLB_Clk,
            SPLB_Rst            => MCH_SPLB_Rst,

            -- MCH interface
            MCH_Access_Control  => mch_access_control(0 to C_NUM_CHANNELS-1),
            MCH_Access_Data     => mch_access_data
                                   (0 to C_NUM_CHANNELS*C_MCH_NATIVE_DWIDTH-1),
            MCH_Access_Write    => mch_access_write(0 to C_NUM_CHANNELS-1),
            MCH_Access_Full     => mch_access_full(0 to C_NUM_CHANNELS-1),

            MCH_ReadData_Control=> mch_readdata_control(0 to C_NUM_CHANNELS-1),
            MCH_ReadData_Data   => mch_readdata_data
                                   (0 to C_NUM_CHANNELS*C_MCH_NATIVE_DWIDTH-1),
            MCH_ReadData_Read   => mch_readdata_read(0 to C_NUM_CHANNELS-1),
            MCH_ReadData_Exists => mch_readdata_exists(0 to C_NUM_CHANNELS-1),

            ----------- Bus Slave signals ----------- 
            PLB_ABus             => PLB_ABus,
            PLB_UABus            => PLB_UABus,
            PLB_PAValid          => PLB_PAValid,
            PLB_SAValid          => PLB_SAValid,
            PLB_rdPrim           => PLB_rdPrim,
            PLB_wrPrim           => PLB_wrPrim,
            PLB_masterID         => PLB_masterID,
            PLB_abort            => PLB_abort,
            PLB_busLock          => PLB_busLock,
            PLB_RNW              => PLB_RNW,
            PLB_BE               => PLB_BE,
            PLB_MSize            => PLB_MSize,
            PLB_size             => PLB_size,
            PLB_type             => PLB_type,
            PLB_lockErr          => PLB_lockErr,
            PLB_wrDBus           => PLB_wrDBus,
            PLB_wrBurst          => PLB_wrBurst,
            PLB_rdBurst          => PLB_rdBurst,
            PLB_wrPendReq        => PLB_wrPendReq,
            PLB_rdPendReq        => PLB_rdPendReq,
            PLB_wrPendPri        => PLB_wrPendPri,
            PLB_rdPendPri        => PLB_rdPendPri,
            PLB_reqPri           => PLB_reqPri,
            PLB_TAttribute       => PLB_TAttribute,

            -- Slave Responce Signals
            Sl_addrAck           => Sl_addrAck,
            Sl_SSize             => Sl_SSize,
            Sl_wait              => Sl_wait,
            Sl_rearbitrate       => Sl_rearbitrate,
            Sl_wrDAck            => Sl_wrDAck,
            Sl_wrComp            => Sl_wrComp,
            Sl_wrBTerm           => Sl_wrBTerm,
            Sl_rdDBus            => Sl_rdDBus,
            Sl_rdWdAddr          => Sl_rdWdAddr,
            Sl_rdDAck            => Sl_rdDAck,
            Sl_rdComp            => Sl_rdComp,
            Sl_rdBTerm           => Sl_rdBTerm,
            Sl_MBusy             => Sl_MBusy,
            Sl_MWrErr            => Sl_MWrErr,
            Sl_MRdErr            => Sl_MRdErr,
            Sl_MIRQ              => Sl_MIRQ,

            -- IP Interconnect (IPIC) port signals
            Bus2IP_Clk           => open,
            Bus2IP_Reset         => open,

            IP2Bus_Data          => ip2bus_data,
            IP2Bus_WrAck         => ip2bus_wrack,
            IP2Bus_RdAck         => ip2bus_rdack,
            IP2Bus_AddrAck       => ip2bus_addrack,
            IP2Bus_Error         => ip2bus_errack,

            Bus2IP_Addr          => bus2ip_addr,
            Bus2IP_Data          => bus2ip_data,
            Bus2IP_RNW           => bus2ip_rnw,
            Bus2IP_BE            => bus2ip_be,
            Bus2IP_Burst         => bus2ip_burst,
            Bus2IP_AddrBurstLength => bus2ip_burstlength,
            Bus2IP_BurstLength   => open,
            Bus2IP_RdReq         => open,
            Bus2IP_WrReq         => open,
            Bus2IP_CS            => bus2ip_cs,
            Bus2IP_RdCE          => bus2ip_rdce,
            Bus2IP_WrCE          => bus2ip_wrce
            );


    ---------------------------------------------------------------------------
     -- Miscellaneous assignments to match EMC controller to IPIC
    ---------------------------------------------------------------------------
    bus2ip_wrreq_i  <= or_reduce(bus2ip_wrce);
    bus2ip_rdreq_i  <= or_reduce(bus2ip_rdce);

    ---------------------------------------------------------------------------
    -- Instantiate the EMC Controller
    ---------------------------------------------------------------------------

    EMC_CTRL_I: entity emc_common_v4_01_a.emc
        generic map(
            C_NUM_BANKS_MEM                => C_NUM_BANKS_MEM,
            C_IPIF_DWIDTH                  => C_MCH_NATIVE_DWIDTH,
            C_IPIF_AWIDTH                  => C_MCH_SPLB_AWIDTH,
            C_SPLB_DWIDTH                  => C_SPLB_DWIDTH,

            C_MEM0_BASEADDR                => C_MEM0_BASEADDR,
            C_MEM0_HIGHADDR                => C_MEM0_HIGHADDR,
            C_MEM1_BASEADDR                => C_MEM1_BASEADDR,
            C_MEM1_HIGHADDR                => C_MEM1_HIGHADDR,
            C_MEM2_BASEADDR                => C_MEM2_BASEADDR,
            C_MEM2_HIGHADDR                => C_MEM2_HIGHADDR,
            C_MEM3_BASEADDR                => C_MEM3_BASEADDR,
            C_MEM3_HIGHADDR                => C_MEM3_HIGHADDR,

            C_PAGEMODE_FLASH_0             => C_PAGEMODE_FLASH_0,
            C_PAGEMODE_FLASH_1             => C_PAGEMODE_FLASH_1,
            C_PAGEMODE_FLASH_2             => C_PAGEMODE_FLASH_2,
            C_PAGEMODE_FLASH_3             => C_PAGEMODE_FLASH_3,
            C_INCLUDE_NEGEDGE_IOREGS       => C_INCLUDE_NEGEDGE_IOREGS,

            C_MEM0_WIDTH                   => C_MEM0_WIDTH,
            C_MEM1_WIDTH                   => C_MEM1_WIDTH,
            C_MEM2_WIDTH                   => C_MEM2_WIDTH,
            C_MEM3_WIDTH                   => C_MEM3_WIDTH,
            C_MAX_MEM_WIDTH                => C_MAX_MEM_WIDTH,

            C_INCLUDE_DATAWIDTH_MATCHING_0 => C_INCLUDE_DATAWIDTH_MATCHING_0,
            C_INCLUDE_DATAWIDTH_MATCHING_1 => C_INCLUDE_DATAWIDTH_MATCHING_1,
            C_INCLUDE_DATAWIDTH_MATCHING_2 => C_INCLUDE_DATAWIDTH_MATCHING_2,
            C_INCLUDE_DATAWIDTH_MATCHING_3 => C_INCLUDE_DATAWIDTH_MATCHING_3,

            -- Memory read and write access times for all memory banks
            C_BUS_CLOCK_PERIOD_PS          => C_MCH_SPLB_CLK_PERIOD_PS,

            C_SYNCH_MEM_0                  => C_SYNCH_MEM_0,
            C_SYNCH_PIPEDELAY_0            => C_SYNCH_PIPEDELAY_0,
            C_TCEDV_PS_MEM_0               => C_TCEDV_PS_MEM_0,
            C_TAVDV_PS_MEM_0               => C_TAVDV_PS_MEM_0,
            C_TPACC_PS_FLASH_0             => C_TPACC_PS_FLASH_0,
            C_THZCE_PS_MEM_0               => C_THZCE_PS_MEM_0,
            C_THZOE_PS_MEM_0               => C_THZOE_PS_MEM_0,
            C_TWC_PS_MEM_0                 => C_TWC_PS_MEM_0,
            C_TWP_PS_MEM_0                 => C_TWP_PS_MEM_0,
            C_TLZWE_PS_MEM_0               => C_TLZWE_PS_MEM_0,

            C_SYNCH_MEM_1                  => C_SYNCH_MEM_1,
            C_SYNCH_PIPEDELAY_1            => C_SYNCH_PIPEDELAY_1,
            C_TCEDV_PS_MEM_1               => C_TCEDV_PS_MEM_1,
            C_TAVDV_PS_MEM_1               => C_TAVDV_PS_MEM_1,
            C_TPACC_PS_FLASH_1             => C_TPACC_PS_FLASH_1,
            C_THZCE_PS_MEM_1               => C_THZCE_PS_MEM_1,
            C_THZOE_PS_MEM_1               => C_THZOE_PS_MEM_1,
            C_TWC_PS_MEM_1                 => C_TWC_PS_MEM_1,
            C_TWP_PS_MEM_1                 => C_TWP_PS_MEM_1,
            C_TLZWE_PS_MEM_1               => C_TLZWE_PS_MEM_1,

            C_SYNCH_MEM_2                  => C_SYNCH_MEM_2,
            C_SYNCH_PIPEDELAY_2            => C_SYNCH_PIPEDELAY_2,
            C_TCEDV_PS_MEM_2               => C_TCEDV_PS_MEM_2,
            C_TAVDV_PS_MEM_2               => C_TAVDV_PS_MEM_2,
            C_TPACC_PS_FLASH_2             => C_TPACC_PS_FLASH_2,
            C_THZCE_PS_MEM_2               => C_THZCE_PS_MEM_2,
            C_THZOE_PS_MEM_2               => C_THZOE_PS_MEM_2,
            C_TWC_PS_MEM_2                 => C_TWC_PS_MEM_2,
            C_TWP_PS_MEM_2                 => C_TWP_PS_MEM_2,
            C_TLZWE_PS_MEM_2               => C_TLZWE_PS_MEM_2,

            C_SYNCH_MEM_3                  => C_SYNCH_MEM_3,
            C_SYNCH_PIPEDELAY_3            => C_SYNCH_PIPEDELAY_3,
            C_TCEDV_PS_MEM_3               => C_TCEDV_PS_MEM_3,
            C_TAVDV_PS_MEM_3               => C_TAVDV_PS_MEM_3,
            C_TPACC_PS_FLASH_3             => C_TPACC_PS_FLASH_3,
            C_THZCE_PS_MEM_3               => C_THZCE_PS_MEM_3,
            C_THZOE_PS_MEM_3               => C_THZOE_PS_MEM_3,
            C_TWC_PS_MEM_3                 => C_TWC_PS_MEM_3,
            C_TWP_PS_MEM_3                 => C_TWP_PS_MEM_3,
            C_TLZWE_PS_MEM_3               => C_TLZWE_PS_MEM_3
        )
        port map (
            Bus2IP_Clk         => MCH_SPLB_Clk,
            RdClk              => RdClk,
            Bus2IP_Reset       => MCH_SPLB_Rst,

            -- Bus and IPIC Interface signals
            Bus2IP_Addr        => bus2ip_addr,
            Bus2IP_BE          => bus2ip_be,
            Bus2IP_Data        => bus2ip_data,
            Bus2IP_RNW         => bus2ip_rnw,
            Bus2IP_Burst       => bus2ip_burst,
            Bus2IP_WrReq       => bus2ip_wrreq_i,
            Bus2IP_RdReq       => bus2ip_rdreq_i,
            Bus2IP_Mem_CS      => bus2ip_cs,
            Bus2IP_BurstLength => bus2ip_burstlength,

            IP2Bus_Data        => ip2bus_data,
            IP2Bus_errAck      => ip2bus_errack,
            IP2Bus_retry       => open,
            IP2Bus_toutSup     => open,
            IP2Bus_RdAck       => ip2bus_rdack,
            IP2Bus_WrAck       => ip2bus_wrack,
            IP2Bus_AddrAck     => ip2bus_addrack,

            -- Memory signals
            Mem_A              => mem_a_i,
            Mem_DQ_I           => mem_dq_i,
            Mem_DQ_O           => mem_dq_o_i,
            Mem_DQ_T           => mem_dq_t_i,
            Mem_CEN            => mem_cen_i,
            Mem_OEN            => mem_oen_i,
            Mem_WEN            => mem_wen_i,
            Mem_QWEN           => mem_qwen_i,
            Mem_BEN            => mem_ben_i,
            Mem_RPN            => Mem_RPN,
            Mem_CE             => mem_ce_i,
            Mem_ADV_LDN        => mem_adv_ldn_i,
            Mem_LBON           => Mem_LBON,
            Mem_CKEN           => mem_cken_i,
            Mem_RNW            => Mem_RNW
        );

end implementation;
-------------------------------------------------------------------------------
-- End of file xps_mch_emc.vhd
-------------------------------------------------------------------------------
