-------------------------------------------------------------------------------
-- XPS_GPIO - entity/architecture pair 
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
-- Filename:        xps_gpio.vhd
-- Version:         v2.00a
-- Description:     General Purpose I/O for PLBV46 bus
--
-------------------------------------------------------------------------------
-- Structure:   
--                  xps_gpio.vhd
--                        -- plbv46_slave_single.vhd
--                        -- interrupt_control.vhd
--                        -- gpio_core.vhd
--
-------------------------------------------------------------------------------
--
-- Author:          VKN
-- History:   
-- ~~~~~~~~~~~~~~
--   VKN                02/08/07
-- ^^^^^^^^^^^^^^
--  First version of xps_gpio. Based on OPB GPIO 3.01b
-- ~~~~~~~~~~~~~~
--   KSB                12/11/08
-- ^^^^^^^^^^^^^^
--  1) IPIF Updates for proc_common_v3
--  2) Fix on CR 470471 - Removed GPIO_in GPIO_d_out PORT GPIO_IO_T
--  3) Fix on 468878    - Unused and redundant code has been removed 
--  4) Fix on 424212    - separate GPIO_WIDTH (C_GPIO_WIDTH, C_GPIO2_WIDTH)
--                     parameters for the 2 channels

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

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for different
-- function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.ipif_pkg.calc_num_ce;
use proc_common_v3_00_a.ipif_pkg.INTEGER_ARRAY_TYPE;
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;

-------------------------------------------------------------------------------
-- xps_gpio_v2_00_a library is used for plbv46 component declarations
-------------------------------------------------------------------------------

library plbv46_slave_single_v1_01_a; 

-------------------------------------------------------------------------------
-- xps_gpio_v2_00_a library is used for interrupt controller component 
-- declarations
-------------------------------------------------------------------------------

library interrupt_control_v2_01_a; 

-------------------------------------------------------------------------------
-- xps_gpio_v2_00_a library is used for xps_gpio component declarations
-------------------------------------------------------------------------------

library xps_gpio_v2_00_a; 

-------------------------------------------------------------------------------
--                     Defination of Generics :                              --
-------------------------------------------------------------------------------
-- C_BASEADDR            -- XPS GPIO Base Address
-- C_HIGHADDR            -- XPS GPIO High Address
-- C_SPLB_AWIDTH         -- Width of the PLB address bus
-- C_SPLB_DWIDTH         -- width of the PLB data bus
-- C_SPLB_P2P            -- Selects point to point or shared topology
-- C_SPLB_MID_WIDTH      -- PLB Master ID bus width
-- C_SPLB_NUM_MASTERS    -- Number of PLB masters 
-- C_SPLB_NATIVE_DWIDTH  -- Slave bus data width
-- C_SPLB_SUPPORT_BURSTS -- Burst/no burst support
-- C_FAMILY              -- XILINX FPGA family
-- C_ALL_INPUTS          -- Channel Inputs only.
-- C_ALL_INPUTS_2        -- Channel2 Inputs only.
-- C_GPIO_WIDTH          -- GPIO Data Bus width
-- C_GPIO2_WIDTH         -- GPIO2 Data Bus width
-- C_INTERRUPT_PRESENT   -- GPIO Interrupt
-- C_DOUT_DEFAULT        -- GPIO_DATA Register reset value
-- C_TRI_DEFAULT         -- GPIO_TRI Register reset value
-- C_IS_DUAL             -- Dual Channel GPIO
-- C_DOUT_DEFAULT_2      -- GPIO2_DATA Register reset value
-- C_TRI_DEFAULT_2       -- GPIO2_TRI Register reset value
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
--                  Defination of Ports                                      --
-------------------------------------------------------------------------------

