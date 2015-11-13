-------------------------------------------------------------------------------
-- $Id: flex_addr_cntr.vhd,v 1.1 2008/04/29 20:49:11 gburch Exp $
-------------------------------------------------------------------------------
-- flex_addr_cntr.vhd
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
-- Filename:        flex_addr_cntr.vhd
-- Version:         v1_00_a
-- Description:     
--    This VHDL design file implements a flexible counter that is used to implement 
-- the address counting function needed for PLB Slave devices. It provides the
-- ability to increment addresses in the following manner:
--  - linear incrementing x1, x2, x4, x8, x16, x32, x64, x128 (burst support)             
--  - 4 word cacheline (x8 count)
--  - 8 word cacheline (x8 count)
--  - 16 word cacheline (x8 count)
--  - growth  32 word cacheln (x8, x16 count)                 
--                  
-- Special notes:
--
--  - Count enables must be held low during load operations
--  - Clock enables must be asserted during load operations                 
--  
--
-- This file also implements the BE generator function.
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
-- Author:          DET
-- Revision:        $Revision: 1.1 $
-- Date:            $3/11/2003$
--
-- History:
--   DET   3/11/2003       Initial Version
--                      
--
--     DET     7/10/2003     Granite Rls PLB IPIF V1.00.e
-- ~~~~~~
--     - Removed XON generic from LUT4 component declaration and instances.
-- ^^^^^^
--
--
--     DET     4/12/2004     IPIF to V1_00_f
-- ~~~~~~
--     - Updated unisim library reference to unisim.vcomponents.all
--     - Commented out Xilinx primitive component declarations
-- ^^^^^^
--
--
--     DET     11/15/2004     EDK_Gmm_SP2
-- ~~~~~~
--     - Changed counter so that the 3 LSB's of the Addr_out port are cleared
--       during cacheline operations.
-- ^^^^^^
--
--      GAB     07/01/05    IPIF to plbv46_slave_v1_00_a
-- ~~~~~~
--      Modified to support PLB V4.6 Specifications (128 Bit DWIDTH).
-- ^^^^^^
--      GAB     02/06/06    IPIF to plbv46_slave_v1_00_a
-- ~~~~~~
--      Modified to support 64-Bit C_DWIDTH
-- ^^^^^^
--      GAB    03/31/2006     
-- ~~~~~~
--     - Added support for 32-Bit slave configuration
-- ^^^^^^
--      GAB    09/29/2006     
-- ~~~~~~
--      - Added qualifiers to the 'set_all_be' signals to look for the sourcing
--      master.  Smaller masters performing cache lines require the be's to
--      not all be set.
-- ^^^^^^
--      GAB    10/11/2006     
-- ~~~~~~
--      - Fixed issue with LSB address bit masking for line word first reads.
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
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------

entity flex_addr_cntr is
  Generic (
     C_AWIDTH   : integer := 32;
     C_DWIDTH   : integer := 64           -- Added for PLB V4.6 (GAB)
     );
    
  port (
    Clk            : in  std_logic;
    Rst            : in  std_logic;
    
   -- address generation 
    MSize          : in  std_logic_vector(0 to 1);
    Load_Enable    : in  std_logic;
    Load_addr      : in  std_logic_vector(C_AWIDTH-1 downto 0);
    Cnt_by_1       : in  std_logic;
    Cnt_by_2       : in  std_logic;
    Cnt_by_4       : in  std_logic;
    Cnt_by_8       : in  std_logic;
    Cnt_by_16      : in  std_logic;
    Cnt_by_32      : in  std_logic;
    Cnt_by_64      : in  std_logic;
    Cnt_by_128     : in  std_logic;
    Clk_En_0       : in  std_logic;
    Clk_En_1       : in  std_logic;
    Clk_En_2       : in  std_logic;
    Clk_En_3       : in  std_logic;
    Clk_En_4       : in  std_logic;
    Clk_En_5       : in  std_logic;
    Clk_En_6       : in  std_logic;
    Clk_En_7       : in  std_logic;
    Addr_out       : out std_logic_vector(C_AWIDTH-1 downto 0);
    Carry_Out      : out std_logic;
    
   -- BE Generation 
    Single_beat    : In  std_logic;
    Cacheline      : In  std_logic;
    burst_bytes    : In  std_logic;
    burst_hwrds    : In  std_logic;
    burst_words    : In  std_logic;
    burst_dblwrds  : In  std_logic;
    burst_qwdwrds  : In  std_logic;
    BE_clk_en      : in  std_logic;
    Reset_BE       : in  std_logic_vector(0 to C_DWIDTH/32 - 1);    
    BE_in          : In  std_logic_vector(0 to C_DWIDTH/8 - 1);
    BE_out         : Out std_logic_vector(0 to C_DWIDTH/8 - 1)
   );

