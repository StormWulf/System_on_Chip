-------------------------------------------------------------------------------
-- $Id: addr_reg_cntr_brst_flex.vhd,v 1.2 2008/05/13 21:43:38 gburch Exp $
-------------------------------------------------------------------------------
-- addr_reg_cntr_brst_flex.vhd 
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
-- Filename:        addr_reg_cntr_brst_flex.vhd
-- Version:         v1_00_a
-- Description:     This vhdl design file is for a specialized address counter
--                  used for linear incrementing or circular address generation
--                  and it has programmable increment values.        
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
-- Author:      D. Thorpe
-- History:
--
--      DET        Feb-5-02
-- ~~~~~~
--      First version
-- ^^^^^^
--
--      DET        Mar-4-02
-- ~~~~~~
--      - Corrected a problem with the cacheline address counting mechanism
-- ^^^^^^
--
--     DET     3/29/2002     v1_00_b
-- ~~~~~~
--     - Added burst mode support to the address reg/counter.
-- ^^^^^^
--
--
--     DET     8/11/2003     v1_00_e (PCI and DDR)
-- ~~~~~~
--     - Corrected a timing problem found with DDR integration. The signal
--       'clr_addr_be' needed to be inhibited when a new address load cycle
--       was being initiated coming out of a 'Wait' condition.
-- ^^^^^^
--
--
--     DET     4/16/2004     IPIF to V1_00_f
-- ~~~~~~
--     - Updated unisim library reference to unisim.vcomponents.all
--     - Commented out Xilinx primitive component declarations
-- ^^^^^^
--
--      GAB     07/01/05    IPIF to plbv46_slave_v1_00_a
-- ~~~~~~
--      - Modified to support PLB V4.6 Specifications (128 Bit DWIDTH)
--      - Removed std_logic_arith library and added numeric_std library
-- ^^^^^^
--      GAB    02/03/2006     
-- ~~~~~~
--     - Incorporated Doug's plb_ipif_v1_00_f changes...
--     - Added the C_CACHLINE_ADDR_MODE parameter.
--     - Added the Cacheline address realignemnt feature for PLB PCI
--       Bridge enhancement (Enhancement addressed in CR225048).
-- ^^^^^^
--      GAB    03/31/2006     
-- ~~~~~~
--     - Added support for 32-Bit slave configuration
-- ^^^^^^
--      GAB    09/29/2006     
-- ~~~~~~
--     - Fixed issue with cken signals for cacheline transfers in mixed dwidth
--       systems
--     - Fixed issue with sample/hold timing in a point-to-point configuration
-- ^^^^^^
--      GAB    12/01/2006     
-- ~~~~~~
--     - Fixed issue with Point-To-Point mode doing cachelines followed by
--       fixed burst.
-- ^^^^^^
--      GAB    4/29/2008   v1.01.a     
-- ~~~~~~
--     - Updated to use proc_common_v3_00_a library
-- ^^^^^^
---------------------------------------------------------------------------------
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
-- Library definitions

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
Use proc_common_v3_00_a.proc_common_pkg.all;
-- Xilinx Primitive Library
library unisim;
use unisim.vcomponents.all;

library plbv46_slave_burst_v1_01_a;
use plbv46_slave_burst_v1_01_a.all;

-------------------------------------------------------------------------------
-- Port Declaration
-------------------------------------------------------------------------------
entity addr_reg_cntr_brst_flex is
  Generic (
           C_CACHLINE_ADDR_MODE : Integer range 0 to 1 := 0;
           C_SPLB_P2P           : integer range 0 to 1 := 0;
           C_NUM_ADDR_BITS      : Integer := 32;   -- bits
           C_PLB_DWIDTH         : Integer := 64    -- bits
          ); 
    port (
       -- Clock and Reset
         Bus_reset          : In  std_logic;
         Bus_clk            : In  std_logic;
       
       
       -- Inputs from Slave Attachment
         Single             : In  std_logic;
         Cacheln            : In  std_logic;
         Burst              : In  std_logic;
         S_H_Qualifiers     : In  std_logic;
         Xfer_done          : In  std_logic;
         Addr_Load          : In  std_logic;
         Addr_Cnt_en        : In  std_logic;
         Addr_Cnt_Size      : In  Std_logic_vector(0 to 3);
         Addr_Cnt_Size_Erly : in  std_logic_vector(0 to 3);
         Mstr_SSize         : in  std_logic_vector(0 to 1);
         Address_In         : in  std_logic_vector(0 to C_NUM_ADDR_BITS-1);
         BE_in              : In  Std_logic_vector(0 to (C_PLB_DWIDTH/8)-1);
         Reset_BE           : in  std_logic_vector(0 to (C_PLB_DWIDTH/32) - 1);    
    
--          StrtAddr          : out std_logic_vector(0 to C_NUM_ADDR_BITS-1); 
       -- BE Outputs
         BE_out             : Out Std_logic_vector(0 to (C_PLB_DWIDTH/8)-1);                                                                
                                                                       
       -- IPIF & IP address bus source (AMUX output)
         Address_Out        : out std_logic_vector(0 to C_NUM_ADDR_BITS-1)

         );