--   PLB Slave Signals 
--      PLB_ABus                -- PLB address bus          
--      PLB_UABus               -- PLB upper address bus
--      PLB_PAValid             -- PLB primary address valid
--      PLB_SAValid             -- PLB secondary address valid
--      PLB_rdPrim              -- PLB secondary to primary read request
--      PLB_wrPrim              -- PLB secondary to primary write request
--      PLB_masterID            -- PLB current master identifier
--      PLB_abort               -- PLB abort request
--      PLB_busLock             -- PLB bus lock
--      PLB_RNW                 -- PLB read not write
--      PLB_BE                  -- PLB byte enable
--      PLB_MSize               -- PLB data bus width indicator
--      PLB_size                -- PLB transfer size
--      PLB_type                -- PLB transfer type
--      PLB_lockErr             -- PLB lock error
--      PLB_wrDBus              -- PLB write data bus
--      PLB_wrBurst             -- PLB burst write transfer
--      PLB_rdBurst             -- PLB burst read transfer
--      PLB_wrPendReq           -- PLB pending bus write request
--      PLB_rdPendReq           -- PLB pending bus read request
--      PLB_wrPendPri           -- PLB pending bus write request priority
--      PLB_rdPendPri           -- PLB pending bus read request priority
--      PLB_reqPri              -- PLB current request 
--      PLB_TAttribute          -- PLB transfer attribute
--   Slave Responce Signal
--      Sl_addrAck              -- Slave address ack
--      Sl_SSize                -- Slave data bus size
--      Sl_wait                 -- Slave wait indicator
--      Sl_rearbitrate          -- Slave rearbitrate
--      Sl_wrDAck               -- Slave write data ack
--      Sl_wrComp               -- Slave write complete
--      Sl_wrBTerm              -- Slave terminate write burst transfer
--      Sl_rdDBus               -- Slave read data bus
--      Sl_rdWdAddr             -- Slave read word address
--      Sl_rdDAck               -- Slave read data ack
--      Sl_rdComp               -- Slave read complete
--      Sl_rdBTerm              -- Slave terminate read burst transfer
--      Sl_MBusy                -- Slave busy
--      Sl_MWrErr               -- Slave write error
--      Sl_MRdErr               -- Slave read error
--      Sl_MIRQ                 -- Master interrput 
--    GPIO Signals
--      GPIO_IO_I               -- Channel 1 General purpose I/O in port
--      GPIO_IO_O               -- Channel 1 General purpose I/O out port
--      GPIO_IO_T               -- Channel 1 General purpose I/O 
--				-- TRI-STATE control port
--      GPIO2_IO_I              -- Channel 2 General purpose I/O in port
--      GPIO2_IO_O              -- Channel 2 General purpose I/O out port
--      GPIO2_IO_T              -- Channel 2 General purpose I/O 
--				-- TRI-STATE control port
--    System Signals
--      SPLB_Clk                -- System clock
--      SPLB_Rst                -- System Reset (active high)
--      IP2INTC_Irpt            -- XPS GPIO Interrupt

-------------------------------------------------------------------------------

