-------------------------------------------------------------------------------
-- chnl_logic.vhd - entity/architecture pair
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
-- Filename:        addr_be_gen.vhd
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
--  VPK         11/02/06        First Version
-- ^^^^^^
--  First version of mch_plbv46_slave_burst
--  Integrated this code in mch_plbv46_slave_burst
-- ~~~~~~
--  KSB         07/07/08        Updated
-- ^^^^^^
-- Updated to close CR#476144: -
-- 1. Updated to generated 32 bit aligned address for read operation to IPIF.
-- 2. In the generate block "BE_SNG_GEN" Chnl2IP_Addr address generation has 
--    been made 32 bit aligned address for Chnl_rnw = '1'.
-- 3. Added Dxcl2_byte_txr signal for DXCL2 write back support
--    
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
-- proc common library is used for different function declarations
-- MCH constants XCL and DAG are defined in ipif_pkg.
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.direct_path_cntr_ai;
use proc_common_v3_00_a.ipif_pkg.XCL;
use proc_common_v3_00_a.ipif_pkg.DAG;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
--      C_MCH_SPLB_DWIDTH       -- MCH channel data width
--      C_MCH_SPLB_AWIDTH       -- MCH channel address width
--      C_MCH_PROTOCOL          -- protocol of MCH channel (only XCL supported)  
--      C_XCL_LINESIZE          -- size of cacheline in 32-bit words 
--      C_XCL_WRITEXFER         -- types of write transfers allowed
--                                  -- 0 = no writes
--                                  -- 1 = single writes
--                                  -- 2 = cacheline writes
--
-- Definition of Ports:
--  
--  -- System signals
--      Sys_Clk                 -- System clock
--      Sys_Rst                 -- System reset
--
--  -- Channel Logic Signals    
--      Chnl_data               -- data from the access buffer for the channel  
--      Chnl_select             -- channel select
--      Chnl_addr_valid         -- address valid indicator
--      Chnl_data_valid         -- data valid indicator
--      Chnl_byte_wr            -- indicator of the write transfer size
--      Chnl_rnw                -- read or write transfer
--
--  -- IPIC Signals
--      Chnl2IP_Addr            -- address output to IP           
--      Chnl2IP_BE              -- BEs output to IP
--      IP2Chnl_AddrAck         -- address acknowledge from IP
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity addr_be_gen is
    generic (  
        C_MCH_SPLB_DWIDTH   : integer   := 32; 
        C_MCH_SPLB_AWIDTH   : integer   := 32;
        C_MCH_PROTOCOL      : integer   := 0;
        C_XCL_LINESIZE      : integer   := 4;
        C_XCL_WRITEXFER     : integer   := 1
        
        );
         
    port (
        Sys_Clk             : in  std_logic;
        Sys_Rst             : in  std_logic;

        -- Channel Logic Signals
        Chnl_data           : in  std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);
        Chnl_select         : in  std_logic;
        Chnl_addr_valid     : in  std_logic;
        Chnl_data_valid     : in  std_logic;
        Chnl_byte_wr        : in  std_logic;
        Chnl_rnw            : in  std_logic;
       
        -- IPIC Signals
        Chnl2IP_Addr        : out std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);     
        Chnl2IP_BE          : out std_logic_vector(0 to C_MCH_SPLB_DWIDTH/8-1);      
        Dxcl2_byte_txr	    : in  std_logic;
        IP2Chnl_AddrAck     : in  std_logic 
        );
  
end addr_be_gen;


-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of addr_be_gen is

-------------------------------------------------------------------------------
-- Function Declarations
-------------------------------------------------------------------------------
-- Function set_cntr_width sets the counter width to generic C_CNTR_WIDTH if
-- it is >= 3, otherwise, the counter width is set to 3. This is due to the 
-- fact that the counter must at least be of width 3 in order to count word 
-- addresses.
function set_cntr_width ( input_cntr_width  : integer)
                         return integer is
begin
    -- For cacheline size greater than 1 word (allows for only word address 
    -- increment)
    if input_cntr_width > 1 then
        return log2(input_cntr_width) + 2;
    else
        return 3;
    end if;