end entity flex_addr_cntr;


architecture implementation of flex_addr_cntr is

-------------------------------------------------------------------------------                       
-- Function Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------                       
-- Type Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Singal Declarations
-------------------------------------------------------------------------------
-- Counter Signals
signal lut_out          : std_logic_vector(C_AWIDTH-1 downto 0);
signal addr_out_i       : std_logic_vector(C_AWIDTH-1 downto 0);
signal next_addr_i      : std_logic_vector(C_AWIDTH-1 downto 0);
signal Cout             : std_logic_vector(C_AWIDTH downto 0);

-- BE Gen signals
signal decoded_be       : std_logic_vector(0 to 3);
signal be_next          : std_logic_vector(0 to C_DWIDTH/8 - 1);
signal set_all_be       : std_logic;
signal addr_lsb_clear   : std_logic;

signal word_enable      : std_logic_vector(0 to C_DWIDTH/32 - 1);
signal xfer_64          : std_logic;
signal be_extended      : std_logic;
signal burst_32or64     : std_logic;



attribute INIT          : string;  -- used for LUTs

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
begin --(architecture implementation)



  -- Misc logic assignments
  
   Addr_out       <= addr_out_i;
 
   Carry_Out      <= Cout(C_AWIDTH);
 
   addr_lsb_clear <= Rst or Cacheline;


   ------------------------------------------------------------
   -- For Generate
   --
   -- Label: GEN_ADDR_MSB
   --
   -- For Generate Description:
   --   This For-Gen implements bits 7 and beyond for the the 
   -- address counter. The entire slice shares the same clock
   -- enable.
   --
   --
   --
   ------------------------------------------------------------
   GEN_ADDR_MSB : for addr_bit_index in 7 to C_AWIDTH-1 generate
      -- local variables
      -- local constants
      -- local signals
      -- local component declarations
   
   begin
   
   
      ------------------------------------------------------------------------------- 
      ---- Address Counter Bits 7 to max address bit  
     
     
      I_LUT_N : LUT4
        generic map(
          INIT => X"F202"
          )
        port map (
          O  => lut_out(addr_bit_index),        
          I0 => addr_out_i(addr_bit_index),     
          I1 => '0',     
          I2 => Load_Enable,       
          I3 => Load_addr(addr_bit_index)       
          );                       

      I_MUXCY_N : MUXCY
        port map (
          DI => '0',
          CI => Cout(addr_bit_index),
          S  => lut_out(addr_bit_index),
          O  => Cout(addr_bit_index+1)
          );

      I_XOR_N : XORCY
        port map (
          LI => lut_out(addr_bit_index),
          CI => Cout(addr_bit_index),
          O  => next_addr_i(addr_bit_index)
          );

      I_FDRE_N: FDRE
        port map (
          Q  => addr_out_i(addr_bit_index),  
          C  => Clk,            
          CE => Clk_En_7,       
          D  => next_addr_i(addr_bit_index), 
          R  => Rst             
          );      
   
   end generate GEN_ADDR_MSB;

------------------------------------------------------------------------------- 
---- Address Counter Bit 6  
 
 
  I_LUT6 : LUT4
    generic map(
      INIT => X"F202"
      )
    port map (
      O  => lut_out(6),        
      I0 => addr_out_i(6),     
      I1 => Cnt_by_128,     
      I2 => Load_Enable,       
      I3 => Load_addr(6)       
      );                       

  I_MUXCY6 : MUXCY
    port map (
      DI => Cnt_by_128,
      CI => Cout(6),
      S  => lut_out(6),
      O  => Cout(7)
      );

  I_XOR6 : XORCY
    port map (
      LI => lut_out(6),
      CI => Cout(6),
      O  => next_addr_i(6)
      );

  I_FDRE6 : FDRE
    port map (
      Q  => addr_out_i(6),  
      C  => Clk,            
      CE => Clk_En_6,       
      D  => next_addr_i(6), 
      R  => Rst             
      );      

  
 
 
