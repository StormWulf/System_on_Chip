-------------------------------------------------------------------------------
-- EMC - entity/architecture pair
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
-- Filename:        emc.vhd
-- Version:         v4.00.a
-- Description:     External Memory Controller
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
-- This file is based on version v2_01_c updated to fixed CR #466745: -
--     Added generic C_MEM_DQ_CAPTURE_NEGEDGE. The same generic is mapped to 
--     component io_registers from emc_common_v2_02_a.
-- ~~~~~~~~~
-- NSK         02/12/08    Updated
-- ^^^^^^^^
-- Added generic C_MEM_DQ_CAPTURE_NEGEDGE in comment "Definition of Generics" 
-- section.
-- ~~~~~~~~
-- NSK         03/03/08    Updated
-- ^^^^^^^^
-- 1. Removed generic C_MEM_DQ_CAPTURE_NEGEDGE.
-- 2. Added the port RdClk used as clock to capture the data from memory.
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
--      combinatorial signals:                  "*_cmb"
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
use ieee.std_logic_signed.all;
use ieee.std_logic_misc.all;

-------------------------------------------------------------------------------
-- vcomponents package of the unisim library is used for different component
-- declarations
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for different
-- function declarations
-------------------------------------------------------------------------------

library proc_common_v3_00_a;
use proc_common_v3_00_a.all;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.proc_common_pkg.Addr_Bits;

-------------------------------------------------------------------------------
-- emc_common_v3_00_a library is used for emc_common component declarations
-------------------------------------------------------------------------------

library emc_common_v4_01_a;
use emc_common_v4_01_a.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
--  C_NUM_BANKS_MEM                 -- Number of memory banks
--  C_IPIF_DWIDTH                   -- Width of processor data bus
--  C_IPIF_AWIDTH                   -- Width of processor address bus
--  C_MEM(0:3)_BASEADDR             -- Memory bank (0:3) base address
--  C_MEM(0:3)_HIGHADDR             -- Memory bank (0:3) high address
--  C_INCLUDE_NEGEDGE_IOREGS        -- Include negative edge IO registers
--  C_PAGEMODE_FLASH_(0:3)          -- Whether a PAGE MODE Flash device is used
--  C_MEM(0:3)_WIDTH                -- Width of memory bank's data bus
--  C_MAX_MEM_WIDTH                 -- Maximum width of memory data bus
--  C_INCLUDE_DATAWIDTH_MATCHING_(0:3)  -- Include datawidth matching logic for
--                                  -- memory bank
--  C_BUS_CLOCK_PERIOD_PS           -- Bus clock period to calculate wait
--                                         state pulse widths.
--  C_SYNCH_MEM_(0:3)               -- Memory bank is synchronous
--  C_TCEDV_PS_MEM_(0:3)            -- Chip Enable to Data Valid Time
--                                  -- (Maximum of TCEDV and TAVDV applied
--                                     as read cycle start to first data valid)
--  C_TAVDV_PS_MEM_(0:3)            -- Address Valid to Data Valid Time
--                                  -- (Maximum of TCEDV and TAVDV applied
--                                     as read cycle start to first data valid)
--  C_TPACC_PS_FLASH_(0:3)          -- Address Valid to Data Valid Time
--                                  -- for a PAGE Read for a PAGE MODE Flash
--  C_THZCE_PS_MEM_(0:3)            -- Chip Enable High to Data Bus High
--                                     Impedance (Maximum of THZCE and THZOE
--                                     applied as Read Recovery before Write)
--  C_THZOE_PS_MEM_(0:3)            -- Output Enable High to Data Bus High
--                                     Impedance (Maximum of THZCE and THZOE
--                                     applied as Read Recovery before Write)
--  C_TWC_PS_MEM_(0:3)              -- Write Cycle Time
--                                     (Maximum of TWC and TWP applied as write
--                                     enable pulse width)
--  C_TWP_PS_MEM_(0:3)              -- Write Enable Minimum Pulse Width
--                                     (Maximum of TWC and TWP applied as write
--                                     enable pulse width)
--  C_TLZWE_PS_MEM_(0:3)            -- Write Enable High to Data Bus Low
--                                     Impedance (Applied as Write Recovery
--                                     before Read)
-- Definition of Ports:
--
--  Bus2IP_Clk             -- System clock
--  RdClk                  -- Read Clock
--  Bus2IP_Reset           -- System Reset
--
-- Bus and IPIC Interface signals
--  Bus2IP_Addr             -- Processor bus address
--  Bus2IP_BE               -- Processor bus byte enables
--  Bus2IP_Data             -- Processor data
--  Bus2IP_RNW              -- Processor read not write
--  Bus2IP_Burst            -- Processor burst
--  Bus2IP_WrReq            -- Processor write request
--  Bus2IP_RdReq            -- Processor read request
--  Bus2IP_Mem_CS           -- Memory address range is being accessed
--
-- EMC to bus signals
--  IP2Bus_Data             -- Data to processor bus
--  IP2Bus_errAck           -- Error acknowledge
--  IP2Bus_retry            -- Retry indicator
--  IP2Bus_toutSup          -- Suppress watch dog timer
--  IP2Bus_RdAck            -- Read acknowledge
--  IP2Bus_WrAck            -- Write acknowledge
--  IP2Bus_AddrAck          -- Read/Write Address acknowledge
--
-- Memory signals
--  Mem_A                   -- Memory address inputs
--  Mem_DQ_I                -- Memory input data bus
--  Mem_DQ_O                -- Memory output data bus
--  Mem_DQ_T                -- Memory data output enable
--  Mem_CEN                 -- Memory chip select
--  Mem_OEN                 -- Memory output enable
--  Mem_WEN                 -- Memory write enable
--  Mem_QWEN                -- Memory qualified write enable
--  Mem_BEN                 -- Memory byte enables
--  Mem_RPN                 -- Memory reset/power down
--  Mem_CE                  -- Memory chip enable
--  Mem_ADV_LDN             -- Memory counter advance/load (=0)
--  Mem_LBON                -- Memory linear/interleaved burst order (=0)
--  Mem_CKEN                -- Memory clock enable (=0)
--  Mem_RNW                 -- Memory read not write
-------------------------------------------------------------------------------
-- Port declarations
-------------------------------------------------------------------------------