entity xps_gpio is  
  generic
  (
    C_BASEADDR           : std_logic_vector(0 to 31) := X"FFFFFFFF";
    C_HIGHADDR           : std_logic_vector(0 to 31) := X"00000000";
    C_SPLB_AWIDTH        : integer range 32 to 32    := 32;
    C_SPLB_DWIDTH        : integer range 32 to 128   := 32;
    C_SPLB_P2P           : integer range 0 to 1      := 0;
    C_SPLB_MID_WIDTH     : integer range 1 to 4      := 1;
    C_SPLB_NUM_MASTERS   : integer range 1 to 16     := 1;
    C_SPLB_NATIVE_DWIDTH : integer range 32 to 32    := 32;    
    C_SPLB_SUPPORT_BURSTS: integer range 0 to 1      := 0;    
    C_FAMILY             : string                    := "virtex5";
    C_ALL_INPUTS         : integer range 0 to 1      := 0;
    C_ALL_INPUTS_2       : integer range 0 to 1      := 0;
    C_GPIO_WIDTH         : integer range 1 to 32     := 32;
    C_GPIO2_WIDTH        : integer range 1 to 32     := 32;
    C_INTERRUPT_PRESENT  : integer range 0 to 1      := 0;
    C_DOUT_DEFAULT       : std_logic_vector          := X"0000_0000";
    C_TRI_DEFAULT        : std_logic_vector          := X"FFFF_FFFF";
    C_IS_DUAL            : integer range 0 to 1      := 0;
    C_DOUT_DEFAULT_2     : std_logic_vector          := X"0000_0000";
    C_TRI_DEFAULT_2      : std_logic_vector          := X"FFFF_FFFF"
  );
  port
  (
    -- System signals ---------------------------------------------------------
    SPLB_Clk             : in std_logic;
    SPLB_Rst             : in std_logic;
    -- Bus Slave signals ------------------------------------------------------  
    PLB_ABus             : in  std_logic_vector(0 to 31);
    PLB_UABus            : in  std_logic_vector(0 to 31);
    PLB_PAValid          : in  std_logic;
    PLB_SAValid          : in  std_logic;
    PLB_rdPrim           : in  std_logic;
    PLB_wrPrim           : in  std_logic;
    PLB_masterID         : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort            : in  std_logic;
    PLB_busLock          : in  std_logic;
    PLB_RNW              : in  std_logic;
    PLB_BE               : in  std_logic_vector(0 to (C_SPLB_DWIDTH/8)-1);
    PLB_MSize            : in  std_logic_vector(0 to 1);
    PLB_size             : in  std_logic_vector(0 to 3);
    PLB_type             : in  std_logic_vector(0 to 2);
    PLB_lockErr          : in  std_logic;
    PLB_wrDBus           : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst          : in  std_logic;
    PLB_rdBurst          : in  std_logic;   
    PLB_wrPendReq        : in  std_logic; 
    PLB_rdPendReq        : in  std_logic; 
    PLB_wrPendPri        : in  std_logic_vector(0 to 1); 
    PLB_rdPendPri        : in  std_logic_vector(0 to 1); 
    PLB_reqPri           : in  std_logic_vector(0 to 1);
    PLB_TAttribute       : in  std_logic_vector(0 to 15); 

    -- Slave Responce Signals--------------------------------------------------
    Sl_addrAck           : out std_logic;
    Sl_SSize             : out std_logic_vector(0 to 1);
    Sl_wait              : out std_logic;
    Sl_rearbitrate       : out std_logic;
    Sl_wrDAck            : out std_logic;
    Sl_wrComp            : out std_logic;
    Sl_wrBTerm           : out std_logic;
    Sl_rdDBus            : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr          : out std_logic_vector(0 to 3);
    Sl_rdDAck            : out std_logic;
    Sl_rdComp            : out std_logic;
    Sl_rdBTerm           : out std_logic;
    Sl_MBusy             : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr            : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);                     
    Sl_MRdErr            : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);                     
    Sl_MIRQ              : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);                     
    -- Interrupt---------------------------------------------------------------
    IP2INTC_Irpt         : out std_logic;

    -- GPIO Signals------------------------------------------------------------
    GPIO_IO_I            : in  std_logic_vector(0 to C_GPIO_WIDTH-1);
    GPIO_IO_O            : out std_logic_vector(0 to C_GPIO_WIDTH-1);
    GPIO_IO_T            : out std_logic_vector(0 to C_GPIO_WIDTH-1);
    GPIO2_IO_I           : in  std_logic_vector(0 to C_GPIO2_WIDTH-1);
    GPIO2_IO_O           : out std_logic_vector(0 to C_GPIO2_WIDTH-1);
    GPIO2_IO_T           : out std_logic_vector(0 to C_GPIO2_WIDTH-1)
  );

-------------------------------------------------------------------------------
-- fan-out attributes for XST
-------------------------------------------------------------------------------

  attribute MAX_FANOUT                   : string;
  attribute MAX_FANOUT   of SPLB_Clk     : signal is "10000";
  attribute MAX_FANOUT   of SPLB_Rst     : signal is "10000";
