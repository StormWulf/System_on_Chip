-------------------------------------------------------------------------------
-- ipic_logic.vhd - entity/architecture pair
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
-- Filename:        ipic_logic.vhd
-- Version:         v2.01a
-- Description:     This file contains the logic for interfacing to each
--                  channel in the defined MCH interface.  The MCH interface
--                  logic generates the buffers (FIFOs), channel control logic,
--                  and IPIC interface for each channel.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--                  -- mch_plbv46_slave_burst.vhd                  
--                      -- mch_interface.vhd
--                          -- access_buffer.vhd
--                          -- readdata_buffer.vhd
--                          -- chnl_logic.vhd
--                          -- addr_be_gen.vhd
--                          -- ipic_logic.vhd
--                      -- arb_mux_demux.vhd
--                          -- addr_data_mux_demux.vhd
--                          -- arbitration_logic.vhd
--                      -- plbv46_slave_burst.vhd
--                      
-------------------------------------------------------------------------------
-- Author:      VPK
-- History:
--  VPK         11/02/06        v1.00a
-- ^^^^^^
--  First version of mch_plbv46_slave_burst
--  Integrated this code in mch_plbv46_slave_burst
--
--  KSB         12/22/08        v2.00a
-- ^^^^^^
-- Added dxcl2_single logic for write back support for DXCL2.
-- ~~~~~~
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
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- The proc_common library is required to instantiate pselect_f component
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.pselect_f;
use proc_common_v3_00_a.ipif_pkg.SLV64_ARRAY_TYPE;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
--  C_MCH_SPLB_DWIDTH               -- MCH interface data width            
--  C_MCH_SPLB_AWIDTH               -- MCH interface address width
--  C_MCH_USERIP_ADDRRANGE_ARRAY    -- address ranges recognized by MCH channels
--                                  -- used to decode chip selects (Bus2IP_CS)
--                              
--  C_XCL_WRITEXFER                 -- types of write transfers allowed
--                                      -- 0 = no writes
--                                      -- 1 = single writes
--                                      -- 2 = cacheline writes
--  C_BRSTCNT_WIDTH                 -- Burst count width
--  C_FAMILY                        -- FPGA Family used
--  C_MCH_PROTOCOL		    -- XCL Transfer Type	
--                                      -- 0 = XCL
--                                      -- 1 = XCL2
-- Definition of Ports:
--
--  -- System signals
--      Sys_Clk                     -- System clock
--      Sys_Rst                     -- System reset
--
--  -- Channel Logic Signals
--      Chnl_data                   -- Data from the channel               
--      Chnl_select                 -- Select from the channel
--      Chnl_data_valid             -- Data valid from the channel
--      Chnl_start_data_valid   
--      Chnl_rnw                    -- RNW from the channel
--      Chnl_rdce                   -- RdCE from the channel
--      Chnl_wrce                   -- WrCE from the channel
--      Chnl_rdreq                  -- RdReq from the channel
--      Chnl_wrreq                  -- WrReq from the channel
--      Chnl_burst                  -- Burst from the channel
--      Chnl_BurstLength            -- Channel burst length 
--      Chnl_addr                   -- Address from the channel
--      IPIC_addr_valid             -- Address valid
--
--      -- IPIC Signals             -- IPIC signals output from the channels
--                                     to the IP
--      Chnl2IP_Addrvalid
--      Chnl2IP_Data     
--      Chnl2IP_RNW      
--      Chnl2IP_CS       
--      Chnl2IP_Burst
--      Chnl2IP_BurstLength
--      Chnl2IP_RdReq    
--      Chnl2IP_WrReq    
--      Chnl2IP_CE       
--      Chnl2IP_Rdce     
--      Chnl2IP_Wrce     
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity ipic_logic is
    generic (  
    
        C_MCH_SPLB_DWIDTH               : integer   := 32; 
        C_MCH_SPLB_AWIDTH               : integer   := 32;
        C_MCH_USERIP_ADDRRANGE_ARRAY    : SLV64_ARRAY_TYPE 
                                           := ( x"0000_0000_0000_0000",
                                                x"0000_0000_0000_8FFF");        
        C_XCL_WRITEXFER                 : integer   := 1;
        C_MCH_PROTOCOL      		: integer   := 0;
        C_BRSTCNT_WIDTH                 : integer   := 6;
        C_FAMILY                        : string    := "nofamily"
        );
         
    port (
        -- System signals       
        Sys_Clk               : in  std_logic;
        Sys_Rst               : in  std_logic;

        -- Channel Logic Signals
        Chnl_data             : in  std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);
        Chnl_select           : in  std_logic;
        Chnl_data_valid       : in  std_logic;
        Chnl_start_data_valid : in  std_logic;
        Chnl_rnw              : in  std_logic;
        Chnl_rdce             : in  std_logic;
        Chnl_wrce             : in  std_logic;
        Chnl_rdreq            : in  std_logic;
        Chnl_wrreq            : in  std_logic;
        Chnl_burst            : in  std_logic;
        Chnl_BurstLength      : in  std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
        Chnl_addr             : in  std_logic_vector (0 to C_MCH_SPLB_AWIDTH-1);
        IPIC_addr_valid       : in  std_logic;
        
        --DXCL2 Signal
        Dxcl2_byte_txr	      : in  std_logic;

        -- IPIC Signals
        Chnl2IP_Addrvalid     : out std_logic; 
        Chnl2IP_Data          : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);     
        Chnl2IP_RNW           : out std_logic; 
        Chnl2IP_CS            : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);  
        Chnl2IP_Burst         : out std_logic;  
        Chnl2IP_BurstLength   : out std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
        Chnl2IP_RdReq         : out std_logic;
        Chnl2IP_WrReq         : out std_logic;       
        Chnl2IP_CE            : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);      
        Chnl2IP_Rdce          : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);   
        Chnl2IP_Wrce          : out std_logic_vector(0 to 
                                    (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1)
        );
  