entity EMC is
    generic (
        C_NUM_BANKS_MEM                 : integer range 1 to 4 := 1;
        C_SPLB_DWIDTH                   : integer := 32;
        C_IPIF_DWIDTH                   : integer := 32;
        C_IPIF_AWIDTH                   : integer := 32;

        C_MEM0_BASEADDR                 : std_logic_vector := x"30000000";
        C_MEM0_HIGHADDR                 : std_logic_vector := x"3000ffff";
        C_MEM1_BASEADDR                 : std_logic_vector := x"40000000";
        C_MEM1_HIGHADDR                 : std_logic_vector := x"4000ffff";
        C_MEM2_BASEADDR                 : std_logic_vector := x"50000000";
        C_MEM2_HIGHADDR                 : std_logic_vector := x"5000ffff";
        C_MEM3_BASEADDR                 : std_logic_vector := x"60000000";
        C_MEM3_HIGHADDR                 : std_logic_vector := x"6000ffff";

        C_INCLUDE_NEGEDGE_IOREGS        : integer := 0;
        C_PAGEMODE_FLASH_0              : integer := 0;
        C_PAGEMODE_FLASH_1              : integer := 0;
        C_PAGEMODE_FLASH_2              : integer := 0;
        C_PAGEMODE_FLASH_3              : integer := 0;

        C_MEM0_WIDTH                    : integer range 8 to 64 := 32;
        C_MEM1_WIDTH                    : integer range 8 to 64 := 32;
        C_MEM2_WIDTH                    : integer range 8 to 64 := 32;
        C_MEM3_WIDTH                    : integer range 8 to 64 := 32;
        C_MAX_MEM_WIDTH                 : integer range 8 to 64 := 32;

        C_INCLUDE_DATAWIDTH_MATCHING_0  : integer := 0;
        C_INCLUDE_DATAWIDTH_MATCHING_1  : integer := 0;
        C_INCLUDE_DATAWIDTH_MATCHING_2  : integer := 0;
        C_INCLUDE_DATAWIDTH_MATCHING_3  : integer := 0;

        C_BUS_CLOCK_PERIOD_PS           : integer := 10000;
        
        -- Memory Channel 0 Timing Parameters
        C_SYNCH_MEM_0                   : integer := 0;
        C_SYNCH_PIPEDELAY_0             : integer := 2;
        C_TCEDV_PS_MEM_0                : integer := 15000;
        C_TAVDV_PS_MEM_0                : integer := 15000;
        C_TPACC_PS_FLASH_0              : integer := 25000;
        C_THZCE_PS_MEM_0                : integer := 7000;
        C_THZOE_PS_MEM_0                : integer := 7000;
        C_TWC_PS_MEM_0                  : integer := 15000;
        C_TWP_PS_MEM_0                  : integer := 12000;
        C_TLZWE_PS_MEM_0                : integer := 0;

        -- Memory Channel 1 Timing Parameters
        C_SYNCH_MEM_1                   : integer := 0;
        C_SYNCH_PIPEDELAY_1             : integer := 2;
        C_TCEDV_PS_MEM_1                : integer := 15000;
        C_TAVDV_PS_MEM_1                : integer := 15000;
        C_TPACC_PS_FLASH_1              : integer := 25000;
        C_THZCE_PS_MEM_1                : integer := 7000;
        C_THZOE_PS_MEM_1                : integer := 7000;
        C_TWC_PS_MEM_1                  : integer := 15000;
        C_TWP_PS_MEM_1                  : integer := 12000;
        C_TLZWE_PS_MEM_1                : integer := 0;

        -- Memory Channel 2 Timing Parameters
        C_SYNCH_MEM_2                   : integer := 0;
        C_SYNCH_PIPEDELAY_2             : integer := 2;
        C_TCEDV_PS_MEM_2                : integer := 15000;
        C_TAVDV_PS_MEM_2                : integer := 15000;
        C_TPACC_PS_FLASH_2              : integer := 25000;
        C_THZCE_PS_MEM_2                : integer := 7000;
        C_THZOE_PS_MEM_2                : integer := 7000;
        C_TWC_PS_MEM_2                  : integer := 15000;
        C_TWP_PS_MEM_2                  : integer := 12000;
        C_TLZWE_PS_MEM_2                : integer := 0;

        -- Memory Channel 3 Timing Parameters
        C_SYNCH_MEM_3                   : integer := 0;
        C_SYNCH_PIPEDELAY_3             : integer := 2;
        C_TCEDV_PS_MEM_3                : integer := 15000;
        C_TAVDV_PS_MEM_3                : integer := 15000;
        C_TPACC_PS_FLASH_3              : integer := 25000;
        C_THZCE_PS_MEM_3                : integer := 7000;
        C_THZOE_PS_MEM_3                : integer := 7000;
        C_TWC_PS_MEM_3                  : integer := 15000;
        C_TWP_PS_MEM_3                  : integer := 12000;
        C_TLZWE_PS_MEM_3                : integer := 0
    );
    port (
        Bus2IP_Clk          : in  std_logic;
        RdClk               : in  std_logic;
        Bus2IP_Reset        : in  std_logic;

        -- Bus and IPIC Interface signals
        Bus2IP_Addr         : in  std_logic_vector(0 to C_IPIF_AWIDTH-1);
        Bus2IP_BE           : in  std_logic_vector(0 to C_IPIF_DWIDTH/8-1);
        Bus2IP_Data         : in  std_logic_vector(0 to C_IPIF_DWIDTH-1);
        Bus2IP_RNW          : in  std_logic;
        Bus2IP_Burst        : in  std_logic;
        Bus2IP_WrReq        : in  std_logic;
        Bus2IP_RdReq        : in  std_logic;
        Bus2IP_Mem_CS       : in  std_logic_vector(0 to C_NUM_BANKS_MEM-1);
        Bus2IP_BurstLength  : in  std_logic_vector(0 to log2(16*(C_SPLB_DWIDTH/8)));

        IP2Bus_Data         : out std_logic_vector(0 to C_IPIF_DWIDTH-1);
        IP2Bus_errAck       : out std_logic;
        IP2Bus_retry        : out std_logic;
        IP2Bus_toutSup      : out std_logic;
        IP2Bus_RdAck        : out std_logic;
        IP2Bus_WrAck        : out std_logic;
        IP2Bus_AddrAck      : out std_logic;

        -- Memory signals
        Mem_DQ_I            : in    std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
        Mem_DQ_O            : out   std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
        Mem_DQ_T            : out   std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
        Mem_A               : out   std_logic_vector(0 to C_IPIF_AWIDTH-1);
        Mem_RPN             : out   std_logic;
        Mem_CEN             : out   std_logic_vector(0 to C_NUM_BANKS_MEM-1);
        Mem_OEN             : out   std_logic_vector(0 to C_NUM_BANKS_MEM-1);
        Mem_WEN             : out   std_logic;
        Mem_QWEN            : out   std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
        Mem_BEN             : out   std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
        Mem_CE              : out   std_logic_vector(0 to C_NUM_BANKS_MEM-1);
        Mem_ADV_LDN         : out   std_logic;
        Mem_LBON            : out   std_logic;
        Mem_CKEN            : out   std_logic;
        Mem_RNW             : out   std_logic
    );
