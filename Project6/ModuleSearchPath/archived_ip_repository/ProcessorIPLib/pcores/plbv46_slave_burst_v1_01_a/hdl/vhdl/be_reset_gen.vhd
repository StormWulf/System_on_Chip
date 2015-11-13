-------------------------------------------------------------------------------
-- $Id: be_reset_gen.vhd,v 1.1 2008/04/29 20:49:11 gburch Exp $
-------------------------------------------------------------------------------
-- be_reset_gen - entity / architecture pair
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
-- Filename:        be_reset_gen.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
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
-- Author:          GAB
--
-- History:
--   GAB   10-4-06   First Version 
-- ~~~~~~
--  - Initial release
-- ^^^^^^
--   GAB   10-4-06   First Version 
-- ~~~~~~
--  - Added missing 64-bit case for when C_SMALLEST = 32 and C_DWIDTH=128.
--    this cause bus2ip_be to be driven incorrectly for offets 0x4.
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

library proc_common_v3_00_a;
use proc_common_v3_00_a.all;

library unisim;
use unisim.vcomponents.all;

entity be_reset_gen is
    generic (
        C_DWIDTH     : integer := 32;
        C_AWIDTH     : integer := 32;
        C_SMALLEST   : integer := 32
    );
    port(
       Addr         : in std_logic_vector(0 to C_AWIDTH-1);
       MSize        : in std_logic_vector(0 to 1);
       
       Reset_BE     : out std_logic_vector(0 to C_DWIDTH/32 - 1)
    );
end entity be_reset_gen;

architecture implementation of be_reset_gen is


-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal reset_be_i   : std_logic_vector(0 to C_DWIDTH/32 - 1);


------------------------------------------------------------------------------
-- Architecture BEGIN
------------------------------------------------------------------------------
begin

Reset_BE <= reset_be_i;


GEN_FOR_SAME : if C_DWIDTH <= C_SMALLEST generate
    reset_be_i    <= (others => '0');
end generate GEN_FOR_SAME;

---------------------
-- 64 Bit Support --
---------------------
  GEN_BE_64_32: if C_DWIDTH = 64 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Addr,MSize) 
     begin
 
       addr_bits <= Addr(C_AWIDTH-3);   --a29
       reset_be_i <= (others => '0');
        case addr_bits is

         when '0' => 
           case MSize is
             when "00" =>  -- 32-Bit Master 
                reset_be_i <= "01";
             when others => null;
           end case;
             
         when '1' => 
           case MSize is
             when "00" =>  -- 32-Bit Master 
                reset_be_i <= "10";
             when others => null;
           end case;
        when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_BE_64_32;

---------------------
-- 128 Bit Support --
---------------------
  GEN_BE_128_32: if C_DWIDTH = 128 and C_SMALLEST = 32 generate
     signal addr_bits : std_logic_vector(0 to 1);
   begin
     CONNECT_PROC: process (addr_bits,Addr,MSize) 
     begin
 
       addr_bits <= Addr(C_AWIDTH-4 to C_AWIDTH-3);   --  24 25 26 27 | 28 29 30 31
       reset_be_i <= (others => '0');                 --              
        case addr_bits is
         when "00" => --0
           case MSize is
             when "00" => -- 32-Bit Master
                reset_be_i <= "0111";
             when "01" => -- 64-Bit Master
                reset_be_i <= "0011";
             when others => null;
           end case;

         when "01" => --4
           case MSize is
             when "00" => -- 32-Bit Master
                reset_be_i <= "1011";
             when "01" => -- 64-Bit Master      -- GAB 12/22/06
                reset_be_i <= "0011";           -- GAB 12/22/06
             when others => null;
           end case;
         when "10" => --8
           case MSize is
             when "00" => --  32-Bit Master
                reset_be_i <= "1101";
             when "01" => --  64-Bit Master
                reset_be_i <= "1100";
             when others => null;
           end case;
         when "11" => --C
           case MSize is
             when "00" => --32-Bit Master
                reset_be_i <= "1110";
             when "01" => --64-Bit Master
                reset_be_i <= "1100";
             when others => null;
           end case;
         when others => null;   
      end case;      
    end process CONNECT_PROC;
   end generate GEN_BE_128_32;

  GEN_BE_128_64: if C_DWIDTH = 128 and C_SMALLEST = 64 generate
     signal addr_bits : std_logic;
   begin
     CONNECT_PROC: process (addr_bits,Addr,MSize) 
     begin
       addr_bits <= Addr(C_AWIDTH-4);   
       reset_be_i <= (others => '0');
        case addr_bits is
          when '0' =>
           case MSize is
             when "01" => -- 64-Bit Master
                reset_be_i <= "0011";
             when others => null;
           end case;

         when '1' => --8
           case MSize is
             when "01" => -- 64-Bit Master
                reset_be_i <= "1100";
             when others => null;
           end case;
          when others =>
            null;
      end case;      
    end process CONNECT_PROC;
   end generate GEN_BE_128_64;
   
   
end implementation; -- (architecture)