end ipic_logic;


-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of ipic_logic is

-------------------------------------------------------------------------------
-- Function num_common_high_order_addr_bits
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- This function returns the number of high-order address bits
-- that can be commonly decoded across all address pairs passed in as
-- the argument ara. Note: only the C_MCH_SPLB_AWIDTH rightmost bits of an 
-- entry in ara are considered to make up the address.
-------------------------------------------------------------------------------
function num_common_high_order_addr_bits(ara: SLV64_ARRAY_TYPE)
                                    return integer is
variable n : integer := C_MCH_SPLB_AWIDTH;
-- Maximum number of common high-order bits for
-- the ranges starting at an index less than i.
variable i, j: integer;
variable old_base: std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1)
                 := ara(0)(   ara(0)'length-C_MCH_SPLB_AWIDTH
                           to ara(0)'length-1 );
variable new_base, new_high: std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);
begin
  i := 0;
  while i < ara'length loop
      new_base := ara(i  )(ara(0)'length-C_MCH_SPLB_AWIDTH to ara(0)'length-1);
      new_high := ara(i+1)(ara(0)'length-C_MCH_SPLB_AWIDTH to ara(0)'length-1);
      j := 0;
      while  j < n                             -- Limited by earlier value. 
         and new_base(j) = old_base(j)         -- High-order addr diff found
                                               -- with a previous range.
         and (new_base(j) xor new_high(j))='0' -- Addr-range boundary found
                                               -- for current range.
      loop
          j := j+1;
      end loop;
      n := j;
      i := i+2;
  end loop;
  return n;
end num_common_high_order_addr_bits;

-------------------------------------------------------------------------------
-- Function num_decode_bits
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- This function returns the number of address bits that need to be
-- decoded to find a "hit" in the address range defined by
-- the idx'th pair of base_address/high_address in c_ard_addr_range_array.
-- Only the rightmost numbits are considered and the result is the
-- number of leftmost bits within this field that need to be decoded.
-------------------------------------------------------------------------------
function num_decode_bits(ard_addr_range_array : SLV64_ARRAY_TYPE;
                         numbits              : natural;
                         idx                  : natural)
return integer is
  constant SZ : natural := ard_addr_range_array(0)'length;
  constant ADDR_XOR : std_logic_vector(0 to numbits-1)
      :=     ard_addr_range_array(2*idx  )(SZ-numbits to SZ-1)  -- base
         xor ard_addr_range_array(2*idx+1)(SZ-numbits to SZ-1); -- high
begin
  for i in 0 to numbits-1 loop
    if ADDR_XOR(i)='1' then return i;
    end if;
  end loop;
  return(numbits);
end function num_decode_bits;

-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------
constant DEV_ADDR_DECODE_WIDTH  : integer := num_common_high_order_addr_bits
                                              (C_MCH_USERIP_ADDRRANGE_ARRAY);