end addr_reg_cntr_brst_flex;




architecture implementation of addr_reg_cntr_brst_flex is

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
signal  cken0               : std_logic;
signal  cken1               : std_logic;
signal  cken2               : std_logic;
signal  cken3               : std_logic;
signal  cken4               : std_logic;
signal  cken5               : std_logic;
signal  cken6               : std_logic;
signal  cntx1               : std_logic;
signal  cntx2               : std_logic;
signal  cntx4               : std_logic;
signal  cntx8               : std_logic;
signal  cntx16              : std_logic; --Added for Rainier (GAB)

signal  BE_clk_en           : std_logic;
signal  clr_addr_be         : std_logic;

signal  s_h_size            : std_logic_vector(0 to 3);
signal  s_h_sngle           : std_logic;
signal  s_h_cacheln         : std_logic;
signal  s_h_burst           : std_logic;

signal  bytes               : std_logic;
signal  hwrds               : std_logic;
signal  words               : std_logic;
signal  dblwrds             : std_logic;
signal  qwdwrds             : std_logic; --Added for Rainier (GAB)

signal  cacheln_4           : std_logic;
signal  cacheln_8           : std_logic;
signal  cacheln_16          : std_logic;
  
signal master_32            : std_logic;   
signal master_64            : std_logic;   
signal master_128           : std_logic;   


signal  start_address       : std_logic_vector(0 to C_NUM_ADDR_BITS-1);
  
-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
begin
  
    -- Output assignments
   
    clr_addr_be   <=  (Xfer_done or Bus_reset) and
                       not(S_H_Qualifiers);
    BE_clk_en     <=  Addr_Load 
                        or (Addr_Cnt_en and s_h_burst)
                        or (Addr_Cnt_en and s_h_cacheln); 

------------------------------------------------------------
-- If Generate
--
-- Label: LEGACY_CACHLINE_ADDR_MODE
--
-- If Generate Description:
--   This IfGen implements the legacy starting address mode
-- for Cacheline operations which is Line word first for 
-- writes and target word first for reads.
--
--
------------------------------------------------------------
LEGACY_CACHLINE_ADDR_MODE : if (C_CACHLINE_ADDR_MODE = 0) generate

-- Local Constants
-- Local variables
-- local signals
-- local components

begin

  start_address <= Address_In;

end generate LEGACY_CACHLINE_ADDR_MODE;



------------------------------------------------------------
-- If Generate
--
-- Label: LINEAR_CACHLINE_ADDR_MODE
--
-- If Generate Description:
--   This IfGen implements the linear starting address mode
-- for Cacheline operations which is Line word first for 
-- both writes and reads.
--
------------------------------------------------------------
LINEAR_CACHLINE_ADDR_MODE : if (C_CACHLINE_ADDR_MODE = 1) generate

constant WORD_ADDR_BIT          : natural := C_NUM_ADDR_BITS - 3;
constant DBLWORD_ADDR_BIT       : natural := C_NUM_ADDR_BITS - 4;
constant QUAD_WORD_ADDR_BIT     : natural := C_NUM_ADDR_BITS - 5;
constant OCT_WORD_ADDR_BIT      : natural := C_NUM_ADDR_BITS - 6;
  
begin
    -------------------------------------------------------------
    -- REALIGN_CACHELINE_ADDR
    -- This process implements the Cacheline starting address
    -- realignment function.
    -------------------------------------------------------------
    REALIGN_CACHELINE_ADDR : process (Address_In,
                                   cacheln_4,
                                   cacheln_8,
                                   cacheln_16)
    begin
        -- assign default load address value  
        start_address <= Address_In; 
        if (cacheln_4 = '1') then -- realign to Cacheline 4
            start_address(WORD_ADDR_BIT)        <= '0';
            start_address(DBLWORD_ADDR_BIT)     <= '0';
        elsif (cacheln_8 = '1') then -- realign to Cacheline 8
            start_address(WORD_ADDR_BIT)        <= '0';
            start_address(DBLWORD_ADDR_BIT)     <= '0';
            start_address(QUAD_WORD_ADDR_BIT)   <= '0';