-------------------------------------------------------------------------------
-- Attributes for MPD file
-------------------------------------------------------------------------------
  attribute IP_GROUP             : string ;
  attribute IP_GROUP of xps_gpio : entity is "LOGICORE";
  attribute MIN_SIZE             : string ;


  attribute MIN_SIZE of C_BASEADDR : constant is "0x100"; 
  attribute SIGIS                  : string ;
  attribute SIGIS of SPLB_Clk      : signal is "Clk";
  attribute SIGIS of SPLB_Rst      : signal is "Rst";
  attribute SIGIS of IP2INTC_Irpt  : signal is "INTR_LEVEL_HIGH";

  
end entity xps_gpio; 
-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------

architecture imp of xps_gpio is 

type     bo2na_type is array (boolean) of natural; -- boolean to natural 
						   -- conversion
constant bo2na      :  bo2na_type := (false => 0, true => 1);

-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------
type BOOLEAN_ARRAY_TYPE is array(natural range <>) of boolean;

----------------------------------------------------------------------------
-- This function returns the number of elements that are true in
-- a boolean array.
----------------------------------------------------------------------------
function num_set( ba : BOOLEAN_ARRAY_TYPE ) return natural is
    variable n : natural := 0;
begin
    for i in ba'range loop
        n := n + bo2na(ba(i));
    end loop;
    return n;
end;

----------------------------------------------------------------------------
-- This function returns a num_ce integer array that is constructed by
-- taking only those elements of superset num_ce integer array
-- that will be defined by the current case.
-- The superset num_ce array is given by parameter num_ce_by_ard.
-- The current case the ard elements that will be used is given
-- by parameter defined_ards.
----------------------------------------------------------------------------
function qual_ard_num_ce_array( defined_ards  : BOOLEAN_ARRAY_TYPE;
                                num_ce_by_ard : INTEGER_ARRAY_TYPE
                              ) return INTEGER_ARRAY_TYPE is
    variable res : INTEGER_ARRAY_TYPE(0 to num_set(defined_ards)-1);
    variable i : natural := 0;
    variable j : natural := defined_ards'left;
begin
    while i /= res'length loop
        while defined_ards(j) = false loop
            j := j+1;
        end loop;
        res(i) := num_ce_by_ard(j);
        i := i+1;
        j := j+1;
    end loop;
    return res;
end;


----------------------------------------------------------------------------
-- This function returns a addr_range array that is constructed by
-- taking only those elements of superset addr_range array
-- that will be defined by the current case.
-- The superset addr_range array is given by parameter addr_range_by_ard.
-- The current case the ard elements that will be used is given
-- by parameter defined_ards.
----------------------------------------------------------------------------
function qual_ard_addr_range_array( defined_ards      : BOOLEAN_ARRAY_TYPE;
                                    addr_range_by_ard : SLV64_ARRAY_TYPE
                                  ) return SLV64_ARRAY_TYPE is
    variable res : SLV64_ARRAY_TYPE(0 to 2*num_set(defined_ards)-1);
    variable i : natural := 0;
    variable j : natural := defined_ards'left;
begin
    while i /= res'length loop
        while defined_ards(j) = false loop
            j := j+1;
        end loop;
        res(i)   := addr_range_by_ard(2*j);
        res(i+1) := addr_range_by_ard((2*j)+1);
        i := i+2;
        j := j+1;
    end loop;
    return res;
end;

----------------------------------------------------------------------------
-- This function returns the maximum width amongst the two GPIO Channels
-- and if there is only one channel, it returns just the width of that
-- channel.
----------------------------------------------------------------------------
function max_width( dual_channel    : INTEGER;
                    channel1_width  : INTEGER;
                    channel2_width  : INTEGER
                  ) return INTEGER is 
