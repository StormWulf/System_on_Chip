-------------------------------------------------------------------------------
-- $Id: plbv46_slave_burst.vhd,v 1.2.4.2 2008/11/18 20:13:02 gburch Exp $
-------------------------------------------------------------------------------
-- plbv46_slave_burst.vhd -  Version v1.00a
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
-- Filename:        plbv46_slave_burst.vhd
-- Version:         v1_00_a
-- Description:     This is the top level design file for the Mauna Loa
--                  plbv46_slave function. It provides a standardized slave
--                  interface between the IP and the PLB Bus. This version
--                  supports cacheln and burst transfers at 1 clock per data
--                  beat.  It does not provide address pipelining and
--                  simultaneous read and write operations.
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
-- BEGIN_CHANGELOG EDK_J
--
--  Initial release of plbv46_slave_burst_v1_00_a
--
-- END_CHANGELOG
-------------------------------------------------------------------------------
-- BEGIN_CHANGELOG EDK_J_SP1
--
--  Fixed issue with addr_out_s_h
--
-- END_CHANGELOG
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- BEGIN_CHANGELOG EDK_Jm
--
--  Fixed tool integer calculation issue.
--  Cleaned up simulation truncation warning.
--
--  Modified to not sl_addrack to 16-word cachelines, byte bursts, and
--  halfword bursts.
--
--  Modifed to fix some issues with P2P mode.
--
--  Added Dataphase timeout timer.
--
-- END_CHANGELOG
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- BEGIN_CHANGELOG EDK_K_SP3
--
--  Updated to use proc_common_v3_00_a library.
--
-- END_CHANGELOG
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
--  - Reworked plb_be_muxed's to prevent acknowledgment of burst lengths
--  greater than 16.
-- ^^^^^^
--  GAB     10/04/06
-- ~~~~~~
--  - Added missing plb_be_muxed logic in GEN_128_TO_64_SLAVE case.
-- ^^^^^^
--  GAB     11/2/06
-- ~~~~~~
--  - Added option to output bus2ip_burstlength as a databeat count - 1.  This
--  count is left justified starting with bit 0 as the msb.  This added
--  the C_BURSTLENGTH_TYPE generic which defaults to the legacy mode of
--  operation.
-- ^^^^^^
--  GAB     11/8/06
-- ~~~~~~
--  - Fixed issues with bus2ip_addr transitioning with dataack as opposed to
--  addrack
--  - Added feature to allow bus2ip_burstlength to be in databeats-1 or byte
--  count depending on setting of C_BURSTLENGTH_TYPE.
-- ^^^^^^
--  GAB     12/20/06
-- ~~~~~~
--  - Fixed issue with mux'ed be logic being out of range for the 32-Bit plb
-- bus case.  Fixes portion of CR429549
-- ^^^^^^
--  GAB     5/4/2007
-- ~~~~~~
--  - Added XST work around for index calculation issue with rdwdaddr in
--  plb_slave_attachment.vhd
-- ^^^^^^
--  GAB     5/11/2007
-- ~~~~~~
--  - Cleaned up truncation warning on bus2ip_burstlength creation logic.
--  conditions causing warning were impossible to reach cases for the
--  particular configuration of the slave. Warning occurs for c_splb_dwidth=32
--  for the Double-Word (64-Bit) and Quad-Word(128-Bit) wide burst requests
--  cases.  Modified plb_slave_attachment.vhd.
-- ^^^^^^
--  GAB     6/12/2007
-- ~~~~~~
--  - Modified valid request to not respond to 16word cachelines, byte bursts,
--  and halfword. Modified plb_slave_attachment_indet.vhd
--  - Qualified sl_addrack_i and set_sl_busy with valid request in the p2p mode
--  - Passed PLB_RWN combinatorially to plb_rnw_reg in p2p mode
-- ^^^^^^
--  GAB     6/15/2007
-- ~~~~~~
-- Qualified PLB_wrBurst with plb_rnw_reg in setting of bus2ip_burst to work
-- around corner case issue where arbiter drove plb_wrburst during address
-- phase of a read. Modified plb_slave_attachment.vhd
-- ^^^^^^
--  GAB     6/19/2007
-- ~~~~~~
--  Created a P2P version and a Shared version for SL_SSize so the shared
--  version could be registered to remove long timing path.
-- ^^^^^^
--  GAB     7/2/2007
-- ~~~~~~
--  Added missing else clause to MID process for master_id_vector.  This
--  fixes CR442664.  Modified plb_slave_attachment.vhd
-- ^^^^^^
--  GAB     7/13/07
-- ~~~~~~
--  - Fixed issue where plb address was not getting sampled correctly in
-- the point to point mode under certain conditions.  Modified
-- plb_address_decoder.vhd
-- ^^^^^^
--  GAB     7/20/07
-- ~~~~~~
--  - Added dataphase timeout timer.  A timeout will terminate the plb cycle
-- normally (driving zeros during reads) and will remove IPIC signal
-- assertion.  Timeout value is set via a constant in this file.
--  - Fixed other minor p2p issues.
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

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.ipif_pkg.all;