-------------------------------------------------------------------------------
-- Signal and Type Declarations
------------------------------------------------------------------------------- 
signal chnl_cs : std_logic_vector(0 to (C_MCH_USERIP_ADDRRANGE_ARRAY'length)/2-1);

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin

    Chnl2IP_RNW         <= Chnl_rnw;
    Chnl2IP_Addrvalid   <= IPIC_addr_valid;
    Chnl2IP_WrReq       <= Chnl_wrreq;
    Chnl2IP_RdReq       <= Chnl_rdreq;
    Chnl2IP_Burst       <= Chnl_burst;  
    Chnl2IP_BurstLength <= Chnl_BurstLength;
    
    ---------------------------------------------------------------------------
    -- CS_GEN Generate
    ---------------------------------------------------------------------------  
    -- Use generate to create CS bus 
    -- Chnl2IP_CS(0) => MEM Bank 0
    -- Chnl2IP_CS(1) => MEM Bank 1 ...
    ---------------------------------------------------------------------------  
    CS_GEN: for i in 0 to (C_MCH_USERIP_ADDRRANGE_ARRAY'length/2)-1 generate
    begin

        -- Generate CS from Chnl_addr
        -- Use pselect from proc_common_v3_00_a library
        CS_SEL: entity proc_common_v3_00_a.pselect_f 
        generic map (
            C_AB     => num_decode_bits(C_MCH_USERIP_ADDRRANGE_ARRAY, 
                                        C_MCH_SPLB_AWIDTH, i),
            C_AW     => C_MCH_SPLB_AWIDTH,
            C_BAR    => C_MCH_USERIP_ADDRRANGE_ARRAY(i*2) 
                        (C_MCH_USERIP_ADDRRANGE_ARRAY(i*2)'length - 
                         C_MCH_SPLB_AWIDTH to 
                         C_MCH_USERIP_ADDRRANGE_ARRAY(i*2)'length-1),
            C_FAMILY => "nofamily"
            )
        port map (
            A        => Chnl_addr,
            AValid   => Chnl_select,
            CS       => chnl_cs(i)
            );    
            
        Chnl2IP_CS(i)   <= chnl_cs(i);
        Chnl2IP_CE(i)   <= Chnl_select  when (chnl_cs(i) = '1') else '0';
        Chnl2IP_Wrce(i) <= Chnl_wrce    when (chnl_cs(i) = '1') else '0'; 
        Chnl2IP_Rdce(i) <= Chnl_rdce    when (chnl_cs(i) = '1') else '0'; 
    
    end generate CS_GEN;
    
    ---------------------------------------------------------------------------
    -- NO_DATA_GEN Generate
    ---------------------------------------------------------------------------  
    -- Optimize Chnl2IP_Data when no write transfers are supported
    NO_DATA_GEN: if (C_XCL_WRITEXFER = 0) generate
        Chnl2IP_Data <= (others => '0');    
    end generate NO_DATA_GEN;      

    ---------------------------------------------------------------------------
    -- SNG_DATA_GEN Generate
    ---------------------------------------------------------------------------  
    -- Use generate to align Chnl2IP_Data with Chnl2IP_BE.  Use Chnl_data_valid
    -- as CE to register data. This type of operation is only supported when 
    -- C_XCL_WRITEXFER = 1 (single write transactions)
    SNG_DATA_GEN: if (C_XCL_WRITEXFER = 1) generate
    begin
    
        -----------------------------------------------------------------------
        -- Chnl2IP_Data Registered Process
        -----------------------------------------------------------------------  
        REG_DATA: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then

                if (Sys_Rst = RESET_ACTIVE) then
                    Chnl2IP_Data <= (others => '0');
                elsif (Chnl_data_valid = '1') then
                    Chnl2IP_Data <= Chnl_data;
                end if;
            end if;
        end process REG_DATA;    

    end generate SNG_DATA_GEN;
 
    ---------------------------------------------------------------------------
    -- XCL_LINE_DATA_GEN Generate
    ---------------------------------------------------------------------------  
    XCL_LINE_DATA_GEN: if (C_MCH_PROTOCOL = 0) generate        
      LINE_DATA_GEN: if (C_XCL_WRITEXFER = 2) generate    
      signal chnl_data_reg : std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);    
      begin
    
        -- Create combination signal for data bus
        -- Data must align with early WrReq 
        -- No need to wait for BE generation
        Chnl2IP_Data <= Chnl_data when (Chnl_start_data_valid = '1') else 
                        chnl_data_reg;
        
        -----------------------------------------------------------------------
        -- Chnl_data Registered Process
        -----------------------------------------------------------------------  
        REG_DATA: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then
        
                if (Sys_Rst = RESET_ACTIVE) then
                    chnl_data_reg <= (others => '0');
        
                elsif (Chnl_data_valid = '1') then
                    chnl_data_reg <= Chnl_data;
        
                end if;
            end if;
        end process REG_DATA;            
      end generate LINE_DATA_GEN;
      
    end generate XCL_LINE_DATA_GEN;      

    ---------------------------------------------------------------------------
    -- XCL_LINE_DATA_GEN Generate
    ---------------------------------------------------------------------------  
    XCL2_LINE_DATA_GEN: if (C_MCH_PROTOCOL = 1) generate        
      LINE_DATA_GEN: if (C_XCL_WRITEXFER = 2) generate    
      signal chnl_data_reg : std_logic_vector(0 to C_MCH_SPLB_DWIDTH-1);    
      begin
    
        -- Create combination signal for data bus
        -- Data must align with early WrReq 
        -- No need to wait for BE generation
        Chnl2IP_Data <= Chnl_data when (Chnl_start_data_valid = '1' 
        					and Dxcl2_byte_txr = '0') else
                        chnl_data_reg;
        
        -----------------------------------------------------------------------
        -- Chnl_data Registered Process
        -----------------------------------------------------------------------  
        REG_DATA: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then
        
                if (Sys_Rst = RESET_ACTIVE) then
                    chnl_data_reg <= (others => '0');
        
                elsif (Chnl_data_valid = '1') then
                    chnl_data_reg <= Chnl_data;
        
                end if;
            end if;
        end process REG_DATA;            
      end generate LINE_DATA_GEN;
      
    end generate XCL2_LINE_DATA_GEN;    
    
end imp;