------------------------------------------------------------------------------- 
---- Address Counter Bit 5  
 
 
  I_LUT5 : LUT4
    generic map(
      INIT => X"F202"
      )
    port map (
      O  => lut_out(5),        
      I0 => addr_out_i(5),     
      I1 => Cnt_by_64,     
      I2 => Load_Enable,       
      I3 => Load_addr(5)       
      );                       

  I_MUXCY5 : MUXCY
    port map (
      DI => Cnt_by_64,
      CI => Cout(5),
      S  => lut_out(5),
      O  => Cout(6)
      );

  I_XOR5 : XORCY
    port map (
      LI => lut_out(5),
      CI => Cout(5),
      O  => next_addr_i(5)
      );

  I_FDRE5: FDRE
    port map (
      Q  => addr_out_i(5),  
      C  => Clk,            
      CE => Clk_En_5,       
      D  => next_addr_i(5), 
      R  => Rst             
      );      

  
 
 
------------------------------------------------------------------------------- 
---- Address Counter Bit 4  
 
 
  I_LUT4 : LUT4
    generic map(
      INIT => X"F202"
      )
    port map (
      O  => lut_out(4),        
      I0 => addr_out_i(4),     
      I1 => Cnt_by_32,     
      I2 => Load_Enable,       
      I3 => Load_addr(4)       
      );                       

  I_MUXCY4 : MUXCY
    port map (
      DI => Cnt_by_32,
      CI => Cout(4),
      S  => lut_out(4),
      O  => Cout(5)
      );

  I_XOR4 : XORCY
    port map (
      LI => lut_out(4),
      CI => Cout(4),
      O  => next_addr_i(4)
      );

  I_FDRE4: FDRE
    port map (
      Q  => addr_out_i(4),  
      C  => Clk,            
      CE => Clk_En_4,       
      D  => next_addr_i(4), 
      R  => Rst             
      );      

  
 
 
------------------------------------------------------------------------------- 
---- Address Counter Bit 3  
 
 
  I_LUT3 : LUT4
    generic map(
      INIT => X"F202"
      )
    port map (
      O  => lut_out(3),        
      I0 => addr_out_i(3),     
      I1 => Cnt_by_16,     
      I2 => Load_Enable,       
      I3 => Load_addr(3)       
      );                       

  I_MUXCY3 : MUXCY
    port map (
      DI => Cnt_by_16,
      CI => Cout(3),
      S  => lut_out(3),
      O  => Cout(4)
      );

  I_XOR3 : XORCY
    port map (
      LI => lut_out(3),
      CI => Cout(3),
      O  => next_addr_i(3)
      );


                    
    GEN_ADDR_FOR_128 : if C_DWIDTH = 128 generate
    signal bit3_reset       : std_logic;
    begin
      -- Reset only if requesting master is a 128 Bits Master
      bit3_reset <= '1' when (Cacheline = '1' and MSize = "10")
                                or (Rst = '1')
               else '0';

      I_FDRE3: FDRE
        port map (
          Q  => addr_out_i(3),  
          C  => Clk,            
          CE => Clk_En_3,       
          D  => next_addr_i(3), 
          R  => bit3_reset
          );      
     end generate GEN_ADDR_FOR_128;

    GEN_ADDR_FOR_32_64 : if C_DWIDTH < 128 generate
      I_FDRE3: FDRE
        port map (
          Q  => addr_out_i(3),  
          C  => Clk,            
          CE => Clk_En_3,       
          D  => next_addr_i(3), 
          R  => Rst             
          );      
     end generate GEN_ADDR_FOR_32_64;
  
 
 
------------------------------------------------------------------------------- 
---- Address Counter Bit 2  
 
 
  I_LUT2 : LUT4
    generic map(
      INIT => X"F202"
      )
    port map (
      O  => lut_out(2),        
      I0 => addr_out_i(2),     
      I1 => Cnt_by_8,     
      I2 => Load_Enable,       
      I3 => Load_addr(2)       
      );                       

  I_MUXCY2 : MUXCY
    port map (
      DI => Cnt_by_8,
      CI => Cout(2),
      S  => lut_out(2),
      O  => Cout(3)
      );

  I_XOR2 : XORCY
    port map (
      LI => lut_out(2),
      CI => Cout(2),
      O  => next_addr_i(2)
      );
