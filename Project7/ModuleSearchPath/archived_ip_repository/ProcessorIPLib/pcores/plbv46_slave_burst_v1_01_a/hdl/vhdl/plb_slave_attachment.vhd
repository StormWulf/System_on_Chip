-------------------------------------------------------------------------------
-- $Id: plb_slave_attachment.vhd,v 1.2 2008/05/13 21:43:38 gburch Exp $
-------------------------------------------------------------------------------
-- PLB Slave attachment entity and architecture
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This text/file contains proprietary, confidential                    **
--  **  information of Xilinx, Inc., is distributed under                    **
--  **  license from Xilinx, Inc., and may be used, copied                   **
--  **  and/or disclosed only pursuant to the terms of a valid               **
--  **  license agreement with Xilinx, Inc. Xilinx hereby                    **
--  **  grants you a license to use this text/file solely for                **
--  **  design, simulation, implementation and creation of                   **
--  **  design files limited to Xilinx devices or technologies.              **
--  **  Use with non-Xilinx devices or technologies is expressly             **
--  **  prohibited and immediately terminates your license unless            **
--  **  covered by a separate agreement.                                     **
--  **                                                                       **
--  **  Xilinx is providing this design, code, or information                **
--  **  "as-is" solely for use in developing programs and                    **
--  **  solutions for Xilinx devices, with no obligation on the              **
--  **  part of Xilinx to provide support. By providing this design,         **
--  **  code, or information as one possible implementation of               **
--  **  this feature, application or standard, Xilinx is making no           **
--  **  representation that this implementation is free from any             **
--  **  claims of infringement. You are responsible for obtaining            **
--  **  any rights you may require for your implementation.                  **
--  **  Xilinx expressly disclaims any warranty whatsoever with              **
--  **  respect to the adequacy of the implementation, including             **
--  **  but not limited to any warranties or representations that this       **
--  **  implementation is free from claims of infringement, implied          **
--  **  warranties of merchantability or fitness for a particular            **
--  **  purpose.                                                             **
--  **                                                                       **
--  **  Xilinx products are not intended for use in life support             **
--  **  appliances, devices, or systems. Use in such applications is         **
--  **  expressly prohibited.                                                **
--  **                                                                       **
--  **  Any modifications that are made to the Source Code are               **
--  **  done at the user’s sole risk and will be unsupported.                **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Hotline support of original source         **
--  **  code IP shall only address issues and questions related              **
--  **  to the standard Netlist version of the core (and thus                **
--  **  indirectly, the original core source).                               **
--  **                                                                       **
--  **  Copyright (c) 2008 Xilinx, Inc. All rights reserved.                 **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
-------------------------------------------------------------------------------
-- Filename:        plb_slave_attachment.vhd
-- Version:         v1_00_a
-- Description:     PLB slave attachment supporting single beat transfers,
--                  cache line, and fixed length bursts. Design
--                  supports high speed data transfer (1 clock per data beat)
--                  on the cacheline and burst transfers.
--
-------------------------------------------------------------------------------
-- Structure:
--
--                  plbv46_slave_burst.vhd
--                      -- data_mirror_128.vhd
--                      -- plb_slave_attachment.vhd
--                          -- plb_address_decoder.vhd
--                          -- addr_reg_cntr_brst_flex.vhd
--                              -- flex_addr_cntr.vhd
--                          -- wr_buffer.vhd
--                          -- be_reset_gen.vhd
--                          -- burst_support.vhd
--
-------------------------------------------------------------------------------
-- Author:      <Gary Burch>
--
-- History:
--
--  GAB     8/9/06
-- ~~~~~~
--  - Initial release of v1.00.a
-- ^^^^^^
--  GAB     9/29/06
-- ~~~~~~
--  - Fixed bus2ip_burst not getting set correctly during cachelines
--  - Modified burst counts to remove early burst terminates.
-- ^^^^^^
--  GAB     10/04/06
-- ~~~~~~
--  - Fixed issue of generating sl_wrbterm during a cacheline in the 
--    'no write buffer' configuration.
--  - Fixed steer address generation for cacheline read in Linear Cacheline
--    Address Mode starting on a non-zero address.
-- ^^^^^^
--  GAB     10/31/06
-- ~~~~~~
--  - Removed range from master_id signal decleration to fix issue found 
--    during formal verification of plbv46_slave_single
-- ^^^^^^
--  GAB     11/2/06
-- ~~~~~~
--  - Added option to output bus2ip_burstlength as a databeat count - 1.  This
--    count is left justified starting with bit 0 as the msb.
-- ^^^^^^
--  GAB     11/8/06
-- ~~~~~~
--  - Fixed issues with bus2ip_addr transitioning with dataack as opposed to 
--    addrack
--  - Added feature to allow bus2ip_burstlength to be in databeats-1 or byte count
--    depending on setting of C_BURSTLENGTH_TYPE.
-- ^^^^^^
--  GAB     12/4/06
-- ~~~~~~
--  - Cleaned up data_cycle_count ModelSim Compile Warning.
--  - Cleaned up num_data_beats_minus1 ModelSim Compile Warning
--  - Cleaned up NUMERIC_STD.TO_UNSIGNED: vector truncated run time warning
--    for C_SPLB_DWIDTH=64 configuration.
-- ^^^^^^
--  GAB     2/7/2007     
-- ~~~~~~
--  - Fixed issue with write buffer data being pushed into write buffer
--    during transition to FLUSH state without looking at the fifo 
--    almost full flag.  This fixes CR433971.
-- ^^^^^^
--  GAB     5/4/2007     
-- ~~~~~~
--  - Added XST work around for index calculation issue with rdwdaddr
-- ^^^^^^
--  GAB     5/11/2007     
-- ~~~~~~
--  - Cleaned up truncation warning on bus2ip_burstlength creation logic.  
--  conditions causing warning were impossible to reach cases for the
--  particular configuration of the slave. Warning occurs for c_splb_dwidth=32 
--  for the Double-Word (64-Bit) and Quad-Word(128-Bit) wide burst requests
--  cases.
-- ^^^^^^
--  GAB     6/12/2007     
-- ~~~~~~
--  - Modified valid request to not respond to 16word cachelines, byte bursts,
--  and halfword.  
--  - Qualified sl_addrack_i and set_sl_busy with valid request in the p2p mode
--  - Passed PLB_RWN combinatorially to plb_rnw_reg in p2p mode
-- ^^^^^^
--  GAB     6/15/2007     
-- ~~~~~~
-- Qualified PLB_wrBurst with plb_rnw_reg in setting of bus2ip_burst to work 
-- around corner case issue where arbiter drove plb_wrburst during address 
-- phase of a read.
-- ^^^^^^
--  GAB     6/19/2007     
-- ~~~~~~
--  Created a P2P version and a Shared version for SL_SSize so the shared
--  version could be registered to remove long timing path.
-- ^^^^^^
--  GAB     7/2/2007     
-- ~~~~~~
--  Added missing else clause to MID process for master_id_vector.  This
--  fixes CR442664.
-- ^^^^^^
--  GAB     7/20/07
-- ~~~~~~
--  - Added dataphase timeout timer.  A timeout will terminate the plb cycle
-- normally (driving zeros during reads) and will remove IPIC signal 
-- assertion.
-- ^^^^^^
--  GAB     8/16/07
-- ~~~~~~
--  - Added generic to include or exclude dataphase timeout timer.
--  - Fixed slow timing path in address decoder
-- ^^^^^^
--      GAB    4/29/2008   v1.01.a     
-- ~~~~~~
--     - Updated to use proc_common_v3_00_a library
-- ^^^^^^
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_type"
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

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.family_support.all;


-- Xilinx Primitive Library
library unisim;
use unisim.vcomponents.all;

library plbv46_slave_burst_v1_01_a;
use plbv46_slave_burst_v1_01_a.all;

-------------------------------------------------------------------------------
entity plb_slave_attachment is
    generic (

        C_STEER_ADDR_SIZE       : integer := 10;
        C_ARD_ADDR_RANGE_ARRAY  : SLV64_ARRAY_type :=
           (
             X"0000_0000_7000_0000", -- IP user0 base address
             X"0000_0000_7000_00FF", -- IP user0 high address
             X"0000_0000_7000_0100", -- IP user1 base address
             X"0000_0000_7000_01FF"  -- IP user1 high address
           );

        C_ARD_NUM_CE_ARRAY   : INTEGER_ARRAY_type :=
           (
             1,         -- User0 CE Number
             8          -- User1 CE Number
           );
        C_PLB_NUM_MASTERS       : integer := 8;
        C_PLB_MID_WIDTH         : integer := 3;
        C_SPLB_P2P              : integer := 0;
        C_PLB_SMALLEST_MASTER   : integer := 128;
        C_IPIF_ABUS_WIDTH       : integer := 32;
        C_IPIF_DBUS_WIDTH       : integer := 128;
        C_SPLB_DWIDTH           : integer := 128;
        C_DEV_MAX_BURST_SIZE    : integer range 2 to 4096 := 4096;
        C_CACHLINE_ADDR_MODE    : integer range 0 to 1 := 0;
        C_WR_BUFFER_DEPTH       : integer range 0 to 64:= 16;
        C_BURSTLENGTH_TYPE      : integer range 0 to 1 := 0;
        C_DPHASE_TIMEOUT        : integer := 64;
        C_INCLUDE_DPHASE_TIMER  : integer range 0 to 1 := 1;
        C_FAMILY                : string  := "virtex4"
        );
    port(
        --System signals
        Bus_Reset           : in  std_logic;
        Bus_Clk             : in  std_logic;

        -- PLB Bus signals
        PLB_ABus            : in  std_logic_vector(0 to 31);
        PLB_UABus           : in  std_logic_vector(0 to 31);
        PLB_PAValid         : in  std_logic;
        PLB_masterID        : in  std_logic_vector
                                (0 to C_PLB_MID_WIDTH - 1);
        PLB_RNW             : in  std_logic;
        PLB_BE              : in  std_logic_vector
                                (0 to (C_IPIF_DBUS_WIDTH/8)-1);
        PLB_Msize           : in  std_logic_vector(0 to 1);
        PLB_size            : in  std_logic_vector(0 to 3);
        PLB_type            : in  std_logic_vector(0 to 2);
        PLB_wrDBus          : in  std_logic_vector(0 to C_IPIF_DBUS_WIDTH-1);
        PLB_wrBurst         : in  std_logic;
        PLB_rdBurst         : in  std_logic;
        Sl_SSize            : out std_logic_vector(0 to 1);
        Sl_addrAck          : out std_logic;
        Sl_wait             : out std_logic;
        Sl_rearbitrate      : out std_logic;
        Sl_wrDAck           : out std_logic;
        Sl_wrComp           : out std_logic;
        Sl_wrBTerm          : out std_logic;
        Sl_rdDBus           : out std_logic_vector(0 to C_IPIF_DBUS_WIDTH-1);
        Sl_rdWdAddr         : out std_logic_vector(0 to 3);
        Sl_rdDAck           : out std_logic;
        Sl_rdComp           : out std_logic;
        Sl_rdBTerm          : out std_logic;
        Sl_MBusy            : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
        Sl_MRdErr           : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);   
        Sl_MWrErr           : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);   

        -- Controls to the Byte Steering/Mirroring Module
        SA2Mirror_RdAddr    : out std_logic_vector(0 to C_STEER_ADDR_SIZE - 1);

        -- Controls to the IP/IPIF modules
        Bus2IP_Addr         : out std_logic_vector (0 to C_IPIF_ABUS_WIDTH-1);
        Bus2IP_Burst        : out std_logic;
        Bus2IP_BurstLength  : out std_logic_vector
                                (0 to log2(C_DEV_MAX_BURST_SIZE));
        Bus2IP_RNW          : out std_logic;
        Bus2IP_BE           : out std_logic_vector (0 to C_IPIF_DBUS_WIDTH/8-1);
        
        Bus2IP_WrReq        : out std_logic;
        Bus2IP_RdReq        : out std_logic;
        
        Bus2IP_CS           : out std_logic_vector
                                (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
        Bus2IP_RdCE         : out std_logic_vector
                                (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);
        Bus2IP_WrCE         : out std_logic_vector
                                (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);

        -- Write Data bus output to the IP/IPIF modules
        Bus2IP_Data         : out std_logic_vector (0 to C_IPIF_DBUS_WIDTH-1);

        --Inputs from the Read Data Bus Mux
        IP2Bus_Data         : in  std_logic_vector (0 to C_IPIF_DBUS_WIDTH-1);

        -- Inputs from the Status Reply Mux
        IP2Bus_AddrAck      : in  std_logic; 
        IP2Bus_WrAck        : in  std_logic;
        IP2Bus_RdAck        : in  std_logic;
        IP2Bus_Error        : in  std_logic

       
    );
end entity plb_slave_attachment;

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

architecture implementation of plb_slave_attachment is


-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------
  -------------------------------------------------------------------
  -- Function
  --
  -- Function Name: check_to_value
  --
  -- Function Description:
  --  This function makes sure a minimum timeout value is passed to
  -- the WDT logic for the Data Phase timeout if the User specifies
  -- one that is too small. Currently, this is minimum is 8 clocks.
  --
  -------------------------------------------------------------------
  function check_to_value (timeout_value: integer) return integer is

     Constant MIN_VALUE_ALLOWED : integer := 8; -- 8 PLB clocks
     Variable to_value : Integer;

  begin
-- removed for coverage....timeout_value is hardcoded in plb_slave_burst.vhd
-- for this core
--     if (timeout_value < MIN_VALUE_ALLOWED) then
--       to_value :=  MIN_VALUE_ALLOWED;
--     else
       to_value := timeout_value;
--     end if;

     return(to_value);

  end function check_to_value;


-------------------------------------------------------------------------------
-- Function min2
--
-- This function returns the lesser of two numbers.
-------------------------------------------------------------------------------
function min2 (num1, num2 : integer) return integer is
begin
    if num1 < num2 then
        return num1;
    else
        return num2;
    end if;
end function min2;

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-- xst workaround for constraining ports in address_decoder
-- component declaration.
constant CS_BUS_SIZE            : integer := C_ARD_ADDR_RANGE_ARRAY'length/2;
constant CE_BUS_SIZE            : integer := calc_num_ce(C_ARD_NUM_CE_ARRAY);

-- Total number of possible address bits (32 for ABUS + 32 for UABUS)
constant TTL_AWIDTH             : integer := 64;


-- Max fixed length burst size in data beats
constant MAX_FLBURST_SIZE       : integer := C_DEV_MAX_BURST_SIZE
                                             / (C_IPIF_DBUS_WIDTH/8);

-- Fix the Slave Size response to the PLB DBus width
-- note "00" = 32 bits wide
--      "01" = 64 bits wide
--      "10" = 128 bits wide
constant SLAVE_SIZE             : std_logic_vector(0 to 1) :=
                                    std_logic_vector(
                                    to_unsigned(C_IPIF_DBUS_WIDTH/64, 2));
                                    
constant WR_BUFFER_AWIDTH     : integer := log2(C_WR_BUFFER_DEPTH);

constant BE_ZEROS               : std_logic_vector(0 to C_IPIF_DBUS_WIDTH/8-1) 
                                    := (others =>'0');
constant RST_BE_ZEROS           : std_logic_vector(0 to C_IPIF_DBUS_WIDTH/32-1) 
                                    := (others => '0');

-- Constants for calculating burst counts
constant NUM_DBEAT_BITS             : integer := min2(8,C_IPIF_DBUS_WIDTH/8)+2;

constant FIFTEEN                    :  std_logic_vector(0 to NUM_DBEAT_BITS - 1) 
                                        := std_logic_vector(
                                        to_unsigned(15,NUM_DBEAT_BITS));

constant SEVEN                      :  std_logic_vector(0 to NUM_DBEAT_BITS - 1) 
                                        := std_logic_vector(
                                        to_unsigned(7,NUM_DBEAT_BITS));

constant THREE                      :  std_logic_vector(0 to NUM_DBEAT_BITS - 1) 
                                        := std_logic_vector(
                                        to_unsigned(3,NUM_DBEAT_BITS));

constant ONE                        :  std_logic_vector(0 to NUM_DBEAT_BITS - 1) 
                                        := std_logic_vector(
                                        to_unsigned(1,NUM_DBEAT_BITS));

-------------------------------------------------------------------------------
-- Signal and type Declarations
-------------------------------------------------------------------------------

-- Intermediate Slave Reply output signals (to PLB)
signal sl_addrack_i             : std_logic;
signal sl_wait_i                : std_logic;
signal sl_rearbitrate_i         : std_logic;
signal sl_wrdack_i              : std_logic;
signal sl_wrcomp_i              : std_logic;
signal sl_wrbterm_i             : std_logic;
signal sl_rddbus_i              : std_logic_vector(0 to C_IPIF_DBUS_WIDTH-1);
signal sl_rdwdaddr_i            : std_logic_vector(0 to 3);
signal sl_rddack_i              : std_logic;
signal sl_rdcomp_i              : std_logic;
signal sl_rdbterm_i             : std_logic;
signal sl_mbusy_i               : std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
signal sl_mrderr_i              : std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
signal sl_mwrerr_i              : std_logic_vector(0 to C_PLB_NUM_MASTERS-1);

