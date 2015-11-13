-------------------------------------------------------------------------------
-- $Id: data_mirror_128.vhd,v 1.1 2008/04/29 20:49:11 gburch Exp $
-------------------------------------------------------------------------------
-- data_mirror_128.vhd
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
-- Filename:        data_mirror_128.vhd
--
-- Description:     
--   This file implements the logic needed to mirror the Master's Write Data
-- bus to a 32/64/128 bit PLBV46 Bus. This module assumes that the data 
-- width adapter module is being used to adapt the Master's write data bus
-- width to the PLB bus data width using the PLB defined scheme.
--                
--                  
--                  
--                  
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
-- Change Log:
--      GAB    4/29/2008   v1.01.a     
-- ~~~~~~
--     - Updated to use proc_common_v3_00_a library
-- ^^^^^^
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.1 $
-- Date:            $6/14/2006$
--
-- History:
--   DET   6/14/2006       Initial Version
--                      
--
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
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library unisim; -- Required for Xilinx primitives
use unisim.all;  


-------------------------------------------------------------------------------

entity data_mirror_128 is
    generic (
        C_PLB_AWIDTH    : integer range 1  to 64  := 32;
        C_PLB_DWIDTH    : integer range 32 to 128 := 128;
        C_IPIF_DWIDTH   : integer range 32 to 128 := 128;
        C_SMALLEST      : integer range 32 to 128 := 128
    );
    port (
    
        Addr_In         : in  std_logic_vector(0 to C_PLB_AWIDTH-1);
    
        Data_In         : in  std_logic_vector(0 to C_IPIF_DWIDTH-1);
        Data_Out        : out std_logic_vector(0 to C_PLB_DWIDTH-1)
    
    
    );

end entity data_mirror_128;


architecture implementation of data_mirror_128 is

-- Constants
Constant A29_OFFSET : integer := 3;
Constant A28_OFFSET : integer := 4;

-- Signals
signal sig_addr_bits_A28_A29 : std_logic_vector(0 to 1);
signal sig_addr_bit_A29      : std_logic;
signal sig_addr_bit_A28      : std_logic;


begin --(architecture implementation)

GEN_SAME : if C_PLB_DWIDTH = C_IPIF_DWIDTH 
          and C_PLB_DWIDTH = C_SMALLEST generate
    
    Data_Out <= Data_In;          
          
end generate GEN_SAME;     



GEN_NOTSAME : if C_PLB_DWIDTH /= C_IPIF_DWIDTH 
              or C_PLB_DWIDTH /= C_SMALLEST 
              or C_IPIF_DWIDTH /= C_SMALLEST generate 



   sig_addr_bits_A28_A29 <=  Addr_In(C_PLB_AWIDTH - A28_OFFSET) &
                             Addr_In(C_PLB_AWIDTH - A29_OFFSET);

   
   sig_addr_bit_A29      <=  Addr_In(C_PLB_AWIDTH - A29_OFFSET);
   sig_addr_bit_A28      <=  Addr_In(C_PLB_AWIDTH - A28_OFFSET);
    
    
   
   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B128_M128
   --
   -- If Generate Description:
   --  Bus Data width is 128 bits and the Master Data width is
   -- 128 bits.
   --
   ------------------------------------------------------------