-- Cacheline 16 is currently unsupported...commented out for code
-- coverage results
--        elsif (cacheln_16 = '1') then -- realign to Cacheline 16 
--            start_address(WORD_ADDR_BIT)        <= '0';
--            start_address(DBLWORD_ADDR_BIT)     <= '0';
--            start_address(QUAD_WORD_ADDR_BIT)   <= '0';
--            start_address(OCT_WORD_ADDR_BIT)    <= '0';
        else -- not a cacheline op
            null; -- do nothing else
        end if;
    end process REALIGN_CACHELINE_ADDR;
end generate LINEAR_CACHLINE_ADDR_MODE;


--StrtAddr  <= start_address;
    
   -- Sample and Hold registers
   
GEN_FOR_SHARED : if C_SPLB_P2P = 0 generate     
      I_SNGL_S_H_REG : FDRE
        port map(
          Q  =>  s_h_sngle,
          C  =>  Bus_clk,
          CE =>  S_H_Qualifiers,
          D  =>  Single,  
          R  =>  clr_addr_be
        );
    
      I_CACHLN_S_H_REG : FDRE
        port map(
          Q  =>  s_h_cacheln,
          C  =>  Bus_clk,
          CE =>  S_H_Qualifiers,
          D  =>  Cacheln,  
          R  =>  clr_addr_be
        );
    
    
      I_BURST_S_H_REG : FDRE
        port map(
          Q  =>  s_h_burst,
          C  =>  Bus_clk,
          CE =>  S_H_Qualifiers,
          D  =>  Burst,  
          R  =>  clr_addr_be 
        );
    
    
      ------------------------------------------------------------
      -- For Generate
      --
      -- Label: GEN_S_H_SIZE_REG
      --
      -- For Generate Description:
      --
      --
      --
      --
      ------------------------------------------------------------
      GEN_S_H_SIZE_REG : for bit_index in 0 to 3 generate
      
      begin
      
        I_SIZE_S_H_REG : FDRE
          port map(
            Q  =>  s_h_size(bit_index),
            C  =>  Bus_clk,
            CE =>  S_H_Qualifiers,
            D  =>  Addr_Cnt_Size(bit_index),  
            R  =>  clr_addr_be 
          );
    
      end generate GEN_S_H_SIZE_REG;
  
end generate GEN_FOR_SHARED;


GEN_FOR_P2P : if C_SPLB_P2P = 1 generate
signal sngle_i      : std_logic;
signal cacheln_i    : std_logic;
signal burst_i      : std_logic;
signal size_i       : std_logic_vector(0 to 3);

begin
      I_SNGL_S_H_REG : FDRE
        port map(
          Q  =>  sngle_i,
          C  =>  Bus_clk,
          CE =>  Addr_Load,
          D  =>  Single,  
          R  =>  clr_addr_be
        );
--    s_h_sngle <= ((Single and Addr_Load) or  sngle_i) and not(clr_addr_be);

    s_h_sngle   <= Single when Addr_Load = '1' and clr_addr_be = '0'
              else sngle_i when Addr_Load = '0' and clr_addr_be = '0'
              else '0';
    
      I_CACHLN_S_H_REG : FDRE
        port map(
          Q  =>  cacheln_i,
          C  =>  Bus_clk,
          CE =>  Addr_Load,
          D  =>  Cacheln,  
          R  =>  clr_addr_be
        );
--    s_h_cacheln <= ((Cacheln and Addr_Load) or  cacheln_i) and not(clr_addr_be);
    
    s_h_cacheln     <= Cacheln when Addr_Load = '1' and clr_addr_be = '0'
                  else cacheln_i when Addr_Load = '0' and clr_addr_be = '0'
                  else '0';
    
      I_BURST_S_H_REG : FDRE
        port map(
          Q  =>  burst_i,
          C  =>  Bus_clk,
          CE =>  Addr_Load,
          D  =>  Burst,  
          R  =>  clr_addr_be 
        );
    