-- Signals for combined address phase state machine
signal addr_cycle_flush         : std_logic;
signal addr_cycle_flush_ns      : std_logic;

signal sl_wait_ns               : std_logic;
signal sl_addrack_ns            : std_logic;
signal set_sl_busy_ns           : std_logic;
signal sl_rearbitrate_ns        : std_logic;

-- PLB Read State Machine
signal sl_rddack_ns             : std_logic;
signal sl_rdcomp_ns             : std_logic;
signal sl_rdbterm_ns            : std_logic;
signal rd_dphase_active_ns      : std_logic;
signal bus2ip_rdreq_ns          : std_logic;
signal bus2ip_rdburst_ns        : std_logic;
signal clear_rd_ce              : std_logic;
signal rd_ce_ld_enable          : std_logic;
signal clear_sl_rd_busy         : std_logic;
signal clear_sl_rd_busy_ns      : std_logic;

-- PLB Write State Machine
signal sl_wrdack_ns             : std_logic;
signal sl_wrcomp_ns             : std_logic;
signal sl_wrbterm_ns            : std_logic;
signal wr_ce_ld_enable          : std_logic;

-- Registered PLB input signals
signal plb_abus_reg             : std_logic_vector(0 to C_IPIF_ABUS_WIDTH-1);
signal plb_abus_early           : std_logic_vector(0 to C_IPIF_ABUS_WIDTH-1);

signal plb_pavalid_reg          : std_logic;
signal plb_savalid_reg          : std_logic;
signal plb_rdprim_reg           : std_logic;
signal plb_wrprim_reg           : std_logic;
signal plb_masterid_reg         : std_logic_vector(0 to C_PLB_MID_WIDTH - 1);
signal master_id_vector         : std_logic_vector(0 to C_PLB_MID_WIDTH - 1);
signal plb_buslock_reg          : std_logic;
signal plb_rnw_reg              : std_logic;
signal plb_be_reg               : std_logic_vector
                                    (0 to (C_IPIF_DBUS_WIDTH/8)-1);
signal plb_msize_reg            : std_logic_vector(0 to 1);
signal plb_size_reg             : std_logic_vector(0 to 3);
signal plb_type_reg             : std_logic_vector(0 to 2);
signal plb_wrdbus_reg           : std_logic_vector(0 to C_IPIF_DBUS_WIDTH-1);
signal plb_wrburst_reg          : std_logic;
signal plb_rdburst_reg          : std_logic;

-- Intermediate IPIC signals
signal bus2ip_data_i            : std_logic_vector(0 to C_IPIF_DBUS_WIDTH-1);
signal bus2ip_addr_i            : std_logic_vector(0 to C_IPIF_ABUS_WIDTH-1);
signal bus2ip_burst_i           : std_logic;
signal burstlength_i            : std_logic_vector
                                    (0 to log2(C_DEV_MAX_BURST_SIZE));
signal bus2ip_rnw_i             : std_logic;
signal bus2ip_be_i              : std_logic_vector(0 to C_IPIF_DBUS_WIDTH/8-1);
signal bus2ip_wrreq_i           : std_logic;
signal bus2ip_rdreq_i           : std_logic;


-- new internal signals
signal master_id                : integer;
signal addr_cntr_load_en        : std_logic;
signal line_count_done          : std_logic;
signal line_count_almostdone    : std_logic;
signal start_data_phase         : std_logic;
signal data_ack                 : std_logic;

signal rdwdaddr                 : std_logic_vector(0 to 3);
signal sa2steer_addr_i          : std_logic_vector(0 to C_STEER_ADDR_SIZE-1);

-- Combined transfer validation signals
signal valid_request            : std_logic;
signal valid_plb_size           : boolean;
signal valid_plb_type           : boolean;
signal indeterminate_burst      : std_logic;
signal single_transfer          : std_logic;
--signal single_transfer_reg      : std_logic;
signal burst_transfer           : std_logic;
signal burst_transfer_reg       : std_logic;
signal cacheln_transfer         : std_logic;
signal cacheln_burst_reg        : std_logic;
signal do_the_cmd               : std_logic;

-- Combined decoder signals
signal address_match            : std_logic;
signal address_match_early      : std_logic;
signal decode_cs_ce_clr         : std_logic;
signal decode_ld_rw_ce          : std_logic;
signal decode_clr_rw_ce         : std_logic;
signal decode_s_h_cs            : std_logic;
signal decode_cs_clr            : std_logic;
signal CS_Early_i               : std_logic_vector(0 to CS_BUS_SIZE-1);
signal bus2ip_cs_i              : std_logic_vector(0 to CS_BUS_SIZE-1);
signal bus2ip_rdce_i            : std_logic_vector(0 to CE_BUS_SIZE-1);
signal bus2ip_wrce_i            : std_logic_vector(0 to CE_BUS_SIZE-1);

-- Other Combined Logic signals
signal set_sl_busy              : std_logic;
signal clear_sl_busy            : std_logic;
signal sl_busy                  : std_logic;
signal sa2mirror_rdaddr_i       : std_logic_vector(0 to C_STEER_ADDR_SIZE - 1);
signal sa2mirror_MSize_i        : std_logic_vector(0 to 1);  
signal sa2mirror_sh_size_i      : std_logic_vector(0 to 1);
signal reset_be                 : std_logic_vector
                                    (0 to C_IPIF_DBUS_WIDTH/32-1);    

type PLB_RDDATA_CNTRL_STATES is (
                  PBRD_IDLE,
                  PBRD_SINGLE,
                  PBRD_BURST_FIXED,
                  PBREAD_FLUSH
                  );




signal plb_read_cntl_state      : PLB_RDDATA_CNTRL_STATES;
signal plb_read_cntl_state_ns   : PLB_RDDATA_CNTRL_STATES;
signal sig_wr_data_ack          : std_logic;
signal sig_rd_data_ack          : std_logic;
signal wr_buf_rden              : std_logic;
signal wr_buf_empty             : std_logic;
--signal wr_buf_burst_in          : std_logic;
--signal wr_buf_burst_out         : std_logic;
signal wr_buf_data_in           : std_logic_vector(0 to C_IPIF_DBUS_WIDTH-1);
signal wr_buf_data_out          : std_logic_vector(0 to C_IPIF_DBUS_WIDTH-1);
signal wr_buf_move_data         : std_logic;
signal wrreq_out                : std_logic;
signal sl_wrdack_i_dly1         : std_logic;
signal wr_buf_wren              : std_logic;
--signal line_done_dly1           : std_logic;
signal wr_buf_done_in           : std_logic;
signal bus2ip_wrburst_i         : std_logic;
signal bus2ip_rdburst_i         : std_logic;
signal control_ack_i            : std_logic;
signal control_done_i           : std_logic;
signal response_ack_i           : std_logic;
signal response_ack_dly1        : std_logic;
signal response_almostdone_i    : std_logic;
signal response_done_i          : std_logic;
signal data_cycle_count         : integer range 0 to MAX_FLBURST_SIZE-1;
signal num_data_beats_minus1    : natural; 

-- IPIF Write State Machine
signal clear_wr_ce              : std_logic;
signal clear_sl_wr_busy         : std_logic;
signal bus2ip_wrburst_ns        : std_logic;
signal wr_dphase_active_ns      : std_logic;
signal wr_buf_rden_ns           : std_logic;
signal bus2ip_wrreq_ns          : std_logic;
signal set_bus2ip_wrreq         : std_logic;
signal clr_bus2ip_wrreq         : std_logic;

-- New Read SM signals
signal set_bus2ip_rdreq         : std_logic;
signal clr_bus2ip_rdreq         : std_logic;

-- Error assertion fix
signal fastbrst_clear_sl_wr_busy: std_logic;
signal extend_wr_busy           : std_logic;

-- Misc Signals
signal rd_burst_done            : std_logic;
signal rd_data_ack              : std_logic;
signal rd_data_ack_ns           : std_logic;
signal plb_size_sh_reg          : std_logic_vector(0 to 3);
signal be_burst_size            : std_logic_vector(0 to NUM_DBEAT_BITS-1);
--                                    (0 to min2(8,C_IPIF_DBUS_WIDTH/8)+1);

signal control_done_d1          : std_logic;
signal control_done_strb        : std_logic;

signal wr_buf_wren2             : std_logic;      
signal fixed_dbeat_cnt          : integer;
--signal dbeat_cnt                : std_logic_vector
--                                    (0 to min2(7,C_IPIF_DBUS_WIDTH/8-1));
signal dbeat_cnt                : std_logic_vector(0 to 3);

-- Used for outputing the burstlength.  Added 3 bits to allow for
-- conversion from dbeats to bytes, namely for quad words
--signal brstlength_i             : std_logic_vector
--                                    (0 to log2(C_DEV_MAX_BURST_SIZE));
signal brstlength_i             : std_logic_vector(0 to 12); --GAB
                                    
                                    
signal wrbuffer_wren            : std_logic;
signal write_cntrl_idle         : std_logic;
signal write_cntrl_burst        : std_logic;

signal msize_i                  : std_logic_vector(0 to 1);
signal size_i                   : std_logic_vector(0 to 3);
signal be_i                     : std_logic_vector(0 to (C_IPIF_DBUS_WIDTH/8)-1);
signal type_i                   : std_logic_vector(0 to 2);
signal pavalid_i                : std_logic;
signal abus_i                   : std_logic_vector(0 to  C_IPIF_ABUS_WIDTH-1);
signal addr_cntr_load_d1        : std_logic;

signal data_timeout             : std_logic; -- GAB 7/20/07
signal target_addrack_i         : std_logic;
signal rnw_s_h                  : std_logic;
-------------------------------------------------------------------------------
-- begin the architecture logic
-------------------------------------------------------------------------------
begin

-- synthesis translate_off

-------------------------------------------------------------------------------
-- REPORT_WARNINGS
-- This process is used only during simulation to generate user warnings.
-------------------------------------------------------------------------------
REPORT_WARNINGS : process (bus_clk)

variable newline            : Character := cr;
variable report_inhibit_cnt : integer := 5; -- 5 Bus_Clk clocks