end entity EMC;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture IMP of EMC is

-------------------------------------------------------------------------------
-- Data Types
-------------------------------------------------------------------------------

type EMC_ARRAY_TYPE is array (0 to 3) of integer;

type INTEGER_ARRAY is array (natural range <>) of integer;

type MEM_ADDR_ARRAY is array (0 to C_NUM_BANKS_MEM-1) of
                                        std_logic_vector(0 to C_IPIF_AWIDTH-1);
-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- not_all_zeros()
-------------------------------------------------------------------------------
function not_all_zeros(input_array          : EMC_ARRAY_TYPE;
                       num_real_elements    : integer)
                       return integer is
    variable sum : integer range 0 to 8 := 0;
    begin
        for i in 0 to num_real_elements -1 loop
            sum := sum + input_array(i);
        end loop;

        if sum = 0 then
            return 0;
        else
            return 1;
        end if;
    end function not_all_zeros;

function get_mem_addr_array return MEM_ADDR_ARRAY is
variable mem_addr_array_v : MEM_ADDR_ARRAY;
begin

    if (C_NUM_BANKS_MEM = 1) then
        mem_addr_array_v(0) := C_MEM0_BASEADDR;      -- EMC BASE address MEM0
    elsif (C_NUM_BANKS_MEM = 2) then
        mem_addr_array_v(0) := C_MEM0_BASEADDR;      -- EMC BASE address MEM0
        mem_addr_array_v(1) := C_MEM1_BASEADDR;      -- EMC BASE address MEM1
    elsif (C_NUM_BANKS_MEM = 3) then
        mem_addr_array_v(0) := C_MEM0_BASEADDR;      -- EMC BASE address MEM0
        mem_addr_array_v(1) := C_MEM1_BASEADDR;      -- EMC BASE address MEM1
        mem_addr_array_v(2) := C_MEM2_BASEADDR;      -- EMC BASE address MEM2
    elsif (C_NUM_BANKS_MEM = 4) then
        mem_addr_array_v(0) := C_MEM0_BASEADDR;      -- EMC BASE address MEM0
        mem_addr_array_v(1) := C_MEM1_BASEADDR;      -- EMC BASE address MEM1
        mem_addr_array_v(2) := C_MEM2_BASEADDR;      -- EMC BASE address MEM2
        mem_addr_array_v(3) := C_MEM3_BASEADDR;      -- EMC BASE address MEM3
    end if;

    return mem_addr_array_v;

end function get_mem_addr_array;

function calc_addr_decode_bits(x:MEM_ADDR_ARRAY; y:integer) return integer is

  variable num_bits_temp          : integer:=0;
  variable num_bits_image         : integer:=0;
  variable num_bits               : integer:=0;

begin
  if (y > 1) then
    for i in 0 to (y-2) loop
      for j in (i+1) to (y-1) loop
        num_bits_temp := Addr_Bits(x(i),x(j));
        num_bits      := max2(num_bits_temp,num_bits_image);
        num_bits_image:= num_bits;
      end loop;
    end loop;
    return num_bits+1;
   else
     return 1;
   end if;
end function calc_addr_decode_bits;

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant MEM_BASE_ADDRESS_ARRAY     : MEM_ADDR_ARRAY:= get_mem_addr_array;
constant ADDR_CMP_BITS              : integer:=
             calc_addr_decode_bits(MEM_BASE_ADDRESS_ARRAY,C_NUM_BANKS_MEM);
-- minimum memory data width supported is 8 bits
constant MIN_MEM_WIDTH      : integer := 8;

-- address offset
constant ADDR_OFFSET        : integer range 0 to 4
                                := log2(C_IPIF_DWIDTH/8);
                                
constant ADDR_CNTR_WIDTH    : integer range 1 to 5
                                := max2(1,log2(C_IPIF_DWIDTH/8));

-- create arrays of generics for use in functions
constant SYNCH_MEM_ARRAY : EMC_ARRAY_TYPE :=
       (C_SYNCH_MEM_0,
        C_SYNCH_MEM_1,
        C_SYNCH_MEM_2,
        C_SYNCH_MEM_3);