--    s_h_burst <= ((Burst and Addr_Load) or  burst_i) and not(clr_addr_be);

    s_h_burst <= Burst when Addr_Load = '1' and clr_addr_be = '0'
            else burst_i when Addr_Load = '0' and clr_addr_be = '0'
            else '0';

      ------------------------------------------------------------
      -- For Generate
      --
      -- Label: GEN_S_H_SIZE_REG
      --
      -- For Generate Description:
      --
      --
      --
      --
      ------------------------------------------------------------
      GEN_S_H_SIZE_REG : for bit_index in 0 to 3 generate
      
      begin
      
        I_SIZE_S_H_REG : FDRE
          port map(
            Q  =>  size_i(bit_index),
            C  =>  Bus_clk,
            CE =>  Addr_Load,
            D  =>  Addr_Cnt_Size_Erly(bit_index),  
            R  =>  clr_addr_be 
          );
    
--        s_h_size(bit_index) <= ((Addr_Cnt_Size_Erly(bit_index) and Addr_Load )
--                                or  size_i(bit_index)) 
--                                and not(clr_addr_be);
                                
        s_h_size(bit_index) <=   Addr_Cnt_Size_Erly(bit_index) when Addr_Load = '1' and clr_addr_be = '0'
                            else size_i(bit_index) when Addr_Load = '0' and clr_addr_be = '0'
                            else '0';
                                
                                
      end generate GEN_S_H_SIZE_REG;

end generate GEN_FOR_P2P;
   
   
   -- use size bits to determine cacheln count (if a cacheline xfer)
   
    cacheln_4     <=  s_h_cacheln and not(s_h_size(2)) and s_h_size(3); -- "01"
    
    cacheln_8     <=  s_h_cacheln and s_h_size(2) and not(s_h_size(3)); -- "10"
    
    cacheln_16    <=  s_h_cacheln and s_h_size(2) and s_h_size(3);      -- "11"
   
   
   
   -- use the size bits to determine tranfer size (if a burst)
    bytes         <=  s_h_burst and not(s_h_size(1)) and not(s_h_size(2)) and not(s_h_size(3)); -- "000"
                                    
    hwrds         <=  s_h_burst and not(s_h_size(1)) and not(s_h_size(2)) and s_h_size(3);      -- "001"
                                    
    words         <=  s_h_burst and not(s_h_size(1)) and s_h_size(2) and not(s_h_size(3));      -- "010"
    
    dblwrds       <=  s_h_burst and not(s_h_size(1)) and s_h_size(2) and s_h_size(3);           -- "011"
    
    qwdwrds       <=  s_h_burst and s_h_size(1) and not(s_h_size(2)) and not(s_h_size(3));      -- "100"
    

   -- Requesting Master
   master_32    <= '1' when Mstr_SSize = "00"
              else '0';
   
   master_64    <= '1' when Mstr_SSize = "01"
              else '0';
   
   master_128   <= '1' when Mstr_SSize = "10"
              else '0';
   
   
   
   -- Set the "count by' controls
   
    cntx1         <=  bytes and not(Addr_Load);
    
    cntx2         <=  hwrds and not(Addr_Load);
    
GEN_DWIDTH32 : if C_PLB_DWIDTH = 32 generate    
    cntx4         <=  (s_h_cacheln or words or dblwrds or qwdwrds) and not(Addr_Load);
    cntx8         <=  '0';
    cntx16        <=  '0';
end generate GEN_DWIDTH32;

GEN_DWIDTH64 : if C_PLB_DWIDTH = 64 generate    
    cntx4         <=  (words   or (master_32 and s_h_cacheln)) and not(Addr_Load);
    cntx8         <=  (dblwrds or qwdwrds or (not master_32 and s_h_cacheln)) and not(Addr_Load);
    cntx16        <=  '0';
end generate GEN_DWIDTH64;

GEN_DWIDTH128 : if C_PLB_DWIDTH = 128 generate    
    cntx4         <=  (words   or (master_32  and s_h_cacheln)) and not(Addr_Load);
    cntx8         <=  (dblwrds or (master_64  and s_h_cacheln)) and not(Addr_Load);
    cntx16        <=  (qwdwrds or (master_128 and s_h_cacheln)) and not(Addr_Load);
end generate GEN_DWIDTH128;


   -- set the clock enables
    
GEN_CKEN_FOR32BIT : if C_PLB_DWIDTH = 32 generate
    cken0         <=  Addr_Load or (Addr_Cnt_en and s_h_burst);
                                                             
    cken1         <=  Addr_Load or (Addr_Cnt_en and s_h_burst);
                                                             
    cken2         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or s_h_cacheln));
    
    cken3         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or s_h_cacheln));
    
    cken4         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or cacheln_8 or cacheln_16));
    
    cken5         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or cacheln_16));
    
    cken6         <=  Addr_Load or (s_h_burst and Addr_Cnt_en);