-- GAB 3/31/06
  GEN_ADDR_FOR_64_128 : if C_DWIDTH > 32 generate
  signal bit2_reset       : std_logic;
  begin

      -- Reset only if requesting master is a 64 or 128 Bits Master
      bit2_reset <= '1' when (Cacheline = '1' and MSize = "10")
                          or (Cacheline = '1' and MSize = "01")
                          or (Rst = '1')
               else '0';

      I_FDRE2: FDRE
        port map (
          Q  => addr_out_i(2),  
          C  => Clk,            
          CE => Clk_En_2,       
          D  => next_addr_i(2), 
          R  => bit2_reset             
          );      
   end generate GEN_ADDR_FOR_64_128;

-- GAB 3/31/06
  GEN_ADDR_FOR_32 : if C_DWIDTH = 32 generate
      I_FDRE2: FDRE
        port map (
          Q  => addr_out_i(2),  
          C  => Clk,            
          CE => Clk_En_2,       
          D  => next_addr_i(2), 
          R  => Rst             
          );      
   end generate GEN_ADDR_FOR_32;
 
 
------------------------------------------------------------------------------- 
---- Address Counter Bit 1  
 
 
  I_LUT1 : LUT4
    generic map(
      INIT => X"F202"
      )
    port map (
      O  => lut_out(1),        
      I0 => addr_out_i(1),     
      I1 => Cnt_by_4,     
      I2 => Load_Enable,       
      I3 => Load_addr(1)       
      );                       

  I_MUXCY1 : MUXCY
    port map (
      DI => Cnt_by_4,
      CI => Cout(1),
      S  => lut_out(1),
      O  => Cout(2)
      );

  I_XOR1 : XORCY
    port map (
      LI => lut_out(1),
      CI => Cout(1),
      O  => next_addr_i(1)
      );

  I_FDRE1: FDRE
    port map (
      Q  => addr_out_i(1),  
      C  => Clk,            
      CE => Clk_En_1,       
      D  => next_addr_i(1), 
      R  => addr_lsb_clear             
      );      

 
 
------------------------------------------------------------------------------- 
---- Address Counter Bit 0  
 
 
  I_LUT0 : LUT4
    generic map(
      INIT => X"F202"
      )
    port map (
      O  => lut_out(0),        
      I0 => addr_out_i(0),     
      I1 => Cnt_by_2,     
      I2 => Load_Enable,       
      I3 => Load_addr(0)       
      );                       

  I_MUXCY0 : MUXCY
    port map (
      DI => Cnt_by_2,
      CI => Cout(0),
      S  => lut_out(0),
      O  => Cout(1)
      );

  I_XOR0 : XORCY
    port map (
      LI => lut_out(0),
      CI => Cout(0),
      O  => next_addr_i(0)
      );

  I_FDRE0: FDRE
    port map (
      Q  => addr_out_i(0),  
      C  => Clk,            
      CE => Clk_En_0,       
      D  => next_addr_i(0), 
      R  => addr_lsb_clear             
      );      

 
 
 
------------------------------------------------------------------------------- 
---- Carry in selection for LS Bit  
 
 
  I_MUXCY : MUXCY
    port map (
      DI => Cnt_by_1,
      CI => '0',
      S  => Load_Enable,
      O  => Cout(0)
      );