end function set_cntr_width;

-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------
constant ADDR_CNTR_WIDTH    : integer := set_cntr_width(C_XCL_LINESIZE);

-------------------------------------------------------------------------------
-- Signal and Type Declarations
------------------------------------------------------------------------------- 
signal chnl_st_addr         : std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);    
signal chnl_st_addr_reg     : std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1); 
signal chnl_st_addr_ld_n    : std_logic;
signal chnl_addr_valid_reg  : std_logic;
signal chnl_addr_i          : std_logic_vector(0 to C_MCH_SPLB_AWIDTH-1);    
signal chnl_be              : std_logic_vector(0 to 1);
signal chnl_addr_cnt_en     : std_logic;
signal chnl_addr_cnt        : std_logic_vector(0 to ADDR_CNTR_WIDTH-1);
signal xfer_size            : std_logic_vector(0 to ADDR_CNTR_WIDTH-1);

-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin
    
    -- Enable the address counter based on ip2chnl_addrack   
    chnl_addr_cnt_en <= IP2Chnl_AddrAck;    
    
    ---------------------------------------------------------------------------
    -- XCL_GEN Generate
    ---------------------------------------------------------------------------  
    -- Only generate Bus2IP_Addr counter when interface is XCL
    XCL_GEN: if C_MCH_PROTOCOL = 0 generate
    begin
      
        -- Bus2IP_Addr counter for cacheline transactions
        -- Max address range for counter is size of cacheline for MCH channel
        -- Load address from chnl_data when Chnl_addr_valid is asserted
        -- Use the direct path counter so a clock delay is not incurred when 
        -- the address
        -- is loaded. Increment counter for each word access.
        ADDR_CNTR_I: entity proc_common_v3_00_a.direct_path_cntr_ai
        generic map (
            C_WIDTH => ADDR_CNTR_WIDTH
            )
        port map (
            Clk     =>  Sys_Clk,
            Din     =>  chnl_st_addr_reg(C_MCH_SPLB_AWIDTH-ADDR_CNTR_WIDTH  
                                         to C_MCH_SPLB_AWIDTH-1),
            Dout    =>  chnl_addr_cnt,
            Load_n  =>  chnl_st_addr_ld_n,
            Cnt_en  =>  chnl_addr_cnt_en,
            Delta   =>  xfer_size
            );

        -- Generating chnl_addr from chnl_st_addr_reg
        chnl_addr_i <=  chnl_st_addr_reg(0 to C_MCH_SPLB_AWIDTH-
        						ADDR_CNTR_WIDTH-1)
                       & chnl_addr_cnt; 

        -----------------------------------------------------------------------
        -- XFER_SIZE_GEN Generate
        ----------------------------------------------------------------------- 
        -- All burst transfers are word operations.  
        XFER_SIZE_SNG_GEN: if (C_XCL_LINESIZE = 1) generate
            xfer_size(ADDR_CNTR_WIDTH-3 to ADDR_CNTR_WIDTH-1) <= "100";        
        end generate XFER_SIZE_SNG_GEN;
        
        -----------------------------------------------------------------------
        -- XFER_SIZE_16_GEN Generate
        ----------------------------------------------------------------------- 
        XFER_SIZE_LINE_GEN: if (C_XCL_LINESIZE > 1) generate
        begin
            xfer_size(0 to ADDR_CNTR_WIDTH-4) <= (others => '0');
            xfer_size(ADDR_CNTR_WIDTH-3 to ADDR_CNTR_WIDTH-1) <= "100";
        end generate XFER_SIZE_LINE_GEN;

        
        -----------------------------------------------------------------------
        -- REG_ST_ADDR : Generate chnl_st_addr_reg and chnl_addr_valid_reg
        -- based on Chnl_addr_valid
        ----------------------------------------------------------------------- 
        REG_ST_ADDR: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then        
        
                if (Sys_Rst = RESET_ACTIVE) then
                    chnl_st_addr_reg <= (others => '0');
                    chnl_addr_valid_reg <= '0';
                elsif (Chnl_addr_valid = '1') then
                    chnl_st_addr_reg <= Chnl_data;
                    chnl_addr_valid_reg <= '1';
                else
                    chnl_addr_valid_reg <= Chnl_addr_valid;
                end if;
            end if;
        end process REG_ST_ADDR;
    
        -- Create combinational starting address load signal
        chnl_st_addr_ld_n <= not (chnl_addr_valid_reg);
        
    end generate XCL_GEN;
    
 XCL2_WX0_GEN: if C_MCH_PROTOCOL = 1 and C_XCL_WRITEXFER = 0 generate
    begin
      
        -- Bus2IP_Addr counter for cacheline transactions
        -- Max address range for counter is size of cacheline for MCH channel
        -- Load address from chnl_data when Chnl_addr_valid is asserted
        -- Use the direct path counter so a clock delay is not incurred when 
        -- the address
        -- is loaded. Increment counter for each word access.
        ADDR_CNTR_I: entity proc_common_v3_00_a.direct_path_cntr_ai
        generic map (
            C_WIDTH => ADDR_CNTR_WIDTH
            )
        port map (
            Clk     =>  Sys_Clk,
            Din     =>  chnl_st_addr_reg(C_MCH_SPLB_AWIDTH-ADDR_CNTR_WIDTH  
                                         to C_MCH_SPLB_AWIDTH-1),
            Dout    =>  chnl_addr_cnt,
            Load_n  =>  chnl_st_addr_ld_n,
            Cnt_en  =>  chnl_addr_cnt_en,
            Delta   =>  xfer_size
            );

        -- Generating chnl_addr from chnl_st_addr_reg
        chnl_addr_i <= chnl_st_addr_reg(0 to C_MCH_SPLB_AWIDTH-
        						ADDR_CNTR_WIDTH-1)
                       & chnl_addr_cnt; 

        -----------------------------------------------------------------------
        -- XFER_SIZE_GEN Generate
        ----------------------------------------------------------------------- 
        -- All burst transfers are word operations.  
        XFER_SIZE_SNG_GEN: if (C_XCL_LINESIZE = 1) generate
            xfer_size(ADDR_CNTR_WIDTH-3 to ADDR_CNTR_WIDTH-1) <= "100";        
        end generate XFER_SIZE_SNG_GEN;
        
        -----------------------------------------------------------------------
        -- XFER_SIZE_16_GEN Generate
        ----------------------------------------------------------------------- 
        XFER_SIZE_LINE_GEN: if (C_XCL_LINESIZE > 1) generate
        begin
            xfer_size(0 to ADDR_CNTR_WIDTH-4) <= (others => '0');
            xfer_size(ADDR_CNTR_WIDTH-3 to ADDR_CNTR_WIDTH-1) <= "100";
        end generate XFER_SIZE_LINE_GEN;

        
        -----------------------------------------------------------------------
        -- REG_ST_ADDR : Generate chnl_st_addr_reg and chnl_addr_valid_reg
        -- based on Chnl_addr_valid
        ----------------------------------------------------------------------- 
        REG_ST_ADDR: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then        
        
                if (Sys_Rst = RESET_ACTIVE) then
                    chnl_st_addr_reg <= (others => '0');
                    chnl_addr_valid_reg <= '0';
                elsif (Chnl_addr_valid = '1') then
                    chnl_st_addr_reg <= Chnl_data;
                    chnl_addr_valid_reg <= '1';
                else
                    chnl_addr_valid_reg <= Chnl_addr_valid;
                end if;
            end if;
        end process REG_ST_ADDR;
    
        -- Create combinational starting address load signal
        chnl_st_addr_ld_n <= not (chnl_addr_valid_reg);
        
    end generate XCL2_WX0_GEN;    
    
    
    XCL2_GEN: if C_MCH_PROTOCOL = 1 and C_XCL_WRITEXFER = 2 generate
    begin
      
        -- Bus2IP_Addr counter for cacheline transactions
        -- Max address range for counter is size of cacheline for MCH channel
        -- Load address from chnl_data when Chnl_addr_valid is asserted
        -- Use the direct path counter so a clock delay is not incurred when 
        -- the address
        -- is loaded. Increment counter for each word access.
        ADDR_CNTR_I: entity proc_common_v3_00_a.direct_path_cntr_ai
        generic map (
            C_WIDTH => ADDR_CNTR_WIDTH
            )
        port map (
            Clk     =>  Sys_Clk,
            Din     =>  chnl_st_addr_reg(C_MCH_SPLB_AWIDTH-ADDR_CNTR_WIDTH
                                         to C_MCH_SPLB_AWIDTH-1),
            Dout    =>  chnl_addr_cnt,
            Load_n  =>  chnl_st_addr_ld_n,
            Cnt_en  =>  chnl_addr_cnt_en,
            Delta   =>  xfer_size
            );

        -- Generating chnl_addr from chnl_st_addr_reg
        
     
            chnl_addr_i <= chnl_st_addr_reg(0 to 
	        			C_MCH_SPLB_AWIDTH-ADDR_CNTR_WIDTH-1)
	                       		& chnl_addr_cnt  ;

        -----------------------------------------------------------------------
        -- XFER_SIZE_GEN Generate
        ----------------------------------------------------------------------- 
        -- All burst transfers are word operations.  
        XFER_SIZE_SNG_GEN: if (C_XCL_LINESIZE = 1) generate
            xfer_size(ADDR_CNTR_WIDTH-3 to ADDR_CNTR_WIDTH-1) <= "100";     
        end generate XFER_SIZE_SNG_GEN;
        
        -----------------------------------------------------------------------
        -- XFER_SIZE_16_GEN Generate
        ----------------------------------------------------------------------- 
        XFER_SIZE_LINE_GEN: if (C_XCL_LINESIZE > 1) generate
        begin
            xfer_size(0 to ADDR_CNTR_WIDTH-4) <= (others => '0');
            xfer_size(ADDR_CNTR_WIDTH-3 to ADDR_CNTR_WIDTH-1) <= "100";
        end generate XFER_SIZE_LINE_GEN;

        
        -----------------------------------------------------------------------
        -- REG_ST_ADDR : Generate chnl_st_addr_reg and chnl_addr_valid_reg
        -- based on Chnl_addr_valid
        ----------------------------------------------------------------------- 
        REG_ST_ADDR: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then        
        
                if (Sys_Rst = RESET_ACTIVE) then
                    chnl_st_addr_reg <= (others => '0');
                    chnl_addr_valid_reg <= '0';
                elsif (Chnl_addr_valid = '1' and Dxcl2_byte_txr = '0') then
                    chnl_st_addr_reg <= Chnl_data(0 
                    				to C_MCH_SPLB_AWIDTH-3) & "00";
                    chnl_addr_valid_reg <= '1';
                elsif (Chnl_addr_valid = '1' and Dxcl2_byte_txr = '1') then
                    chnl_st_addr_reg <= Chnl_data;
                    chnl_addr_valid_reg <= '1';                    
                else
                    chnl_addr_valid_reg <= Chnl_addr_valid;
                end if;
            end if;
        end process REG_ST_ADDR;
    
        -- Create combinational starting address load signal
        chnl_st_addr_ld_n <= not (chnl_addr_valid_reg);
        
    end generate XCL2_GEN;    
    
    ---------------------------------------------------------------------------
    -- XCL_BE_LINE_GEN Generate
    ---------------------------------------------------------------------------  
    -- Use generate to create Chnl2IP_BE based on generic settings
    -- If C_XCL_WRITEXFER = 0, write transactions are disabled.  Read
    -- transactions will always be word operations.
    -- If C_XCL_WRITEXFER = 2, read or write transactions will always be 
    -- word operations.  In this case, always set Chnl2IP_BE = "1111"
    XCL_BE_LINE_GEN: if C_MCH_PROTOCOL = 0 generate
      BE_LINE_GEN: if C_XCL_WRITEXFER = 0 or C_XCL_WRITEXFER = 2 generate

        Chnl2IP_BE <= (others => '1');
        Chnl2IP_Addr <= chnl_addr_i when Chnl_rnw = '0' else
                        chnl_addr_i (0 to C_MCH_SPLB_AWIDTH-3) &
                        	        "00" when Chnl_rnw = '1';
      end generate BE_LINE_GEN;
    end generate XCL_BE_LINE_GEN;
    
    
    XCL_WXR0_BE_LINE_GEN: if C_MCH_PROTOCOL = 1 generate
      BE_LINE_GEN: if C_XCL_WRITEXFER = 0 generate
    
        Chnl2IP_BE <= (others => '1');
        Chnl2IP_Addr <= chnl_addr_i when Chnl_rnw = '0' else
                        chnl_addr_i (0 to C_MCH_SPLB_AWIDTH-3) &
                            	        "00" when Chnl_rnw = '1';
      end generate BE_LINE_GEN;
    end generate XCL_WXR0_BE_LINE_GEN;

    ---------------------------------------------------------------------------
    -- XCL2_BE_LINE_GEN Generate
    ---------------------------------------------------------------------------  
    -- Use generate to create Chnl2IP_BE based on generic settings
    -- If C_XCL_WRITEXFER = 0, write transactions are disabled.  Read
    -- transactions will always be word operations.
    -- If C_XCL_WRITEXFER = 2, read or write transactions will always be 
    -- word operations.  In this case, always set Chnl2IP_BE = "1111"
    
    XCL2_BE_LINE_GEN: if C_MCH_PROTOCOL = 1 generate
      BE_LINE_GEN: if C_XCL_WRITEXFER = 2 generate
	signal byte_addr_sel        : std_logic;
        signal byte_addr_sel_reg    : std_logic;
      
      begin
    
        -- Create IPIC byte enables based on MCH address
        chnl_be      <= chnl_addr_i (C_MCH_SPLB_AWIDTH-2 to 
        						C_MCH_SPLB_AWIDTH-1);
        
        -- Added to support halfword addressing at ipic level to have
        -- addr alligned with byte enables
        byte_addr_sel <= '1' when Chnl_byte_wr = '1' else
                         byte_addr_sel_reg ;
                      
        Chnl2IP_Addr <= chnl_addr_i (0 to C_MCH_SPLB_AWIDTH-3) & "00" when 
        			(Dxcl2_byte_txr = '0' or Chnl_rnw = '1') else
        		chnl_addr_i when byte_addr_sel = '1' else
        		chnl_addr_i (0 to C_MCH_SPLB_AWIDTH-2) & '0';
        
        -----------------------------------------------------------------------
        -- REG_ADDR_SEL : Registering byte_addr_sel_reg 
        ----------------------------------------------------------------------- 
        REG_ADDR_SEL:process(Sys_Clk)
        begin
            if (Sys_Clk'event and Sys_Clk = '1') then
                if (Sys_Rst = RESET_ACTIVE or IP2Chnl_AddrAck = '1') then
                    byte_addr_sel_reg  <= '0';
                else
                    byte_addr_sel_reg   <= byte_addr_sel;
                end if;
            end if;
        end process REG_ADDR_SEL; 

        -----------------------------------------------------------------------
        -- REG_BE : Generate Chnl2IP_BE based on chnl_be, Chnl_rnw, 
        -- Chnl_data_valid and Chnl_byte_wr (decides byte or halfword/word)
        ----------------------------------------------------------------------- 

        REG_BE: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then

                if (Sys_Rst = RESET_ACTIVE) then
                    Chnl2IP_BE <= (others => '0');
                elsif (Chnl_rnw = '1' or Dxcl2_byte_txr = '0') then
                    Chnl2IP_BE <= (others => '1');
                elsif (Chnl_data_valid = '1') then
                    -- Byte write    
                    if (Chnl_rnw = '0') and (Chnl_byte_wr = '1') then
                        case chnl_be is                        
                            when "00"   =>  Chnl2IP_BE <= "1000";
                            when "01"   =>  Chnl2IP_BE <= "0100";
                            when "10"   =>  Chnl2IP_BE <= "0010";
                            when "11"   =>  Chnl2IP_BE <= "0001";
                            -- coverage off
                            when others =>  Chnl2IP_BE <= "0000";
                            -- coverage on

                        end case;                                         
                    -- Halfword or word write (Chnl_byte_wr = '0')
                    else 
                        case chnl_be is            
                            when "00"   =>  Chnl2IP_BE <= "1111";
                            when "01"   =>  Chnl2IP_BE <= "1100";  
                            when "11"   =>  Chnl2IP_BE <= "0011";
                            -- coverage off
                            when others =>  Chnl2IP_BE <= "0000";    
                            -- coverage on
                        end case;
                    end if;
                end if;
            end if;
        end process REG_BE;          		
        		
        		
      end generate BE_LINE_GEN;
    end generate XCL2_BE_LINE_GEN;    
    ---------------------------------------------------------------------------
    -- BE_SNG_GEN Generate
    ---------------------------------------------------------------------------  
    -- If C_XCL_WRITEXFER = 1, then single write transactions are supported.
    -- Need to generate Chnl2IP_BE based on request in Access Buffer 
    -- (for write operations).
    -- Read operations will always be word based cacheline transactions.
    BE_SNG_GEN: if C_XCL_WRITEXFER = 1 generate
    
    signal byte_addr_sel        : std_logic;
    signal byte_addr_sel_reg    : std_logic;
      
    begin
    
        -- Create IPIC byte enables based on MCH address
        chnl_be      <= chnl_addr_i (C_MCH_SPLB_AWIDTH-2 to 
        						C_MCH_SPLB_AWIDTH-1);
        
        -- Added to support halfword addressing at ipic level to have
        -- addr alligned with byte enables
        byte_addr_sel <= '1' when Chnl_byte_wr = '1' else
                         byte_addr_sel_reg ;
                      
        Chnl2IP_Addr <= chnl_addr_i when byte_addr_sel = '1' else
                        chnl_addr_i (0 to C_MCH_SPLB_AWIDTH-2) & '0' 
                        		when Chnl_rnw = '0' else
                        chnl_addr_i (0 to C_MCH_SPLB_AWIDTH-3) & "00" 
                        		when Chnl_rnw = '1';        
        
        -----------------------------------------------------------------------
        -- REG_ADDR_SEL : Registering byte_addr_sel_reg 
        ----------------------------------------------------------------------- 
        REG_ADDR_SEL:process(Sys_Clk)
        begin
            if (Sys_Clk'event and Sys_Clk = '1') then
                if (Sys_Rst = RESET_ACTIVE or IP2Chnl_AddrAck = '1') then
                    byte_addr_sel_reg  <= '0';
                else
                    byte_addr_sel_reg   <= byte_addr_sel;
                end if;
            end if;
        end process REG_ADDR_SEL; 

        -----------------------------------------------------------------------
        -- REG_BE : Generate Chnl2IP_BE based on chnl_be, Chnl_rnw, 
        -- Chnl_data_valid and Chnl_byte_wr (decides byte or halfword/word)
        ----------------------------------------------------------------------- 
        REG_BE: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then

                if (Sys_Rst = RESET_ACTIVE) then
                    Chnl2IP_BE <= (others => '0');
                elsif (Chnl_rnw = '1') then
                    Chnl2IP_BE <= (others => '1');
                elsif (Chnl_data_valid = '1') then
                    -- Byte write    
                    if (Chnl_rnw = '0') and (Chnl_byte_wr = '1') then
                        case chnl_be is                        
                            when "00"   =>  Chnl2IP_BE <= "1000";
                            when "01"   =>  Chnl2IP_BE <= "0100";
                            when "10"   =>  Chnl2IP_BE <= "0010";
                            when "11"   =>  Chnl2IP_BE <= "0001";
                            -- coverage off
                            when others =>  Chnl2IP_BE <= "0000";
                            -- coverage on

                        end case;                                         
                    -- Halfword or word write (Chnl_byte_wr = '0')
                    else 
                        case chnl_be is            
                            when "00"   =>  Chnl2IP_BE <= "1111";
                            when "01"   =>  Chnl2IP_BE <= "1100";
                            when "11"   =>  Chnl2IP_BE <= "0011";
                            -- coverage off
                            when others =>  Chnl2IP_BE <= "0000";
                            -- coverage on
                        end case;
                    end if;
                end if;
            end if;
        end process REG_BE;  
   
    end generate BE_SNG_GEN;

end imp;