constant DATAWIDTH_MATCH_ARRAY : EMC_ARRAY_TYPE :=
       (C_INCLUDE_DATAWIDTH_MATCHING_0,
        C_INCLUDE_DATAWIDTH_MATCHING_1,
        C_INCLUDE_DATAWIDTH_MATCHING_2,
        C_INCLUDE_DATAWIDTH_MATCHING_3);

constant C_PAGEMODE_FLASH : EMC_ARRAY_TYPE :=
       (C_PAGEMODE_FLASH_0,
        C_PAGEMODE_FLASH_1,
        C_PAGEMODE_FLASH_2,
        C_PAGEMODE_FLASH_3);        
        

-------------------------------------------------------------------------------
-- Create global constants that indicate if any data matching is needed or if
-- any memories are synchronous. These can be used to eliminate un-necessary
-- logic.
-------------------------------------------------------------------------------
constant GLOBAL_SYNC_MEM    : integer range 0 to 1
                                := not_all_zeros(SYNCH_MEM_ARRAY,
                   C_NUM_BANKS_MEM);

constant GLOBAL_DATAWIDTH_MATCH : integer range 0 to 1
                                := not_all_zeros(DATAWIDTH_MATCH_ARRAY,
                   C_NUM_BANKS_MEM);
                   
constant PAGEMODE_FLASH : integer range 0 to 1
                                := not_all_zeros(C_PAGEMODE_FLASH,
                   C_NUM_BANKS_MEM);

-------------------------------------------------------------------------------
-- Memory Cycle Time Calculations
-------------------------------------------------------------------------------
-- Read Cycle (maximum of CE or Address Change to Valid Data)
-- Note: Minimum 1 extra clock is required to interface from the asynchronous
-- environment to a synchronous environment.
-------------------------------------------------------------------------------

