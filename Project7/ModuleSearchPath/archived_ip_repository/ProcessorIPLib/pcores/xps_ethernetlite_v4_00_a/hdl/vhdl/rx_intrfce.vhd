-------------------------------------------------------------------------------
-- rx_intrfce - entity/architecture pair
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This file contains proprietary and confidential information of       **
--  **  Xilinx, Inc. ("Xilinx"), that is distributed under a license         **
--  **  from Xilinx, and may be used, copied and/or disclosed only           **
--  **  pursuant to the terms of a valid license agreement with Xilinx.      **
--  **                                                                       **
--  **  XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION                **
--  **  ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER           **
--  **  EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                  **
--  **  LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,            **
--  **  MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx        **
--  **  does not warrant that functions included in the Materials will       **
--  **  meet the requirements of Licensee, or that the operation of the      **
--  **  Materials will be uninterrupted or error-free, or that defects       **
--  **  in the Materials will be corrected. Furthermore, Xilinx does         **
--  **  not warrant or make any representations regarding use, or the        **
--  **  results of the use, of the Materials in terms of correctness,        **
--  **  accuracy, reliability or otherwise.                                  **
--  **                                                                       **
--  **  Xilinx products are not designed or intended to be fail-safe,        **
--  **  or for use in any application requiring fail-safe performance,       **
--  **  such as life-support or safety devices or systems, Class III         **
--  **  medical devices, nuclear facilities, applications related to         **
--  **  the deployment of airbags, or any other applications that could      **
--  **  lead to death, personal injury or severe property or                 **
--  **  environmental damage (individually and collectively, "critical       **
--  **  applications"). Customer assumes the sole risk and liability         **
--  **  of any use of Xilinx products in critical applications,              **
--  **  subject only to applicable laws and regulations governing            **
--  **  limitations on product liability.                                    **
--  **                                                                       **
--  **  Copyright 2007, 2008, 2009 Xilinx, Inc.                              **
--  **  All rights reserved.                                                 **
--  **                                                                       **
--  **  This disclaimer and copyright notice must be retained as part        **
--  **  of this file at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename     : rx_intrfce.vhd
-- Version      : v4.00.a
-- Description  : This is the ethernet receive interface. 
-- VHDL-Standard: VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
--  xps_ethernetlite.vhd
--      \
--      \-- xemac.vhd
--           \
--           \-- xps_ipif_ssp1.vhd
--           \-- mdio_if.vhd
--           \-- emac_dpram.vhd                     
--           \    \                     
--           \    \-- RAMB16_S4_S36
--           \                          
--           \    
--           \-- emac.vhd                     
--                \                     
--                \                     
--                \-- receive.vhd
--                \      rx_statemachine.vhd
--                \      rx_intrfce.vhd
--                \         ethernetlite_v1_01_b_dmem_v2.edn
--                \      crcgenrx.vhd
--                \                     
--                \-- transmit.vhd
--                       crcgentx.vhd
--                          crcnibshiftreg
--                       tx_intrfce.vhd
--                          ethernetlite_v1_01_b_dmem_v2.edn
--                       tx_statemachine.vhd
--                       deferral.vhd
--                          cntr5bit.vhd
--                          defer_state.vhd
--                       bocntr.vhd
--                          lfsr16.vhd
--                       msh_cnt.vhd
--                       ld_arith_reg.vhd
--
-------------------------------------------------------------------------------
-- Author:         MSH
-- History:
--  RSK            11/06/06
-- ^^^^^^
--                 First Version, Based on opb_ethernetlite v1.01.b
--  ~~~~~
--  PVK       3/13/2009    Version v3.00.a
-- ^^^^^^^
--  Updated to new version v3.00.a.
-- ~~~~~~~
--  PVK       11/25/2009    Version v4.00.a
-- ^^^^^^^
--  Updated to new version v4.00.a.
--  Coregen async_fifo_v5_1 is replaced with the proc_common_fifo generator. 
-- ~~~~~~~
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

-------------------------------------------------------------------------------
-- xps_ethernetlite_v4_00_a library is used for xps_ethernetlite_v4_00_a 
-- component declarations
-------------------------------------------------------------------------------
library xps_ethernetlite_v4_00_a;
use xps_ethernetlite_v4_00_a.all;

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for different 
-- function declarations
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.all;
use proc_common_v3_00_a.family.all;

-- synopsys translate_off
Library xilinxcorelib;
library unisim;
library simprim;
-- synopsys translate_on

-------------------------------------------------------------------------------
-- Definition of Ports:
--
--  Clk                 -- System Clock
--  Rst                 -- System Reset
--  Phy_rx_clk          -- PHY RX Clock
--  InternalWrapEn      -- Internal wrap enable
--  Phy_rx_er           -- Receive error
--  Phy_dv              -- Ethernet receive enable
--  Phy_rx_data         -- Ethernet receive data
--  Rcv_en              -- Receive enable
--  Fifo_empty          -- RX FIFO empty
--  Fifo_full           -- RX FIFO full
--  Emac_rx_rd          -- RX FIFO Read enable
--  Emac_rx_rd_data     -- RX FIFO read data to controller
--  RdAck               -- RX FIFO read ack
-------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------
entity rx_intrfce is
  generic 
    (
    C_FAMILY        : string  := "virtex5"  
    );
  port (
    Clk             : in std_logic;
    Rst             : in std_logic;
    Phy_rx_clk      : in std_logic;
    InternalWrapEn  : in std_logic;
    Phy_rx_er       : in std_logic;
    Phy_dv          : in std_logic;
    Phy_rx_data     : in std_logic_vector (0 to 3);
    Rcv_en          : in std_logic;
    Fifo_empty      : out std_logic;
    Fifo_full       : out std_logic;
    Emac_rx_rd      : in std_logic;
    Emac_rx_rd_data : out std_logic_vector (0 to 5);
    RdAck           : out std_logic
    );
end rx_intrfce;

-------------------------------------------------------------------------------
-- Definition of Generics:
--          No Generics were used for this Entity.
--
-- Definition of Ports:
--         
-------------------------------------------------------------------------------

architecture implementation of rx_intrfce is

-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Signal and Type Declarations
-------------------------------------------------------------------------------

signal rxBusCombo      : std_logic_vector (0 to 5);
signal rx_wr_en        : std_logic;
signal rx_data         : std_logic_vector (0 to 5);
signal rx_fifo_full    : std_logic;
signal rx_fifo_empty   : std_logic;
signal rx_rd_ack       : std_logic;

-------------------------------------------------------------------------------
-- Component Declarations
-------------------------------------------------------------------------------
-- The following components are the building blocks of the EMAC
-------------------------------------------------------------------------------


begin

   I_RX_FIFO: entity proc_common_v3_00_a.async_fifo_fg
     generic map(
       C_ALLOW_2N_DEPTH   => 0,  -- New paramter to leverage FIFO Gen 2**N depth
       C_FAMILY           => C_FAMILY,  -- new for FIFO Gen
       C_DATA_WIDTH       => 6,
       C_ENABLE_RLOCS     => 0,  -- not supported in FG
       C_FIFO_DEPTH       => 15,
       C_HAS_ALMOST_EMPTY => 0,
       C_HAS_ALMOST_FULL  => 0,
       C_HAS_RD_ACK       => 1,
       C_HAS_RD_COUNT     => 0,
       C_HAS_RD_ERR       => 0,
       C_HAS_WR_ACK       => 0,
       C_HAS_WR_COUNT     => 0,
       C_HAS_WR_ERR       => 0,
       C_RD_ACK_LOW       => 0,
       C_RD_COUNT_WIDTH   => 2,
       C_RD_ERR_LOW       => 0,
       C_USE_BLOCKMEM     => 0,  -- 0 = distributed RAM, 1 = BRAM
       C_WR_ACK_LOW       => 0,
       C_WR_COUNT_WIDTH   => 2,
       C_WR_ERR_LOW       => 0   
     )
     port map(
       Din            => rxBusCombo, 
       Wr_en          => rx_wr_en,
       Wr_clk         => Phy_rx_clk,
       Rd_en          => Emac_rx_rd,
       Rd_clk         => Clk,
       Ainit          => Rst,   
       Dout           => rx_data,
       Full           => rx_fifo_full,
       Empty          => rx_fifo_empty,
       Almost_full    => open,
       Almost_empty   => open, 
       Wr_count       => open,
       Rd_count       => open,
       Rd_ack         => rx_rd_ack,
       Rd_err         => open,
       Wr_ack         => open,
       Wr_err         => open
     );

rxBusCombo      <= (Phy_rx_data & Phy_dv & Phy_rx_er);
Emac_rx_rd_data <= rx_data; 
RdAck           <= rx_rd_ack; 
Fifo_full       <= rx_fifo_full; 
Fifo_empty      <= rx_fifo_empty; 
rx_wr_en        <= Rcv_en; 

           
end implementation;