end generate  GEN_CKEN_FOR32BIT; 
  
GEN_CKEN_FOR64BIT : if C_PLB_DWIDTH = 64 generate
    cken0         <=  Addr_Load or (Addr_Cnt_en and s_h_burst);
                                                             
    cken1         <=  Addr_Load or (Addr_Cnt_en and s_h_burst);
                                                             
    cken2         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or (master_32 and s_h_cacheln)));
    
    cken3         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or s_h_cacheln));
    
    cken4         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or cacheln_8 or cacheln_16));
    
    cken5         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or cacheln_16));
    
    cken6         <=  Addr_Load or (s_h_burst and Addr_Cnt_en);
end generate  GEN_CKEN_FOR64BIT; 

GEN_CKEN_FOR128BIT : if C_PLB_DWIDTH = 128 generate
    cken0         <=  Addr_Load or (Addr_Cnt_en and s_h_burst);
                                                             
    cken1         <=  Addr_Load or (Addr_Cnt_en and s_h_burst);
                                                             
    cken2         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or (master_32 and s_h_cacheln)));
    
    cken3         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or ((master_32 or master_64) and s_h_cacheln)));
    
    cken4         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or cacheln_8 or cacheln_16));
    
    cken5         <=  Addr_Load or (Addr_Cnt_en and (s_h_burst or cacheln_16));
    
    cken6         <=  Addr_Load or (s_h_burst and Addr_Cnt_en);
end generate  GEN_CKEN_FOR128BIT; 


  
  I_FLEX_ADDR_CNTR : entity plbv46_slave_burst_v1_01_a.flex_addr_cntr
    Generic map(
       C_AWIDTH      => C_NUM_ADDR_BITS,
       C_DWIDTH      => C_PLB_DWIDTH
       )
      
    port map(
      Clk            =>  Bus_clk,       -- : in  std_logic;
      Rst            =>  clr_addr_be,   -- : in  std_logic;
      MSize          =>  Mstr_SSize,
      Load_Enable    =>  Addr_Load,     -- : in  std_logic;
      Load_addr      =>  start_address, -- : in  std_logic_vector(C_AWIDTH-1 downto 0);
      Cnt_by_1       =>  cntx1,         -- : in  std_logic;
      Cnt_by_2       =>  cntx2,         -- : in  std_logic;
      Cnt_by_4       =>  cntx4,         -- : in  std_logic;
      Cnt_by_8       =>  cntx8,         -- : in  std_logic;
      Cnt_by_16      =>  cntx16,        -- : in  std_logic;
      Cnt_by_32      =>  '0',           -- : in  std_logic;
      Cnt_by_64      =>  '0',           -- : in  std_logic;
      Cnt_by_128     =>  '0',           -- : in  std_logic;
      Clk_En_0       =>  cken0,         -- : in  std_logic;
      Clk_En_1       =>  cken1,         -- : in  std_logic;
      Clk_En_2       =>  cken2,         -- : in  std_logic;
      Clk_En_3       =>  cken3,         -- : in  std_logic;
      Clk_En_4       =>  cken4,         -- : in  std_logic;
      Clk_En_5       =>  cken5,         -- : in  std_logic;
      Clk_En_6       =>  cken6,         -- : in  std_logic;
      Clk_En_7       =>  cken6,         -- : in  std_logic;
      Addr_out       =>  Address_Out,   -- : out std_logic_vector(C_AWIDTH-1 downto 0);
      Carry_Out      =>  open,          -- : out std_logic;
      Single_beat    =>  s_h_sngle,     -- : in  std_logic;
      Cacheline      =>  s_h_cacheln,   -- : in  std_logic;
      burst_bytes    =>  bytes,         -- : in  std_logic;
      burst_hwrds    =>  hwrds,         -- : in  std_logic;
      burst_words    =>  words,         -- : in  std_logic;
      burst_dblwrds  =>  dblwrds,       -- : in  std_logic;
      burst_qwdwrds  =>  qwdwrds,       -- : in  std_logic;
      BE_clk_en      =>  BE_clk_en,     -- : in  std_logic;
      Reset_BE       =>  Reset_BE,      -- : in  std_logic_vector(0 to C_PLB_DWIDTH/32 - 1);
      BE_in          =>  BE_in,         -- : In  std_logic_vector(0 to C_PLB_DWIDTH/8 - 1);
      BE_out         =>  BE_out         -- : Out std_logic_vector(0 to C_PLB_DWIDTH/8 - 1)
     );

        
end implementation;
  