constant TRD_CLKS_0 : integer range 0 to 31
                        := ((max2(1,max2(C_TCEDV_PS_MEM_0,
                             C_TAVDV_PS_MEM_0))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TRD_CLKS_1 : integer range 0 to 31
                        := ((max2(1,max2(C_TCEDV_PS_MEM_1,
                             C_TAVDV_PS_MEM_1))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TRD_CLKS_2 : integer range 0 to 31
                        := ((max2(1,max2(C_TCEDV_PS_MEM_2,
                             C_TAVDV_PS_MEM_2))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TRD_CLKS_3 : integer range 0 to 31
                        := ((max2(1,max2(C_TCEDV_PS_MEM_3,
                             C_TAVDV_PS_MEM_3))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TRDCNT_0   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TRD_CLKS_0+1, 5);
                    
constant TRDCNT_1   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TRD_CLKS_1+1, 5);

constant TRDCNT_2   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TRD_CLKS_2+1, 5);

constant TRDCNT_3   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TRD_CLKS_3+1, 5);


constant TRD_TPACC_0 :integer range 0 to 31
          := (C_TPACC_PS_FLASH_0/C_BUS_CLOCK_PERIOD_PS);

constant TRD_TPACC_1 :integer range 0 to 31
          := (C_TPACC_PS_FLASH_1/C_BUS_CLOCK_PERIOD_PS);
         
constant TRD_TPACC_2 :integer range 0 to 31
          := (C_TPACC_PS_FLASH_2/C_BUS_CLOCK_PERIOD_PS);

constant TRD_TPACC_3 :integer range 0 to 31
          := (C_TPACC_PS_FLASH_3/C_BUS_CLOCK_PERIOD_PS);
                   
constant TPACC_0    : std_logic_vector(0 to 4)
            := conv_std_logic_vector(TRD_TPACC_0+1, 5);
            
constant TPACC_1    : std_logic_vector(0 to 4)
            := conv_std_logic_vector(TRD_TPACC_1+1, 5);

constant TPACC_2    : std_logic_vector(0 to 4)
            := conv_std_logic_vector(TRD_TPACC_2+1, 5);
            
constant TPACC_3    : std_logic_vector(0 to 4)
            := conv_std_logic_vector(TRD_TPACC_3+1, 5);
            

-------------------------------------------------------------------------------
-- Read Cycle End to Data Bus High Impedance
-------------------------------------------------------------------------------
constant THZ_CLKS_0 : integer range 0 to 31
                        := ((max2(1,max2(C_THZCE_PS_MEM_0,
                             C_THZOE_PS_MEM_0))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant THZ_CLKS_1 : integer range 0 to 31
                        := ((max2(1,max2(C_THZCE_PS_MEM_1,
                             C_THZOE_PS_MEM_1))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant THZ_CLKS_2 : integer range 0 to 31
                        := ((max2(1,max2(C_THZCE_PS_MEM_2,
                             C_THZOE_PS_MEM_2))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant THZ_CLKS_3 : integer range 0 to 31
                        := ((max2(1,max2(C_THZCE_PS_MEM_2,
                             C_THZOE_PS_MEM_3))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant THZCNT_0   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(THZ_CLKS_0+1, 5);

constant THZCNT_1   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(THZ_CLKS_1+1, 5);

constant THZCNT_2   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(THZ_CLKS_2+1, 5);

constant THZCNT_3   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(THZ_CLKS_3+1, 5);

-------------------------------------------------------------------------------
-- Write Cycle to Data Store
-------------------------------------------------------------------------------

constant TWR_CLKS_0 : integer range 0 to 31
                        := ((max2(1,max2(C_TWC_PS_MEM_0,
                             C_TWP_PS_MEM_0))-1)
                                     /C_BUS_CLOCK_PERIOD_PS);

constant TWR_CLKS_1 : integer range 0 to 31
                        := ((max2(1,max2(C_TWC_PS_MEM_1,
                             C_TWP_PS_MEM_1))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TWR_CLKS_2 : integer range 0 to 31
                        := ((max2(1,max2(C_TWC_PS_MEM_2,
                             C_TWP_PS_MEM_2))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TWR_CLKS_3 : integer range 0 to 31
                        := ((max2(1,max2(C_TWC_PS_MEM_3,
                             C_TWP_PS_MEM_3))-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TWRCNT_0   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TWR_CLKS_0+1, 5);

constant TWRCNT_1   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TWR_CLKS_1+1, 5);

constant TWRCNT_2   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TWR_CLKS_2+1, 5);

constant TWRCNT_3   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TWR_CLKS_3+1, 5);
                        
                        
------------------------------------------------------------------------------
-- Write Cycle End Data Hold Time
-------------------------------------------------------------------------------
constant TLZ_CLKS_0 : integer range 0 to 31
                        := ((max2(1,C_TLZWE_PS_MEM_0)-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TLZ_CLKS_1 : integer range 0 to 31
                        := ((max2(1,C_TLZWE_PS_MEM_1)-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TLZ_CLKS_2 : integer range 0 to 31
                        := ((max2(1,C_TLZWE_PS_MEM_2)-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TLZ_CLKS_3 : integer range 0 to 31
                        := ((max2(1,C_TLZWE_PS_MEM_3)-1)
                             /C_BUS_CLOCK_PERIOD_PS);

constant TLZCNT_0   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TLZ_CLKS_0+1, 5);

constant TLZCNT_1   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TLZ_CLKS_1+1, 5);

constant TLZCNT_2   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TLZ_CLKS_2+1, 5);

constant TLZCNT_3   : std_logic_vector(0 to 4)
                        := conv_std_logic_vector(TLZ_CLKS_3+1, 5);

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
-- Write Cycle Time
signal twr_data           : std_logic_vector(0 to 4);
signal twr_load           : std_logic;
signal twr_cnt_en         : std_logic;
signal twr_end            : std_logic;

-- Write Cycle End To Data Bus Low-Z
signal tlz_data           : std_logic_vector(0 to 4);
signal tlz_load           : std_logic;
signal Tlz_cnt_en         : std_logic;
signal tlz_end            : std_logic;

-- Read Cycle End To Data Bus High-Z
signal thz_data           : std_logic_vector(0 to 4);
signal thz_load           : std_logic;
signal Thz_cnt_en         : std_logic;
signal thz_end            : std_logic;

-- Read Cycle Address Change to Valid Data
signal trd_data           : std_logic_vector(0 to 4);
signal trd_load           : std_logic;
signal trd_cnt_en         : std_logic;
signal trd_end            : std_logic;

-- Read Cycle Address Change to Valid Data
signal tpacc_data         : std_logic_vector(0 to 4);
signal tpacc_load         : std_logic;
signal tpacc_cnt_en       : std_logic;
signal tpacc_end          : std_logic;


-- Memory Access IPIC Signals
signal bus2ip_cs_reg      : std_logic_vector(0 to C_NUM_BANKS_MEM-1);
signal cs_Strobe          : std_logic;
signal new_page_access    : std_logic;
signal bus2Mem_CS         : std_logic;
signal bus2Mem_RdReq      : std_logic;
signal bus2Mem_WrReq      : std_logic;
signal mem2Bus_RdAck      : std_logic;
signal mem2Bus_WrAck      : std_logic;
signal mem2Bus_RdAddrAck  : std_logic;
signal mem2Bus_WrAddrAck  : std_logic;
signal mem2Bus_Data       : std_logic_vector(0 to C_IPIF_DWIDTH - 1);

signal write_req_ack      : std_logic;
signal read_req_ack       : std_logic;
signal read_data_en       : std_logic;
signal read_ack           : std_logic;

-- Memory Control Internal Signals
signal mem_CEN_cmb        : std_logic;
signal mem_OEN_cmb        : std_logic;
signal mem_WEN_cmb        : std_logic;

signal bus2ip_ben_int     : std_logic_vector(0 to C_IPIF_DWIDTH/8-1);
signal mem_a_int          : std_logic_vector(0 to C_IPIF_AWIDTH-1);
signal mem_dq_i_int       : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal mem_dq_o_int       : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal mem_dq_t_int       : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal mem_cen_int        : std_logic_vector(0 to C_NUM_BANKS_MEM-1);
signal mem_oen_int        : std_logic_vector(0 to C_NUM_BANKS_MEM-1);
signal mem_wen_int        : std_logic;
signal mem_qwen_int       : std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
signal mem_ben_int        : std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
signal mem_rpn_int        : std_logic;
signal mem_ce_int         : std_logic_vector(0 to C_NUM_BANKS_MEM-1);
signal mem_adv_ldn_int    : std_logic;
signal mem_lbon_int       : std_logic;
signal mem_cken_int       : std_logic;
signal mem_rnw_int        : std_logic;
signal mem_be_int         : std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);

-- Data Width Matching Address Management
signal addr_cnt_ce        : std_logic;
signal addr_cnt_rst       : std_logic;
signal addr_cnt           : std_logic_vector(0 to ADDR_CNTR_WIDTH-1);
signal addr_align         : std_logic;
signal addr_align_rd      : std_logic;
signal addr_align_write   : std_logic;


signal cycle_cnt_en       : std_logic;
signal cycle_cnt_ld       : std_logic;
signal cycle_End          : std_logic;
signal address_strobe     : std_logic;
signal data_strobe        : std_logic;

-- Access Parameters
signal mem_width_bytes    : std_logic_vector(0 to 3);
signal datawidth_match    : std_logic;
signal synch_mem          : std_logic;
signal two_pipe_delay     : std_logic;
signal ip2Bus_RdAck_i     : std_logic;

signal Mem_Addr_rst       : std_logic;
signal transaction_done_i : std_logic;
-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin

mem_rpn_int     <= not Bus2IP_Reset;
mem_adv_ldn_int <= '0';
mem_lbon_int    <= '0';
mem_cken_int    <= '0';
IP2Bus_RdAck    <= ip2Bus_RdAck_i;

    ---------------------------------------------------------------------------
    -- Store the Chip Select Coming from IPIF in case C_NUM_BANKS_MEM > 1
    ---------------------------------------------------------------------------

    CS_STORE_GEN: if (C_NUM_BANKS_MEM > 1) generate
    begin
        CS_STORE_PROCESS:process(Bus2IP_Clk)
        begin

            if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
                if Bus2IP_Reset = '1' then
                    bus2ip_cs_reg  <= (others=>'0');
                elsif (cs_Strobe = '1' ) then
                    bus2ip_cs_reg  <= Bus2IP_Mem_CS;
                end if;
           end if;
        end process CS_STORE_PROCESS;
    end generate CS_STORE_GEN;
    
    ---------------------------------------------------------------------------
    -- Pass on the Chip Select Coming from IPIF in case C_NUM_BANKS_MEM = 1
    ---------------------------------------------------------------------------
    
    CS_PASS_GEN: if (C_NUM_BANKS_MEM = 1) generate
    begin
        bus2ip_cs_reg  <= Bus2IP_Mem_CS;
    end generate CS_PASS_GEN;

-------------------------------------------------------------------------------
-- IPIC Interface
-------------------------------------------------------------------------------

IPIC_IF_I : entity emc_common_v4_01_a.ipic_if
    generic map (
        C_NUM_BANKS_MEM   => C_NUM_BANKS_MEM,
        C_SPLB_DWIDTH     => C_SPLB_DWIDTH,
        C_IPIF_DWIDTH     => C_IPIF_DWIDTH
    )
    port map (
        Bus2IP_RNW        => Bus2IP_RNW,
        Bus2IP_Mem_CS     => Bus2IP_Mem_CS,

        Mem2Bus_RdAddrAck => mem2Bus_RdAddrAck,
        Mem2Bus_WrAddrAck => mem2Bus_WrAddrAck,
        Mem2Bus_RdAck     => mem2Bus_RdAck,
        Mem2Bus_WrAck     => mem2Bus_WrAck,
        Mem2Bus_Data      => mem2Bus_Data,

        Burst_length      => Bus2IP_BurstLength,
        Transaction_done  => transaction_done_i,

        Bus2Mem_CS        => bus2Mem_CS,
        Bus2Mem_RdReq     => bus2Mem_RdReq,
        Bus2Mem_WrReq     => bus2Mem_WrReq,

        IP2Bus_Data       => IP2Bus_Data,
        IP2Bus_errAck     => IP2Bus_errAck,
        IP2Bus_retry      => IP2Bus_retry,
        IP2Bus_toutSup    => IP2Bus_toutSup,
        IP2Bus_RdAck      => ip2Bus_RdAck_i,
        IP2Bus_WrAck      => IP2Bus_WrAck,
        IP2Bus_AddrAck    => IP2Bus_AddrAck,

        Bus2IP_Clk        => Bus2IP_Clk,
        Bus2IP_Reset      => Bus2IP_Reset
    );

-------------------------------------------------------------------------------
-- Memory State Machine
-------------------------------------------------------------------------------

MEM_STATE_MACHINE_I : entity emc_common_v4_01_a.mem_state_machine
    port map (
        Bus2IP_RNW       => Bus2IP_RNW,
        Bus2IP_RdReq     => bus2Mem_RdReq,
        Bus2IP_WrReq     => Bus2Mem_WrReq,
        Synch_mem        => synch_mem,
        Two_pipe_delay   => two_pipe_delay,
        Cycle_End        => cycle_End,

        Read_data_en     => read_data_en,
        Read_ack         => read_ack,

        Address_strobe   => address_strobe,
        Data_strobe      => data_strobe,
        CS_Strobe        => cs_Strobe,

        Addr_cnt_ce      => addr_cnt_ce,
        Addr_cnt_rst     => addr_cnt_rst,
        Cycle_cnt_ld     => cycle_cnt_ld,
        Cycle_cnt_en     => cycle_cnt_en,

        Trd_cnt_en       => trd_cnt_en,
        Twr_cnt_en       => twr_cnt_en,
        Tpacc_cnt_en     => tpacc_cnt_en,
        Trd_load         => trd_load,
        Twr_load         => twr_load,
        Tpacc_load       => tpacc_load,

        Thz_load         => thz_load,
        Tlz_load         => tlz_load,
        Trd_end          => trd_end,
        Twr_end          => twr_end,
        Thz_end          => thz_end,
        Tlz_end          => tlz_end,
        Tpacc_end          => Tpacc_end,
        
        New_page_access  => new_page_access,

        MSM_Mem_CEN      => mem_CEN_cmb,
        MSM_Mem_OEN      => mem_OEN_cmb,
        MSM_Mem_WEN      => mem_WEN_cmb,
        
        Addr_align       => addr_align_write,
        Addr_align_rd    => addr_align_rd,

        Write_req_ack    => write_req_ack,
        Read_req_ack     => read_req_ack,
        Transaction_done => transaction_done_i,
        Mem_Addr_rst     => Mem_Addr_rst,

        Clk              => Bus2IP_Clk,
        Rst              => Bus2IP_Reset
    );

-------------------------------------------------------------------------------
-- Datawidth Matching Address Counter
-------------------------------------------------------------------------------

ADDR_COUNTER_MUX_I : entity emc_common_v4_01_a.addr_counter_mux
    generic map (
        C_ADDR_CNTR_WIDTH        => ADDR_CNTR_WIDTH,
        C_IPIF_DWIDTH            => C_IPIF_DWIDTH,
        C_IPIF_AWIDTH            => C_IPIF_AWIDTH,
        C_ADDR_OFFSET            => ADDR_OFFSET,
        C_GLOBAL_DATAWIDTH_MATCH => GLOBAL_DATAWIDTH_MATCH
    )
    port map (
        Bus2IP_Addr              => Bus2IP_Addr,
        Bus2IP_BE                => Bus2IP_BE,
        Address_strobe           => address_strobe,
        Data_strobe              => data_strobe,

        Mem_width_bytes          => mem_width_bytes,
        Datawidth_match          => datawidth_match,

        Addr_cnt_ce              => addr_cnt_ce,
        Addr_cnt_rst             => addr_cnt_rst,
        Addr_cnt                 => addr_cnt,
        Addr_align               => addr_align_write,

        Cycle_cnt_ld             => cycle_cnt_ld,
        Cycle_cnt_en             => cycle_cnt_en,
        Cycle_End                => cycle_End,
        Mem_addr                 => Mem_A_int,
        Mem_Ben                  => bus2ip_ben_int,

        Clk                      => Bus2IP_Clk,
        Rst                      => Bus2IP_Reset
    );

-------------------------------------------------------------------------------
-- Asynchronous Memory Cycle Timers
-------------------------------------------------------------------------------

COUNTERS_I: entity emc_common_v4_01_a.counters
    port map (
        Synch_mem  => synch_mem,

        Twr_data   => twr_data,
        Twr_load   => twr_load,
        Twr_cnt_en => twr_cnt_en,
        Tlz_data   => tlz_data,
        Tlz_load   => tlz_load,
        Trd_data   => trd_data,
        Trd_load   => trd_load,
        Trd_cnt_en => trd_cnt_en,
        Tpacc_data   => tpacc_data,
    Tpacc_load   => tpacc_load,
    Tpacc_cnt_en => tpacc_cnt_en,
               
        
        Thz_data   => thz_data,
        Thz_load   => thz_load,
        Twr_end    => twr_end,
        Tlz_end    => tlz_end,
        Trd_end    => trd_end,
        Thz_end    => thz_end,
        Tpacc_end  => Tpacc_end,

        Clk        => Bus2IP_Clk,
        Rst        => Bus2IP_Reset
    );

-------------------------------------------------------------------------------
-- Memory Paramter Selector
-------------------------------------------------------------------------------

SELECT_PARAM_I: entity emc_common_v4_01_a.select_param
    generic map (
        C_NUM_BANKS_MEM                 => C_NUM_BANKS_MEM,
        C_GLOBAL_SYNC_MEM               => GLOBAL_SYNC_MEM,
        C_SYNCH_MEM_0                   => C_SYNCH_MEM_0,
        C_SYNCH_MEM_1                   => C_SYNCH_MEM_1,
        C_SYNCH_MEM_2                   => C_SYNCH_MEM_2,
        C_SYNCH_MEM_3                   => C_SYNCH_MEM_3,

        C_MEM0_WIDTH                    => C_MEM0_WIDTH,
        C_MEM1_WIDTH                    => C_MEM1_WIDTH,
        C_MEM2_WIDTH                    => C_MEM2_WIDTH,
        C_MEM3_WIDTH                    => C_MEM3_WIDTH,
        
        C_PAGEMODE_FLASH		=> PAGEMODE_FLASH,
        C_PAGEMODE_FLASH_0              => C_PAGEMODE_FLASH_0,
        C_PAGEMODE_FLASH_1              => C_PAGEMODE_FLASH_1,
        C_PAGEMODE_FLASH_2              => C_PAGEMODE_FLASH_2,
        C_PAGEMODE_FLASH_3              => C_PAGEMODE_FLASH_3,

        C_SYNCH_PIPEDELAY_0             => C_SYNCH_PIPEDELAY_0,
        C_SYNCH_PIPEDELAY_1             => C_SYNCH_PIPEDELAY_1,
        C_SYNCH_PIPEDELAY_2             => C_SYNCH_PIPEDELAY_2,
        C_SYNCH_PIPEDELAY_3             => C_SYNCH_PIPEDELAY_3,

        C_GLOBAL_DATAWIDTH_MATCH        => GLOBAL_DATAWIDTH_MATCH,
        C_INCLUDE_DATAWIDTH_MATCHING_0  => C_INCLUDE_DATAWIDTH_MATCHING_0,
        C_INCLUDE_DATAWIDTH_MATCHING_1  => C_INCLUDE_DATAWIDTH_MATCHING_1,
        C_INCLUDE_DATAWIDTH_MATCHING_2  => C_INCLUDE_DATAWIDTH_MATCHING_2,
        C_INCLUDE_DATAWIDTH_MATCHING_3  => C_INCLUDE_DATAWIDTH_MATCHING_3,

        TRDCNT_0                        => TRDCNT_0,
        TRDCNT_1                        => TRDCNT_1,
        TRDCNT_2                        => TRDCNT_2,
        TRDCNT_3                        => TRDCNT_3,

        THZCNT_0                        => THZCNT_0,
        THZCNT_1                        => THZCNT_1,
        THZCNT_2                        => THZCNT_2,
        THZCNT_3                        => THZCNT_3,

        TWRCNT_0                        => TWRCNT_0,
        TWRCNT_1                        => TWRCNT_1,
        TWRCNT_2                        => TWRCNT_2,
        TWRCNT_3                        => TWRCNT_3,
        
        C_IPIF_AWIDTH                   => C_IPIF_AWIDTH,
        C_IPIF_DWIDTH                   => C_IPIF_DWIDTH,
        
        
        TPACC_0                         => TPACC_0,
        TPACC_1                         => TPACC_1,
        TPACC_2                         => TPACC_2,
        TPACC_3                         => TPACC_3,

        TLZCNT_0                        => TLZCNT_0,
        TLZCNT_1                        => TLZCNT_1,
        TLZCNT_2                        => TLZCNT_2,
        TLZCNT_3                        => TLZCNT_3
    )
    port map (
        Bus2IP_Mem_CS                   => bus2ip_cs_reg,
        Bus2IP_Addr                     => Bus2IP_Addr,
        Bus2IP_Clk                      => Bus2IP_Clk,
        Bus2IP_Reset                    => Bus2IP_Reset,
        Bus2IP_RNW                      => Bus2IP_RNW,
        
        New_page_access                 => new_page_access,

        Twr_data                        => twr_data,
        Tlz_data                        => tlz_data,
        Trd_data                        => trd_data,
        Thz_data                        => thz_data,
        Tpacc_data                      => tpacc_data,
        Synch_mem                       => synch_mem,
        Mem_width_bytes                 => mem_width_bytes,
        Two_pipe_delay                  => two_pipe_delay,
        Datawidth_match                 => datawidth_match
    );

-------------------------------------------------------------------------------
-- Memory Data/Control Steering Logic
-------------------------------------------------------------------------------

MEM_STEER_I : entity emc_common_v4_01_a.mem_steer
    generic map(
        C_NUM_BANKS_MEM          => C_NUM_BANKS_MEM,
        C_MAX_MEM_WIDTH          => C_MAX_MEM_WIDTH,
        C_MIN_MEM_WIDTH          => MIN_MEM_WIDTH,
        C_IPIF_DWIDTH            => C_IPIF_DWIDTH,
        C_ADDR_CNTR_WIDTH        => ADDR_CNTR_WIDTH,
        C_GLOBAL_SYNC_MEM        => GLOBAL_SYNC_MEM,
        C_GLOBAL_DATAWIDTH_MATCH => GLOBAL_DATAWIDTH_MATCH
    )
    port map(
        Bus2IP_Data              => Bus2IP_Data,
        Bus2IP_BE                => bus2ip_ben_int,
        Bus2IP_Mem_CS            => bus2ip_cs_reg,

        Write_req_ack            => write_req_ack,
        Read_req_ack             => read_req_ack,
        Read_ack                 => read_ack,
        Read_data_en             => read_data_en,

        Data_strobe              => data_strobe,

        Mem2Bus_WrAddrAck        => mem2Bus_WrAddrAck,
        Mem2Bus_WrAck            => mem2Bus_WrAck,
        Mem2Bus_RdAddrAck        => mem2Bus_RdAddrAck,
        Mem2Bus_RdAck            => mem2Bus_RdAck,
        Mem2Bus_Data             => mem2Bus_Data,

        MSM_Mem_CEN              => mem_CEN_cmb,
        MSM_Mem_OEN              => mem_OEN_cmb,
        MSM_Mem_WEN              => mem_WEN_cmb,

        Mem_width_bytes          => mem_width_bytes,
        Synch_mem                => synch_mem,
        Two_pipe_delay           => two_pipe_delay,
        Addr_cnt                 => addr_cnt,
        Addr_align               => addr_align_write,
        Addr_align_rd            => addr_align_rd,
        
        MemSteer_Mem_DQ_I        => mem_dq_i_int,
        MemSteer_Mem_DQ_O        => mem_dq_o_int,
        MemSteer_Mem_DQ_T        => mem_dq_t_int,
        MemSteer_Mem_CEN         => mem_cen_int,
        MemSteer_Mem_OEN         => mem_oen_int,
        MemSteer_Mem_WEN         => mem_wen_int,
        MemSteer_Mem_QWEN        => mem_qwen_int,
        MemSteer_Mem_BEN         => mem_ben_int,
        MemSteer_Mem_CE          => mem_ce_int,
        MemSteer_Mem_RNW         => mem_rnw_int,

        Clk                      => Bus2IP_Clk,
        Rst                      => Bus2IP_Reset
    );

-------------------------------------------------------------------------------
-- Instantiate the IO register block to memory
-- IO registers will be instantiated based on the parameter settings
-------------------------------------------------------------------------------

IO_REGISTERS_I: entity emc_common_v4_01_a.io_registers
    generic map (
        C_INCLUDE_NEGEDGE_IOREGS => C_INCLUDE_NEGEDGE_IOREGS,
        C_IPIF_AWIDTH            => C_IPIF_AWIDTH,
        C_MAX_MEM_WIDTH          => C_MAX_MEM_WIDTH,
        C_NUM_BANKS_MEM          => C_NUM_BANKS_MEM
    )
    port map (
        Mem_A_int                => mem_a_int,
        Mem_DQ_I_int             => mem_dq_i_int,
        Mem_DQ_O_int             => mem_dq_o_int,
        Mem_DQ_T_int             => mem_dq_t_int,
        Mem_CEN_int              => mem_cen_int,
        Mem_OEN_int              => mem_oen_int,
        Mem_WEN_int              => mem_wen_int,
        Mem_QWEN_int             => mem_qwen_int,
        Mem_BEN_int              => mem_ben_int,
        Mem_RPN_int              => mem_rpn_int,
        Mem_CE_int               => mem_ce_int,
        Mem_ADV_LDN_int          => mem_adv_ldn_int,
        Mem_LBON_int             => mem_lbon_int,
        Mem_CKEN_int             => mem_cken_int,
        Mem_RNW_int              => mem_rnw_int,

        Mem_A                    => Mem_A,
        Mem_DQ_I                 => Mem_DQ_I,
        Mem_DQ_O                 => Mem_DQ_O,
        Mem_DQ_T                 => Mem_DQ_T,
        Mem_CEN                  => Mem_CEN,
        Mem_OEN                  => Mem_OEN,
        Mem_WEN                  => Mem_WEN,
        Mem_QWEN                 => Mem_QWEN,
        Mem_BEN                  => Mem_BEN,
        Mem_RPN                  => Mem_RPN,
        Mem_CE                   => Mem_CE,
        Mem_ADV_LDN              => Mem_ADV_LDN,
        Mem_LBON                 => Mem_LBON,
        Mem_CKEN                 => Mem_CKEN,
        Mem_RNW                  => Mem_RNW,

        Mem_Addr_rst             => Mem_Addr_rst,

        Clk                      => Bus2IP_Clk,
        RdClk                    => RdClk,
        Rst                      => Bus2IP_Reset
    );

end architecture imp;
-------------------------------------------------------------------------------
-- End of File emc.vhd
-------------------------------------------------------------------------------