library unisim;
use unisim.vcomponents.all;

library plbv46_slave_burst_v1_01_a;
use plbv46_slave_burst_v1_01_a.all;

-------------------------------------------------------------------------------

entity plbv46_slave_burst is
    generic (


            C_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE :=
                -- Base address and high address pairs.
                (
                            X"0000_0000_7000_0000", -- BRAM1 base address
                            X"0000_0000_7000_0FFF", -- BRAM1 high address
                            X"0000_0000_8000_0000", -- BRAM2 base address
                            X"0000_0000_8000_0FFF", -- BRAM2 high address
                            X"0000_0000_9000_0000", -- Reset base address
                            X"0000_0000_9000_0003", -- Reset high address
                            X"0000_0000_A000_0000", -- DDR Widget base address
                            X"0000_0000_A000_FFFF", -- DDR Widget high address
                            X"0000_0000_B000_0000", -- Error Widget Registers base address
                            X"0000_0000_B000_003F", -- Error Widget Registers high address
                            X"0000_0000_B000_1000", -- Error Widget BRAM base address
                            X"0000_0000_B000_1FFF"  -- Error Widget BRAM high address
                 );

            C_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE :=
                -- This array spcifies the number of Chip Enables (CE) that is
                -- required by the cooresponding baseaddr pair.
                (
                            0 => 1,    -- BRAM1 CE Number
                            1 => 1,    -- BRAM2 CE Number
                            2 => 1,    -- Reset Module
                            3 => 1,    -- DDR Widget CE Number
                            4 => 16,   -- Error Widget Registers CE Number
                            5 => 1     -- Error Widget BRAM CE Number
                 );

            C_SPLB_P2P                  : integer range 0 to 1 := 0;
                -- Optimize slave interface for a point to point connection

            C_CACHLINE_ADDR_MODE        : integer range 0 to 1 := 1;
                -- Selects the addressing mode to use for Cacheline Read
                -- operations.
                -- 0 = Legacy Read mode (target word first)
                -- 1 = Realign target word address to Cacheline aligned and
                --     then do a linear incrementing addressing from start
                --     to end of the Cacheline (PCI Bridge enhancement).

            C_WR_BUFFER_DEPTH           : integer range 0 to 64 := 16;
                -- The number of storage locations for the write buffer
                -- Valid depths are 16, and 32. Setting to 0 removes the
                -- buffer.

            C_BURSTLENGTH_TYPE          : integer range 0 to 1 := 0;
                -- The type out of the bus2ip_burstlength.
                -- 0 = length is in actual byte number
                -- 1 = length is in data beats - 1
            C_INCLUDE_DPHASE_TIMER      : integer range 0 to 1 := 1;
                -- Include or exclude the data phase timeout timer
                -- 0 = exclude data phase timeout timer
                -- 1 = include data phase timeout timer

            C_SPLB_MID_WIDTH            : integer range 0 to 4:= 3;
                -- The width of the Master ID bus
                -- This is set to log2(C_SPLB_NUM_MASTERS)

            C_SPLB_NUM_MASTERS          : integer range 1 to 16 := 8;
                -- The number of Master Devices connected to the PLB bus
                -- Research this to find out default value

            C_SPLB_SMALLEST_MASTER      : integer range 32 to 128 := 32;
                -- The dwidth (in bits) of the smallest master that will
                -- access this ipif.

            C_SPLB_AWIDTH               : integer range 32 to 32  := 32;
                --  width of the PLB Address Bus (in bits)

            C_SPLB_DWIDTH               : integer range 32 to 128 := 32;
                --  Width of the PLB Data Bus (in bits)

            C_SIPIF_DWIDTH              : integer range 32 to 128 := 32;
                --  Width of IPIF Data Bus (in bits)

            C_FAMILY                        : string := "virtex4"
                -- Select the target architecture type
                -- see the family.vhd package in the proc_common
                -- library
           );
    port (

        -- System signals ---------------------------------------------------------
        SPLB_Clk                : in std_logic                              ;
        SPLB_Rst                : in std_logic                              ;

        -- Bus Slave signals ------------------------------------------------------
        PLB_ABus                : in  std_logic_vector(0 to 31)             ;
        PLB_UABus               : in  std_logic_vector(0 to 31)             ;
        PLB_PAValid             : in  std_logic                             ;
        PLB_SAValid             : in  std_logic                             ;
        PLB_rdPrim              : in  std_logic                             ;
        PLB_wrPrim              : in  std_logic                             ;
        PLB_masterID            : in  std_logic_vector
                                    (0 to C_SPLB_MID_WIDTH-1)               ;
        PLB_abort               : in  std_logic                             ;
        PLB_busLock             : in  std_logic                             ;
        PLB_RNW                 : in  std_logic                             ;
        PLB_BE                  : in  std_logic_vector
                                    (0 to (C_SPLB_DWIDTH/8)-1)              ;
        PLB_MSize               : in  std_logic_vector(0 to 1)              ;
        PLB_size                : in  std_logic_vector(0 to 3)              ;
        PLB_type                : in  std_logic_vector(0 to 2)              ;
        PLB_lockErr             : in  std_logic                             ;
        PLB_wrDBus              : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
        PLB_wrBurst             : in  std_logic                             ;
        PLB_rdBurst             : in  std_logic                             ;
        PLB_wrPendReq           : in  std_logic                             ;
        PLB_rdPendReq           : in  std_logic                             ;
        PLB_wrPendPri           : in  std_logic_vector(0 to 1)              ;
        PLB_rdPendPri           : in  std_logic_vector(0 to 1)              ;
        PLB_reqPri              : in  std_logic_vector(0 to 1)              ;
        PLB_TAttribute          : in  std_logic_vector(0 to 15)             ;

        -- Slave Responce Signals
        Sl_addrAck              : out std_logic                             ;
        Sl_SSize                : out std_logic_vector(0 to 1)              ;
        Sl_wait                 : out std_logic                             ;
        Sl_rearbitrate          : out std_logic                             ;
        Sl_wrDAck               : out std_logic                             ;
        Sl_wrComp               : out std_logic                             ;
        Sl_wrBTerm              : out std_logic                             ;
        Sl_rdDBus               : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
        Sl_rdWdAddr             : out std_logic_vector(0 to 3)              ;
        Sl_rdDAck               : out std_logic                             ;
        Sl_rdComp               : out std_logic                             ;
        Sl_rdBTerm              : out std_logic                             ;
        Sl_MBusy                : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1)             ;
        Sl_MWrErr               : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1)             ;
        Sl_MRdErr               : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1)             ;
        Sl_MIRQ                 : out std_logic_vector
                                    (0 to C_SPLB_NUM_MASTERS-1)             ;

    -- IP Interconnect (IPIC) port signals -----------------------------------------
        Bus2IP_Clk              : out std_logic                             ;
        Bus2IP_Reset            : out std_logic                             ;
        IP2Bus_Data             : in  std_logic_vector
                                    (0 to C_SIPIF_DWIDTH-1)                 ;
        IP2Bus_WrAck            : in  std_logic                             ;
        IP2Bus_RdAck            : in  std_logic                             ;
        IP2Bus_AddrAck          : in  std_logic                             ;
        IP2Bus_Error            : in  std_logic                             ;
        Bus2IP_Addr             : out std_logic_vector
                                    (0 to C_SPLB_AWIDTH-1)                  ;
        Bus2IP_Data             : out std_logic_vector
                                    (0 to C_SIPIF_DWIDTH-1)                 ;
        Bus2IP_RNW              : out std_logic;
        Bus2IP_BE               : out std_logic_vector
                                    (0 to (C_SIPIF_DWIDTH/8)-1)             ;
        Bus2IP_Burst            : out std_logic                             ;
        Bus2IP_BurstLength      : out std_logic_vector
                                    (0 to log2(16 * (C_SPLB_DWIDTH/8)))    ;
        Bus2IP_WrReq            : out std_logic                             ;
        Bus2IP_RdReq            : out std_logic                             ;
        Bus2IP_CS               : out std_logic_vector
                                    (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
        Bus2IP_RdCE             : out std_logic_vector
                                    (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1);
        Bus2IP_WrCE             : out std_logic_vector
                                    (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1)
        );