begin

    if (Bus_clk'event and Bus_clk = '1') then

        -- Inhibit warnings during sim initialization
        if (report_inhibit_cnt = 0) then
            null; -- stop down count
        else
            report_inhibit_cnt := report_inhibit_cnt-1;
        end if;


        if (Bus_Reset = '1' or report_inhibit_cnt > 0) then
            null; -- do nothing
        else
            
        Assert (data_timeout = '0')
        Report "Data phase timeout assertion....  Addressed Target did not respond!"
        Severity warning;

        end if;
    end if;
end process REPORT_WARNINGS;

-- synthesis translate_on

------------------------------------------------------------------
-- Misc. Logic Assignments
------------------------------------------------------------------

-- PLB Output port connections
Sl_addrAck          <= sl_addrack_i         ;
Sl_wait             <= sl_wait_i            ;
Sl_rearbitrate      <= sl_rearbitrate_i     ;
Sl_wrDAck           <= sl_wrdack_i          ;
Sl_wrComp           <= sl_wrcomp_i          ;
Sl_wrBTerm          <= sl_wrbterm_i         ; 
Sl_rdDBus           <= sl_rddbus_i          ;
Sl_rdWdAddr         <= sl_rdwdaddr_i        ;
Sl_rdDAck           <= sl_rddack_i          ;
Sl_rdComp           <= sl_rdcomp_i          ;
Sl_rdBTerm          <= sl_rdbterm_i;
Sl_MBusy            <= sl_mbusy_i           ;
Sl_MRdErr           <= sl_mrderr_i          ;
Sl_MWrErr           <= sl_mwrerr_i          ;

-- IPIF output signals
Bus2IP_Addr         <= bus2ip_addr_i        ;
Bus2IP_Burst        <= bus2ip_burst_i       ;
Bus2IP_BurstLength  <= burstlength_i        ;
Bus2IP_RNW          <= bus2ip_rnw_i         ;
Bus2IP_BE           <= bus2ip_be_i          ;
Bus2IP_WrReq        <= bus2ip_wrreq_i       ;
Bus2IP_RdReq        <= bus2ip_rdreq_i       ;
Bus2IP_Data         <= bus2ip_data_i        ;
Bus2IP_CS           <= bus2ip_cs_i          ;
Bus2IP_RdCE         <= bus2ip_rdce_i        ;

-- Byte steering support
SA2Mirror_RdAddr    <= sa2mirror_rdaddr_i   ;

-------------------------------------------------------------------------------
-- Register all PLB input signals
-------------------------------------------------------------------------------
REG_PLB_INPUTS : Process (Bus_clk)
    begin
        if (Bus_clk'EVENT and Bus_clk = '1')  then
            if (Bus_reset = '1') then
                plb_pavalid_reg     <= '0'              ;
                plb_wrdbus_reg      <= (others => '0')  ;
                plb_masterid_reg    <= (others => '0')  ;
                plb_wrburst_reg     <= '0'              ;
                plb_rdburst_reg     <= '0'              ;
            else
                -- Clear pavalid on flush request
                if (addr_cycle_flush = '1') then  
                    plb_pavalid_reg     <= '0'          ;
                else                           
                    plb_pavalid_reg     <= PLB_PAValid  ;
                end if;

                -- Register these signals continously
                plb_wrdbus_reg      <= PLB_wrDBus       ;
                plb_masterid_reg    <= PLB_masterID     ;
                plb_wrburst_reg     <= PLB_wrBurst      ;
                plb_rdburst_reg     <= PLB_rdBurst      ;

            end if;
        end if;
    end process REG_PLB_INPUTS;
    
-------------------------------------------------------------------------------
-- Concatinate Address buses for PLB AWIDTH's greater than 32 bits
-------------------------------------------------------------------------------
-- Removed for code coverage - core currently only supports 32 bit addresses
--GEN_GRTR_THAN_32_ADDR : if C_IPIF_ABUS_WIDTH > 32 generate
--
--    REG_ADDR_INPUT : process(Bus_Clk)
--        begin
--            if(Bus_Clk'EVENT and Bus_Clk = '1')then
--                if(Bus_Reset = '1')then
--                    plb_abus_reg    <= (others => '0');
--                else
--                    plb_abus_reg    <=  PLB_UABUS(TTL_AWIDTH-C_IPIF_ABUS_WIDTH
--                                                    to  (TTL_AWIDTH/2)-1)
--                                        & PLB_ABus;
--                end if;
--            end if;
--        end process REG_ADDR_INPUT;
--
--    plb_abus_early  <= PLB_UABUS(TTL_AWIDTH-C_IPIF_ABUS_WIDTH
--                                                    to  (TTL_AWIDTH/2)-1)
--                                        & PLB_ABus;
--
--end generate GEN_GRTR_THAN_32_ADDR;
                    
-------------------------------------------------------------------------------
-- Simply pass input address bus to out for PLB AWIDTH's equal to 32 bits
-------------------------------------------------------------------------------
GEN_EQL_TO_32_ADDR : if C_IPIF_ABUS_WIDTH = 32 generate

    REG_ADDR_INPUT : process(Bus_Clk)
        begin
            if(Bus_Clk'EVENT and Bus_Clk = '1')then
                if(Bus_Reset = '1')then
                    plb_abus_reg    <= (others => '0');
                else
                    plb_abus_reg    <=  PLB_ABus;
                end if;
            end if;
        end process REG_ADDR_INPUT;
    
    plb_abus_early <=  PLB_ABus;

end generate GEN_EQL_TO_32_ADDR;

-------------------------------------------------------------------------------
-- Drive Slave Size
-------------------------------------------------------------------------------
-- GAB Modified 6-19-07 - Created a P2P version and a Shared version.
-- Register shared version to remove long timing path
GEN_SSIZE_P2P : if C_SPLB_P2P = 1 generate
    Sl_SSize <= SLAVE_SIZE when address_match_early = '1'
           else (others => '0');
end generate GEN_SSIZE_P2P;

GEN_SSIZE_SHARED : if C_SPLB_P2P = 0 generate
    REG_SL_SSIZE : process(Bus_Clk)
        begin
            if(Bus_Clk'EVENT and Bus_Clk = '1')then
                if(Bus_Reset = '1' or sl_addrack_i='1' or sl_rearbitrate_i='1')then
                    Sl_SSize <= (others => '0');
                elsif(address_match_early = '1')then
                    Sl_SSize <= SLAVE_SIZE;
                else
                    Sl_SSize <= (others => '0');
                end if;
            end if;
        end process REG_SL_SSIZE;
end generate GEN_SSIZE_SHARED;


-------------------------------------------------------------------------------
-- For Point-To-Point need to use combinatorial versions of these
-------------------------------------------------------------------------------
GEN_XFER_CNT_CNTRL_P2P : if C_SPLB_P2P = 1 generate
    msize_i     <= PLB_MSize;
    size_i      <= PLB_size;
    type_i      <= PLB_type;
    be_i        <= PLB_BE;
    pavalid_i   <= PLB_PAValid;
    abus_i      <= plb_abus_early;
    plb_rnw_reg <= PLB_RNW;

    plb_be_reg          <= PLB_BE           ;
    plb_size_reg        <= PLB_size         ;
    plb_type_reg        <= PLB_type         ;



end generate GEN_XFER_CNT_CNTRL_P2P;

-------------------------------------------------------------------------------
-- For Shared bus need to use registered versions of these
-------------------------------------------------------------------------------
GEN_XFER_CNT_CNTRL_SHARED : if C_SPLB_P2P = 0 generate
    msize_i     <= plb_msize_reg;
    size_i      <= plb_size_reg;
    type_i      <= plb_type_reg;
    be_i        <= plb_be_reg;
    pavalid_i   <= plb_pavalid_reg;
    abus_i      <= plb_abus_reg;

    REG_RNW : process(Bus_clk)
        begin
            if (Bus_clk'EVENT and Bus_clk = '1')  then
                if (Bus_reset = '1') then
                    plb_rnw_reg <= '0';
                    plb_be_reg      <= (others => '0');
                    plb_size_reg    <= (others => '0');
                    plb_type_reg    <= (others => '0');
                else    
                    plb_rnw_reg     <= PLB_RNW        ;
                    plb_be_reg      <= PLB_BE         ;
                    plb_size_reg    <= PLB_size       ;
                    plb_type_reg    <= PLB_type       ;
                end if;
            end if;
        end process REG_RNW;

end generate GEN_XFER_CNT_CNTRL_SHARED;

-------------------------------------------------------------------------------
-- Sample And Hold PLB_MSize for use during the acknowledged cycle.
-- plb_msize_reg is only used during the address phase
-- sa2mirror_MSize_i is used during the data phase
-- sa2mirror_rdaddr_i is used to properly steer read data
-------------------------------------------------------------------------------
SH_WRCNTRL_PROCESS : process(Bus_Clk)
begin
    if(Bus_Clk'EVENT and Bus_Clk = '1')then
        if(Bus_Reset = '1')then
            plb_msize_reg    <= (others => '0');
        elsif(PLB_PAValid = '1')then
            plb_msize_reg    <= PLB_MSize;    
        end if;
    end if;
end process SH_WRCNTRL_PROCESS;

SH_RDCNTRL_PROCESS : process(Bus_Clk)
begin
    if(Bus_Clk'EVENT and Bus_Clk = '1')then
        if(Bus_Reset = '1')then
            sa2mirror_sh_size_i    <= (others => '0');
        elsif(sl_addrack_i = '1')then
            sa2mirror_sh_size_i    <= PLB_MSize;    
        end if;
    end if;
end process SH_RDCNTRL_PROCESS;


REG_MSize_MUX : process(Addr_cntr_load_en,PLB_MSize,sa2mirror_sh_size_i)
    begin
        if(Addr_cntr_load_en = '1')then
            sa2mirror_MSize_i <= PLB_MSize;
        else
            sa2mirror_MSize_i <= sa2mirror_sh_size_i;
        end if;
    end process REG_MSize_MUX;
            

REG_RDADDR_PROCESS : process(Bus_Clk)
begin
    if(Bus_Clk'EVENT and Bus_Clk = '1')then
        if(Bus_Reset = '1')then
            sa2mirror_rdaddr_i    <= (others => '0');
        else
            sa2mirror_rdaddr_i    <= sa2steer_addr_i;
        end if;
    end if;
end process REG_RDADDR_PROCESS;


-------------------------------------------------------------------------------
-- BE Reset Generator
-- The following entity clears mirrored BE's.  The BE's of smaller masters
-- are mirrored to the upper byte lanes, so based on the master's size and
-- the address presented, all un-needed BE's are cleared to zero by reset_be.
-------------------------------------------------------------------------------
BE_RESET_I : entity plbv46_slave_burst_v1_01_a.be_reset_gen
    generic map(
        C_DWIDTH     => C_IPIF_DBUS_WIDTH,
        C_AWIDTH     => C_IPIF_ABUS_WIDTH,
        C_SMALLEST   => C_PLB_SMALLEST_MASTER
    )
    port map(
       Addr             => abus_i,
       MSize            => sa2mirror_MSize_i,
       
       Reset_BE         => reset_be
    );

-------------------------------------------------------------------------------
-- PLB Size Validation
-- This combinatorial process validates the PLB request attribute PLB_Size
-- that is supported by this slave. It also detirmines if a cacheline or
-- burst operation is being requested.
-------------------------------------------------------------------------------
VALIDATE_SIZE : process (size_i)
    begin
        case size_i is
            -- single data beat transfer
            when "0000" =>   -- one to eight bytes
                valid_plb_size   <= true;
                single_transfer  <= '1';
                cacheln_transfer <= '0';
                burst_transfer   <= '0';

            -- cacheline transfer
            when "0001" |   -- 4 word cache-line
                 "0010" =>   -- 8 word cache-line
--GAB 6/12/07 - Modified to not respond to 16 word cachelines.
--                 "0010" |   -- 8 word cache-line
--                 "0011" =>  -- 16 word cache-line

                valid_plb_size   <= true;
                single_transfer  <= '0';
                cacheln_transfer <= '1';
                burst_transfer   <= '0';

--GAB 6/12/07 - Modified to not respond to byte and halfword bursts
--            -- burst transfer (fixed length)
--            when "1000" |    -- byte burst transfer
--                 "1001" |    -- halfword burst transfer
--                 "1010" |    -- word burst transfer
--                 "1011" |    -- double word burst transfer                 
--                 "1100" =>   -- quad word burst transfer                   
--                             -- octal widths are not allowed (256 wide bus)
            when "1010" |    -- word burst transfer
                 "1011" |    -- double word burst transfer                 
                 "1100" =>   -- quad word burst transfer                   
                             -- octal widths are not allowed (256 wide bus)

                valid_plb_size   <= true;
                single_transfer  <= '0';
                cacheln_transfer <= '0';
                burst_transfer   <= '1';

            when others   =>

                valid_plb_size   <= false;
                single_transfer  <= '0';
                cacheln_transfer <= '0';
                burst_transfer   <= '0';

            end case;

        end process VALIDATE_SIZE;

-------------------------------------------------------------------------------
-- PLB Size Validation
-- This combinatorial process validates the PLB request attribute PLB_type
-- that is supported by this slave.
-------------------------------------------------------------------------------
VALIDATE_type : process (type_i)
    begin
        if(type_i="000")then
            valid_plb_type <= true;
        else
            valid_plb_type <= false;
        end if;
    end process VALIDATE_type;

-------------------------------------------------------------------------------
-- Indeterminate Burst
-- This slave attachment does NOT support indeterminate burst.  Cycles which
-- are determined to be indeterminate will not be responded to by this slave.
-------------------------------------------------------------------------------
GEN_IBURST_FOR_32_SLAVE : if C_IPIF_DBUS_WIDTH=32 generate
  VALIDATE_BURST : process (burst_transfer, be_i)
     begin

       if (burst_transfer = '1' and
           be_i(0 to 3) = "0000") then  -- indetirminate burst
         indeterminate_burst <= '1';
       else
         indeterminate_burst <= '0';
       end if;

     end process VALIDATE_BURST;
end generate GEN_IBURST_FOR_32_SLAVE;


GEN_IBURST_FOR_64_128_SLAVE : if C_IPIF_DBUS_WIDTH > 32 generate
  VALIDATE_BURST : process (burst_transfer, be_i)
     begin

       if (burst_transfer = '1' and
           be_i(0 to 7) = "00000000") then  -- indetirminate burst
         indeterminate_burst <= '1';
       else
         indeterminate_burst <= '0';
       end if;

     end process VALIDATE_BURST;
end generate GEN_IBURST_FOR_64_128_SLAVE;

-------------------------------------------------------------------------------
-- Access Validation
-- This combinatorial process validates the PLB request attributes that are
-- supported by this slave.
-------------------------------------------------------------------------------
VALIDATE_REQUEST : process (pavalid_i,valid_plb_size,valid_plb_type,
                            indeterminate_burst)
    begin
        if (pavalid_i = '1')                -- Address Request
        and (valid_plb_size)                -- and a valid plb_size
        and (valid_plb_type)                -- and a memory xfer
        and (indeterminate_burst='0')then   -- and not Indeterminate Burst
            valid_request <= '1';
        else
            valid_request <= '0';
        end if;
  end process VALIDATE_REQUEST;


-------------------------------------------------------------------------------
-- Address Decoder Component Instance
-- This component decodes the specified base address pairs and outputs the
-- specified number of chip enables and the target bus size.
-------------------------------------------------------------------------------
I_DECODER : entity plbv46_slave_burst_v1_01_a.plb_address_decoder
    generic map
    (
        C_BUS_AWIDTH            => C_IPIF_ABUS_WIDTH        ,
        C_SIPIF_DWIDTH          => C_IPIF_DBUS_WIDTH        ,
        C_ARD_ADDR_RANGE_ARRAY  => C_ARD_ADDR_RANGE_ARRAY   ,
        C_ARD_NUM_CE_ARRAY      => C_ARD_NUM_CE_ARRAY       ,
        C_SPLB_P2P              => C_SPLB_P2P               ,
-- GAB 8/16/07 modified to provide better timing in spartan3 devices,
-- carry chain logic in spartan is slow.  This mod forces
-- inferred logic.
--        C_FAMILY                => C_FAMILY
        C_FAMILY                => "nofamily"
    )
    port map
    (
        Bus_clk                 => Bus_clk                  ,
        Bus_rst                 => Bus_reset                ,

        -- PLB Interface signals
        Address_In              => plb_abus_reg             ,
        Address_In_Erly         => plb_abus_early           ,
        Address_Valid           => plb_pavalid_reg          ,
        Address_Valid_Erly      => PLB_PAValid              ,
        Bus_RNW                 => plb_rnw_reg              ,

        -- Registering control signals
        cs_sample_hold_n        => decode_s_h_cs            ,
        cs_sample_hold_clr      => decode_cs_clr            ,
        CS_CE_ld_enable         => addr_cntr_load_en        ,
        Clear_CS_CE_Reg         => decode_cs_ce_clr         ,
        RW_CE_ld_enable         => decode_ld_rw_ce          ,
        Clear_RW_CE_Reg         => decode_clr_rw_ce         ,
        Clear_addr_match        => addr_cycle_flush         ,

        -- Decode output signals
        Addr_Match_early        => address_match_early      ,
        Addr_Match              => address_match            ,
        RNW_S_H_Out             => rnw_s_h                  ,
        CS_Out                  => bus2ip_cs_i              ,
        RdCE_Out                => bus2ip_rdce_i            ,
        WrCE_Out                => bus2ip_wrce_i
    );

-------------------------------------------------------------------------------
-- Generate Address Phase Control State Machine for a Shared PLB configuration.
-------------------------------------------------------------------------------
GEN_FOR_SHARED : if C_SPLB_P2P = 0 generate
type PLB_ADDR_CNTRL_STATES is (
                    VALIDATE_REQ,
                    REARBITRATE,
                    GEN_ADDRACK
                    );
signal addr_cntl_cs             : PLB_ADDR_CNTRL_STATES;
signal addr_cntl_ns             : PLB_ADDR_CNTRL_STATES;
signal rearbitrate_condition    : std_logic;
signal sl_addrack_i_ns          : std_logic;
signal set_sl_busy_ns           : std_logic;

begin
    decode_s_h_cs       <=  not(sl_busy)
                            or (address_match and clear_sl_busy);

    decode_cs_clr       <=  clear_sl_busy 
                            and not(address_match);

    decode_ld_rw_ce     <= '1' when (wr_ce_ld_enable='1' or rd_ce_ld_enable='1')
                      else '0';
    



    addr_cntr_load_en   <= set_sl_busy;


    -- detect a command execute condition and set a flag if it exists
    do_the_cmd              <=  valid_request
                            and address_match_early
                            and not(sl_busy);

    -- Rearbitrate if another address hit occurs and slave is busy
    rearbitrate_condition   <=  valid_request       
                            and address_match_early
                            and sl_busy             
                            and not(clear_sl_busy);

    ---------------------------------------------------------------------------
    -- Address Controller State Machine
    -- This state machine controls the validation and address acknowledge
    -- of the incoming PLB bus requests. The local Slave
    -- Attachment decoder will reply with an address match signal should
    -- the incoming address match the assigned address ranges.
    ---------------------------------------------------------------------------
    ADDRESS_CONTROLLER : Process (addr_cntl_cs,do_the_cmd,rearbitrate_condition)
        begin
            sl_addrack_i_ns             <= '0';
            set_sl_busy_ns              <= '0';
            addr_cycle_flush_ns         <= '0';
            sl_rearbitrate_ns           <= '0';
            addr_cntl_ns                <= VALIDATE_REQ;


            -- States
            case addr_cntl_cs is

                when VALIDATE_REQ =>

                       -- Rearbitrate condition
                    if (rearbitrate_condition = '1') then 
                        sl_rearbitrate_ns           <= '1';
                        addr_cycle_flush_ns         <= '1';
                        addr_cntl_ns                <= REARBITRATE;

                    -- Do the command
                    elsif (do_the_cmd = '1') then
                       sl_addrack_i_ns              <= '1';
                       set_sl_busy_ns               <= '1';
                       addr_cycle_flush_ns          <= '1';
                       addr_cntl_ns                 <= GEN_ADDRACK;
                    else
                       addr_cntl_ns    <= VALIDATE_REQ;
                    end if;


                when REARBITRATE =>
                    addr_cntl_ns    <= VALIDATE_REQ;

                when GEN_ADDRACK =>
                    addr_cntl_ns    <= VALIDATE_REQ;

--coverage off
                when others   =>
                    addr_cntl_ns    <= VALIDATE_REQ;
--coverage on
            end case;
        end process ADDRESS_CONTROLLER;
    

    REG_STATES_PROCESS : process(Bus_Clk)
        begin
            if(Bus_Clk'EVENT and Bus_Clk = '1')then
                if(Bus_Reset = '1')then
                    addr_cntl_cs        <= VALIDATE_REQ;
                    sl_rearbitrate_i    <= '0';
                else
                    addr_cntl_cs        <= addr_cntl_ns;
                    sl_rearbitrate_i    <= sl_rearbitrate_ns;
                end if;
            end if;
        end process REG_STATES_PROCESS;

    REG_STATE_SIGNALS : process(Bus_Clk)
        begin
            if(Bus_Clk'EVENT and Bus_Clk = '1')then
                if(Bus_Reset = '1')then
                   sl_addrack_i            <= '0';
                   set_sl_busy             <= '0';
                   addr_cycle_flush        <= '0';
                else
                   sl_addrack_i            <= sl_addrack_i_ns;
                   set_sl_busy             <= set_sl_busy_ns;
                   addr_cycle_flush        <= addr_cycle_flush_ns;
                end if;
            end if;
        end process REG_STATE_SIGNALS;

    -- Always inactive in a shared bus configuration
    sl_wait_i                  <= '0';

end generate GEN_FOR_SHARED;

-------------------------------------------------------------------------------
-- Generate Address Phase Control State Machine for a Point 2 Point PLB
-- configuration.
-------------------------------------------------------------------------------
GEN_FOR_P2P : if C_SPLB_P2P = 1 generate
type PLB_ADDR_CNTRL_STATES is (
                    VALIDATE_REQ,
                    GEN_WAIT,
                    GEN_ADDRACK
                    );
signal addr_cntl_cs             : PLB_ADDR_CNTRL_STATES;
signal addr_cntl_ns             : PLB_ADDR_CNTRL_STATES;
signal end_busy                 : std_logic;
signal wait_condition           : std_logic;
begin
    decode_s_h_cs       <=  not(sl_busy)
                            or (address_match_early and clear_sl_busy);

    decode_cs_clr       <=  clear_sl_busy 
                            and not(PLB_PAValid);


    -- detect a command execute condition and set a flag if it exists
    do_the_cmd              <=  valid_request
                            and not(sl_busy);

    --- detect a wait condition and set a flag if it exists
    wait_condition          <=  valid_request
                            and sl_busy; 

    ---------------------------------------------------------------------------
    -- Address Controller State Machine
    -- This state machine controls the validation and address acknowledge
    -- of the incoming PLB bus requests. The local Slave
    -- Attachment decoder will reply with an address match signal should
    -- the incoming address match the assigned address ranges.
    ---------------------------------------------------------------------------
    ADDRESS_CONTROLLER : Process (addr_cntl_cs,do_the_cmd,wait_condition,
                                    end_busy)
        begin
            addr_cycle_flush_ns         <= '0';
            sl_wait_ns                  <= '0';
            addr_cntl_ns                <= addr_cntl_cs;

            case addr_cntl_cs is

                when VALIDATE_REQ =>
                    -- Wait condition
                    if (wait_condition = '1') then 
                        sl_wait_ns                  <= '1';
                        addr_cycle_flush_ns         <= '1';
                        addr_cntl_ns                <= GEN_WAIT;

                    -- Do the command
                    elsif (do_the_cmd = '1') then
                        addr_cycle_flush_ns         <= '1';
                        addr_cntl_ns                <= GEN_ADDRACK;

                    else
                        addr_cntl_ns                <= VALIDATE_REQ;
                    end if;

                when GEN_WAIT =>
                    if (end_busy = '1') then
                        addr_cycle_flush_ns         <= '1';
                        addr_cntl_ns                <= GEN_ADDRACK;
                    else
                        sl_wait_ns                  <= '1';
                    end if;

                when GEN_ADDRACK =>
                    addr_cntl_ns    <= VALIDATE_REQ;

--coverage off
                when others   =>
                    addr_cntl_ns    <= VALIDATE_REQ;
--coverage on
            end case;
        end process ADDRESS_CONTROLLER;
    
    REG_STATES_PROCESS : process(Bus_Clk)
        begin
            if(Bus_Clk'EVENT and Bus_Clk = '1')then
                if(Bus_Reset = '1')then
                    addr_cntl_cs        <= VALIDATE_REQ;
                else
                    addr_cntl_cs        <= addr_cntl_ns;
                end if;
            end if;
        end process REG_STATES_PROCESS;

    REG_STATE_SIGNALS : process(Bus_Clk)
        begin
            if(Bus_Clk'EVENT and Bus_Clk = '1')then
                if(Bus_Reset = '1')then
                    addr_cycle_flush    <= '0';
                    end_busy            <= '0';
                else
                    addr_cycle_flush    <= addr_cycle_flush_ns;
                    end_busy            <= clear_sl_busy;
                end if;
            end if;
        end process REG_STATE_SIGNALS;


    -- Drive combinatorially in a Point2Point configuration
--GAB 6/12/07 - sl_addrack and set_sl_busy where not qualified by a valid request
--    sl_addrack_i            <= '1' when (PLB_PAValid='1'  and wait_condition = '0')
--                                     or (end_busy='1' and addr_cntl_cs = GEN_WAIT)
--                         else  '0';
--                         
--    set_sl_busy             <= '1' when (PLB_PAValid='1'  and wait_condition = '0')
--                                     or (end_busy='1' and addr_cntl_cs = GEN_WAIT)
--                         else  '0';
    
    sl_addrack_i            <= '1' when (valid_request='1'  and wait_condition = '0')
                                     or (end_busy='1' and addr_cntl_cs = GEN_WAIT)
                         else  '0';
                         
    set_sl_busy             <= '1' when (valid_request='1'  and wait_condition = '0')
                                     or (end_busy='1' and addr_cntl_cs = GEN_WAIT)
                         else  '0';
   
    sl_wait_i               <= sl_wait_ns;
    addr_cntr_load_en       <= set_sl_busy;
    decode_ld_rw_ce         <= set_sl_busy;
    
    -- Always inactive in a Point2Point configuration
    sl_rearbitrate_i    <= '0';

end generate GEN_FOR_P2P;

        
-------------------------------------------------------------------------------
-- Register Master ID
-- This process controls the registering of the PLB Master ID signals
-------------------------------------------------------------------------------
--GEN_MSTRID_SHARED : if C_SPLB_P2P = 0 generate

    REGISTER_MID : process (Bus_clk)
        begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
                if (Bus_reset = '1') then
                    master_id_vector    <= (others => '0');
                elsif (decode_s_h_cs = '1') then
                    master_id_vector         <= plb_masterid_reg;
                end if;
            end if;
        end process REGISTER_MID;

--end generate GEN_MSTRID_SHARED;

--GEN_MSTRID_P2P : if C_SPLB_P2P = 1 generate
--
--    MID : process (decode_s_h_cs,PLB_masterID)
--        begin
--            if (decode_s_h_cs = '1') then
--                master_id_vector         <= PLB_masterID;
--            else
--                master_id_vector         <= (others => '0');
--            end if;
--        end process MID;
--
--end generate GEN_MSTRID_P2P;

--master_id         <= to_integer(unsigned(master_id_vector));

master_id         <= to_integer(unsigned(PLB_masterID)) when decode_s_h_cs = '1' and C_SPLB_P2P=1
                else to_integer(unsigned(master_id_vector));


-------------------------------------------------------------------------------
-- Generate the Slave Busy
-- This process controls the registering and output of the Slave Busy signals
-- onto the PLB Bus.
-------------------------------------------------------------------------------
GENERATE_SL_BUSY : process (Bus_clk)
    begin
        if (Bus_clk'EVENT and Bus_clk = '1') Then
                if (Bus_reset = '1' or clear_sl_busy='1') then
                    sl_busy         <= '0';
                elsif (set_sl_busy = '1') Then
                    sl_busy         <= '1';
                end if;
            end if;
    end process GENERATE_SL_BUSY;

GEN_SL_MBUSY : process(Bus_clk)
    begin
        if (Bus_clk'EVENT and Bus_clk = '1') Then
            for i in 0 to C_PLB_NUM_MASTERS - 1 loop
                if (Bus_reset = '1') then
                    sl_mbusy_i(i)   <= '0';
                elsif (i=master_id)then
                    if(set_sl_busy = '1') Then
                        sl_mbusy_i(i)   <= '1';  -- set specific bit for req master
                    elsif (clear_sl_busy = '1') Then
                        sl_mbusy_i(i)   <= '0';  -- set specific bit for req master
                    end if;
--                else
--                    sl_mbusy_i(i) <= '0';
                end if;
            end loop;
        end if;
    end process GEN_SL_MBUSY;

    -------------------------------------------------------------------------------
    -- Generate the Slave Error Reply
    -- This process controls the registering and output of the Slave MRdErr signals
    -- onto the PLB Bus.
    -------------------------------------------------------------------------------
    GENERATE_SL_RDERR : process (Bus_clk)
        begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
                for i in 0 to C_PLB_NUM_MASTERS - 1 loop
                    if (Bus_reset = '1') then
                        sl_mrderr_i(i) <= '0';
                    elsif (master_id = i 
                    and IP2Bus_RdAck = '1') then
                        sl_mrderr_i(i) <= IP2Bus_Error;
                    else
                        sl_mrderr_i(i) <= '0'; -- no error
                    end if;
                end loop;
            end if;
        end process GENERATE_SL_RDERR;

GEN_WRERROR_FOR_BUFFER : if C_WR_BUFFER_DEPTH/=0 generate
    -- Unable to generate an sl_mwrerr coincident with a sl_wrdack when the write
    -- buffer is instantiated, therefore any ip2bus_error during a write
    -- will simply be ignored.
    sl_mwrerr_i <= (others => '0');
end generate GEN_WRERROR_FOR_BUFFER;


GEN_WRERROR_FOR_NOBUFFER : if C_WR_BUFFER_DEPTH=0 generate
    -------------------------------------------------------------------------------
    -- Generate the Slave Error Reply
    -- This process controls the registering and output of the Slave MRdErr signals
    -- onto the PLB Bus.
    -------------------------------------------------------------------------------
    GENERATE_SL_WRERR : process (IP2Bus_Error,IP2Bus_WrAck,master_id)
        begin
            for i in 0 to C_PLB_NUM_MASTERS - 1 loop
                if (master_id = i 
                and IP2Bus_WrAck = '1') then
                    sl_mwrerr_i(i) <= IP2Bus_Error;
                else
                    sl_mwrerr_i(i) <= '0'; -- no error
                end if;
            end loop;
        end process GENERATE_SL_WRERR;
end generate GEN_WRERROR_FOR_NOBUFFER;




--coverage off
--synopsys translate_off
assert     C_WR_BUFFER_DEPTH = 0 
        or C_WR_BUFFER_DEPTH = 16
        or C_WR_BUFFER_DEPTH = 32
        or C_WR_BUFFER_DEPTH = 64

report "ERROR: Invalid Write Buffer Depth - Valid depths for C_WR_BUFFER_DEPTH " &
       "are 0, 16, 32, or 64."
severity FAILURE;
--synopsys translate_on
--coverage off

--------------------------------------------------------------------------
-- Address decoder support
-- Create the load enables and clears for the decoder chip select (CS) and
-- chip enable (CE) signals that need to be latched and held during the
-- data phase of a request
--------------------------------------------------------------------------
decode_cs_ce_clr   <=  (response_ack_i and response_done_i);

decode_clr_rw_ce   <=  clear_rd_ce or clear_wr_ce;

---------------------------------------------------------------------------
-- Data Phase Support
---------------------------------------------------------------------------
start_data_phase <=  set_sl_busy;

sig_wr_data_ack  <=  IP2Bus_WrAck                           -- Write Acknowledge
                  or (data_timeout and not rnw_s_h);   -- Dataphase timeout

sig_rd_data_ack  <= IP2Bus_RdAck
                  or (data_timeout and rnw_s_h);



data_ack         <=  IP2Bus_RdAck or        -- Read acknowledge
                     IP2Bus_WrAck or        -- Write Acknowledge
                     data_timeout;          -- Dataphase timeout

clear_sl_busy    <=  clear_sl_rd_busy or
                     fastbrst_clear_sl_wr_busy;

fastbrst_clear_sl_wr_busy <=  (clear_sl_wr_busy and not(IP2Bus_error))
                              or extend_wr_busy;

--------------------------------------------------------------------------
-- Assign the PLB read word address
--------------------------------------------------------------------------
GEN_MSTR_GRTR_SLAVE : if C_PLB_SMALLEST_MASTER >= C_IPIF_DBUS_WIDTH generate

--XST Issue with calculation WRD_ADDR_LSB
--constant WRD_ADDR_LSB     : integer   := C_STEER_ADDR_SIZE -                     
--                                           log2(C_IPIF_DBUS_WIDTH/8) - 1;
--constant WRD_ADDR_MSB     : integer   := C_STEER_ADDR_SIZE - 6;                  
--constant WRD_ADDR_PAD     : std_logic_vector(0 to log2(C_IPIF_DBUS_WIDTH/8) - 3) 
--                              := (others => '0');

begin    
--    rdwdaddr         <=  sa2steer_addr_i(WRD_ADDR_MSB to WRD_ADDR_LSB) 
--                         & WRD_ADDR_PAD when cacheln_burst_reg = '1'
--
--                   else (others => '0');
--XST Work Around
    GEN_RDWDADDR_32BIT : if C_IPIF_DBUS_WIDTH = 32 generate
    
    
        rdwdaddr         <=  sa2steer_addr_i(4 to 7) when cacheln_burst_reg = '1'

                       else (others => '0');
    end generate GEN_RDWDADDR_32BIT;


    GEN_RDWDADDR_64BIT : if C_IPIF_DBUS_WIDTH = 64 generate
    
    
        rdwdaddr         <=  sa2steer_addr_i(4 to 6) & '0' when cacheln_burst_reg = '1'

                       else (others => '0');
    end generate GEN_RDWDADDR_64BIT;


    GEN_RDWDADDR_128BIT : if C_IPIF_DBUS_WIDTH = 128 generate
    
    
        rdwdaddr         <=  sa2steer_addr_i(4 to 5) & "00" when cacheln_burst_reg = '1'

                       else (others => '0');
    end generate GEN_RDWDADDR_128BIT;


end generate GEN_MSTR_GRTR_SLAVE;


GEN_MSTR_LESS_SLAVE : if C_PLB_SMALLEST_MASTER < C_IPIF_DBUS_WIDTH generate

--XST Issue with calculation WRD_ADDR_LSB
--constant WRD_ADDR_LSB     : integer   := C_STEER_ADDR_SIZE -        
--                                         log2(C_PLB_SMALLEST_MASTER/8) - 1;
--constant WRD_ADDR_MSB     : integer   := C_STEER_ADDR_SIZE - 6;  
--constant WRD_ADDR_PAD     : std_logic_vector(0 to log2(C_PLB_SMALLEST_MASTER/8) - 3) 
--                                      := (others => '0');
begin
--    rdwdaddr         <=  sa2steer_addr_i(WRD_ADDR_MSB to WRD_ADDR_LSB) 
--                         & WRD_ADDR_PAD when cacheln_burst_reg = '1'
--
--                   else (others => '0');
--XST Work Around
    GEN_RDWDADDR2_32BIT : if C_PLB_SMALLEST_MASTER = 32 generate
    
    
        rdwdaddr         <=  sa2steer_addr_i(4 to 7) when cacheln_burst_reg = '1'

                       else (others => '0');
    end generate GEN_RDWDADDR2_32BIT;


    GEN_RDWDADDR2_64BIT : if C_PLB_SMALLEST_MASTER = 64 generate
    
    
        rdwdaddr         <=  sa2steer_addr_i(4 to 6) & '0' when cacheln_burst_reg = '1'

                       else (others => '0');
    end generate GEN_RDWDADDR2_64BIT;


    GEN_RDWDADDR2_128BIT : if C_PLB_SMALLEST_MASTER = 128 generate
    
    
        rdwdaddr         <=  sa2steer_addr_i(4 to 5) & "00" when cacheln_burst_reg = '1'

                       else (others => '0');
    end generate GEN_RDWDADDR2_128BIT;



end generate GEN_MSTR_LESS_SLAVE;

--------------------------------------------------------------------------

sl_rddack_i    <=  rd_data_ack and not(rd_burst_done);


---------------------------------------------------------------------------
-- Extend Busy
-- This process detects the assertion of the Error Reply signal
-- and generates a signal to extend the Sl_Mbusy assertion by
-- one PLB Clock. This enables the Sl_Merr assertion to be under
-- the umbrella of the Sl_Mbusy assertion.
---------------------------------------------------------------------------
XTEND_BUSY : process (bus_clk)
    begin
        if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Reset = '1') then
                extend_wr_busy <= '0';
            elsif (clear_sl_wr_busy = '1' and IP2Bus_Error = '1') then
                extend_wr_busy <= '1';
            else
                extend_wr_busy <= '0';
            end if;
        end if;
    end process XTEND_BUSY;

---------------------------------------------------------------------------
-- Detect Read Burst Done
---------------------------------------------------------------------------
DETECT_RDBURST_DONE : process (bus_clk)
    begin
        if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_reset = '1' or clear_sl_rd_busy = '1') then
                rd_burst_done <= '0';
            elsif (sl_rddack_i = '1' and PLB_rdBurst = '0'
            and cacheln_burst_reg = '0') then
                rd_burst_done <= '1';
            end if;
        end if;
    end process DETECT_RDBURST_DONE;

---------------------------------------------------------------------------
-- Read Data Controller
-- This state machine controls the transfer of data to
-- the PLB Bus (Reads).
---------------------------------------------------------------------------
PLB_RDDATA_CONTROLLER : process (plb_read_cntl_state,
                                 start_data_phase,
                                 plb_rnw_reg,
                                 size_i,  
                                 cacheln_transfer, 
                                 single_transfer,
                                 control_ack_i,
                                 control_done_i,
                                 response_ack_i,
                                 response_almostdone_i,
                                 response_done_i,
                                 plb_rdburst_reg,
                                 msize_i)
  begin

    -- default conditions
     bus2ip_rdburst_ns      <= '0';
     rd_data_ack_ns         <= '0';
     sl_rdcomp_ns           <= '0';
     sl_rdbterm_ns          <= '0';
     rd_dphase_active_ns    <= '0';
     rd_ce_ld_enable        <= '0';
     clear_rd_ce            <= '0';
     clear_sl_rd_busy_ns    <= '0';
     set_bus2ip_rdreq       <= '0';
     clr_bus2ip_rdreq       <= '0';

     case plb_read_cntl_state Is

        when PBRD_IDLE =>

            if (start_data_phase = '1' 
            and plb_rnw_reg      = '1') then

                rd_ce_ld_enable      <= '1';
                rd_dphase_active_ns  <= '1';
                set_bus2ip_rdreq     <= '1';

                -- 4 word cacheln read for 128 bit wide dbus
                if (cacheln_transfer = '1' and size_i = "0001"
                and C_IPIF_DBUS_WIDTH = 128 and msize_i = "10")then
                    plb_read_cntl_state_ns  <= PBRD_SINGLE;

                -- Fixed burst or 8 or 16 word cacheln read
                -- or for 64 or 32 bit wide dbus then 4 word cacheln
                elsif (single_transfer = '0') then  
                    plb_read_cntl_state_ns  <= PBRD_BURST_FIXED;
                    bus2ip_rdburst_ns       <= '1';

                -- Single beat read request
                else                         
                    plb_read_cntl_state_ns  <= PBRD_SINGLE;
                end if;

            else
                plb_read_cntl_state_ns  <= PBRD_IDLE;
                clr_bus2ip_rdreq        <= '1';
            end if;

        when PBRD_SINGLE =>
            clr_bus2ip_rdreq        <= '1';
            if (response_ack_i = '1') then
                plb_read_cntl_state_ns   <= PBREAD_FLUSH;
                rd_data_ack_ns           <= '1';
                sl_rdcomp_ns             <= '1';
                clear_sl_rd_busy_ns      <= '1';
                clear_rd_ce              <= '1';
            else
                plb_read_cntl_state_ns   <= PBRD_SINGLE;
                rd_dphase_active_ns      <= '1';
            end if;

        when PBRD_BURST_FIXED =>
            rd_data_ack_ns        <= response_ack_i;                
            clr_bus2ip_rdreq      <= (control_ack_i
                                  and control_done_i);

            if (response_ack_i = '1'
            and response_done_i = '1') then
                plb_read_cntl_state_ns  <= PBREAD_FLUSH;
                sl_rdcomp_ns            <= '1';
                clear_sl_rd_busy_ns     <= '1';
                clear_rd_ce             <= '1';
            elsif (response_ack_i = '1'
            and response_almostdone_i = '1') then
                plb_read_cntl_state_ns  <= PBRD_BURST_FIXED;
                rd_dphase_active_ns     <= '1';
                bus2ip_rdburst_ns       <= '0';
                sl_rdbterm_ns           <= plb_rdburst_reg;
            else
                plb_read_cntl_state_ns  <= PBRD_BURST_FIXED;
                rd_dphase_active_ns     <= '1';
                bus2ip_rdburst_ns       <= not(response_done_i);
                sl_rdbterm_ns           <= '0';
            end if;

        when PBREAD_FLUSH =>
            plb_read_cntl_state_ns   <= PBRD_IDLE;
            clear_rd_ce              <= '1';

--coverage off
        when others   =>
            plb_read_cntl_state_ns   <= PBRD_IDLE;
            clear_rd_ce              <= '1';
--coverage on

        end case;
end process PLB_RDDATA_CONTROLLER;

---------------------------------------------------------------------------
-- PLB_RD_SM_SYNCD
-- This process registers outputs from the PLB Read Data
-- state machine.
---------------------------------------------------------------------------
PLB_RD_SM_SYNCD : process (bus_clk)
    begin
        if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_reset = '1') then

                plb_read_cntl_state <= PBRD_IDLE                ;
                bus2ip_rdburst_i    <= '0'                      ;
                rd_data_ack         <= '0'                      ;
                sl_rdcomp_i         <= '0'                      ;
                sl_rdbterm_i        <= '0'                      ;
                clear_sl_rd_busy    <= '0'                      ;
            else
                plb_read_cntl_state <= plb_read_cntl_state_ns   ;
                bus2ip_rdburst_i    <= bus2ip_rdburst_ns        ;
                rd_data_ack         <= rd_data_ack_ns           ;
                sl_rdcomp_i         <= sl_rdcomp_ns             ;
                sl_rdbterm_i        <= sl_rdbterm_ns            ; 
                clear_sl_rd_busy    <= clear_sl_rd_busy_ns      ;
            end if;
        end if;
    end process PLB_RD_SM_SYNCD;



---------------------------------------------------------------------------
-- Instantiate the Register for the Bus2IP_RdReq signal generation.
-- This is needed for Determinate Read Timing to terminate the RdReq
-- when the Address & Control timing is complete but data transfer is
-- not yet complete do to pipeline delays.
---------------------------------------------------------------------------
I_RDREQ_FDRSE : FDRSE
    port map(
        Q  =>  bus2ip_rdreq_i,    -- : out std_logic;
        C  =>  Bus_Clk,           -- : in  std_logic;
        CE =>  '1',               -- : in  std_logic;
        D  =>  bus2ip_rdreq_i,    -- : in  std_logic;
        R  =>  clr_bus2ip_rdreq,  -- : in  std_logic
        S  =>  set_bus2ip_rdreq   -- : in  std_logic
    );


---------------------------------------------------------------------------
---------------------------- Write Buffer ---------------------------------
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- Generate a write buffer is the depth parameter is set to something
-- other than 0
---------------------------------------------------------------------------
GEN_WRITE_BUFFER : if C_WR_BUFFER_DEPTH /= 0 generate   

type PLB_WRDATA_CNTRL_STATES is (
                  PBWR_IDLE,
                  PBWR_BURST_FIXED,
                  PBWRITE_FLUSH
                  );

type IPIF_WR_CNTRL_STATES is (
                  IWR_IDLE,
                  IWR_INIT,
                  IWR_BURST_FIXED1,
                  IWR_SINGLE1
                  );
signal ipif_wr_cntl_state       : IPIF_WR_CNTRL_STATES;
signal ipif_wr_cntl_state_ns    : IPIF_WR_CNTRL_STATES;
signal plb_write_cntl_state     : PLB_WRDATA_CNTRL_STATES;
signal plb_write_cntl_state_ns  : PLB_WRDATA_CNTRL_STATES;
signal wr_buff_addr_out         : std_logic_vector(0 to WR_BUFFER_AWIDTH-1);
signal wrbuf_goingfull          : std_logic;
signal wrbuf_full               : std_logic;
signal inhibit_wrburst          : std_logic;
signal wr_buffer_rst            : std_logic;
begin
    ---------------------------------------------------------------------------
    -- PLB_WRITE_DATA_CONTROLLER
    -- This state machine controls the transfer of data from the PLB Bus
    -- (writes). The write data is put into an intermediate FIFO buffer. A
    -- second data write state machine is then activated to transfer data from
    -- the FIFO buffer to the IPIF.
    ---------------------------------------------------------------------------
    PLB_WRITE_DATA_CONTROLLER : process (plb_write_cntl_state,
                                         start_data_phase,
                                         plb_rnw_reg,
                                         size_i,
                                         msize_i,
                                         burst_transfer,
                                         cacheln_transfer, 
                                         num_data_beats_minus1,
                                         single_transfer,
                                         wrbuf_goingfull,
                                         line_count_done,
                                         line_count_almostdone,
                                         burst_transfer_reg
                                         )
        begin


            plb_write_cntl_state_ns  <= PBWR_IDLE;
            sl_wrdack_ns             <= '0';
            sl_wrcomp_ns             <= '0';
            sl_wrbterm_ns            <= '0';
            wrbuffer_wren            <= '0';

            case plb_write_cntl_state is

                when PBWR_IDLE =>

                    if (start_data_phase = '1' and plb_rnw_reg = '0') then

                        if (burst_transfer = '1'
                        and num_data_beats_minus1 = 1) then 

                            wrbuffer_wren             <= not(wrbuf_goingfull); 
                            sl_wrdack_ns              <= not(wrbuf_goingfull);                     
                            sl_wrbterm_ns             <= not(wrbuf_goingfull);  
                            plb_write_cntl_state_ns   <= PBWR_BURST_FIXED;

                        -- 4 word chaceln reads are a single beat on a 128-bit bus
                        -- therefore transision to the single data beat write state
                        elsif (cacheln_transfer = '1' and size_i = "0001"
                        and C_IPIF_DBUS_WIDTH = 128 and msize_i = "10")then
                            wrbuffer_wren             <= '1';
                            sl_wrdack_ns              <= '1';                                     
                            sl_wrcomp_ns              <= '1';                                     
                            plb_write_cntl_state_ns   <= PBWRITE_FLUSH;                           

                        -- Not a single beat transfer, not a 4-Word Cacheline,
                        -- and more than 2 data beat burst
                        -- (8 or 16-Word Cacheline or Fixed Burst > 2)
                        elsif (single_transfer = '0') then  
                            wrbuffer_wren             <= not(wrbuf_goingfull); 
                            sl_wrdack_ns              <= not(wrbuf_goingfull);                   
                            plb_write_cntl_state_ns   <= PBWR_BURST_FIXED;

                        -- Single data beat write
                        else
                            wrbuffer_wren             <= '1';
                            sl_wrdack_ns              <= '1';                                 
                            sl_wrcomp_ns              <= '1';                                 
                            plb_write_cntl_state_ns   <= PBWRITE_FLUSH;

                        end if;
                    else
                        plb_write_cntl_state_ns <= PBWR_IDLE;
                    end if;


                when PBWR_BURST_FIXED =>
                    if (line_count_done = '1') then
                        
                        if(wrbuf_goingfull = '0')then
                            wrbuffer_wren            <= '1';
                            sl_wrdack_ns             <= '1';
                            sl_wrcomp_ns             <= '1';
                            plb_write_cntl_state_ns  <= PBWRITE_FLUSH;
                        else
                            plb_write_cntl_state_ns  <= PBWR_BURST_FIXED;
                        end if;

                    else
                        wrbuffer_wren            <= not(wrbuf_goingfull);
                        sl_wrdack_ns             <= not(wrbuf_goingfull);
                        sl_wrbterm_ns            <= line_count_almostdone and
                                                    burst_transfer_reg
                                                    and not(wrbuf_goingfull);--gab 9/29/06


                        plb_write_cntl_state_ns  <= PBWR_BURST_FIXED;
                    end if;



                when PBWRITE_FLUSH =>
                    plb_write_cntl_state_ns   <= PBWR_IDLE;

--coverage off
                when others   =>

                    plb_write_cntl_state_ns   <= PBWR_IDLE;
--coverage on

            end case;

        end process PLB_WRITE_DATA_CONTROLLER;

    ---------------------------------------------------------------------------
    -- PLB_WR_SM_SYNCD
    -- This process registers the syncronous outputs of the PLB Write state
    -- machine.
    ---------------------------------------------------------------------------
    PLB_WR_SM_SYNCD : process (bus_clk)
       begin
         if (Bus_Clk'event and Bus_Clk = '1') then
            if (Bus_Reset = '1') then

               plb_write_cntl_state   <= PBWR_IDLE;
               sl_wrdack_i            <= '0';
               sl_wrcomp_i            <= '0';
               sl_wrbterm_i           <= '0';

            else

               plb_write_cntl_state   <= plb_write_cntl_state_ns;
               sl_wrdack_i            <= sl_wrdack_ns ;
               sl_wrcomp_i            <= sl_wrcomp_ns ;
               sl_wrbterm_i           <= sl_wrbterm_ns;

            end if;
         end if;
       end process PLB_WR_SM_SYNCD;

    ---------------------------------------------------------------------------
    -- GEN_wr_buf_wren
    -- This process generates the write enable to the write buffer.
    -- It is essentially an echo of sl_wrDAck response to the PLB
    ---------------------------------------------------------------------------
    -- Generate 2 write enables to reduce fanout
    GEN_WRBUF_WREN1 : FDR
        port map(
            Q  =>  wr_buf_wren,  
            C  =>  bus_clk,                
            D  =>  sl_wrdack_ns,  
            R  =>  bus_reset                 
        );

    GEN_WRBUF_WREN2 : FDR
        port map(
            Q  =>  wr_buf_wren2,  
            C  =>  bus_clk,                
            D  =>  sl_wrdack_ns,  
            R  =>  bus_reset                 
        );

    -- Build the input data elements for the Wr Data Buffer
    wr_buf_data_in   <=  PLB_wrDBus;


    -----------------------------------------------------------------------
    -- Instantiate the FIFO implementing the Wr Data Buffer
    -----------------------------------------------------------------------
     WR_DATA_BUFFER : entity plbv46_slave_burst_v1_01_a.wr_buffer
        generic map(
            C_DWIDTH    => C_IPIF_DBUS_WIDTH    ,  
            C_AWIDTH    => WR_BUFFER_AWIDTH     ,
            C_DEPTH     => C_WR_BUFFER_DEPTH    ,    
            C_FAMILY    => C_FAMILY
        )
        port map(
            Clk         => bus_clk              ,          
            Reset       => Bus_reset            ,        
            FIFO_Write  => wr_buf_wren          ,      
            FIFO_Write2 => wr_buf_wren2         ,     
            Data_In     => wr_buf_data_in       ,   
            FIFO_Read   => wr_buf_move_data     , 
            Data_Out    => wr_buf_data_out      ,  
            FIFO_Full   => wrbuf_full           ,       
            FIFO_Empty  => wr_buf_empty         ,     
            Data_Exists => open                 ,             
            Addr        => wr_buff_addr_out  
        );

    -----------------------------------------------------------------------
    -- GEN_WRBUF_GOINGFULL
    -- This process determines if there is at least one vacant storage 
    -- location in the Write Buffer and it generates a signal to indicate
    -- the condition. Two storage locations are needed because there is a
    -- one clock delay between assertion of sl_wrAck_i and the next 
    -- plb_wrdata_reg being available to write into the write buffer.
    -----------------------------------------------------------------------
    GEN_WRBUF_GOINGFULL : process (wr_buff_addr_out)
        begin

            if (wr_buff_addr_out < std_logic_vector(to_unsigned(
                                    (C_WR_BUFFER_DEPTH-2),
                                     WR_BUFFER_AWIDTH)) )then
                wrbuf_goingfull <= '0';
            else
                wrbuf_goingfull <= '1';
            end if;
        end process GEN_WRBUF_GOINGFULL;

    ---------------------------------------------------------------------------
    -- IPIF_WR_DATA_CONTROLLER
    -- This process implements a state machine that transfers write data from
    -- the intermediate WR FIFO buffer to the selected target device (IPIF 
    -- element or IP)
    ---------------------------------------------------------------------------
    IPIF_WR_DATA_CONTROLLER : process (ipif_wr_cntl_state,
                                       start_data_phase,
                                       plb_rnw_reg,
                                       plb_size_sh_reg, 
                                       wr_buf_empty,
                                       burst_transfer_reg,
                                       cacheln_burst_reg,
                                       response_ack_i,
                                       response_done_i,
                                       sig_wr_data_ack,
                                       control_ack_i,
                                       control_done_i,
                                       plb_msize_reg)
        begin

            -- default conditions
            ipif_wr_cntl_state_ns  <= IWR_IDLE;
            wr_ce_ld_enable        <= '0';
            clear_wr_ce            <= '0';
            wr_buf_rden_ns         <= '0';
            clear_sl_wr_busy       <= '0';
            set_bus2ip_wrreq       <= '0';
            clr_bus2ip_wrreq       <= '0';
            wr_buf_move_data       <= '0';
            write_cntrl_idle       <= '1';

            case ipif_wr_cntl_state Is

                when IWR_IDLE =>
                    write_cntrl_idle       <= '1';

                    if (start_data_phase = '1'
                    and plb_rnw_reg      = '0') then
                        ipif_wr_cntl_state_ns   <= IWR_INIT;
                    else
                        ipif_wr_cntl_state_ns   <= IWR_IDLE;
                    end if;


                when IWR_INIT =>
                    -- if Write Buffer is NOT empty
                    if (wr_buf_empty = '0')then
                        wr_buf_move_data      <= '1';   
                        wr_ce_ld_enable       <= '1';
                        set_bus2ip_wrreq      <= '1';
                        -- 4 word cacheline and dwidth=128,
                        -- treat it as a single beat transfer
                        if(cacheln_burst_reg = '1' 
                        and plb_size_sh_reg = "0001"
                        and C_IPIF_DBUS_WIDTH = 128 
                        and plb_msize_reg = "10")then
                            ipif_wr_cntl_state_ns <= IWR_SINGLE1;

                        -- Not a 4 word cacheline or dwidth /=128 or
                        -- fixed burst
                        elsif(burst_transfer_reg = '1' 
                        or cacheln_burst_reg = '1') then
                            ipif_wr_cntl_state_ns <= IWR_BURST_FIXED1;

                        -- All other cases are singles beat
                        else
                            ipif_wr_cntl_state_ns <= IWR_SINGLE1;
                        end if;
                    else
                        ipif_wr_cntl_state_ns <= IWR_INIT;
                    end if;

                -- Single Beat Write
                when IWR_SINGLE1 =>
                    clr_bus2ip_wrreq        <= '1'; 
                    if(response_ack_i = '1')then
                        clear_sl_wr_busy        <= '1';
                        clear_wr_ce             <= '1';
                        ipif_wr_cntl_state_ns   <= IWR_IDLE;
                    else
                      ipif_wr_cntl_state_ns     <= IWR_SINGLE1;
                    end if;

                -- Fixed / Cacheline Burst Write
                when IWR_BURST_FIXED1 =>
                    if (response_ack_i = '1'
                    and response_done_i = '1')then 
                        clear_sl_wr_busy      <= '1';
                        clear_wr_ce           <= '1';
                        clr_bus2ip_wrreq      <= '1';
                        ipif_wr_cntl_state_ns <= IWR_IDLE;
                    else
                        ipif_wr_cntl_state_ns <= IWR_BURST_FIXED1;
                        wr_buf_move_data      <= sig_wr_data_ack;
                        clr_bus2ip_wrreq      <= (control_ack_i
                                              and control_done_i);
                    end if;

--coverage off
                when others   =>
                    ipif_wr_cntl_state_ns   <= IWR_IDLE;
--coverage on
            end case;
       end process IPIF_WR_DATA_CONTROLLER;

    ---------------------------------------------------------------------------
    -- IPIF_WR_SM_SYNCD
    -- This process registers the outputs of the IPIF Write Data Controller
    -- State Machine.
    ---------------------------------------------------------------------------
    IPIF_WR_SM_SYNCD : process (bus_clk)
        begin
            if (Bus_Clk'event and Bus_Clk = '1') then
                if (bus_reset = '1') then
                    ipif_wr_cntl_state  <= IWR_IDLE;
                else
                    ipif_wr_cntl_state  <= ipif_wr_cntl_state_ns;
                end if;
            end if;
        end process IPIF_WR_SM_SYNCD;

    ---------------------------------------------------------------------------
    -- DO_WR_DATA_REG
    -- This process implements the wr data register. It registers the output of
    -- the intermediate Wr Data FIFO buffer.
    ---------------------------------------------------------------------------
    DO_WR_DATA_REG : process (bus_clk)
        begin
            if(bus_clk'event and bus_clk = '1')then
                if(bus_reset = '1' )then
                    bus2ip_data_i <= (others => '0');

                elsif(wr_buf_move_data = '1')then
                    bus2ip_data_i <= wr_buf_data_out;

                end if;
            end if;
        end process DO_WR_DATA_REG;

    ---------------------------------------------------------------------------
    -- WRCE Sample and Holde for P2P mode, pass through for Shared mode.
    ---------------------------------------------------------------------------
    GEN_WRCE_FOR_P2P : if C_SPLB_P2P = 1 generate
    begin
        DO_WRCE_REG : process (bus_clk)
            begin
                if(bus_clk'event and bus_clk = '1')then
--                    if(bus_reset = '1' or clr_bus2ip_wrreq='1')then
                    if(bus_reset = '1' or clear_wr_ce='1')then
                        Bus2IP_WrCE  <= (others => '0');
--                    elsif(set_bus2ip_wrreq='1')then
                    elsif(wr_ce_ld_enable='1')then
                        Bus2IP_WrCE  <= bus2ip_wrce_i;
                    end if;
                end if;
            end process DO_WRCE_REG;
    end generate GEN_WRCE_FOR_P2P;

    GEN_WRCE_FOR_SHARED : if C_SPLB_P2P = 0 generate
        Bus2IP_WrCE         <= bus2ip_wrce_i; 
    end generate GEN_WRCE_FOR_SHARED;

    ---------------------------------------------------------------------------
    ---------------------------------------------------------------------------
    BUS2IP_WRBURST : process(bus_clk)
        begin
            if(bus_clk'EVENT and bus_clk='1')then
                if(bus_reset = '1' 
                or (response_almostdone_i='1' and response_ack_i='1'))then
                    bus2ip_wrburst_i <= '0';
--GAB 6/15/07 Qualified PLB_wrBurst with plb_rnw_reg to work around issue with PLB_wrBurst
--being asserted incorrectly on the PLB bus
                elsif((start_data_phase = '1' and PLB_wrBurst = '1' and plb_rnw_reg='0')
               
               or (start_data_phase='1' and cacheln_transfer='1' 
               and plb_rnw_reg='0' and inhibit_wrburst='0'))then
               
                    bus2ip_wrburst_i <= '1';
                end if;
            end if;
        end process BUS2IP_WRBURST;

    GEN_INHBURST_128 : if C_IPIF_DBUS_WIDTH=128 generate 
        inhibit_wrburst <= '1' when cacheln_transfer='1'
                                    and plb_size  = "0001"
                                    and plb_msize = "10"
                      else '0';
    end generate GEN_INHBURST_128;
    
    GEN_NOINHBURST : if C_IPIF_DBUS_WIDTH/=128 generate
        inhibit_wrburst <= '0';
    end generate GEN_NOINHBURST;

    ---------------------------------------------------------------------------
    -- Check that the data phase is done
    -- when the data cycle counter has reached zero, signal a 'done' to the
    -- data controller state machine.
    ---------------------------------------------------------------------------
--    CHECK_DATA_DONE : process (data_cycle_count,sl_wrdack_i) 
--        begin
--            if (data_cycle_count = 2 and sl_wrdack_i = '1' )then   
--                line_count_done       <= '0';
--                line_count_almostdone <= '1';
--
--            elsif (data_cycle_count <= 1 and sl_wrdack_i = '1' )then        
--                line_count_done       <= '1';
--                line_count_almostdone <= '0';
--
--            else
--                line_count_done       <= '0';
--                line_count_almostdone <= '0';
--            end if;
--         end process CHECK_DATA_DONE;

    CHECK_DATA_DONE : process (data_cycle_count) 
        begin
            if (data_cycle_count = 2 )then   
                line_count_done       <= '0';
                line_count_almostdone <= '1';

            elsif (data_cycle_count <= 1  )then        
                line_count_done       <= '1';
                line_count_almostdone <= '0';

            else
                line_count_done       <= '0';
                line_count_almostdone <= '0';
            end if;
         end process CHECK_DATA_DONE;
end generate GEN_WRITE_BUFFER;


---------------------------------------------------------------------------
-------------------------- No Write Buffer --------------------------------
---------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- No Write Buffer
-- Do Not generate a write buffer when the depth parameter equals 0.
-------------------------------------------------------------------------------
GEN_NO_WRITE_BUFFER : if C_WR_BUFFER_DEPTH = 0 generate

type PLB_WRDATA_CNTRL_STATES is (
                  PBWR_IDLE,
                  PBWR_SINGLE,
                  PBWR_BURST_FIXED
                  );
signal plb_write_cntl_state     : PLB_WRDATA_CNTRL_STATES;
signal plb_write_cntl_state_ns  : PLB_WRDATA_CNTRL_STATES;
signal wr_data_ack              : std_logic;
signal inhibit_wrburst          : std_logic;
begin

    ---------------------------------------------------------------------------
    -- Read Data Controller
    -- This state machine controls the transfer of data to
    -- the PLB Bus (Reads).
    ---------------------------------------------------------------------------
    IPIF_WR_DATA_CONTROLLER : process (plb_write_cntl_state,
                                     start_data_phase,
                                     plb_rnw_reg,
                                     plb_size_reg,  
                                     cacheln_transfer, 
                                     single_transfer,
                                     control_ack_i,
                                     control_done_i,
                                     response_ack_i,
                                     response_done_i,
                                     sa2mirror_MSize_i,
                                     sig_wr_data_ack)
                                     --ip2bus_wrack)  
      begin

        -- default conditions
         wr_ce_ld_enable        <= '0';
         clear_wr_ce            <= '0';
         clear_sl_wr_busy       <= '0';
         set_bus2ip_wrreq       <= '0';
         clr_bus2ip_wrreq       <= '0';
         write_cntrl_idle       <= '0';
         write_cntrl_burst      <= '0';

         case plb_write_cntl_state Is

           when PBWR_IDLE =>
              write_cntrl_idle       <= '1';
              if (start_data_phase = '1' and
                  plb_rnw_reg      = '0') then

                 wr_ce_ld_enable      <= '1';
                 set_bus2ip_wrreq     <= '1';

                 --4 word cacheln read for 128 bit wide dbus
                 if (cacheln_transfer = '1' and plb_size_reg = "0001"    
                 and C_IPIF_DBUS_WIDTH = 128
                 and sa2mirror_MSize_i = "10")then
                   plb_write_cntl_state_ns  <= PBWR_SINGLE;

                 -- fixed burst or 8 or 16 word cacheln write
                 -- or for 64 or 32 bit wide dbus then 4 word cacheln
                 elsif (single_transfer = '0') then  
                    write_cntrl_burst       <= '1';
                    plb_write_cntl_state_ns <= PBWR_BURST_FIXED;

                 else                         -- single beat read request
                   plb_write_cntl_state_ns  <= PBWR_SINGLE;

                 end if;

              else

                 plb_write_cntl_state_ns  <= PBWR_IDLE;
                 clr_bus2ip_wrreq         <= '1';

              end if;


           when PBWR_SINGLE =>

              clr_bus2ip_WrReq        <= '1';
--              if (ip2bus_wrack = '1') then
              if (sig_wr_data_ack = '1') then
                 plb_write_cntl_state_ns   <= PBWR_IDLE;
                 clear_sl_wr_busy         <= '1';
                 clear_wr_ce              <= '1';
              else
                 plb_write_cntl_state_ns  <= PBWR_SINGLE;
              end if;

           when PBWR_BURST_FIXED =>

              clr_bus2ip_wrreq      <= (control_ack_i and
                                        control_done_i);
              if (response_ack_i = '1' and
                  response_done_i = '1') then

                 plb_write_cntl_state_ns <= PBWR_IDLE;
                 clear_sl_wr_busy        <= '1';
                 clear_wr_ce             <= '1';
              else
                 write_cntrl_burst        <= '1';
                 plb_write_cntl_state_ns  <= PBWR_BURST_FIXED;
              end if;

--coverage off
           when others   =>
              plb_write_cntl_state_ns  <= PBWR_IDLE;
              clear_wr_ce              <= '1';
--coverage on
         end case;

    end process IPIF_WR_DATA_CONTROLLER;

    -----------------------------------------------------------------------
    -- PLB_RD_SM_SYNCD
    -- This process registers outputs from the PLB Read Data
    -- state machine.
    -----------------------------------------------------------------------
    IPIF_WR_SM_SYNCD : process (bus_clk)
        begin
            if (Bus_Clk'event and Bus_Clk = '1') then
                if (Bus_reset = '1') then
                    plb_write_cntl_state   <= PBWR_IDLE;
                else
                    plb_write_cntl_state  <= plb_write_cntl_state_ns;
                end if;
            end if;
    end process IPIF_WR_SM_SYNCD;

    -----------------------------------------------------------------------
    -- Generate IP2Bus_Burst Signal
    -----------------------------------------------------------------------
    BUS2IP_WRBURST : process(bus_clk)
        begin
            if(bus_clk'EVENT and bus_clk='1')then
                if(bus_reset = '1' 
                or (response_almostdone_i='1' and response_ack_i='1'))then
                    bus2ip_wrburst_i <= '0';
--GAB 6/15/07 Qualified PLB_wrBurst with plb_rnw_reg to work around issue with PLB_wrBurst
--being asserted incorrectly on the PLB bus
                elsif((start_data_phase = '1' and PLB_wrBurst = '1' and plb_rnw_reg='0')
                  or (start_data_phase='1' and cacheln_transfer='1' 
                  and plb_rnw_reg='0' and inhibit_wrburst='0'))then
                    bus2ip_wrburst_i <= '1';
                end if;
            end if;
        end process BUS2IP_WRBURST;


        GEN_INHBURST_P2P : if C_IPIF_DBUS_WIDTH=128 generate --and C_SPLB_P2P = 1 generate
            inhibit_wrburst <= '1' when cacheln_transfer='1'
                                        and plb_size  = "0001"
                                        and plb_msize = "10"
                          else '0';
        end generate GEN_INHBURST_P2P;

--        GEN_INHBURST_SHARED : if C_IPIF_DBUS_WIDTH=128 and C_SPLB_P2P = 0 generate
--            inhibit_wrburst <= '1' when cacheln_burst_reg='1'
--                                        and plb_size_reg  = "0001"
--                                        and plb_msize_reg = "10"
--                          else '0';
--        end generate GEN_INHBURST_SHARED;

        GEN_NOINHBURST : if C_IPIF_DBUS_WIDTH/=128 generate
            inhibit_wrburst <= '0';
        end generate GEN_NOINHBURST;






    -- Write Burst Terminate
    sl_wrbterm_i        <= response_almostdone_i        -- Almost Done
                            and sl_wrdack_i             -- and on a ack       
                            and burst_transfer_reg;     -- and for fixed burst
    
    -- Write Complete
    sl_wrcomp_i         <= '1' when data_cycle_count = 0  and sl_wrdack_i = '1'
                      else '0';

--    sl_wrdack_i         <= ip2bus_wrack;
    sl_wrdack_i         <= sig_wr_data_ack;
    wr_buf_wren         <= sl_wrdack_i;
    wrbuffer_wren       <= sl_wrdack_i;
    
    bus2ip_data_i       <= PLB_wrDBus; 
    Bus2IP_WrCE         <= bus2ip_wrce_i; 

--    ------------------------------------------------------------------------------
--    -- Transfer counter control
--    -- This process keeps track of how many data transfers into the write buffer
--    -- occur during a write request.
--    --
--    -- This is primarily used during cache line writes and burst writes.
--    ------------------------------------------------------------------------------
--    WBUF_CYCLE_COUNTER : process (Bus_clk)
--        begin
--            if (Bus_clk'EVENT and Bus_clk = '1') then
--                if (Bus_reset = '1') then
--                    data_cycle_count <= 0;
--
--                -- Load data cycle count at beginning of write cycle
--                elsif(write_cntrl_idle = '1'
--                and start_data_phase = '1') then
--                    if(MAX_FLBURST_SIZE > num_data_beats_minus1)then
--                        data_cycle_count <= num_data_beats_minus1;
--                    else
--                        data_cycle_count <= MAX_FLBURST_SIZE - 1;
--                    end if;
--
--                elsif(data_cycle_count /= 0 and sl_wrdack_i = '1')then 
--                    data_cycle_count <= data_cycle_count-1;
--                end if;
--            end if;
--        end process WBUF_CYCLE_COUNTER;

end generate GEN_NO_WRITE_BUFFER;

------------------------------------------------------------------------------
-- Transfer counter control
-- This process keeps track of how many data transfers into the write buffer
-- occur during a write request.
--
-- This is primarily used during cache line writes and burst writes.
------------------------------------------------------------------------------
WBUF_CYCLE_COUNTER : process (Bus_clk)
    begin
        if (Bus_clk'EVENT and Bus_clk = '1') then
            if (Bus_reset = '1') then
                data_cycle_count <= 0;

            -- Load data cycle count at beginning of write cycle
            elsif(write_cntrl_idle = '1'
            and start_data_phase = '1') then
-- removed for code coverage
-- MAX_FLBURST_SIZE will always be greater than or equal to num_data_beats_minus1
--                if(MAX_FLBURST_SIZE > num_data_beats_minus1)then
                    data_cycle_count <= num_data_beats_minus1;
--                else
--                    data_cycle_count <= MAX_FLBURST_SIZE - 1;
--                end if;

            elsif(data_cycle_count /= 0 and wrbuffer_wren = '1')then 
                data_cycle_count <= data_cycle_count-1;
            end if;
        end if;
    end process WBUF_CYCLE_COUNTER;

---------------------------------------------------------------------------
-- Instantiate the Register for the Bus2IP_WrReq signal generation.
-- This is needed for Terminating Bus2IP_WrReq signal
-- when the Address & Control timing is complete but data transfer is
-- not yet complete due to pipeline delays (Address preceeds data).
---------------------------------------------------------------------------
I_WRREQ_FDRSE : FDRSE
    port map(
        Q  =>  bus2ip_wrreq_i,    
        C  =>  Bus_Clk,           
        CE =>  '1',               
        D  =>  bus2ip_wrreq_i,    
        R  =>  clr_bus2ip_wrreq,  
        S  =>  set_bus2ip_wrreq   
    );

bus2ip_burst_i <= bus2ip_wrburst_i or bus2ip_rdburst_i;

---------------------------------------------------------------------------
-- GEN_XFER_CYCLE_COUNT
-- This process generates the data beat count required for a transaction.
-- It uses the PLB Size and PLB BE control signals to calculate the 
-- required count value.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- 128-Bit Slave 
---------------------------------------------------------------------------
GEN_128BIT_BUS : if C_IPIF_DBUS_WIDTH = 128 generate
    GEN_XFER_CYCLE_COUNT : process (size_i,
                                    be_i,
                                    be_burst_size,
                                    msize_i)
       begin

          be_burst_size <= (others => '0');

          case size_i Is
            -- 1 word xfer
            when "0000" =>
                be_burst_size <= (others => '0');
            -- 4 word xfer (1 quad words)
            when "0001" =>
                -- Request from 128Bit Master
                if(msize_i = "10")then 
                    be_burst_size <= (others => '0');
                -- Request from 64Bit Master
                elsif(msize_i = "01")then
                    be_burst_size <= ONE;
                -- Request from 32Bit Master
                else    
                    be_burst_size <= THREE;
                end if;

            -- 8 word xfer (2 quad words)
            when "0010" =>
                -- Request from 128Bit Master
                if(msize_i = "10")then 
                    be_burst_size <= ONE;
                -- Request from 64Bit Master
                elsif(msize_i = "01")then
                    be_burst_size <= THREE;
                -- Request from 32Bit Master
                else    
                    be_burst_size <= SEVEN;
                end if;
-- removed for code coverage
-- 16 word cache line not supported
--            -- 16 word xfer (4 quad words)
--            when "0011" =>
--                -- Request from 128Bit Master
--                if(msize_i = "10")then 
--                    be_burst_size <= THREE;
--                -- Request from 64Bit Master
--                elsif(msize_i = "01")then
--                    be_burst_size <= SEVEN;
--                -- Request from 32Bit Master
--                else    
--                    be_burst_size <= FIFTEEN;
--                end if;

            -- Burst transfer of bytes, halfwords, words, 
            -- double words, and quad words
            when "1000" | "1001" | "1010" | "1011" | "1100" =>  
                -- Request from 32Bit Master
                if(msize_i = "00")then    
                    be_burst_size       <= "000000" 
                                                & be_i(0 to 3);
                else
                    be_burst_size       <= "00" & be_i(4 to 7) 
                                                & be_i(0 to 3);
                end if;

            -- undefined operations so assume 1 data beat
--coverage off
            when others   =>
                be_burst_size <= (others => '0');
--coverage on

          end case;

       end process GEN_XFER_CYCLE_COUNT;
end generate  GEN_128BIT_BUS;

-------------------------------------------------------------
-- 64-Bit Slave 
-------------------------------------------------------------
GEN_64BIT_BUS : if C_IPIF_DBUS_WIDTH = 64 generate
    GEN_XFER_CYCLE_COUNT : process (size_i,
                                    be_i,
                                    be_burst_size,
                                    msize_i)
       begin

          be_burst_size         <= (others => '0');

          case size_i Is
            -- 1 word xfer
            when "0000" =>
                be_burst_size <= (others => '0');

            -- 4 word xfer (2 double words)
            when "0001" =>
                -- Request from 64Bit or 128Bit Master
                if(msize_i = "01"
                or msize_i = "10")then
                    be_burst_size <= ONE;
                -- Request from 32Bit Master
                else    
                    be_burst_size <= THREE;
                end if;

            -- 8 word xfer (4 double words)
            when "0010" =>
                -- Request from 64Bit or 128Bit Master
                if(msize_i = "01"
                or msize_i = "10")then
                    be_burst_size <= THREE;
                -- Request from 32Bit Master
                else    
                    be_burst_size <= SEVEN;
                end if;

-- removed for code coverage
-- 16 word cachelines not supported
--            -- 16 word xfer (8 double words)
--            when "0011" =>
--                -- Request from 64Bit or 128Bit Master
--                if(msize_i = "01"
--                or msize_i = "10")then
--                    be_burst_size <= SEVEN;
--                -- Request from 32Bit Master
--                else    
--                    be_burst_size <= FIFTEEN;
--                end if;

            -- Burst transfer of bytes, halfwords, words
            -- and double words
            when "1000" | "1001" | "1010" | "1011" =>  
                -- Request from 32Bit Master
                if(msize_i = "00")then    
                    be_burst_size   <= "000000" 
                                            & be_i(0 to 3);
                else
                    be_burst_size   <= "00" & be_i(4 to 7) 
                                            & be_i(0 to 3);
                end if;

            -- Burst transfer of quad words (Double Words * 2)
            when "1100"  =>        
                be_burst_size       <= '0'  & be_i(4 to 7) 
                                            & be_i(0 to 3) 
                                            & '1';

            -- Undefined operations so assume 1 data beat
--coverage off
            when others   =>
                be_burst_size       <= (others => '0');
--coverage on
          end case;

       end process GEN_XFER_CYCLE_COUNT;
end generate  GEN_64BIT_BUS;

-------------------------------------------------------------
-- 32-Bit Slave 
-------------------------------------------------------------
GEN_32BIT_BUS : if C_IPIF_DBUS_WIDTH = 32 generate
    GEN_XFER_CYCLE_COUNT : process (size_i,
                                    be_i,
                                    be_burst_size)
       begin

          be_burst_size <= (others => '0');

          case size_i Is

            -- 1 word xfer
            when "0000" =>
                be_burst_size <= (others => '0');
            -- 4 word xfer 
            when "0001" =>
                be_burst_size <= THREE;

            -- 8 word xfer
            when "0010" =>
                be_burst_size <= SEVEN;
-- removed for code coverage
-- 16 word cachelines not supported
--            -- 16 word xfer
--            when "0011" =>
--                be_burst_size <= FIFTEEN;

            -- Burst transfer of bytes, halfwords, and words
            when "1000" | "1001" | "1010" =>  
                be_burst_size           <= "00" & be_i(0 to 3);

            -- Burst transfer of double words (Words * 2)
            when "1011" =>        
                be_burst_size   <= '0' & be_i(0 to 3) & '1';

            -- Burst transfer of quad words (Words * 4)
            when "1100"  =>      
                be_burst_size   <= be_i(0 to 3) & "11";

            -- Undefined operations so assume 1 data beat
--coverage off
            when others   =>
                be_burst_size <= (others => '0');
--coverage on

          end case;

       end process GEN_XFER_CYCLE_COUNT;
end generate  GEN_32BIT_BUS;


-- Convert number of data beats - 1 into an integer
num_data_beats_minus1   <= to_integer(unsigned(be_burst_size));

-------------------------------------------------------------------------------
-- Output burst length in units of bytes
-------------------------------------------------------------------------------
GEN_LENGTH_EQ_BYTES : if C_BURSTLENGTH_TYPE = 0 generate
    -----------------------------------------------------------------------
    -- Determine Number of data beats for fixed length burst    
    -----------------------------------------------------------------------
-- This ipif does not support burst counts > 16
--    GEN_BRSTLNGTH_GRTR32 : if C_IPIF_DBUS_WIDTH >= 64 generate
--        DBEAT_CNT_PROCESS : process(plb_msize,plb_be_reg)
--            begin
--                if(plb_msize = "00")then
--                    dbeat_cnt <= "0000" & plb_be_reg(0 to 3);
--                else                
--                    dbeat_cnt <= plb_be_reg(4 to 7) & plb_be_reg(0 to 3);
--                end if;
--            end process DBEAT_CNT_PROCESS;
--    end generate GEN_BRSTLNGTH_GRTR32;
--
--    GEN_BRSTLNGTH_EQL32 : if C_IPIF_DBUS_WIDTH = 32 generate
--        dbeat_cnt       <= plb_be_reg;
--    end generate GEN_BRSTLNGTH_EQL32;
--
-- This ipif does not support burst counts > 16
-- To support dbeats greater than 16 the BURST_LENGTH_PROCESS and in particular
-- brstlength_i vector will need to increase in width.
    dbeat_cnt <= plb_be_reg(0 to 3);
    fixed_dbeat_cnt <= to_integer(unsigned(dbeat_cnt))+1;

--BURST_LENGTH_PROCESS : process (plb_size_reg,fixed_dbeat_cnt,plb_msize_reg)
--    begin
--
--        case plb_size_reg Is
--
--            -- 1 word xfer
--            when "0000" =>
--                brstlength_i    <= std_logic_vector(to_unsigned
--                                    (0,log2(C_DEV_MAX_BURST_SIZE)+1));
--            -- 4 word xfer 
--            when "0001" =>
--                if(C_IPIF_DBUS_WIDTH=128 and plb_msize_reg="10")then
--                    brstlength_i <= (others => '0');
--                else
--                    brstlength_i    <= std_logic_vector(to_unsigned
--                                        (16,log2(C_DEV_MAX_BURST_SIZE)+1));
--                end if;
--            -- 8 word xfer
--            when "0010" =>
--                brstlength_i    <= std_logic_vector(to_unsigned
--                                    (32,log2(C_DEV_MAX_BURST_SIZE)+1));
--            -- 16 word xfer
--            when "0011" =>
--                brstlength_i    <= std_logic_vector(to_unsigned
--                                    (64,log2(C_DEV_MAX_BURST_SIZE)+1));
--
--            -- Burst transfer of bytes, 
--            when "1000" =>
--                brstlength_i    <= std_logic_vector(to_unsigned
--                                    (fixed_dbeat_cnt,
--                                    log2(C_DEV_MAX_BURST_SIZE)+1));
--
--            -- Burst transfer of half words
--            when "1001" =>
--                brstlength_i    <= std_logic_vector(to_unsigned
--                                    (fixed_dbeat_cnt,
--                                    log2(C_DEV_MAX_BURST_SIZE))) & '0';
--
--            -- Burst transfer of words
--            when "1010" =>  
--                if(C_DEV_MAX_BURST_SIZE >= 4)then
--                    brstlength_i    <= std_logic_vector(to_unsigned
--                                        (fixed_dbeat_cnt,
--                                        log2(C_DEV_MAX_BURST_SIZE)-1)) & "00";
--                else
--                    brstlength_i    <= (others => '0');  
--                end if;
--
--            -- Burst transfer of double words (Words * 2)
--            when "1011" =>        
--                if(C_DEV_MAX_BURST_SIZE >= 8)then
--                    brstlength_i    <= std_logic_vector(to_unsigned
--                                        (fixed_dbeat_cnt,
--                                        log2(C_DEV_MAX_BURST_SIZE)-2)) & "000";
--                else
--                    brstlength_i    <= (others => '0');  
--                end if;
--
--            -- Burst transfer of quad words (Words * 4)
--            when "1100"  =>      
--                if(C_DEV_MAX_BURST_SIZE >= 16)then
--                    brstlength_i    <= std_logic_vector(to_unsigned
--                                        (fixed_dbeat_cnt,
--                                        log2(C_DEV_MAX_BURST_SIZE)-3)) & "0000";
--                else
--                    brstlength_i    <= (others => '0');  
--                end if;
--
--            -- Undefined operations so assume 1 data beat
--            when others   =>
--                brstlength_i    <= (others => '0');  
--
--        end case;
--
--    end process BURST_LENGTH_PROCESS;
--    
--    REG_BURST_LENGTH : process(Bus_clk)
--        begin
--            if(Bus_clk'EVENT and Bus_clk = '1')then
--                if(Bus_Reset = '1' or decode_cs_ce_clr = '1')then
--                    burstlength_i <= (others => '0');
--                elsif(addr_cntr_load_en = '1')then
--                    burstlength_i <= brstlength_i;
--                end if;
--            end if;
--        end process REG_BURST_LENGTH;


    ---------------------------------------------------------------------------
    -- Generate Burst Length
    ---------------------------------------------------------------------------
    BURST_LENGTH_PROCESS : process (plb_size_reg,fixed_dbeat_cnt,plb_msize_reg)
        begin

            case plb_size_reg Is

                -- 1 word xfer
                when "0000" =>
                    brstlength_i    <= (others => '0');
                -- 4 word xfer 
                when "0001" =>
                    if(C_IPIF_DBUS_WIDTH=128 and plb_msize_reg="10")then
                        brstlength_i <= (others => '0');
                    else
                        brstlength_i    <= std_logic_vector(to_unsigned(16,13));
                    end if;
                -- 8 word xfer
                when "0010" =>
                    brstlength_i    <= std_logic_vector(to_unsigned(32,13));

-- removed for code coverage
-- 16 word cachelines not supported
--                -- 16 word xfer
--                when "0011" =>
--                    brstlength_i    <= std_logic_vector(to_unsigned(64,13));

                -- Burst transfer of bytes, 
                when "1000" =>
                    brstlength_i    <= std_logic_vector(to_unsigned
                                        (fixed_dbeat_cnt,13));

                -- Burst transfer of half words
                when "1001" =>
                    brstlength_i    <= "000" & std_logic_vector(to_unsigned
                                        (fixed_dbeat_cnt,9)) & '0';

                -- Burst transfer of words
                when "1010" =>  
-- removed for code coverage
-- C_DEV_MAX_BURST_SIZE is hardcoded to 16 or greater in top level
--                    if(C_DEV_MAX_BURST_SIZE >= 4)then
                        brstlength_i    <= "00" & std_logic_vector(to_unsigned
                                            (fixed_dbeat_cnt,9)) & "00";
--                    else
--                        brstlength_i    <= (others => '0');  
--                    end if;

                -- Burst transfer of double words (Words * 2)
                when "1011" =>        
-- removed for code coverage
-- C_DEV_MAX_BURST_SIZE is hardcoded to 16 or greater in top level
--                    if(C_DEV_MAX_BURST_SIZE >= 8)then
                        brstlength_i    <= '0' & std_logic_vector(to_unsigned
                                            (fixed_dbeat_cnt,9)) & "000";
--                    else
--                        brstlength_i    <= (others => '0');  
--                    end if;
                
                -- Burst transfer of quad words (Words * 4)
                when "1100"  =>      
-- removed for code coverage
-- C_DEV_MAX_BURST_SIZE is hardcoded to 16 or greater in top level
--                    if(C_DEV_MAX_BURST_SIZE >= 16)then
                        brstlength_i    <= std_logic_vector(to_unsigned
                                            (fixed_dbeat_cnt,9)) & "0000";
--                    else
--                        brstlength_i    <= (others => '0');  
--                    end if;
                
                -- Undefined operations so assume 1 data beat
--coverage off
                when others   =>
                    brstlength_i    <= (others => '0');  
--coverage on

            end case;

        end process BURST_LENGTH_PROCESS;

        REG_BURST_LENGTH : process(Bus_clk)
            begin
                if(Bus_clk'EVENT and Bus_clk = '1')then
                    if(Bus_Reset = '1' or decode_cs_ce_clr = '1')then
                        burstlength_i <= (others => '0');
                    elsif(addr_cntr_load_en = '1')then
                        burstlength_i <= brstlength_i(12-log2(C_DEV_MAX_BURST_SIZE) to 12);
                    end if;
                end if;
            end process REG_BURST_LENGTH;
    
end generate GEN_LENGTH_EQ_BYTES;

-- Output burst length in data beats - 1
GEN_LENGTH_EQ_DBEATS : if C_BURSTLENGTH_TYPE = 1 generate
constant DBEAT_CNTR_SIZE    : integer := log2(MAX_FLBURST_SIZE);
constant LENGTH_PAD         : std_logic_vector
                                (0 to log2(C_DEV_MAX_BURST_SIZE)
                                -DBEAT_CNTR_SIZE) := (others => '0');
begin
    REG_BURST_LENGTH : process(Bus_clk)
        begin
            if(Bus_clk'EVENT and Bus_clk = '1')then
                if(Bus_Reset = '1' or decode_cs_ce_clr = '1')then
                    burstlength_i <= (others => '0');
                elsif(addr_cntr_load_en = '1')then
                    burstlength_i <= LENGTH_PAD & std_logic_vector
                                        (to_unsigned((num_data_beats_minus1),
                                        DBEAT_CNTR_SIZE));
                end if;
            end if;
        end process REG_BURST_LENGTH;
end generate GEN_LENGTH_EQ_DBEATS;

---------------------------------------------------------------------------
-- Read Data Register
-- This process controls the registering and output of the Slave read data
-- onto the PLB Bus.  Logic duplications was utilized to reduce fan-out for
-- the 128-bit wide data bus
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Generate Read Bus for 128-Bit Data Width
---------------------------------------------------------------------------
GEN_FOR_128 : if C_IPIF_DBUS_WIDTH = 128 generate
signal sl_rddbus1_i         : std_logic_vector(0 to 31);
signal sl_rddbus2_i         : std_logic_vector(0 to 31);
signal sl_rddbus3_i         : std_logic_vector(0 to 31);
signal sl_rddbus4_i         : std_logic_vector(0 to 31);

signal rd1_dphase_active    : std_logic;
signal rd2_dphase_active    : std_logic;
signal rd3_dphase_active    : std_logic;
signal rd4_dphase_active    : std_logic;


begin


    -- Direct instantiate D-FF's to prevent removal due to
    -- optimization during build.
    DPHASE_REG1 : FDR
    port map (
      Q  => rd1_dphase_active,  
      C  => Bus_clk,            
      D  => rd_dphase_active_ns, 
      R  => Bus_reset             
      );      

    DPHASE_REG2 : FDR
    port map (
      Q  => rd2_dphase_active,  
      C  => Bus_clk,            
      D  => rd_dphase_active_ns, 
      R  => Bus_reset             
      );      

    DPHASE_REG3 : FDR
    port map (
      Q  => rd3_dphase_active,  
      C  => Bus_clk,            
      D  => rd_dphase_active_ns, 
      R  => Bus_reset             
      );      

    DPHASE_REG4 : FDR
    port map (
      Q  => rd4_dphase_active,  
      C  => Bus_clk,            
      D  => rd_dphase_active_ns, 
      R  => Bus_reset             
      );      

    -- Section 1:
    GEN_0TO31_SECTION : for i in 0 to 31 generate

       READ_DATA_REGISTER1 : process (Bus_clk)
         begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
               if (Bus_reset = '1' or data_timeout='1') then
                  sl_rddbus1_i(i) <= '0';
               elsif (rd1_dphase_active = '1') then
                  sl_rddbus1_i(i) <= IP2Bus_Data(i);
               else
                  sl_rddbus1_i(i) <= '0';
               end if;
            end if;
        end process READ_DATA_REGISTER1; 

    end generate GEN_0TO31_SECTION;

    -- Section 2:
    GEN_32TO63_SECTION : for i in 32 to 63 generate

       READ_DATA_REGISTER2 : process (Bus_clk)
         begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
               if (Bus_reset = '1' or data_timeout='1') then
                  sl_rddbus2_i(i-32) <= '0';
               elsif (rd2_dphase_active = '1') then
                  sl_rddbus2_i(i-32) <= IP2Bus_Data(i);
               else
                  sl_rddbus2_i(i-32) <= '0';
               end if;
            end if;
        end process READ_DATA_REGISTER2; 

    end generate GEN_32TO63_SECTION;

    -- Section 3:
    GEN_64TO95_SECTION : for i in 64 to 95 generate

       READ_DATA_REGISTER3 : process (Bus_clk)
         begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
               if (Bus_reset = '1' or data_timeout='1') then
                  sl_rddbus3_i(i-64) <= '0';
               elsif (rd3_dphase_active = '1') then
                  sl_rddbus3_i(i-64) <= IP2Bus_Data(i);
               else
                  sl_rddbus3_i(i-64) <= '0';
               end if;
            end if;
        end process READ_DATA_REGISTER3; 

    end generate GEN_64TO95_SECTION;

    -- Section 4:
    GEN_96TO127_SECTION : for i in 96 to 127 generate

       READ_DATA_REGISTER4 : process (Bus_clk)
         begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
               if (Bus_reset = '1' or data_timeout='1') then
                  sl_rddbus4_i(i-96) <= '0';
               elsif (rd4_dphase_active = '1') then
                  sl_rddbus4_i(i-96) <= IP2Bus_Data(i);
               else
                  sl_rddbus4_i(i-96) <= '0';
               end if;
            end if;
        end process READ_DATA_REGISTER4; 

    end generate GEN_96TO127_SECTION;


    sl_rddbus_i <= sl_rddbus1_i 
                 & sl_rddbus2_i 
                 & sl_rddbus3_i 
                 & sl_rddbus4_i;

    READ_DATA_REGISTER : process (Bus_clk)
     begin
        if (Bus_clk'EVENT and Bus_clk = '1') then
           if (Bus_reset = '1') then
              sl_rdwdaddr_i <= (others => '0');
--           elsif (rd1_dphase_active = '1' and
--                  IP2Bus_RdAck = '1') then
           elsif (rd1_dphase_active = '1' and
                  sig_rd_data_ack = '1') then
              sl_rdwdaddr_i <= rdwdaddr;
           else
              sl_rdwdaddr_i <= (others => '0');
           end if;
        end if;
    end process; -- READ_DATA_REGISTER


end generate GEN_FOR_128;


---------------------------------------------------------------------------
-- Generate Read Bus for 64-Bit Data Width
---------------------------------------------------------------------------
GEN_FOR_64 : if C_IPIF_DBUS_WIDTH = 64 generate
signal sl_rddbus1_i         : std_logic_vector(0 to 31);
signal sl_rddbus2_i         : std_logic_vector(0 to 31);

signal rd1_dphase_active    : std_logic;
signal rd2_dphase_active    : std_logic;


begin


    DPHASE_REG1 : FDR
    port map (
      Q  => rd1_dphase_active,  
      C  => Bus_clk,            
      D  => rd_dphase_active_ns, 
      R  => Bus_reset             
      );      

    DPHASE_REG2 : FDR
    port map (
      Q  => rd2_dphase_active,  
      C  => Bus_clk,            
      D  => rd_dphase_active_ns, 
      R  => Bus_reset             
      );      

    -- Section 1:
    GEN_0TO31_SECTION : for i in 0 to 31 generate

       READ_DATA_REGISTER1 : process (Bus_clk)
         begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
               if (Bus_reset = '1' or data_timeout='1') then
                  sl_rddbus1_i(i) <= '0';
               elsif (rd1_dphase_active = '1') then
                  sl_rddbus1_i(i) <= IP2Bus_Data(i);
               else
                  sl_rddbus1_i(i) <= '0';
               end if;
            end if;
        end process READ_DATA_REGISTER1; 

    end generate GEN_0TO31_SECTION;

    -- Section 2:
    GEN_32TO63_SECTION : for i in 32 to 63 generate

       READ_DATA_REGISTER2 : process (Bus_clk)
         begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
               if (Bus_reset = '1' or data_timeout='1') then
                  sl_rddbus2_i(i-32) <= '0';
               elsif (rd2_dphase_active = '1') then
                  sl_rddbus2_i(i-32) <= IP2Bus_Data(i);
               else
                  sl_rddbus2_i(i-32) <= '0';
               end if;
            end if;
        end process READ_DATA_REGISTER2; 

    end generate GEN_32TO63_SECTION;


    sl_rddbus_i <= sl_rddbus1_i 
                 & sl_rddbus2_i;

    READ_DATA_REGISTER : process (Bus_clk)
     begin
        if (Bus_clk'EVENT and Bus_clk = '1') then
           if (Bus_reset = '1') then
              sl_rdwdaddr_i <= (others => '0');
--           elsif (rd1_dphase_active = '1' and
--                  IP2Bus_RdAck = '1') then
           elsif (rd1_dphase_active = '1' and
                  sig_rd_data_ack = '1') then
              sl_rdwdaddr_i <= rdwdaddr;
           else
              sl_rdwdaddr_i <= (others => '0');
           end if;
        end if;
    end process; -- READ_DATA_REGISTER

end generate GEN_FOR_64;

---------------------------------------------------------------------------
-- Generate Read Bus for 32-Bit Data Width
---------------------------------------------------------------------------
GEN_FOR_32 : if C_IPIF_DBUS_WIDTH = 32 generate
signal sl_rddbus1_i         : std_logic_vector(0 to 31);

signal rd1_dphase_active    : std_logic;

begin


    DPHASE_REG1 : FDR
    port map (
      Q  => rd1_dphase_active,  
      C  => Bus_clk,            
      D  => rd_dphase_active_ns, 
      R  => Bus_reset             
      );      


    -- Section 1:
    GEN_0TO31_SECTION : for i in 0 to 31 generate

       READ_DATA_REGISTER1 : process (Bus_clk)
         begin
            if (Bus_clk'EVENT and Bus_clk = '1') then
               if (Bus_reset = '1' or data_timeout='1') then
                  sl_rddbus1_i(i) <= '0';
               elsif (rd1_dphase_active = '1') then
                  sl_rddbus1_i(i) <= IP2Bus_Data(i);
               else
                  sl_rddbus1_i(i) <= '0';
               end if;
            end if;
        end process READ_DATA_REGISTER1; 

    end generate GEN_0TO31_SECTION;

    sl_rddbus_i <= sl_rddbus1_i;

    READ_DATA_REGISTER : process (Bus_clk)
     begin
        if (Bus_clk'EVENT and Bus_clk = '1') then
           if (Bus_reset = '1') then
              sl_rdwdaddr_i <= (others => '0');
--           elsif (rd1_dphase_active = '1' and
--                  IP2Bus_RdAck = '1') then
           elsif (rd1_dphase_active = '1' and
                  sig_rd_data_ack = '1') then
              sl_rdwdaddr_i <= rdwdaddr;
           else
              sl_rdwdaddr_i <= (others => '0');
           end if;
        end if;
    end process; -- READ_DATA_REGISTER

end generate GEN_FOR_32;

---------------------------------------------------------------------------
-- Burst Support Counters/Controls
---------------------------------------------------------------------------

target_addrack_i <= IP2Bus_AddrAck or data_timeout;

I_BURST_SUPPORT : entity plbv46_slave_burst_v1_01_a.burst_support
    generic map (
        C_MAX_DBEAT_CNT     => MAX_FLBURST_SIZE         ,
        C_FAMILY            => C_FAMILY
    )
    port map(
        -- Input ports
        Bus_reset           => Bus_Reset                ,              
        Bus_clk             => Bus_Clk                  ,                
        RNW                 => plb_rnw_reg              ,            
        Req_Init            => decode_s_h_cs            ,          
        Num_Data_Beats      => num_data_beats_minus1    ,  
--        Target_AddrAck      => IP2Bus_AddrAck           ,         
        Target_AddrAck      => target_addrack_i         ,         
        Target_DataAck      => data_ack                 ,               
        WrBuf_wen           => wr_buf_wren              ,            

        -- Output signals
        Control_Ack         => control_ack_i            ,          
        Control_Done        => control_done_i           ,         
        Response_Ack        => response_ack_i           ,         
        Response_AlmostDone => response_almostdone_i    ,  
        Response_Done       => response_done_i          
    );

---------------------------------------------------------------------------
-- Main IPIF Address counter instantiation
---------------------------------------------------------------------------
I_BUS_ADDRESS_COUNTER : entity plbv46_slave_burst_v1_01_a.addr_reg_cntr_brst_flex
    Generic map (
        C_CACHLINE_ADDR_MODE    => C_CACHLINE_ADDR_MODE ,
        C_SPLB_P2P              => C_SPLB_P2P           ,
        C_NUM_ADDR_BITS         => C_IPIF_ABUS_WIDTH    ,
        C_PLB_DWIDTH            => C_IPIF_DBUS_WIDTH
    )
    port map (
        -- Clock and Reset
        Bus_reset               => Bus_Reset            ,
        Bus_clk                 => Bus_Clk              ,


        -- Inputs from Slave Attachment
        Single                  => single_transfer      ,
        Cacheln                 => cacheln_transfer     ,
        Burst                   => burst_transfer       ,
        S_H_Qualifiers          => decode_s_h_cs        ,
        Xfer_done               => decode_cs_ce_clr     ,
        Addr_Load               => addr_cntr_load_en    ,
        Addr_Cnt_en             => control_ack_i        ,
        Addr_Cnt_Size           => plb_size_reg         ,
        Addr_Cnt_Size_Erly      => plb_size             ,
        Mstr_SSize              => sa2mirror_MSize_i    ,
        Address_In              => abus_i               ,

        BE_in                   => BE_ZEROS             ,
        Reset_BE                => RST_BE_ZEROS         ,

        BE_out                  => open                 ,

        -- IPIF & IP address bus source (AMUX output)
        Address_Out             => bus2ip_addr_i
    );
---------------------------------------------------------------------------
---------------------------------------------------------------------------
I_STEER_ADDRESS_COUNTER : entity plbv46_slave_burst_v1_01_a.addr_reg_cntr_brst_flex
    Generic map (
        C_CACHLINE_ADDR_MODE    => C_CACHLINE_ADDR_MODE ,
        C_SPLB_P2P              => C_SPLB_P2P           ,
        C_NUM_ADDR_BITS         => C_STEER_ADDR_SIZE    ,
        C_PLB_DWIDTH            => C_IPIF_DBUS_WIDTH
    )
    port map (
        -- Clock and Reset
        Bus_reset               => Bus_Reset            ,
        Bus_clk                 => Bus_Clk              ,


        -- Inputs from Slave Attachment
        Single                  => single_transfer      ,
        Cacheln                 => cacheln_transfer     ,
        Burst                   => burst_transfer       ,
        S_H_Qualifiers          => decode_s_h_cs        ,
        Xfer_done               => decode_cs_ce_clr     ,
        Addr_Load               => addr_cntr_load_en    ,
        Addr_Cnt_en             => response_ack_i       ,
        Addr_Cnt_Size           => plb_size_reg         ,
        Addr_Cnt_Size_Erly      => plb_size             ,
        Mstr_SSize              => sa2mirror_MSize_i    ,
        Address_In              => abus_i(C_IPIF_ABUS_WIDTH -
                                          C_STEER_ADDR_SIZE to
                                          C_IPIF_ABUS_WIDTH-1)              ,
        BE_in                   => plb_be_reg           ,
        Reset_BE                => reset_be             ,

        -- BE Outputs
        BE_out                  => bus2ip_be_i          ,
        Address_Out             => sa2steer_addr_i
    );

---------------------------------------------------------------------------
-- Sample and hold the transfer qualifer signals to be output to the IPIF
-- during the data phase of a bus transfer.
---------------------------------------------------------------------------
S_AND_H_XFER_QUAL : process (Bus_clk)
    begin
        if (Bus_clk'EVENT and Bus_clk = '1') then
            if (Bus_reset = '1' or decode_cs_ce_clr = '1') then
                bus2ip_rnw_i            <= '0';
                burst_transfer_reg      <= '0';
                cacheln_burst_reg       <= '0';
                plb_size_sh_reg         <= (others => '0');

            elsif (addr_cntr_load_en = '1') then
                bus2ip_rnw_i            <=  plb_rnw_reg;
                burst_transfer_reg      <=  burst_transfer;
                cacheln_burst_reg       <=  cacheln_transfer;
                plb_size_sh_reg         <=  plb_size_reg;
            end if;
        end if;
   end process S_AND_H_XFER_QUAL; 



--/////////////////////////////////////////////////////////////////////////////
------------------------------------------------------------
-- if Generate
--
-- Label: OMIT_DATA_PHASE_WDT
--
-- if Generate Description:
--  This ifGEN omits the dataphase watchdog timeout function.
--
--
------------------------------------------------------------
 OMIT_DATA_PHASE_WDT : if (C_DPHASE_TIMEOUT = 0 or C_INCLUDE_DPHASE_TIMER = 0) generate


   begin

       data_timeout  <= '0';


   end generate OMIT_DATA_PHASE_WDT;
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



--/////////////////////////////////////////////////////////////////////////////
------------------------------------------------------------
-- if Generate
--
-- Label: INCLUDE_DATA_PHASE_WDT
--
-- if Generate Description:
--  This ifGEN implements the dataphase watchdog timeout
-- function. The counter is allowed to count down when an active
-- IPIF operation is ongoing. A data acknowledge from the target
-- address space forces the counter to reload.
--
--
------------------------------------------------------------
 INCLUDE_DATA_PHASE_WDT : if (C_DPHASE_TIMEOUT > 0 and C_INCLUDE_DPHASE_TIMER = 1) generate


    constant TIMEOUT_VALUE_TO_USE : integer := check_to_value(C_DPHASE_TIMEOUT);
    constant COUNTER_WIDTH  : Integer := log2(TIMEOUT_VALUE_TO_USE-2)+1;
    constant DPTO_LD_VALUE  : std_logic_vector(COUNTER_WIDTH-1 downto 0)
                              := std_logic_vector(to_unsigned(TIMEOUT_VALUE_TO_USE-2,
                                                       COUNTER_WIDTH));
    signal dpto_cntr_ld_en  : std_logic;

    signal dpto_cnt_en      : std_logic;

    signal timeout_i        : std_logic;

   begin


    dpto_cntr_ld_en <= '1'
      when  sl_busy        = '0'
      else  data_ack;

    dpto_cnt_en <= '1'; -- always enabled, load suppresses counting



    I_DPTO_COUNTER : entity proc_common_v3_00_a.counter_f
      generic map(
        C_NUM_BITS    =>  COUNTER_WIDTH,     --: Integer := 9
        C_FAMILY      => "nofamily"          -- set to "no family" to force inferred logic.
          )
      port map(
        Clk           =>  bus_clk,          --: in  std_logic;
        Rst           =>  '0',              --: in  std_logic;
        Load_In       =>  DPTO_LD_VALUE,    --: in  std_logic_vector(C_NUM_BITS - 1 downto 0);
        Count_Enable  =>  dpto_cnt_en,      --: in  std_logic;
        Count_Load    =>  dpto_cntr_ld_en,  --: in  std_logic;
        Count_Down    =>  '1',              --: in  std_logic;
        Count_Out     =>  open,             --: out std_logic_vector(C_NUM_BITS - 1 downto 0);
        Carry_Out     =>  timeout_i         --: out std_logic
        );

    REG_TIMEOUT : process(bus_clk)
        begin
            if(bus_clk'EVENT and bus_clk='1')then
                if(Bus_reset='1' or clear_sl_busy = '1')then
                    data_timeout <= '0';
                elsif(timeout_i='1')then
                    data_timeout <= '1';
                end if;
            end if;
        end process REG_TIMEOUT;


    end generate INCLUDE_DATA_PHASE_WDT;
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
-- end of Combined HDL
-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\










end implementation;
