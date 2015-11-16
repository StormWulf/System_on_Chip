-------------------------------------------------------------------------------
-- $Id: plb_address_decoder.vhd,v 1.2 2008/05/13 21:43:38 gburch Exp $
-------------------------------------------------------------------------------
-- plb_address_decoder - entity/architecture pair
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
-- Filename:        plb_address_decoder.vhd
-- Version:         v1.00a
-- Description:     Address decoder utilizing unconstrained arrays for Base
--                  Address specification and ce number.
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
--  GAB     8/3/06
-- ~~~~~~
--  - Initial release of v1.00.a
-- ^^^^^^
--  GAB     12/20/06
-- ~~~~~~
--  - Fixed Point-to-Point issue where address used to decode CE's was
-- a clock too late causing wrong CE to be driven.
-- ^^^^^^
--  GAB     1/21/07
-- ~~~~~~
--  - Pulled addr_out_s_h out of MEM_DECODE_GEN loop to prevent multiple
--  drivers of addr_out_s_h.
-- ^^^^^^
--  GAB     7/13/07
-- ~~~~~~
--  - Fixed issue where plb address was not getting sampled correctly in
-- the point to point mode.
-- ^^^^^^
--  GAB     7/20/07
-- ~~~~~~
--  - Passed a sample and help version of RNW for use with dataphase 
--  timeout timer.
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
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.pselect_f;
use proc_common_v3_00_a.or_gate128;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.family_support.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- Port declarations
-------------------------------------------------------------------------------