--   CASE_M128_B128 : if (C_PLB_DWIDTH = C_IPIF_DWIDTH) generate
   
   CASE_M128_B128 : if (C_PLB_DWIDTH = 128 and C_IPIF_DWIDTH=128) generate
   
      begin
   
       -- direct connect for byte lanes 8 - 15 
        Data_Out(64 to 127) <= Data_In(64 to 127);
         
        
        
        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: MIRROR_MUX_0_3
        --
        -- Process Description:
        -- Mirror mux for byte lanes 0-3. 
        --
        -------------------------------------------------------------
        MIRROR_MUX_0_3 : process (sig_addr_bits_A28_A29,
                                  Data_In)
           begin
        
             case sig_addr_bits_A28_A29 is
               -- when "00" =>
               --   Data_Out(0 to 31) <= Data_In(0 to 31);
               when "01" =>
                 Data_Out(0 to 31) <= Data_In(32 to 63);
               when "10" =>
                 Data_Out(0 to 31) <= Data_In(64 to 95);
               when "11" =>
                 Data_Out(0 to 31) <= Data_In(96 to 127);
               when others => -- '00' case
                 Data_Out(0 to 31) <= Data_In(0 to 31);
             end case;

           end process MIRROR_MUX_0_3; 
        
         
        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: MIRROR_MUX_4_7
        --
        -- Process Description:
        -- Mirror mux for byte lanes 4-7. 
        --
        -------------------------------------------------------------
        MIRROR_MUX_4_7 : process (sig_addr_bit_A28,
                                  Data_In)
           begin
             
             If (sig_addr_bit_A28 = '1') Then
    
               Data_Out(32 to 63) <= Data_In(96 to 127);
               
             else

               Data_Out(32 to 63) <= Data_In(32 to 63);
                 
             End if;
             
           end process MIRROR_MUX_4_7; 

         
      end generate CASE_M128_B128;
  
  
   CASE_M64_B64 : if (C_PLB_DWIDTH = 64 and C_IPIF_DWIDTH=64) generate
   
      begin
        
       -- direct connect for byte lanes 4 - 7 
        Data_Out(32 to 63) <= Data_In(32 to 63);
         
         
        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: MIRROR_MUX_0_3
        --
        -- Process Description:
        -- Mirror mux for byte lanes 0-3. 
        --
        -------------------------------------------------------------
        MIRROR_MUX_0_3 : process (sig_addr_bit_A29,
                                  Data_In)
           begin
        
             
             If (sig_addr_bit_A29 = '1') Then
    
               Data_Out(0 to 31) <= Data_In(32 to 63);
               
             else

               Data_Out(0 to 31) <= Data_In(0 to 31);
                 
             End if;
             
           end process MIRROR_MUX_0_3; 

         
      end generate CASE_M64_B64;
   
   
   CASE_M32_B32 : if (C_PLB_DWIDTH = 32 and C_IPIF_DWIDTH = 32) generate
   
      begin
        
       -- direct connect for byte lanes 0 - 3 
        Data_Out(0 to 31) <= Data_In(0 to 31);
         
         
      end generate CASE_M32_B32;

   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B128_M64
   --
   -- If Generate Description:
   --  Bus is 128 bits and Master is 64 bits
   --
   --
   ------------------------------------------------------------
   CASE_B128_M64 : if (C_PLB_DWIDTH = 128 and C_IPIF_DWIDTH = 64) generate
   
      begin
   
       -- direct connect for byte lanes 4 - 15 
--        Data_Out(32 to 127) <= Data_In(32 to 127);
        Data_Out(64 to 127) <= Data_In(0 to 63);
        Data_Out(32 to 63)  <= Data_In(32 to 63);
         
         
        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: MIRROR_MUX_0_3
        --
        -- Process Description:
        -- Mirror mux for byte lanes 0-3. 
        --
        -------------------------------------------------------------
        MIRROR_MUX_0_3 : process (sig_addr_bit_A29,
                                  Data_In)
           begin
        
             
             If (sig_addr_bit_A29 = '1') Then
    
               Data_Out(0 to 31) <= Data_In(32 to 63);
               
             else

               Data_Out(0 to 31) <= Data_In(0 to 31);
                 
             End if;
             
           end process MIRROR_MUX_0_3; 
           
           
      end generate CASE_B128_M64;
  
  
  
  
  
  
   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_B64_M64
   --
   -- If Generate Description:
   --  Bus is 64 bits and Master is 64 bits
   --
   --
   ------------------------------------------------------------
   CASE_B64_M64 : if (C_PLB_DWIDTH = 64 and C_IPIF_DWIDTH = 32) generate
   
      begin
   
       -- direct connect for byte lanes 4 - 7 
        Data_Out(32 to 63)  <= Data_In(0 to 31);
        Data_Out(0  to 31)  <= Data_In(0 to 31);
         
           
      end generate CASE_B64_M64;
   
   
    
   ------------------------------------------------------------
   -- If Generate
   --
   -- Label: CASE_MSTR_IS_32
   --
   -- If Generate Description:
   --  Bus is 32, 64, or 128 bits and Master is 32 bits
   --
   --
   ------------------------------------------------------------
   CASE_MSTR_IS_32 : if (C_PLB_DWIDTH = 128 and C_IPIF_DWIDTH = 32) generate
   
      begin
   
       -- Just a direct connection
--        Data_Out <= Data_In;

        Data_Out(96 to 127) <= Data_In(0 to 31);
        Data_Out(64 to 95)  <= Data_In(0 to 31);
        Data_Out(32 to 63)  <= Data_In(0 to 31);
        Data_Out(0  to 31)  <= Data_In(0 to 31);
        
      end generate CASE_MSTR_IS_32;
  

end generate GEN_NOTSAME;

end implementation;