begin
     if (dual_channel = 0) then
         return channel1_width;
     else
         if (channel1_width > channel2_width) then
             return channel1_width;
         else
             return channel2_width;
         end if; 
     end if;
     
end;
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant ZERO_ADDR_PAD : std_logic_vector(0 to 64-C_SPLB_AWIDTH-1) := 
                                                          (others => '0');

constant INTR_TYPE      : integer   := 5;

constant INTR_BASEADDR  : std_logic_vector(0 to 31)  
					:= C_BASEADDR or X"00000100";
constant INTR_HIGHADDR  : std_logic_vector(0 to 31)  
					:= C_BASEADDR or X"000001FF";
constant GPIO_HIGHADDR  : std_logic_vector(0 to 31)  
					:= C_BASEADDR or X"0000000F";

constant MAX_GPIO_WIDTH : integer := max_width
					(C_IS_DUAL,C_GPIO_WIDTH,C_GPIO2_WIDTH);

constant ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
    qual_ard_addr_range_array(
        (true,C_INTERRUPT_PRESENT=1),
        (ZERO_ADDR_PAD & C_BASEADDR, 
         ZERO_ADDR_PAD & GPIO_HIGHADDR,
         ZERO_ADDR_PAD & INTR_BASEADDR,
         ZERO_ADDR_PAD & INTR_HIGHADDR               
        )
    );

constant ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE :=
    qual_ard_num_ce_array(
                (true,C_INTERRUPT_PRESENT=1),
                (5,16)
    );  

constant IP_INTR_MODE_ARRAY : INTEGER_ARRAY_TYPE(0 to 0+bo2na(C_IS_DUAL=1))
                            := (others => 5);

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------

signal ip2bus_intrevent     : std_logic_vector(0 to 1);

signal GPIO_xferAck_i : std_logic;
signal Bus2IP_Data_i  : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
signal Bus2IP1_Data_i  : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
signal Bus2IP2_Data_i  : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
-- IPIC Used Signals

signal ip2bus_data    : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);

signal bus2ip_addr    : std_logic_vector(0 to C_SPLB_AWIDTH-1);
signal bus2ip_data    : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
signal bus2ip_rnw     : std_logic;
signal bus2ip_cs      : std_logic_vector(0 to 0 + 
						bo2na(C_INTERRUPT_PRESENT=1));
signal bus2ip_rdce    : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
signal bus2ip_wrce    : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
signal bus2ip_be      : std_logic_vector(0 to (C_SPLB_NATIVE_DWIDTH / 8) - 1);
signal bus2ip_clk     : std_logic;
signal bus2ip_reset   : std_logic;
signal intr2bus_data  : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
signal intr2bus_wrack : std_logic;
signal intr2bus_rdack : std_logic;
signal intr2bus_error : std_logic;

signal ip2bus_data_i  : std_logic_vector(0 to C_SPLB_NATIVE_DWIDTH-1);
signal ip2bus_wrack_i : std_logic;
signal ip2bus_rdack_i : std_logic;
signal ip2bus_error_i : std_logic;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