end plbv46_slave_burst;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture implementation of plbv46_slave_burst is

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
-- (also see ipif_pkg and proc_common_pkg for other functions)


-------------------------------------------------------------------------------
-- set_ssize()
-- This function is used to set the value of size based
-- on the size of the input bus width parameter.
-------------------------------------------------------------------------------
-- removed for code coverage
-- function not used
--function set_ssize (bus_width : integer) return integer is
--
--   Variable size : Integer := 0;
--
--begin
--
--   case bus_width is
--     when 32 =>
--         size := 0;
--     when 64 =>
--         size := 1;
--     when 128 =>
--         size := 2;
--     when 256 =>
--         size := 3;
--     when others =>
--         size := 0;
--   end case;
--
--   return(size);
--
--end function set_ssize;


-------------------------------------------------------------------------------
-- Constants Declarations
-------------------------------------------------------------------------------
-- The integer value of the encoded PLB Bus size to be returned
-- on the Sl_Ssize output bus.
--constant SSIZE_RESPONSE     : integer := set_ssize(C_SIPIF_DWIDTH);
--

-- Unconstrained generic array size calculations
constant NUM_BASEADDRS      : integer := (C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2;

constant NUM_CE             : integer := calc_num_ce(C_ARD_NUM_CE_ARRAY);

constant ZERO_VALUE         : std_logic_vector(0 to C_SIPIF_DWIDTH - 1)
                                                := (others => '0');
constant ZERO_BE            : std_logic_vector(0 to C_SIPIF_DWIDTH/8 - 1)
                                                := (others => '0');
constant CS_BUS_WIDTH       : integer := NUM_BASEADDRS;

constant STEER_ADDR_SIZE    : integer := 10;


-- Fix the maximum to 16 data beats.
--constant DEV_MAX_BURST_SIZE : integer := 16 * (C_SIPIF_DWIDTH/8);
constant DEV_MAX_BURST_SIZE : integer := 16 * (C_SPLB_DWIDTH/8);

-- Dataphase timeout value, a value of zero will remove the timer.
constant DPHASE_TIMEOUT     : integer := 128;


-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------

signal sl_addrack_i         : std_logic;
signal sl_ssize_i           : std_logic_vector(0 to 1);
signal Sl_wait_i            : std_logic;
signal Sl_rearbitrate_i     : std_logic;
signal sl_wrdack_i          : std_logic;
signal sl_wrcomp_i          : std_logic;
signal sl_wrbterm_i         : std_logic;
signal sl_rddbus_i          : std_logic_vector(0 to C_SPLB_DWIDTH-1);
signal sl_rdwdaddr_i        : std_logic_vector(0 to 3);
signal sl_rddack_i          : std_logic;
signal sl_rdcomp_i          : std_logic;
signal sl_rdbterm_i         : std_logic;
signal sl_mbusy_i           : std_logic_vector
                                (0 to C_SPLB_NUM_MASTERS-1);
signal sl_mrderr_i          : std_logic_vector
                                (0 to C_SPLB_NUM_MASTERS-1);
signal sl_mwrerr_i          : std_logic_vector
                                (0 to C_SPLB_NUM_MASTERS-1);

signal bus2ip_addr_i        : std_logic_vector(0 to C_SPLB_AWIDTH - 1 );
signal bus2ip_be_i          : std_logic_vector(0 to C_SIPIF_DWIDTH/8 - 1 );
signal bus2ip_burst_i       : std_logic;
signal bus2ip_burstlength_i : std_logic_vector
                                (0 to log2(DEV_MAX_BURST_SIZE));
signal bus2ip_data_i        : std_logic_vector(0 to C_SIPIF_DWIDTH - 1 );
signal bus2ip_rnw_i         : std_logic;
signal bus2ip_rdreq_i       : std_logic;
signal bus2ip_wrreq_i       : std_logic;

signal bus2ip_cs_i          : std_logic_vector(0 to NUM_BASEADDRS-1);
signal bus2ip_rdce_i        : std_logic_vector(0 to NUM_CE-1);
signal bus2ip_wrce_i        : std_logic_vector(0 to NUM_CE-1);

-- Auto hookup support for read dbus and status reply
signal plb_be_muxed         : std_logic_vector(0 to C_SIPIF_DWIDTH/8 - 1);

signal sa2mirror_rddata_i   : std_logic_vector(0 to C_SIPIF_DWIDTH - 1);
signal sa2mirror_rdaddr_i   : std_logic_vector(0 to STEER_ADDR_SIZE - 1);


-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin

Sl_MIRQ         <= (others => '0');

-------------------------------------------------------------------------------
-- Mux/Steer data/be's correctly for connect 64-bit slave to 128-bit plb
-------------------------------------------------------------------------------
GEN_128_TO_64_SLAVE : if C_SIPIF_DWIDTH = 64 and C_SPLB_DWIDTH = 128 generate

    ---------------------------------------------------------------------------
    -- BE Mux - For addresses 0x0 to 0x7 use PLB_BE's 0 to 7
    --          For addresses 0x8 to 0xF use PLB_BE's 8 to 15
    ---------------------------------------------------------------------------
    MUX_BE_PROCESS : process(PLB_BE,PLB_ABus,PLB_size,PLB_mSize)
        begin
            -- If transfer type is a single and address offset is
            -- between 0x8 and 0xF then map upper BE's to lower bytelanes.
            -- Single Beat Transfer
            if(PLB_size = "0000")then
                if(PLB_ABus(28) = '1')then
                    plb_be_muxed <= PLB_BE(8 to 15);
                -- If transfer type is burst or address offset is
                -- between 0x0 and 0x7 then map lower BE's to lower bytelanes
                else
                    plb_be_muxed <= PLB_BE(0 to 7);
                end if;
            -- Burst Transfer
            else
                case PLB_mSize is
                    when "00" =>    -- 32-Bit Master
                        plb_be_muxed <= PLB_BE(0 to 3) & "0000";

                    when "01"|"10" =>    -- 64-Bit Master or 128-Bit Master
                        -- Burst Length > 16 therefore force to be
                        -- indetermiante burst where the slave
                        -- attachment will NOT respond
                        if(or_reduce(PLB_BE(4 to 7)) = '1')then
                            plb_be_muxed <= (others =>'0');

                        -- Burst Length <= 16 therefore pass be's
                        -- to slave attachment
                        else
                            plb_be_muxed <= PLB_BE(0 to 3) & "0000";
                        end if;

                    when others =>
                        plb_be_muxed <= (others =>'0');
                end case;
            end if;

        end process MUX_BE_PROCESS;

end generate GEN_128_TO_64_SLAVE;

-------------------------------------------------------------------------------
-- Mux/Steer data/be's correctly for connect 32-bit slave to 128-bit plb
-------------------------------------------------------------------------------
GEN_128_TO_32_SLAVE : if C_SIPIF_DWIDTH = 32 and C_SPLB_DWIDTH = 128 generate
signal be_select   : std_logic_vector(0 to 1);

    begin
        be_select <= PLB_ABus(28 to 29);


    ---------------------------------------------------------------------------
    -- BE Mux - Single Beat - For addresses 0x0 to 0x3 use PLB_BE's 0 to 3
    --          Single Beat - For addresses 0x4 to 0x7 use PLB_BE's 4 to 7
    --          Single Beat - For addresses 0x8 to 0xB use PLB_BE's 8 to 11
    --          Single Beat - For addresses 0xC to 0xF use PLB_BE's 12 to 15
    --          Burst       - Verify burst length less than 16
    ---------------------------------------------------------------------------
        MUX_BE_PROCESS : process(PLB_BE,be_select,PLB_SIZE,PLB_mSize)
            begin
                -- If transfer type is a single and address offset is
                -- between 0x4 and 0x7 then map upper BE's to lower bytelanes
                -- Single Beat Transfer
                if(PLB_size = "0000")then
                    case be_select is
                        when "00" =>    -- Addresses 0, 1, 2, to 3
                            plb_be_muxed <= PLB_BE(0 to 3);

                        when "01" =>    -- Addresses 4, 5, 6, to 7
                            plb_be_muxed <= PLB_BE(4 to 7);

                        when "10" =>    -- Addresses 8, 9, A, to B
                            plb_be_muxed <= PLB_BE(8 to 11);

                        when "11" =>    -- Addresses C, D, E, to F
                            plb_be_muxed <= PLB_BE(12 to 15);

                        when others =>
                            plb_be_muxed <= PLB_BE(0 to 3);
                    end case;
                -- Burst Transfer
                else
                    case PLB_mSize is
                        when "00" =>    -- 32-Bit Master
                            plb_be_muxed <= PLB_BE(0 to 3);

                        when "01"|"10" =>    -- 64-Bit Master or 128-Bit Master
                            -- Burst Length > 16 therefore force to be
                            -- indetermiante burst where the slave
                            -- attachment will NOT respond
                            if(or_reduce(PLB_BE(4 to 7)) = '1')then
                                plb_be_muxed <= (others =>'0');

                            -- Burst Length <= 16 therefore pass be's
                            -- to slave attachment
                            else
                                plb_be_muxed <= PLB_BE(0 to 3);
                            end if;

                        when others =>
                            plb_be_muxed <= (others =>'0');
                    end case;
                end if;
            end process MUX_BE_PROCESS;

end generate GEN_128_TO_32_SLAVE;

-------------------------------------------------------------------------------
-- Mux/Steer data/be's correctly for connect 32-bit slave to 64-bit plb
-------------------------------------------------------------------------------
GEN_64_TO_32_SLAVE : if C_SIPIF_DWIDTH = 32 and C_SPLB_DWIDTH = 64 generate
    begin

    ---------------------------------------------------------------------------
    -- BE Mux - Single Beat - For addresses 0x0 to 0x3 use PLB_BE's 0 to 3
    --          Single Beat - For addresses 0x4 to 0x7 use PLB_BE's 4 to 7
    --          Burst       - Verify burst length less than 16
    ---------------------------------------------------------------------------
    MUX_BE_PROCESS : process(PLB_BE,PLB_ABus,PLB_SIZE,PLB_mSize)
        begin
            -- If transfer type is a single and address offset is
            -- between 0x4 and 0x7 then map upper BE's to lower bytelanes
            -- Single Beat Transfer
            if(PLB_size = "0000")then
                if(PLB_ABus(29) = '1')then
                    plb_be_muxed <= PLB_BE(4 to 7);
                else
                    plb_be_muxed <= PLB_BE(0 to 3);
                end if;
            -- Burst Transfer
            else
                case PLB_mSize is
                    when "00" =>    -- 32-Bit Master
                        plb_be_muxed <= PLB_BE(0 to 3);

                    when "01"|"10" =>    -- 64-Bit Master or 128-Bit Master
                        -- Burst Length > 16 therefore force to be
                        -- indetermiante burst where the slave
                        -- attachment will NOT respond
                        if(or_reduce(PLB_BE(4 to 7)) = '1')then
                            plb_be_muxed <= (others =>'0');

                        -- Burst Length <= 16 therefore pass be's
                        -- to slave attachment
                        else
                            plb_be_muxed <= PLB_BE(0 to 3);
                        end if;

                    when others =>
                        plb_be_muxed <= (others =>'0');
                end case;
            end if;
        end process MUX_BE_PROCESS;


end generate GEN_64_TO_32_SLAVE;

-------------------------------------------------------------------------------
-- IPIF DWidth = PLB DWidth
-- If IPIF Slave Data width is equal to the PLB Bus Data Width
-- Then BE and Read Data Bus map directly to eachother.
-------------------------------------------------------------------------------
GEN_FOR_EQUAL_SLAVE_64_128 : if C_SIPIF_DWIDTH = C_SPLB_DWIDTH
                      and C_SPLB_DWIDTH >= 64 generate

--    plb_be_muxed <= PLB_BE;
    ---------------------------------------------------------------------------
    -- BE Mux - Single Beat - For addresses 0x0 to 0x3 use PLB_BE's 0 to 3
    --          Single Beat - For addresses 0x4 to 0x7 use PLB_BE's 4 to 7
    --          Burst       - Verify burst length less than 16
    ---------------------------------------------------------------------------
    MUX_BE_PROCESS : process(PLB_BE,PLB_SIZE,PLB_mSize)
        begin
            -- Single Beat Transfer
            if(PLB_size = "0000")then
                plb_be_muxed <= PLB_BE;
            -- Burst Transfer
            else
                case PLB_mSize is
                    when "00" =>    -- 32-Bit Master
                        plb_be_muxed <= PLB_BE;

                    when "01"|"10" =>    -- 64-Bit Master or 128-Bit Master
                        -- Burst Length > 16 therefore force to be
                        -- indetermiante burst where the slave
                        -- attachment will NOT respond
                        if(or_reduce(PLB_BE(4 to 7)) = '1')then
                            plb_be_muxed <= (others =>'0');

                        -- Burst Length <= 16 therefore pass be's
                        -- to slave attachment
                        else
                            plb_be_muxed <= PLB_BE;
                        end if;

                    when others =>
                        plb_be_muxed <= (others =>'0');
                end case;
            end if;
        end process MUX_BE_PROCESS;

end generate GEN_FOR_EQUAL_SLAVE_64_128;

GEN_FOR_EQUAL_SLAVE_32 : if C_SIPIF_DWIDTH = C_SPLB_DWIDTH
                         and C_SPLB_DWIDTH =32 generate

    plb_be_muxed <= PLB_BE;

end generate GEN_FOR_EQUAL_SLAVE_32;

-------------------------------------------------------------------------------
-- Slave Attachment
-------------------------------------------------------------------------------
I_SLAVE_ATTACHMENT:  entity plbv46_slave_burst_v1_01_a.plb_slave_attachment
    generic map(
        C_STEER_ADDR_SIZE       => STEER_ADDR_SIZE                  ,
        C_ARD_ADDR_RANGE_ARRAY  => C_ARD_ADDR_RANGE_ARRAY           ,
        C_ARD_NUM_CE_ARRAY      => C_ARD_NUM_CE_ARRAY               ,
        C_PLB_NUM_MASTERS       => C_SPLB_NUM_MASTERS               ,
        C_PLB_MID_WIDTH         => C_SPLB_MID_WIDTH                 ,
        C_PLB_SMALLEST_MASTER   => C_SPLB_SMALLEST_MASTER           ,
        C_IPIF_ABUS_WIDTH       => C_SPLB_AWIDTH                    ,
        C_IPIF_DBUS_WIDTH       => C_SIPIF_DWIDTH                   ,
        C_SPLB_DWIDTH           => C_SPLB_DWIDTH                    ,
        C_SPLB_P2P              => C_SPLB_P2P                       ,
        C_DEV_MAX_BURST_SIZE    => DEV_MAX_BURST_SIZE               ,
        C_CACHLINE_ADDR_MODE    => C_CACHLINE_ADDR_MODE             ,
        C_WR_BUFFER_DEPTH       => C_WR_BUFFER_DEPTH                ,
        C_BURSTLENGTH_TYPE      => C_BURSTLENGTH_TYPE               ,
        C_DPHASE_TIMEOUT        => DPHASE_TIMEOUT                   ,
        C_INCLUDE_DPHASE_TIMER  => C_INCLUDE_DPHASE_TIMER           ,
        C_FAMILY                => C_FAMILY
    )
    port map(
        --System Signals
        Bus_Reset               => SPLB_Rst                         ,
        Bus_Clk                 => SPLB_Clk                         ,

        -- PLB Bus Signals
        PLB_ABus                => PLB_ABus                         ,
        PLB_UABus               => PLB_UABus                        ,
        PLB_PAValid             => PLB_PAValid                      ,
        PLB_masterID            => PLB_masterID                     ,
        PLB_RNW                 => PLB_RNW                          ,
        PLB_BE                  => plb_be_muxed                     ,
        PLB_Msize               => PLB_MSize                        ,
        PLB_size                => PLB_size                         ,
        PLB_type                => PLB_type                         ,
        PLB_wrDBus              => PLB_wrDBus(0 to C_SIPIF_DWIDTH-1),
        PLB_wrBurst             => PLB_wrBurst                      ,
        PLB_rdBurst             => PLB_rdBurst                      ,
        Sl_SSize                => sl_ssize_i                       ,
        Sl_addrAck              => sl_addrack_i                     ,
        Sl_wait                 => sl_wait_i                        ,
        Sl_rearbitrate          => sl_rearbitrate_i                 ,
        Sl_wrDAck               => sl_wrdack_i                      ,
        Sl_wrComp               => sl_wrcomp_i                      ,
        Sl_wrBTerm              => sl_wrbterm_i                     ,
        Sl_rdDBus               => sa2mirror_rddata_i               ,
        Sl_rdWdAddr             => sl_rdwdaddr_i                    ,
        Sl_rdDAck               => sl_rddack_i                      ,
        Sl_rdComp               => sl_rdcomp_i                      ,
        Sl_rdBTerm              => sl_rdbterm_i                     ,
        Sl_MBusy                => sl_mbusy_i                       ,
        Sl_MRdErr               => sl_mrderr_i                      ,
        Sl_MWrErr               => sl_mwrerr_i                      ,

        -- Controls to the Byte Steering Module
        SA2Mirror_RdAddr        => sa2mirror_rdaddr_i               ,

        -- IPIC Bus Signals
        Bus2IP_Addr             => bus2ip_addr_i                    ,
        Bus2IP_Burst            => bus2ip_burst_i                   ,
        Bus2IP_BurstLength      => bus2ip_burstlength_i             ,
        Bus2IP_RNW              => bus2ip_rnw_i                     ,
        Bus2IP_BE               => bus2ip_be_i                      ,
        Bus2IP_RdReq            => bus2ip_rdreq_i                   ,
        Bus2IP_WrReq            => bus2ip_wrreq_i                   ,
        Bus2IP_CS               => bus2ip_cs_i                      ,
        Bus2IP_RdCE             => bus2ip_rdce_i                    ,
        Bus2IP_WrCE             => bus2ip_wrce_i                    ,
        Bus2IP_Data             => bus2ip_data_i                    ,
        IP2Bus_Data             => IP2Bus_Data                      ,
        IP2Bus_AddrAck          => IP2Bus_AddrAck                   ,
        IP2Bus_WrAck            => IP2Bus_WrAck                     ,
        IP2Bus_RdAck            => IP2Bus_RdAck                     ,
        IP2Bus_Error            => IP2Bus_Error
    );

-------------------------------------------------------------------------------
-- This module is used to handle master that have a smaller
-- dwidth than the ipif slave.  i.e. 32-bit Master to 128-bit
-- slave.
-------------------------------------------------------------------------------
I_BYTE_MIRRORING : entity plbv46_slave_burst_v1_01_a.data_mirror_128
    generic map(
        C_PLB_AWIDTH    => STEER_ADDR_SIZE          ,
        C_PLB_DWIDTH    => C_SPLB_DWIDTH            ,
        C_IPIF_DWIDTH   => C_SIPIF_DWIDTH           ,
        C_SMALLEST      => C_SPLB_SMALLEST_MASTER
    )
    port map(

        Addr_In         => SA2Mirror_RdAddr_i       ,
        Data_In         => SA2Mirror_RdData_i       ,
        Data_Out        => Sl_rdDBus_i
    );


Sl_rdDBus <= Sl_rdDBus_i;

-------------------------------------------------------------------------------
-- Misc logic assignments
-------------------------------------------------------------------------------

  Sl_addrAck                <=  sl_addrack_i        ;
  Sl_SSize                  <=  sl_ssize_i          ;
  Sl_wait                   <=  Sl_wait_i           ;
  Sl_rearbitrate            <=  Sl_rearbitrate_i    ;
  Sl_wrDAck                 <=  sl_wrdack_i         ;
  Sl_wrComp                 <=  sl_wrcomp_i         ;
  Sl_wrBTerm                <=  sl_wrbterm_i        ;
  Sl_rdWdAddr               <=  sl_rdwdaddr_i       ;
  Sl_rdDAck                 <=  sl_rddack_i         ;
  Sl_rdComp                 <=  sl_rdcomp_i         ;
  Sl_rdBTerm                <=  sl_rdbterm_i        ;
  Sl_MBusy                  <=  sl_mbusy_i          ;
  Sl_MRdErr                 <=  sl_mrderr_i         ;
  Sl_MWrErr                 <=  sl_mwrerr_i         ;

  Bus2IP_RNW                <= bus2ip_rnw_i         ;
  Bus2IP_Addr               <= bus2ip_addr_i        ;
  Bus2IP_Data               <= bus2ip_data_i        ;
  Bus2IP_BE                 <= bus2ip_be_i          ;
  Bus2IP_RdReq              <= bus2ip_rdreq_i       ;
  Bus2IP_WrReq              <= bus2ip_wrreq_i       ;
  Bus2IP_Burst              <= bus2ip_burst_i       ;
  Bus2IP_BurstLength        <= bus2ip_burstlength_i ;
  Bus2IP_CS                 <= bus2ip_cs_i          ;
  Bus2IP_RdCE               <= bus2ip_rdce_i        ;
  Bus2IP_WrCE               <= bus2ip_wrce_i        ;
  Bus2IP_Clk                <= SPLB_Clk             ;
  Bus2IP_Reset              <= SPLB_Rst             ;


end implementation; -- (architecture)