------------------------------------------------------------------------------- 
------------------------------------------------------------------------------- 
---- BE Generator   (C_DWIDTH=128 Bit   26 LUTs, 16 FDREs)
--                  (C_DWIDTH=64 Bit    16 LUTs, 8 FDREs)
--                  (C_DWIDTH=32 Bit    10 LUTs, 4 FDREs
--Modified for PLB V4.6 (GAB)  

-- GAB 3/31/06
GEN_BE_32 : if C_DWIDTH = 32 generate
    set_all_be   <=  burst_words 
                    or burst_dblwrds 
                    or burst_qwdwrds 
                    or Cacheline;
                    
    burst_32or64 <=  '0';
end generate GEN_BE_32;

GEN_BE_64 : if C_DWIDTH = 64 generate
    set_all_be <= '1' when burst_dblwrds ='1'
                        or burst_qwdwrds ='1'
                        or (Cacheline='1' and MSize/="00")
             else '0';
                    
    burst_32or64 <=  '1' when (burst_words='1')
                           -- Cacheline and 32 bit master
                           or (Cacheline='1' and MSize="00")
                else '0';
end generate GEN_BE_64;

GEN_BE_128 : if C_DWIDTH = 128 generate
    set_all_be <=  '1' when burst_qwdwrds='1' 
                        or (Cacheline='1' and MSize="10")
              else '0';
              
    burst_32or64 <=  '1' when (burst_words='1' )
                                or (burst_dblwrds='1')
                                -- Cacheline and 32 or 64 bit master
                                or (Cacheline='1' and MSize/="10")  
                else '0';
end generate GEN_BE_128;


  I_BE_GEN_LUT0 : LUT4
    generic map(
      INIT => X"FF31"
      )
    port map (
      O  => decoded_be(0),     
      I0 => next_addr_i(0),     
      I1 => next_addr_i(1),
      I2 => burst_hwrds,     
      I3 => burst_32or64     
      );                       

  I_BE_GEN_LUT1 : LUT4
    generic map(
      INIT => X"FF32"
      )
    port map (
      O  => decoded_be(1),     
      I0 => next_addr_i(0),     
      I1 => next_addr_i(1),
      I2 => burst_hwrds,     
      I3 => burst_32or64     
      );                       

  I_BE_GEN_LUT2 : LUT4
    generic map(
      INIT => X"FFC4"
      )
    port map (
      O  => decoded_be(2),     
      I0 => next_addr_i(0),     
      I1 => next_addr_i(1),
      I2 => burst_hwrds,     
      I3 => burst_32or64     
      );                       

  I_BE_GEN_LUT4 : LUT4
    generic map(
      INIT => X"FFC8"
      )
    port map (
      O  => decoded_be(3),     
      I0 => next_addr_i(0),     
      I1 => next_addr_i(1),
      I2 => burst_hwrds,     
      I3 => burst_32or64     
      );                       


------------------------------------------------------------
-- Generate Word Enables 
------------------------------------------------------------
-- Added for Rainier (GAB)

--xfer_64     <= burst_dblwrds or Cacheline;

xfer_64     <= '1' when (burst_dblwrds = '1')
                     or (Cacheline='1' and MSize/="00")
          else '0';


be_extended <= '1' when C_DWIDTH = 128
       else    '0';

-- For 32-Bit DWIDTH always enable word 0
GEN_ENABLE_32 : if C_DWIDTH = 32 generate
    word_enable(0) <= '1';
end generate GEN_ENABLE_32;

-- For 64-Bit and 128-Bit DWIDTH enable word 0
-- and word 1 based on transfer type and address
GEN_ENABLE_64_128 : if C_DWIDTH >= 64 generate
  I_BE_ENBL_LUT0 : LUT4
    generic map(
      INIT => X"31F5"
      )
    port map (
      O  => word_enable(0),     
      I0 => next_addr_i(2),     
      I1 => next_addr_i(3),
      I2 => xfer_64,     
      I3 => be_extended     
      );                       

  I_BE_ENBL_LUT1 : LUT4
    generic map(
      INIT => X"32FA"
      )
    port map (
      O  => word_enable(1),     
      I0 => next_addr_i(2),     
      I1 => next_addr_i(3),
      I2 => xfer_64,     
      I3 => be_extended     
      );                       
end generate GEN_ENABLE_64_128;

-- For 128-Bit DWIDTH enable word 2 and word 3
-- based on transfer type and address
GEN_ENABLE_128 : if C_DWIDTH = 128 generate

  I_BE_ENBL_LUT2 : LUT4
    generic map(
      INIT => X"C400"
      )
    port map (
      O  => word_enable(2),     
      I0 => next_addr_i(2),     
      I1 => next_addr_i(3),
      I2 => xfer_64,     
      I3 => be_extended     
      );                       

  I_BE_ENBL_LUT4 : LUT4
    generic map(
      INIT => X"C800"
      )
    port map (
      O  => word_enable(3),     
      I0 => next_addr_i(2),     
      I1 => next_addr_i(3),
      I2 => xfer_64,     
      I3 => be_extended     
      );                       

end generate GEN_ENABLE_128;

------------------------------------------------------------
-- For Generate
--
-- Label: LDMUX_FDRSE_0to3
--
-- For Generate Description:
--    Implements Load Mux and Output register for BE_out bits
--    0 to 3.
--
--
--
------------------------------------------------------------
LDMUX_FDRSE_0to3 : for BE_index in 0 to 3 generate
signal reset0_3     : std_logic;

begin
  I_BE_LDMUX_0to3 : LUT4
    generic map(
      INIT => X"F088"
      )
    port map (
      O  => be_next(BE_index),     
      I0 => decoded_be(BE_index),               
      I1 => word_enable(0),
      I2 => BE_in(BE_index),     
      I3 => Single_beat     
      );                       

  I_FDRSE_BE0to3: FDRSE
    port map (
      Q  => BE_out(BE_index),  
      C  => Clk,            
      CE => BE_clk_en,       
      D  => be_next(BE_index), 
      R  => reset0_3,
      S  => set_all_be             
      );      
reset0_3 <= Rst or (Reset_BE(0) and Single_beat and BE_clk_en);

end generate LDMUX_FDRSE_0to3;
  
  ------------------------------------------------------------
  -- For Generate
  --
  -- Label: LDMUX_FDRSE_4to7
  --
  -- For Generate Description:
  --    Implements Load Mux and Output register for BE_out bits
  --    4 to 7.
  --
  --
  --
  ------------------------------------------------------------
GEN_DWIDTH_64_128 : if C_DWIDTH >= 64 generate
signal reset4_7     : std_logic;
begin
    LDMUX_FDRSE_4to7 : for BE_index in 4 to 7 generate

    begin
        I_BE_LDMUX_4to7 : LUT4
          generic map(
            INIT => X"F088"
            )
          port map (
            O  => be_next(BE_index),     
            I0 => decoded_be(BE_index-4),     
            I1 => word_enable(1),
            I2 => BE_in(BE_index),     
            I3 => Single_beat     
            );                       

        I_FDRSE_BE4to7: FDRSE
          port map (
            Q  => BE_out(BE_index),  
            C  => Clk,            
            CE => BE_clk_en,       
            D  => be_next(BE_index), 
            R  => reset4_7,
            S  => set_all_be             
            );      

    end generate LDMUX_FDRSE_4to7;
  reset4_7 <= Rst or (Reset_BE(1) and Single_beat and BE_clk_en);

end generate GEN_DWIDTH_64_128;
  
  ------------------------------------------------------------
  -- Generate
  --
  -- Label: GEN_DWIDTH_128
  --
  -- For Generate Description:
  --    Implements Load Mux and Output register for BE_out bits
  --    12 to 15.
  --
  --
  --
  ------------------------------------------------------------
GEN_DWIDTH_128 : if C_DWIDTH = 128 generate
signal reset8_11    : std_logic;
signal reset12_15   : std_logic;
begin
    LDMUX_FDRSE_8to11 : for BE_index in 8 to 11 generate

    begin
      I_BE_LDMUX_8to11 : LUT4
        generic map(
          INIT => X"F088"
          )
        port map (
          O  => be_next(BE_index),     
          I0 => decoded_be(BE_index-8),               
          I1 => word_enable(2),          -- A2=0 selects decoded bit       
          I2 => BE_in(BE_index),     
          I3 => Single_beat     
          );                       

      I_FDRSE_BE8to11: FDRSE
        port map (
          Q  => BE_out(BE_index),  
          C  => Clk,            
          CE => BE_clk_en,       
          D  => be_next(BE_index), 
          R  => reset8_11,
          S  => set_all_be             
          );      

    end generate LDMUX_FDRSE_8to11;

    LDMUX_FDRSE_12to15 : for BE_index in 12 to 15 generate
    begin
        I_BE_LDMUX_12to15 : LUT4
          generic map(
            INIT => X"F088"
            )
          port map (
            O  => be_next(BE_index),     
            I0 => decoded_be(BE_index-12),     
            I1 => word_enable(3),
            I2 => BE_in(BE_index),     
            I3 => Single_beat     
            );                       

        I_FDRSE_BE12to15: FDRSE
          port map (
            Q  => BE_out(BE_index),  
            C  => Clk,            
            CE => BE_clk_en,       
            D  => be_next(BE_index), 
            R  => reset12_15,
            S  => set_all_be             
            );      

    end generate LDMUX_FDRSE_12to15;
reset8_11     <= Rst or (Reset_BE(2) and Single_beat and BE_clk_en);
reset12_15    <= Rst or (Reset_BE(3) and Single_beat and BE_clk_en);

end generate GEN_DWIDTH_128;





 --- End of BE Generation

end implementation;