begin -- architecture IMP

  PLBV46_I : entity plbv46_slave_single_v1_01_a.plbv46_slave_single
    generic map
    (
      C_ARD_ADDR_RANGE_ARRAY      => ARD_ADDR_RANGE_ARRAY,
      C_ARD_NUM_CE_ARRAY          => ARD_NUM_CE_ARRAY,
      C_SPLB_P2P                  => C_SPLB_P2P,
      C_SPLB_MID_WIDTH            => C_SPLB_MID_WIDTH,
      C_SPLB_NUM_MASTERS          => C_SPLB_NUM_MASTERS,
      C_SPLB_AWIDTH               => C_SPLB_AWIDTH,
      C_SPLB_DWIDTH               => C_SPLB_DWIDTH, 
      C_SIPIF_DWIDTH              => C_SPLB_NATIVE_DWIDTH,
      C_FAMILY                    => C_FAMILY
    )
    port map
    (
      -- System signals -------------------------------------------------------
      SPLB_Clk             => SPLB_Clk,
      SPLB_Rst             => SPLB_Rst,
      -- Bus Slave signals ----------------------------------------------------
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
      -- Slave Response Signals -----------------------------------------------
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
      -- IP Interconnect (IPIC) port signals ----------------------------------
      Bus2IP_Clk           => Bus2IP_Clk,   
      Bus2IP_Reset         => bus2ip_reset, 
      IP2Bus_Data          => ip2bus_data_i,       
      IP2Bus_WrAck         => ip2bus_wrack_i,
      IP2Bus_RdAck         => ip2bus_rdack_i,
      IP2Bus_Error         => ip2bus_error_i,
      Bus2IP_Addr          => bus2ip_addr,   
      Bus2IP_Data          => bus2ip_data,
      Bus2IP_RNW           => bus2ip_rnw,      
      Bus2IP_BE            => bus2ip_be,    
      Bus2IP_CS            => bus2ip_cs,
      Bus2IP_RdCE          => bus2ip_rdce, 
      Bus2IP_WrCE          => bus2ip_wrce    
    );

    ip2bus_data_i   <= intr2bus_data  or ip2bus_data;
    ip2bus_wrack_i  <= intr2bus_wrack or (GPIO_xferAck_i and not(bus2ip_rnw));
    ip2bus_rdack_i  <= intr2bus_rdack or (GPIO_xferAck_i and bus2ip_rnw);
    ip2bus_error_i  <= intr2bus_error;

    ---------------------------------------------------------------------------
    -- Interrupts
    ---------------------------------------------------------------------------

    INTR_CTRLR_GEN : if (C_INTERRUPT_PRESENT = 1) generate
         constant NUM_IPIF_IRPT_SRC     : natural := 1;
         constant NUM_CE                : integer := 16;

         signal errack_reserved         : std_logic_vector(0 to 1);
         signal ipif_lvl_interrupts     : std_logic_vector(0 to 
                                                    NUM_IPIF_IRPT_SRC-1);
    begin

      ipif_lvl_interrupts    <= (others => '0');  
      errack_reserved        <= (others => '0');

      INTERRUPT_CONTROL_I : entity interrupt_control_v2_01_a.interrupt_control
        generic map
        (
          C_NUM_CE                => NUM_CE,
          C_NUM_IPIF_IRPT_SRC     => NUM_IPIF_IRPT_SRC,   
          C_IP_INTR_MODE_ARRAY    => IP_INTR_MODE_ARRAY,
          C_INCLUDE_DEV_PENCODER  => false,
          C_INCLUDE_DEV_ISC       => false,
          C_IPIF_DWIDTH           => C_SPLB_NATIVE_DWIDTH
        )
        port map
        (
          -- Inputs From the IPIF Bus 
          Bus2IP_Clk           => Bus2IP_Clk,
          Bus2IP_Reset         => bus2ip_reset, 
          Bus2IP_Data          => bus2ip_data,
          Bus2IP_BE            => bus2ip_be,
          Interrupt_RdCE       => bus2ip_rdce(5 to 20), 
          Interrupt_WrCE       => bus2ip_wrce(5 to 20), 

          -- Interrupt inputs from the IPIF sources that will 
          -- get registered in this design
          IPIF_Reg_Interrupts  => errack_reserved,     

          -- Level Interrupt inputs from the IPIF sources
          IPIF_Lvl_Interrupts  => ipif_lvl_interrupts,     

          -- Inputs from the IP Interface  
          IP2Bus_IntrEvent     => ip2bus_intrevent(IP_INTR_MODE_ARRAY'range),  

          -- Final Device Interrupt Output
          Intr2Bus_DevIntr     => IP2INTC_Irpt,       

          -- Status Reply Outputs to the Bus 
          Intr2Bus_DBus        => intr2bus_data,           
          Intr2Bus_WrAck       => intr2bus_wrack,   
          Intr2Bus_RdAck       => intr2bus_rdack,   
          Intr2Bus_Error       => intr2bus_error,   
          Intr2Bus_Retry       => open,          
          Intr2Bus_ToutSup     => open      
        );
    end generate INTR_CTRLR_GEN;
    -----------------------------------------------------------------------
    -- Assigning the intr2bus signal to zero's when interrupt is not 
    -- present
    -----------------------------------------------------------------------
    REMOVE_INTERRUPT : if (C_INTERRUPT_PRESENT = 0) generate

         intr2bus_data     <=  (others => '0');
         IP2INTC_Irpt      <=  '0';
         intr2bus_error    <=  '0'; 
         intr2bus_rdack    <=  '0'; 
         intr2bus_wrack    <=  '0'; 

    end generate REMOVE_INTERRUPT; 

    gpio_core_1 : entity xps_gpio_v2_00_a.gpio_core
       generic map 
       (
         C_DW                => C_SPLB_NATIVE_DWIDTH,
         C_AW                => C_SPLB_AWIDTH,
         C_GPIO_WIDTH        => C_GPIO_WIDTH,
         C_GPIO2_WIDTH       => C_GPIO2_WIDTH,
         C_MAX_GPIO_WIDTH    => MAX_GPIO_WIDTH,
         C_INTERRUPT_PRESENT => C_INTERRUPT_PRESENT,
         C_DOUT_DEFAULT      => C_DOUT_DEFAULT,
         C_TRI_DEFAULT       => C_TRI_DEFAULT,
         C_IS_DUAL           => C_IS_DUAL,
         C_DOUT_DEFAULT_2    => C_DOUT_DEFAULT_2,
         C_TRI_DEFAULT_2     => C_TRI_DEFAULT_2,
         C_FAMILY            => C_FAMILY
       )

       port map 
       (
         Clk              => Bus2IP_Clk,
         Rst              => bus2ip_reset,
         ABus_Reg         => Bus2IP_Addr,
         BE_Reg           => Bus2IP_BE(0 to C_SPLB_NATIVE_DWIDTH/8-1),
         DBus_Reg         => Bus2IP_Data_i(0 to MAX_GPIO_WIDTH-1),
         RNW_Reg          => Bus2IP_RNW, 
         GPIO_DBus        => IP2Bus_Data(0 to C_SPLB_NATIVE_DWIDTH-1),
         GPIO_xferAck     => GPIO_xferAck_i,
         GPIO_Select      => bus2ip_cs(0),
         GPIO_intr        => ip2bus_intrevent(0),
         GPIO2_intr       => ip2bus_intrevent(1),
         GPIO_IO_I        => GPIO_IO_I,
         GPIO_IO_O        => GPIO_IO_O,
         GPIO_IO_T        => GPIO_IO_T,
         GPIO2_IO_I       => GPIO2_IO_I,
         GPIO2_IO_O       => GPIO2_IO_O,
         GPIO2_IO_T       => GPIO2_IO_T
       );



       Bus2IP_Data_i  <= Bus2IP1_Data_i when bus2ip_cs(0) = '1' 
       				and bus2ip_addr (28) = '0'else Bus2IP2_Data_i;
       

	BUS_CONV_ch1 : for i in 0 to C_GPIO_WIDTH-1 generate
		Bus2IP1_Data_i(i) <= Bus2IP_Data(i+
					C_SPLB_NATIVE_DWIDTH-C_GPIO_WIDTH);
	end generate BUS_CONV_ch1;       



	BUS_CONV_ch2 : for i in 0 to C_GPIO2_WIDTH-1 generate
		Bus2IP2_Data_i(i) <= Bus2IP_Data(i+
					C_SPLB_NATIVE_DWIDTH-C_GPIO2_WIDTH);
	end generate BUS_CONV_ch2;       
       

end architecture imp;