entity plb_address_decoder is
    generic (
        C_BUS_AWIDTH            : integer := 32;
        C_SIPIF_DWIDTH          : integer := 32;

        C_ARD_ADDR_RANGE_ARRAY  : SLV64_ARRAY_TYPE :=                              
                (                                                            
                 X"0000_0000_1000_0000", --  IP user0 base address       
                 X"0000_0000_1000_01FF", --  IP user0 high address       
                 X"0000_0000_1000_0200", --  IP user1 base address       
                 X"0000_0000_1000_02FF"  --  IP user1 high address       
                );                                                                    


        C_ARD_NUM_CE_ARRAY      : INTEGER_ARRAY_TYPE :=
                (
                 8,     -- User0 CE Number
                 1      -- User1 CE Number
                );
        C_SPLB_P2P              : integer := 0;
        C_FAMILY                : string  := "virtex4"
    );   
  port (
        Bus_clk             : in  std_logic;
        Bus_rst             : in  std_logic;

        -- PLB Interface signals
        Address_In          : in  std_logic_vector(0 to C_BUS_AWIDTH-1)     ;
        Address_In_Erly     : in  std_logic_vector(0 to C_BUS_AWIDTH-1)     ;
        Address_Valid       : in  std_logic                                 ;
        Address_Valid_Erly  : in  std_logic                                 ;
        Bus_RNW             : in  std_logic                                 ;

        -- Registering control signals
        cs_sample_hold_n    : in  std_logic                                 ;
        cs_sample_hold_clr  : in  std_logic                                 ;
        CS_CE_ld_enable     : in  std_logic                                 ;
        Clear_CS_CE_Reg     : in  std_logic                                 ;
        RW_CE_ld_enable     : in  std_logic                                 ;
        Clear_RW_CE_Reg     : in  std_logic                                 ;
        Clear_addr_match    : in  std_logic                                 ;
    
        -- Decode output signals
        Addr_Match_early    : out std_logic                                 ; 
        Addr_Match          : out std_logic                                 ; 
        RNW_S_H_Out         : out std_logic                                 ;
        CS_Out              : out std_logic_vector
                                (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
        RdCE_Out            : out std_logic_vector
                                (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1)    ;
        WrCE_Out            : out std_logic_vector
                                (0 to calc_num_ce(C_ARD_NUM_CE_ARRAY)-1)
    );
end entity plb_address_decoder;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture IMP of plb_address_decoder is

-- local type declarations ----------------------------------------------------
type decode_bit_array_type is Array(natural range 0 to (
                           (C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1) of 
                           integer;

type short_addr_array_type is Array(natural range 0 to 
                           C_ARD_ADDR_RANGE_ARRAY'LENGTH-1) of 
                           std_logic_vector(0 to C_BUS_AWIDTH-1);
-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- This function converts a 64 bit address range array to a AWIDTH bit 
-- address range array.
-------------------------------------------------------------------------------
function slv64_2_slv_awidth(slv64_addr_array   : SLV64_ARRAY_TYPE;
                            awidth             : integer) 
                        return short_addr_array_type is

    variable temp_addr   : std_logic_vector(0 to 63);
    variable slv_array   : short_addr_array_type;
    begin
        for array_index in 0 to slv64_addr_array'length-1 loop
            temp_addr := slv64_addr_array(array_index);
            slv_array(array_index) := temp_addr((64-awidth) to 63);
        end loop; 
        return(slv_array);
    end function slv64_2_slv_awidth;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function Addr_Bits (x,y : std_logic_vector(0 to C_BUS_AWIDTH-1)) 
                    return integer is
    variable addr_nor : std_logic_vector(0 to C_BUS_AWIDTH-1);
    begin
        addr_nor := x xor y;
        for i in 0 to C_BUS_AWIDTH-1 loop
            if addr_nor(i)='1' then 
                return i;
            end if;
        end loop;
--coverage off
        return(C_BUS_AWIDTH);
--coverage on
    end function Addr_Bits;

 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function Get_Addr_Bits (baseaddrs : short_addr_array_type) 
                        return decode_bit_array_type is
 
    variable num_bits : decode_bit_array_type;
    begin
        for i in 0 to ((baseaddrs'length)/2)-1 loop
   
            num_bits(i) :=  Addr_Bits (baseaddrs(i*2), 
                                       baseaddrs(i*2+1));
        end loop;
        return(num_bits);
    end function Get_Addr_Bits;
 
 
-------------------------------------------------------------------------------
-- NEEDED_ADDR_BITS
--
-- Function Description:
--  This function calculates the number of address bits required 
-- to support the CE generation logic. This is determined by 
-- multiplying the number of CEs for an address space by the 
-- data width of the address space (in bytes). Each address
-- space entry is processed and the biggest of the spaces is 
-- used to set the number of address bits required to be latched
-- and used for CE decoding. A minimum value of 1 is returned by
-- this function.
--
-------------------------------------------------------------------------------
function needed_addr_bits (ce_array   : INTEGER_ARRAY_TYPE;
                           dwidth     : integer ) 
                            return integer is

    constant NUM_CE_ENTRIES     : integer := CE_ARRAY'length;
    variable biggest            : integer := 2; 
    variable req_ce_addr_size   : integer := 0;
    variable num_addr_bits      : integer := 0;
    begin

        for i in 0 to NUM_CE_ENTRIES-1 loop
            req_ce_addr_size := ce_array(i) * (dwidth/8);                                  
            if (req_ce_addr_size > biggest) Then
                biggest := req_ce_addr_size;
            end if;
        end loop;
        num_addr_bits := log2(biggest);
        return(num_addr_bits);
    end function NEEDED_ADDR_BITS;



-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant ARD_ADDR_RANGE_ARRAY   : short_addr_array_type :=
                                    slv64_2_slv_awidth(C_ARD_ADDR_RANGE_ARRAY,
                                                       C_BUS_AWIDTH);

constant NUM_BASE_ADDRS         : integer := (C_ARD_ADDR_RANGE_ARRAY'length)/2;

constant DECODE_BITS            : decode_bit_array_type := 
                                    Get_Addr_Bits(ARD_ADDR_RANGE_ARRAY);

constant NUM_CE_SIGNALS         : integer := 
                                    calc_num_ce(C_ARD_NUM_CE_ARRAY);

--constant NUM_S_H_ADDR_BITS      : integer := 
--                                    needed_addr_bits(C_ARD_NUM_CE_ARRAY,);
Constant NUM_S_H_ADDR_BITS      : integer := needed_addr_bits(C_ARD_NUM_CE_ARRAY,
                                                         C_SIPIF_DWIDTH);


-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal pselect_hit_i    : std_logic_vector
                            (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
signal cs_out_i         : std_logic_vector
                            (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
signal ce_expnd_i       : std_logic_vector(0 to NUM_CE_SIGNALS-1);  
signal rdce_out_i       : std_logic_vector(0 to NUM_CE_SIGNALS-1);  
signal wrce_out_i       : std_logic_vector(0 to NUM_CE_SIGNALS-1);
Signal decode_hit       : std_logic_vector(0 to 0);
Signal decode_hit_reg   : std_logic;

Signal cs_s_h_clr       : std_logic;
Signal cs_ce_clr        : std_logic;
Signal rdce_clr         : std_logic;
Signal wrce_clr         : std_logic;
Signal addr_match_clr   : std_logic;
Signal rnw_s_h          : std_logic;
Signal addr_out_s_h     : std_logic_vector(0 to NUM_S_H_ADDR_BITS-1);

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin -- architecture IMP
  
   
-- Register clears
cs_s_h_clr      <= Bus_rst or cs_sample_hold_clr;
cs_ce_clr       <= Bus_rst or Clear_CS_CE_Reg;
rdce_clr        <= Bus_rst or Clear_RW_CE_Reg or not(rnw_s_h);
wrce_clr        <= Bus_rst or Clear_RW_CE_Reg or rnw_s_h;
addr_match_clr  <= Bus_rst or Clear_addr_match; 
  
-------------------------------------------------------------------------------
-- GEN_S_H_ADDR_REG
-- This ForGen implements the Sample and Hold 
-- register for the input PLB address. Only those LS address 
-- bits needed for CE generation are registered. 
-------------------------------------------------------------------------------
--GEN_S_H_ADDR_REG : for addr_bit_index in 0 to NUM_S_H_ADDR_BITS-1 generate
--
--    constant START_ADDR_INDEX : integer := C_BUS_AWIDTH - NUM_S_H_ADDR_BITS;
--    begin
--
--        I_ADDR_S_H_REG : FDRE
--            port map
--            (
--                Q  =>  addr_out_s_h(addr_bit_index),  
--                C  =>  Bus_clk,                
--                CE =>  cs_sample_hold_n,       
--                D  =>  Address_In(START_ADDR_INDEX+addr_bit_index),  
--                R  =>  cs_s_h_clr                 
--            );
--    end generate GEN_S_H_ADDR_REG;

-- Instantate sample and hold register for the PLB RNW 
I_RNW_S_H_REG : FDRE
    port map (
        Q  =>  rnw_s_h,  
        C  =>  Bus_clk,                
        CE =>  cs_sample_hold_n,       
        D  =>  Bus_RNW,  
        R  =>  cs_s_h_clr                 
    );

RNW_S_H_Out <= rnw_s_h;

GEN_RNW_FOR_SHARED : if C_SPLB_P2P = 0 generate


    S_H_ADDR_REG : process(Bus_clk)
        begin
            if(Bus_clk'EVENT and Bus_clk = '1')then
                if(Bus_rst='1' or cs_s_h_clr='1')then
                    addr_out_s_h <= (others => '0');
                elsif(cs_sample_hold_n='1')then
                    addr_out_s_h <= Address_In(C_BUS_AWIDTH-NUM_S_H_ADDR_BITS 
                                                to C_BUS_AWIDTH-1);
                end if;
            end if;
            end process S_H_ADDR_REG;

end generate GEN_RNW_FOR_SHARED;      
-- Modified to fix issue with AddressIn not valid clock prior to pavalid
-- in the point to point mode. 7/13/07
--GEN_RNW_FOR_P2P : if  C_SPLB_P2P = 1 generate
--    rnw_s_h <= '0';
--    addr_out_s_h <= Address_In(C_BUS_AWIDTH-NUM_S_H_ADDR_BITS 
--                                to C_BUS_AWIDTH-1);
--end generate GEN_RNW_FOR_P2P;      

GEN_RNW_FOR_P2P : if  C_SPLB_P2P = 1 generate
signal addr_out_hold : std_logic_vector(0 to NUM_S_H_ADDR_BITS-1);
begin
--    rnw_s_h <= '0';
    addr_out_s_h <= Address_In_Erly(C_BUS_AWIDTH-NUM_S_H_ADDR_BITS 
                                                to C_BUS_AWIDTH-1);
                                
end generate GEN_RNW_FOR_P2P;      

-------------------------------------------------------------------------------
-- Universal Address Decode Block
-------------------------------------------------------------------------------
MEM_DECODE_GEN: for bar_index in 0 to NUM_BASE_ADDRS-1 generate
begin  

    GEN_PLB_SHARED : if C_SPLB_P2P = 0 generate
    signal cs_out_s_h       : std_logic_vector
                                (0 to ((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1);
    begin
        -- Instantiate the basic Base Address Decoders
        MEM_SELECT_I: entity proc_common_v3_00_a.pselect_f
            generic map 
            (
                C_AB     => DECODE_BITS(bar_index),
                C_AW     => C_BUS_AWIDTH,
                C_BAR    => ARD_ADDR_RANGE_ARRAY(bar_index*2),
                C_FAMILY => C_FAMILY
            )
            port map 
            (
                A        => Address_In,                 -- [in]
                AValid   => Address_Valid,              -- [in]
                CS       => pselect_hit_i(bar_index)    -- [out]
            );        

        -- Instantate sample and hold registers for the Chip Selects
        I_CS_S_H_REG : FDRE
            port map
            (
                Q  =>  cs_out_s_h(bar_index),  
                C  =>  Bus_clk,                
                CE =>  cs_sample_hold_n,       
                D  =>  pselect_hit_i(bar_index),  
                R  =>  cs_s_h_clr                 
            );


        -- Instantate backend registers for the Chip Selects
        I_BKEND_CS_REG : FDRE
            port map
            (
                Q  =>  cs_out_i(bar_index),  
                C  =>  Bus_clk,              
                CE =>  CS_CE_ld_enable,      
                D  =>  cs_out_s_h(bar_index),
                R  =>  cs_ce_clr 
            );

        -----------------------------------------------------------------------   
        -- Now expand the individual chip enables for each base address
        -----------------------------------------------------------------------   
        DECODE_REGBITS: for ce_index in 0 to 
                                        C_ARD_NUM_CE_ARRAY(bar_index)-1 generate

        constant NEXT_CE_INDEX_START    : integer := 
                                            calc_start_ce_index(
                                            C_ARD_NUM_CE_ARRAY,bar_index);
        constant CE_DECODE_ADDR_SIZE    : integer range 0 to 
                                            NUM_S_H_ADDR_BITS :=
                                            log2(C_ARD_NUM_CE_ARRAY(bar_index));   
        begin

            -------------------------------------------------------------------
            -- There is only one CE required so just use the output of the 
            -- Sample and hold CS register as the CE.
            -------------------------------------------------------------------
            CE_IS_CS : if (CE_DECODE_ADDR_SIZE = 0) generate
            constant ARRAY_INDEX        : integer := ce_index;
            constant BASEADDR_INDEX     : integer := bar_index;
            begin

                ce_expnd_i(NEXT_CE_INDEX_START + ARRAY_INDEX) 
                                            <= cs_out_s_h(BASEADDR_INDEX);
            end generate CE_IS_CS;  

            -------------------------------------------------------------------
            -- Multiple CEs are required so expand and decode as needed by the 
            -- specified number of CEs and address bits.
            -------------------------------------------------------------------
            CE_EXPAND : if (CE_DECODE_ADDR_SIZE > 0) generate

            constant ARRAY_INDEX          : integer := ce_index;
            constant BASEADDR_INDEX       : integer := bar_index;

--            constant CE_DECODE_SKIP_BITS  : integer range 0 to NUM_S_H_ADDR_BITS 
--                                            := 2;
            constant CE_DECODE_SKIP_BITS  : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := log2(C_SIPIF_DWIDTH/8);

            constant CE_ADDR_WIDTH        : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := CE_DECODE_ADDR_SIZE 
                                             + CE_DECODE_SKIP_BITS;

            constant ADDR_START_INDEX     : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := NUM_S_H_ADDR_BITS
                                             - CE_ADDR_WIDTH;

            constant ADDR_END_INDEX       : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := NUM_S_H_ADDR_BITS
                                             - CE_DECODE_SKIP_BITS - 1;

            signal   compare_address      : std_logic_vector
                                            (0 to CE_DECODE_ADDR_SIZE-1);

            begin   
                INDIVIDUAL_CE_GEN : process (addr_out_s_h,cs_out_s_h(BASEADDR_INDEX), 
                                             compare_address)
                    begin
                        compare_address <= addr_out_s_h
                                            (ADDR_START_INDEX 
                                            to ADDR_END_INDEX);

                        if(compare_address = std_logic_vector(
                        to_unsigned(ARRAY_INDEX,CE_DECODE_ADDR_SIZE)))then
                            ce_expnd_i(NEXT_CE_INDEX_START
                                     + ARRAY_INDEX) <= cs_out_s_h(BASEADDR_INDEX);

                        else
                            ce_expnd_i(NEXT_CE_INDEX_START
                                     + ARRAY_INDEX) <= '0';
                        end if;
                    end process INDIVIDUAL_CE_GEN;  
            end generate CE_EXPAND;  
        end generate DECODE_REGBITS;


    end generate GEN_PLB_SHARED;


    GEN_PLB_P2P : if  C_SPLB_P2P = 1 generate

        GEN_FOR_MULTI_CS : if C_ARD_ADDR_RANGE_ARRAY'length > 2 generate
            -- Instantiate the basic Base Address Decoders
            MEM_SELECT_I: entity proc_common_v3_00_a.pselect_f
                generic map 
                (
                    C_AB     => DECODE_BITS(bar_index),
                    C_AW     => C_BUS_AWIDTH,
                    C_BAR    => ARD_ADDR_RANGE_ARRAY(bar_index*2),
                    C_FAMILY => C_FAMILY
                )
                port map 
                (
                    A        => Address_In_Erly,            -- [in]
                    AValid   => Address_Valid_Erly,         -- [in]
                    CS       => pselect_hit_i(bar_index)    -- [out]
                );        
        end generate GEN_FOR_MULTI_CS;
        
        GEN_FOR_ONE_CS : if C_ARD_ADDR_RANGE_ARRAY'length = 2 generate
            pselect_hit_i(bar_index) <= Address_Valid_Erly;
        end generate GEN_FOR_ONE_CS;


        -- Instantate backend registers for the Chip Selects
        I_BKEND_CS_REG : FDRE
            port map
            (
                Q  =>  cs_out_i(bar_index),  
                C  =>  Bus_clk,              
                CE =>  CS_CE_ld_enable,      
                D  =>  pselect_hit_i(bar_index),
                R  =>  cs_ce_clr 
            );
        
        -----------------------------------------------------------------------   
        -- Now expand the individual chip enables for each base address
        -----------------------------------------------------------------------   
        DECODE_REGBITS: for ce_index in 0 to 
                                        C_ARD_NUM_CE_ARRAY(bar_index)-1 generate

        constant NEXT_CE_INDEX_START    : integer := 
                                            calc_start_ce_index(
                                            C_ARD_NUM_CE_ARRAY,bar_index);
        constant CE_DECODE_ADDR_SIZE    : integer range 0 to 
                                            NUM_S_H_ADDR_BITS :=
                                            log2(C_ARD_NUM_CE_ARRAY(bar_index));   
        begin

            -------------------------------------------------------------------
            -- There is only one CE required so just use the output of the 
            -- Sample and hold CS register as the CE.
            -------------------------------------------------------------------
            CE_IS_CS : if (CE_DECODE_ADDR_SIZE = 0) generate
            constant ARRAY_INDEX        : integer := ce_index;
            constant BASEADDR_INDEX     : integer := bar_index;
            begin

                ce_expnd_i(NEXT_CE_INDEX_START + ARRAY_INDEX) 
                                            <= pselect_hit_i(BASEADDR_INDEX);
            end generate CE_IS_CS;  

            -------------------------------------------------------------------
            -- Multiple CEs are required so expand and decode as needed by the 
            -- specified number of CEs and address bits.
            -------------------------------------------------------------------
            CE_EXPAND : if (CE_DECODE_ADDR_SIZE > 0) generate

            constant ARRAY_INDEX          : integer := ce_index;
            constant BASEADDR_INDEX       : integer := bar_index;

--            constant CE_DECODE_SKIP_BITS  : integer range 0 to NUM_S_H_ADDR_BITS 
--                                            := 2;

            constant CE_DECODE_SKIP_BITS  : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := log2(C_SIPIF_DWIDTH/8);

            constant CE_ADDR_WIDTH        : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := CE_DECODE_ADDR_SIZE 
                                             + CE_DECODE_SKIP_BITS;

            constant ADDR_START_INDEX     : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := NUM_S_H_ADDR_BITS
                                             - CE_ADDR_WIDTH;

            constant ADDR_END_INDEX       : integer range 0 to NUM_S_H_ADDR_BITS 
                                            := NUM_S_H_ADDR_BITS
                                             - CE_DECODE_SKIP_BITS - 1;

            signal   compare_address      : std_logic_vector
                                            (0 to CE_DECODE_ADDR_SIZE-1);

            begin   
                INDIVIDUAL_CE_GEN : process (addr_out_s_h,
                                             pselect_hit_i(BASEADDR_INDEX),
                                             compare_address)
                    begin
                        compare_address <= addr_out_s_h
                                            (ADDR_START_INDEX to ADDR_END_INDEX);

                        if(compare_address = std_logic_vector(
                        to_unsigned(ARRAY_INDEX,CE_DECODE_ADDR_SIZE)))then
                            ce_expnd_i(NEXT_CE_INDEX_START
                                 + ARRAY_INDEX) <= pselect_hit_i(BASEADDR_INDEX);

                        else
                            ce_expnd_i(NEXT_CE_INDEX_START
                                 + ARRAY_INDEX) <= '0';
                        end if;
                    end process INDIVIDUAL_CE_GEN;  
            end generate CE_EXPAND;  
        end generate DECODE_REGBITS;


    end generate GEN_PLB_P2P;
    

    
end generate MEM_DECODE_GEN;    


I_OR_CS :  entity proc_common_v3_00_a.or_gate128
    generic map(
        C_OR_WIDTH   => NUM_BASE_ADDRS,
        C_BUS_WIDTH  => 1,
        C_USE_LUT_OR => TRUE
    )
    port map(
        A => pselect_hit_i,
        Y => decode_hit
    );

                       
                       
-- Instantate Address Match register
I_ADDR_MATCH_REG : FDRE
    port map(
        Q  =>  decode_hit_reg,          
        C  =>  Bus_clk,                       
        CE =>  '1',               
        D  =>  decode_hit(0),          
        R  =>  addr_match_clr
    );


GEN_CE_FOR_SHARED : if C_SPLB_P2P = 0 generate
    ---------------------------------------------------------------------------
    -- GEN_BKEND_CE_REGISTERS
    -- This ForGen implements the backend registering for
    -- the CE, RdCE, and WrCE output buses.
    ---------------------------------------------------------------------------
    GEN_BKEND_CE_REGISTERS : for ce_index in 0 to NUM_CE_SIGNALS-1 generate

        -- Instantate Backend RdCE register
        I_BKEND_RDCE_REG : FDRE
            port map (
                Q  =>  rdce_out_i(ce_index),          
                C  =>  Bus_clk,                       
                CE =>  RW_CE_ld_enable,               
                D  =>  ce_expnd_i(ce_index),          
                R  =>  rdce_clr
            );

        -- Instantate Backend WrCE register
        I_BKEND_WRCE_REG : FDRE
            port map(
                Q  =>  wrce_out_i(ce_index),          
                C  =>  Bus_clk,                       
                CE =>  RW_CE_ld_enable,               
                D  =>  ce_expnd_i(ce_index),          
                R  =>  wrce_clr
            );

    end generate GEN_BKEND_CE_REGISTERS;
end generate GEN_CE_FOR_SHARED;     


GEN_CE_FOR_P2P : if C_SPLB_P2P = 1 generate

    ---------------------------------------------------------------------------
    -- GEN_BKEND_CE_REGISTERS
    -- This ForGen implements the backend registering for
    -- the CE, RdCE, and WrCE output buses.
    ---------------------------------------------------------------------------
    GEN_BKEND_CE_REGISTERS : for ce_index in 0 to NUM_CE_SIGNALS-1 generate
    signal rdce_expnd_i : std_logic_vector(0 to NUM_CE_SIGNALS-1);  
    signal wrce_expnd_i : std_logic_vector(0 to NUM_CE_SIGNALS-1);  
    begin

        rdce_expnd_i(ce_index)    <= ce_expnd_i(ce_index) and Bus_RNW;
        -- Instantate Backend RdCE register
        I_BKEND_RDCE_REG : FDRE
            port map (
                Q  =>  rdce_out_i(ce_index),          
                C  =>  Bus_clk,                       
                CE =>  CS_CE_ld_enable,               
                D  =>  rdce_expnd_i(ce_index),          
                R  =>  cs_ce_clr
            );


        wrce_expnd_i(ce_index)    <= ce_expnd_i(ce_index) and not Bus_RNW;
        -- Instantate Backend WrCE register
        I_BKEND_WRCE_REG : FDRE
            port map(
                Q  =>  wrce_out_i(ce_index),          
                C  =>  Bus_clk,                       
                CE =>  CS_CE_ld_enable,               
                D  =>  wrce_expnd_i(ce_index),          
                R  =>  cs_ce_clr
            );

    end generate GEN_BKEND_CE_REGISTERS;

end generate GEN_CE_FOR_P2P;     
 
-- Assign registered output signals
Addr_Match   <= decode_hit_reg ;
CS_Out       <= cs_out_i   ;
RdCE_Out     <= rdce_out_i ;
WrCE_Out     <= wrce_out_i ;

-- Assign early timing output for Address Match.
-- This is unregistered so it occurs 1 clock early
-- but may induce large Fmax timing paths
Addr_Match_early   <= decode_hit(0) ;  
                       
-------------------------------------------------------------------------------
-- end of decoder block
-------------------------------------------------------------------------------
        
end architecture IMP;
