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
-- Filename:        chnl_logic.vhd
-- Version:         v2.00a
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
-- Author:      PVK
-- History:
--  PVK         11/02/06        v1.00a
-- ^^^^^^
--  First version of mch_plbv46_slave_burst
--  Integrated this code in mch_plbv46_slave_burst
--  VPK         10/07/06        v1.00a
-- ^^^^^^
--  ADDRACK_CNT_I counter incrementing logic is changed. When IP2Chnl_AddrAck
--  and IP2Chnl_Ack comes at a same time then counter load and increment
--  signal will go active at same time. This in turn will not load the
--  counter with expected value.
-- ~~~~~
--  KSB         12/22/08        v2.00a
-- ^^^^^^
-- Added dxcl2_single logic for write back support for DXCL2.
-- ~~~~~

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
-- The proc_common library is required to instantiate ld_arith_reg component
-- MCH constants XCL and DAG are defined in ipif_pkg
-------------------------------------------------------------------------------
library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ld_arith_reg;
use proc_common_v3_00_a.ipif_pkg.XCL;
use proc_common_v3_00_a.ipif_pkg.DAG;

-------------------------------------------------------------------------------
-- Definition of Generics:
--      C_MCH_SPLB_DWIDTH    -- MCH channel data width
--      C_MCH_SPLB_AWIDTH    -- MCH channel address width 
--      C_MCH_PROTOCOL       -- MCH channel protocol (only XCL is supported)
--      C_XCL_LINESIZE       -- size of cacheline in 32-bit words 
--      C_XCL_WRITEXFER      -- types of write transfers allowed
--                               -- 0 = no writes
--                               -- 1 = single writes
--                               -- 2 = cacheline writes
--  C_BRSTCNT_WIDTH          -- burst count width  
--
-- Definition of Ports:
--
--  -- System signals
--      Sys_Clk                 -- System clock
--      Sys_Rst                 -- System reset
--
--  -- Access Buffer Signals
--     Access_Ctrl              -- Control indicated R/W transfer
--     Access_Exists            -- Data exists in FIFO
--     Access_Read              -- Read data from Access buffer
--
--  -- ReadData Buffer Signals
--     ReadData_Ctrl            -- Control bit indicating if data is valid
--     ReadData_Write           -- Control signal to write data to ReadData
--                                  buffer
--     ReadData_Full            -- Signal indicating if ReadData buffer is full
--
--  -- Addr/BE Signals
--     Chnl_addr_valid          -- Address valid indicator
--     Chnl_byte_wr             -- Indicator of the write transfer size

--  -- IPIC Interface Signals
--     Chnl_select               -- IPIC select signal from the channel
--     Chnl_data_valid           -- Data valid indicator
--     Chnl_start_data_valid     -- indicates start of valid data
--     Chnl_rnw                  -- IPIC RNW signal from the channel
--     Chnl_rdce                 -- IPIC RdCE signal from the channel
--     Chnl_wrce                 -- IPIC WrCE signal from the channel
--     Chnl_rdreq                -- IPIC RdReq signal from the channel
--     Chnl_wrreq                -- IPIC WrReq signal from the channel
--     Chnl_burst                -- IPIC Burst signal from the channel
--     Chnl_BurstLength          -- IPIC Burst count length
--     IPIC_addr_valid           -- IPIC Address Valid signal from the channel
--
--     IP2Chnl_AddrAck           -- Address acknowledge from the IP
--     IP2Chnl_Ack               -- Data acknowledge from the IP
--
--  -- Channel Logic Signals
--     Chnl_Req                  -- Indicates channel with active transaction
--     Chnl_Data_Almost_Done     -- Indicates channel data transaction almost
--                                  complete                            
--     Chnl_Addr_Almost_Done     -- Indicates channel address transaction 
--                                  almost complete 
--     Address_Master            -- Current master of the address phase
--     Data_Master               -- Current master of the data phase
--     Timeout_error             -- Signal from Timeout/Error Logic
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------
entity chnl_logic is
    generic (  
        C_MCH_SPLB_DWIDTH       : integer   := 32; 
        C_MCH_SPLB_AWIDTH       : integer   := 32;
        C_MCH_PROTOCOL          : integer   := 0;                                           
        C_XCL_LINESIZE          : integer   := 4;
        C_XCL_WRITEXFER         : integer   := 1;
        C_BRSTCNT_WIDTH         : integer   := 4 
        );
         
    port (
        -- System Signals
        Sys_Clk                 : in  std_logic;
        Sys_Rst                 : in  std_logic;

        -- Access Buffer Signals
        Access_Ctrl             : in  std_logic;
        Access_Exists           : in  std_logic;
        Access_Read             : out std_logic;
        Access_data             : in  std_logic_vector(0 to 
        						C_MCH_SPLB_DWIDTH-1);
        
        -- ReadData Buffer Signals
        ReadData_Ctrl           : out std_logic;
        ReadData_Write          : out std_logic;
        ReadData_Full           : in  std_logic;
                
        -- Addr/BE Generation Signals
        Chnl_addr_valid         : out std_logic;
        Chnl_byte_wr            : out std_logic;
        
        --DXCL2_Signals
        Dxcl2_byte_txr		: out std_logic;
        
        -- IPIC Logic Interface Signals
        Chnl_select             : out std_logic;
        Chnl_data_valid         : out std_logic;
        Chnl_start_data_valid   : out std_logic;
        Chnl_rnw                : out std_logic;
        Chnl_rdce               : out std_logic;
        Chnl_wrce               : out std_logic;
        Chnl_rdreq              : out std_logic;
        Chnl_wrreq              : out std_logic;
        Chnl_burst              : out std_logic;
        Chnl_BurstLength        : out std_logic_vector(0 to C_BRSTCNT_WIDTH-1);
        
        IPIC_addr_valid         : out std_logic;
        IP2Chnl_AddrAck         : in  std_logic; 
        IP2Chnl_Ack             : in  std_logic; 
        
        -- Channel Logic Signals
        Chnl_Req                : out std_logic;
        Chnl_Data_Almost_Done   : out std_logic;
        Chnl_Addr_Almost_Done   : out std_logic;
        Addr_Master             : in  std_logic;
        Data_Master             : in  std_logic
        );
  
end chnl_logic;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------
architecture imp of chnl_logic is

-------------------------------------------------------------------------------
--  Function Declarations
-------------------------------------------------------------------------------
function get_cnt_size ( C_XCL_LINESIZE : integer ) return integer is
begin
    if (C_XCL_LINESIZE = 1) then
        return 1;
    else
        return log2(C_XCL_LINESIZE);
    end if;
end get_cnt_size;

-------------------------------------------------------------------------------
--  Constant Declarations
-------------------------------------------------------------------------------
constant CHNL_BUF_CNT_SIZE       : integer := get_cnt_size (C_XCL_LINESIZE);
constant CHNL_BUF_CNT_RST        : std_logic_vector (0 to CHNL_BUF_CNT_SIZE-1) 
                                    := (others => '0');
constant CHNL_BUF_CNT_MAX        : std_logic_vector (0 to CHNL_BUF_CNT_SIZE-1)  
                                    := conv_std_logic_vector(C_XCL_LINESIZE-1, 
                                                           CHNL_BUF_CNT_SIZE);
                                                           
constant CHNL_BUF_CNT_ALMST_MAX  : std_logic_vector (0 to CHNL_BUF_CNT_SIZE-1) 
                                    := conv_std_logic_vector(C_XCL_LINESIZE-2, 
                                                           CHNL_BUF_CNT_SIZE);

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------
type CHNL_STATE_TYPE is (IDLE, RD_OP_ADDR, WR_OP_ADDR,WR_OP_DXCL2_ADDR,RD_DATA,
			WAIT_ACK, WAIT_LAST_ACK);

signal chnlsm_ns : CHNL_STATE_TYPE;
signal chnlsm_cs : CHNL_STATE_TYPE;

signal chnl_buf_cnt         : std_logic_vector (0 to CHNL_BUF_CNT_SIZE-1);
signal chnl_buf_ld          : std_logic;
signal chnl_buf_cnt_en      : std_logic;

signal ack_cnt              : std_logic_vector (0 to CHNL_BUF_CNT_SIZE-1);
signal ack_cnt_en           : std_logic;
signal addrack_cnt          : std_logic_vector (0 to CHNL_BUF_CNT_SIZE-1);

signal Access_data_reg      : std_logic_vector (0 to 1); 

signal chnl_addr_valid_i    : std_logic;
signal chnl_data_valid_i    : std_logic;
signal chnl_rdce_i          : std_logic;
signal chnl_wrce_i          : std_logic;

signal ipic_addr_valid_com  : std_logic;
signal ipic_addr_valid_reg  : std_logic;

signal chnl_wrreq_com       : std_logic; 
signal chnl_wrreq_reg       : std_logic;

signal chnl_rdreq_com       : std_logic;
signal chnl_rdreq_reg       : std_logic;

signal chnl_select_com      : std_logic;
signal chnl_select_reg      : std_logic;

signal chnl_rnw_com         : std_logic;
signal chnl_rnw_reg         : std_logic;

signal chnl_burst_com       : std_logic;
signal chnl_burst_reg       : std_logic;

signal rd_access_buffer     : std_logic;
signal wr_readdata_buffer   : std_logic;
signal wr_readdata_error    : std_logic;

signal chnl_req_reg         : std_logic;
signal chnl_req_com         : std_logic;
signal addrack_cnt_en       : std_logic;
signal dxcl2_single         : std_logic;
signal dxcl2_single_d1      : std_logic;
signal dxcl2_single_d2      : std_logic;
signal dxcl2_single_d1_reg  : std_logic;

-- This signal needs to be the same width as the burst lenght signals from the
-- PLB
signal chnl_burstlength_i   : std_logic_vector(0 to C_BRSTCNT_WIDTH-1) 
                               := (others => '0');
                               
signal Access_Ctrl_d :std_logic;                               
signal byte_wr :std_logic;                               
-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------
begin
       
    ---------------------------------------------------------------------------
    -- MCH Access Buffer Channel Logic
    ---------------------------------------------------------------------------       
    Access_Read      <= rd_access_buffer;    
    Chnl_select      <= chnl_select_reg;
    Chnl_addr_valid  <= chnl_addr_valid_i;
    Chnl_data_valid  <= chnl_data_valid_i;
    Chnl_rnw         <= chnl_rnw_reg;
    Chnl_rdce        <= chnl_rdce_i;
    Chnl_wrce        <= chnl_wrce_i;    
    Chnl_rdreq       <= chnl_rdreq_reg;
    Chnl_wrreq       <= chnl_wrreq_reg; 
    Chnl_burst       <= chnl_burst_reg;
    IPIC_addr_valid  <= ipic_addr_valid_reg;    
    Chnl_BurstLength <= chnl_burstlength_i; 
    
    ---------------------------------------------------------------------------
    -- SNG_BYTE_GEN Generate
    ---------------------------------------------------------------------------          
    -- Capture Access_Ctrl during Data read from Access Buffer to determine
    -- byte or halfword/word operation ('1' = byte write, '0' = halfword or 
    -- word write)
    -- Use generate to optimize chnl_byte_wr signal.  Byte write operations 
    -- only supported when C_XCL_WRITEXFER = 1.

    XCL_BYTE_GEN: if C_MCH_PROTOCOL = 0 generate
    	SNG_BYTE_GEN: if C_XCL_WRITEXFER = 1 generate
    	   Chnl_byte_wr <= Access_Ctrl when (chnl_data_valid_i = '1') else '0';
    	end generate SNG_BYTE_GEN;
	-----------------------------------------------------------------------
	    -- LINE_BYTE_GEN Generate
    	-----------------------------------------------------------------------          
    	LINE_BYTE_GEN: if C_XCL_WRITEXFER = 0 or C_XCL_WRITEXFER = 2 generate
    	    Chnl_byte_wr <= '0';
    	end generate LINE_BYTE_GEN;    	
	Dxcl2_byte_txr   <= '0';
	dxcl2_single     <= '0';
    end generate XCL_BYTE_GEN;
    
    XCL2_BYTE_GEN: if C_MCH_PROTOCOL = 1 generate
    	SNG_BYTE_GEN: if C_XCL_WRITEXFER = 1 generate 
 	   Chnl_byte_wr <= Access_Ctrl when (chnl_data_valid_i = '1') else '0';
    	end generate SNG_BYTE_GEN;

	-----------------------------------------------------------------------
	    -- LINE_BYTE_GEN Generate
    	-----------------------------------------------------------------------          
    	LINE_BYTE_GEN: if C_XCL_WRITEXFER = 0 or C_XCL_WRITEXFER = 2 generate
    	   Chnl_byte_wr <= Access_Ctrl when (chnl_data_valid_i = '1') else '0';
    	   byte_wr <= Access_Ctrl when (chnl_data_valid_i = '1') else '0';    	   
    	end generate LINE_BYTE_GEN;


	Dxcl2_byte_txr   <= '1' when (
				       chnl_wrreq_com = '0' and	
				       dxcl2_single_d1 = '0' and
				       Access_Ctrl = '1')
			    else dxcl2_single_d1;
			    
	dxcl2_single     <= '1' when (
				       dxcl2_single_d1 = '0' and
				       Access_Ctrl = '1')
			    else dxcl2_single_d1;
			    
	dxcl2_single_d2 <= (Access_data_reg(0) and (not Access_data_reg(1)));
	
    end generate XCL2_BYTE_GEN;
    
    XCL2_REG: if C_MCH_PROTOCOL = 1 generate

    ---------------------------------------------------------------------------
    -- Process to register chnl_req_com
    -- Use Addr_Master to reset chnl_req_reg
    ---------------------------------------------------------------------------
    dxcl2_test: process (Sys_Clk)
    begin    
        if (Sys_Clk'event and Sys_Clk = '1') then
            if (Sys_Rst = RESET_ACTIVE) then
                Access_data_reg <=  (others => '0');
                Access_Ctrl_d <= '0';
            else
            	Access_Ctrl_d <= Access_Ctrl;
            	if chnl_addr_valid_i = '1' then 
                	Access_data_reg  <= Access_data (30 to 31);
                end if;	
            end if;
        end if;
    end process dxcl2_test;        
    end generate XCL2_REG;

    
    
    ---------------------------------------------------------------------------
    -- CNT_GEN Generate
    ---------------------------------------------------------------------------          
    -- Only create Access buffer, Ack, & AddrAck counters when cacheline 
    -- transactions are larger than a single word
    CNT_GEN: if (C_XCL_LINESIZE /= 1) generate
    begin    
    
        -- When C_XCL_LINESIZE = 1, only 2 reads performed from Access buffer
        -- SM logic determines rd_access_buffer assertion
        -- Use counter to keep track of data reads from Access buffer 
        -- and writes to ReadData buffer
        BUF_CNT_I: entity proc_common_v3_00_a.ld_arith_reg
        generic map (
            C_ADD_SUB_NOT  => true                  ,
            C_REG_WIDTH    => CHNL_BUF_CNT_SIZE     ,
            C_RESET_VALUE  => CHNL_BUF_CNT_RST      ,
            C_LD_WIDTH     => CHNL_BUF_CNT_SIZE     ,
            C_LD_OFFSET    => 0                     ,
            C_AD_WIDTH     => 1                     ,
            C_AD_OFFSET    => 0
            )
        port map (   
            CK             => Sys_Clk               ,
            RST            => Sys_Rst               ,
            Q              => chnl_buf_cnt          ,   
            LD             => CHNL_BUF_CNT_RST      , 
            AD             => "1"                   ,  
            LOAD           => chnl_buf_ld           ,
            OP             => chnl_buf_cnt_en
            );    

        -- Use counter to keep track of Acks from IP
        ACK_CNT_I: entity proc_common_v3_00_a.ld_arith_reg
        generic map (
            C_ADD_SUB_NOT  => true                  ,
            C_REG_WIDTH    => CHNL_BUF_CNT_SIZE     ,
            C_RESET_VALUE  => CHNL_BUF_CNT_RST      ,
            C_LD_WIDTH     => CHNL_BUF_CNT_SIZE     ,
            C_LD_OFFSET    => 0                     ,
            C_AD_WIDTH     => 1                     ,
            C_AD_OFFSET    => 0
            )
        port map (   
            CK             => Sys_Clk               ,
            RST            => Sys_Rst               ,
            Q              => ack_cnt               ,   
            LD             => CHNL_BUF_CNT_RST      , 
            AD             => "1"                   ,  
            LOAD           => chnl_buf_ld           ,
            OP             => ack_cnt_en
            );

        -- Use counter to keep track of AddrAcks from IP
        -- Counter is used to control assertion of RdReq and WrReq
        -- RdReq and WrReq negate upon the 2nd to last AddrAck
        ADDRACK_CNT_I: entity proc_common_v3_00_a.ld_arith_reg
        generic map (
            C_ADD_SUB_NOT  => true                  ,
            C_REG_WIDTH    => CHNL_BUF_CNT_SIZE     ,
            C_RESET_VALUE  => CHNL_BUF_CNT_RST      ,
            C_LD_WIDTH     => CHNL_BUF_CNT_SIZE     ,
            C_LD_OFFSET    => 0                     ,
            C_AD_WIDTH     => 1                     ,
            C_AD_OFFSET    => 0
            )
        port map (   
            CK             => Sys_Clk               ,
            RST            => Sys_Rst               ,
            Q              => addrack_cnt           ,   
            LD             => CHNL_BUF_CNT_RST      , 
            AD             => "1"                   ,  
            LOAD           => chnl_buf_ld           ,
            OP             => addrack_cnt_en
            );

      addrack_cnt_en   <= IP2Chnl_AddrAck and (not chnl_buf_ld);
      
    end generate CNT_GEN;
      
    ---------------------------------------------------------------------------
    -- NO_WRREQ_GEN Generate
    ---------------------------------------------------------------------------          
    -- Default setting for WrReq when no write operations supported.
    NO_WRREQ_GEN: if (C_XCL_WRITEXFER = 0) generate
        chnl_wrreq_reg <= '0';    
    end generate NO_WRREQ_GEN;
       
       
    ---------------------------------------------------------------------------
    -- XCL SNG_WRREQ_GEN Generate
    ---------------------------------------------------------------------------
    XCL_SNG_WRREQ_GEN: if C_MCH_PROTOCOL = 0 generate
    	-- Generate WrReq for single write transactions.
    	SNG_WRREQ_GEN: if (C_XCL_WRITEXFER = 1) generate
    	begin
        -----------------------------------------------------------------------
        -- WRREQ_REG: chnl_wrreq_reg Registered Process for C_XCL_LINESIZE /= 1
        -----------------------------------------------------------------------
    	    -- Reset upon 1st and only AddrAck
    	    WRREQ_REG: process (Sys_Clk)
    	    begin    
    	        if (Sys_Clk'event and Sys_Clk = '1') then
    	            if (Sys_Rst = RESET_ACTIVE) or (IP2Chnl_AddrAck= '1') then
    	                chnl_wrreq_reg <= '0';
	
    	            -- WrReq is registered here to allow generation of BEs.
    	            -- Only when C_XCL_WRITEXFER = 1 are byte or halfword write 
    	            -- operations allowed. BEs aren't decoded from the Access 
    	            -- buffer until the 2nd write into the Access buffer.
    	            else
    	                chnl_wrreq_reg <= chnl_wrreq_com;
    	            end if;
    	        end if;
    	    end process WRREQ_REG;    
     
    	end generate SNG_WRREQ_GEN;       
    end generate XCL_SNG_WRREQ_GEN;           	
    ---------------------------------------------------------------------------
    -- XCL SNG_WRREQ_GEN Generate
    ---------------------------------------------------------------------------          
    XCL2_SNG_WRREQ_GEN: if C_MCH_PROTOCOL = 1 generate
    	-- Generate WrReq for single write transactions.
    	SNG_WRREQ_GEN: if (C_XCL_WRITEXFER = 1) generate
    	begin
        -----------------------------------------------------------------------
        -- WRREQ_REG: chnl_wrreq_reg Registered Process for C_XCL_LINESIZE /= 1
        -----------------------------------------------------------------------
    	    -- Reset upon 1st and only AddrAck
    	    WRREQ_REG: process (Sys_Clk)
    	    begin    
    	        if (Sys_Clk'event and Sys_Clk = '1') then
    	            if (Sys_Rst = RESET_ACTIVE) or (IP2Chnl_AddrAck= '1') then
    	                chnl_wrreq_reg <= '0';
	
    	            -- WrReq is registered here to allow generation of BEs.
    	            -- Only when C_XCL_WRITEXFER = 1 are byte or halfword write 
    	            -- operations allowed. BEs aren't decoded from the Access 
    	            -- buffer until the 2nd write into the Access buffer.
    	            else
    	                chnl_wrreq_reg <= chnl_wrreq_com;
    	            end if;
    	        end if;
    	    end process WRREQ_REG;    
     
    	end generate SNG_WRREQ_GEN;       
    end generate XCL2_SNG_WRREQ_GEN;
       
    ---------------------------------------------------------------------------
    -- XCL LINE_WRREQ_GEN Generate
    ---------------------------------------------------------------------------  
    -- Generate WrReq for cacheline write transactions.
    XCL_LINE_WRREQ_GEN: if C_MCH_PROTOCOL = 0 generate
      LINE_WRREQ_GEN: if (C_XCL_WRITEXFER = 2) generate
      begin
    
        -----------------------------------------------------------------------
        -- SNG_LINE_WRREQ_GEN Generate
        -----------------------------------------------------------------------      
        -- If cacheline transaction is a single word write.
        SNG_LINE_WRREQ_GEN: if (C_XCL_LINESIZE = 1) generate
        begin
        
            -------------------------------------------------------------------
            -- WRREQ_REG: chnl_wrreq Registered Process for C_XCL_LINESIZE = 1
            -------------------------------------------------------------------
            WRREQ_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    -- Reset upon 1st and only AddrAck
                    if (Sys_Rst = RESET_ACTIVE) or (IP2Chnl_AddrAck= '1') then
                        chnl_wrreq_reg <= '0';                
                    else
                        chnl_wrreq_reg <= chnl_wrreq_com;
                    end if;
                end if;
            end process WRREQ_REG;    
            
        end generate SNG_LINE_WRREQ_GEN;

        -----------------------------------------------------------------------
        -- MULT_LINE_WRREQ_GEN Generate
        -----------------------------------------------------------------------      
        -- If cacheline transactions is a multiple word write.
        MULT_LINE_WRREQ_GEN: if (C_XCL_LINESIZE /= 1) generate
        begin
        
            -------------------------------------------------------------------
            -- WRREQ_REG: chnl_wrreq Registered Process for C_XCL_LINESIZE /= 1
            -------------------------------------------------------------------
            WRREQ_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    -- Reset upon 2nd to last AddrAck
                    -- In case of pause (ie. IP is busy), hold off negation of
                    -- WrReq until last AddrAck is received.
                    if (Sys_Rst = RESET_ACTIVE) or 
                       (addrack_cnt >= CHNL_BUF_CNT_MAX and 
                         IP2Chnl_AddrAck = '1') then
                        chnl_wrreq_reg <= '0';
                    else
                        chnl_wrreq_reg <= chnl_wrreq_com;
                    end if;
                end if;
            end process WRREQ_REG;  
      
        end generate MULT_LINE_WRREQ_GEN;
      end generate LINE_WRREQ_GEN;       
    end generate XCL_LINE_WRREQ_GEN;
    
        -----------------------------------------------------------------------
        -- XCL2 LINE_WRREQ_GEN Generate
        -----------------------------------------------------------------------
        -- Generate WrReq for cacheline write transactions.
        XCL2_LINE_WRREQ_GEN: if C_MCH_PROTOCOL = 1 generate
          LINE_WRREQ_GEN: if (C_XCL_WRITEXFER = 2) generate
          begin
        
            -------------------------------------------------------------------
            -- SNG_LINE_WRREQ_GEN Generate
            -------------------------------------------------------------------
            -- If cacheline transaction is a single word write.
            SNG_LINE_WRREQ_GEN: if (C_XCL_LINESIZE = 1) generate
            begin
            
            ---------------------------------------------------------------
            -- WRREQ_REG: chnl_wrreq Registered Process for C_XCL_LINESIZE = 1
            ---------------------------------------------------------------
                WRREQ_REG: process (Sys_Clk)
                begin    
                    if (Sys_Clk'event and Sys_Clk = '1') then
                        -- Reset upon 1st and only AddrAck
                        if (Sys_Rst = RESET_ACTIVE) or (IP2Chnl_AddrAck= '1') 
                        						then
                            chnl_wrreq_reg <= '0';                
                        else
                            chnl_wrreq_reg <= chnl_wrreq_com;
                        end if;
                    end if;
                end process WRREQ_REG;    
                
            end generate SNG_LINE_WRREQ_GEN;
            
            -------------------------------------------------------------------
            -- MULT_LINE_WRREQ_GEN Generate
            -------------------------------------------------------------------
            -- If cacheline transactions is a multiple word write.
            MULT_LINE_WRREQ_GEN: if (C_XCL_LINESIZE /= 1) generate
            begin
            -------------------------------------------------------------------
            -- WRREQ_REG: chnl_wrreq Registered Process for C_XCL_LINESIZE /= 1
            -------------------------------------------------------------------
                WRREQ_REG: process (Sys_Clk)
                begin    
                    if (Sys_Clk'event and Sys_Clk = '1') then
                        -- Reset upon 2nd to last AddrAck
                        -- In case of pause (ie. IP is busy), hold off negation
                        -- WrReq until last AddrAck is received.
	                if (Sys_Rst = RESET_ACTIVE) or 
                    	     (addrack_cnt >= CHNL_BUF_CNT_MAX and 
                             IP2Chnl_AddrAck = '1' and dxcl2_single = '0')
                             or (IP2Chnl_AddrAck= '1' and 
                             dxcl2_single = '1') then
                            	chnl_wrreq_reg <= '0';
                        else
                            chnl_wrreq_reg <= chnl_wrreq_com;
                        end if;
                    end if;
                end process WRREQ_REG;  
          
            end generate MULT_LINE_WRREQ_GEN;
          end generate LINE_WRREQ_GEN;       
    end generate XCL2_LINE_WRREQ_GEN;
    
    
    ---------------------------------------------------------------------------
    -- RDREQ_SNG_GEN Generate
    ---------------------------------------------------------------------------  
    -- Generate RdReq based on parameter, C_XCL_LINESIZE
    -- If C_XCL_LINESIZE=1, then reset RdReq on 1st and only AddrAck    
    RDREQ_SNG_GEN: if (C_XCL_LINESIZE = 1) generate
    begin
    
        -----------------------------------------------------------------------
        -- chnl_rdreq Registered Process for C_XCL_LINESIZE = 1
        -----------------------------------------------------------------------
        RDREQ_REG: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then
                if (Sys_Rst = RESET_ACTIVE or IP2Chnl_AddrAck = '1') then
                    chnl_rdreq_reg <= '0';
                else
                    chnl_rdreq_reg <= chnl_rdreq_com;
                end if;
            end if;
        end process RDREQ_REG;   
    
    end generate RDREQ_SNG_GEN;

    ---------------------------------------------------------------------------
    -- RDREQ_LINE_GEN Generate
    ---------------------------------------------------------------------------  
    -- Generate RdReq based on parameter, C_XCL_LINESIZE
    -- If C_XCL_LINESIZE/=1, then reset RdReq on last AddrAck    
    RDREQ_LINE_GEN: if (C_XCL_LINESIZE /= 1) generate
    begin

        -----------------------------------------------------------------------
        -- RDREQ_REG : chnl_rdreq Registered Process for C_XCL_LINESIZE /= 1
        -----------------------------------------------------------------------
        RDREQ_REG: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then
            
                -- In case of pause (ie. IP is busy),hold off negation of RdReq 
                -- until last AddrAck is received.
                if (Sys_Rst = RESET_ACTIVE or 
                   (addrack_cnt = CHNL_BUF_CNT_MAX and 
                    IP2Chnl_AddrAck = '1')) then
                    chnl_rdreq_reg <= '0';
                else
                    chnl_rdreq_reg <= chnl_rdreq_com;
                end if;
            end if;
        end process RDREQ_REG;  
        
    end generate RDREQ_LINE_GEN;
    
    ---------------------------------------------------------------------------
    -- ADDRVAL_SNG_GEN Generate
    ---------------------------------------------------------------------------  
    -- Process to generate AddrValid -- generate based on X_XCL_LINESIZE 
    -- parameter. All read and write transactions are only a single word 
    -- (only need AddrAck)
    ADDRVAL_SNG_GEN: if (C_XCL_LINESIZE = 1) generate
    begin    

       -----------------------------------------------------------------------
       -- Resets on 1st and only AddrAck during a write or read operation.
       -- Does not depend on value of C_XCL_WRITEXFER, since C_XCL_LINESIZE = 1
       -----------------------------------------------------------------------
        ADDRVALID_REG: process (Sys_Clk)
        begin    
            if (Sys_Clk'event and Sys_Clk = '1') then
                if (Sys_Rst = RESET_ACTIVE) or (IP2Chnl_AddrAck = '1' ) then
                    ipic_addr_valid_reg <= '0';
                else
                    ipic_addr_valid_reg <= ipic_addr_valid_com;
                end if;
            end if;
        end process ADDRVALID_REG;    

    end generate ADDRVAL_SNG_GEN;

    ---------------------------------------------------------------------------
    -- ADDRVAL_LINE_GEN Generate
    ---------------------------------------------------------------------------  
    -- Process to generate AddrValid -- generate based on X_XCL_LINESIZE 
    -- parameter
    ADDRVAL_LINE_GEN: if (C_XCL_LINESIZE /= 1) generate
    begin    
    
        -----------------------------------------------------------------------
        -- XCL AV_SNG_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read operations are cacheline transactions.
        -- All write operations are single transactions.
        XCL_AV_SNG_WR_GEN: if C_MCH_PROTOCOL = 0 generate
	  AV_SNG_WR_GEN: if (C_XCL_WRITEXFER = 1) generate
          begin        

            -- Resets on 1st and only AddrAck during a single write operation.
            -- Resets on last AddrAck during a cacheline read operation.
            ADDRVALID_REG: process (Sys_Clk)
            begin    
               if (Sys_Clk'event and Sys_Clk = '1') then
                  if (Sys_Rst = RESET_ACTIVE) or 

                     -- If single write operation
                     (chnl_rnw_reg = '0' and IP2Chnl_AddrAck = '1') or

                     -- If cacheline read operation
                     -- In case of pause (ie. IP is busy), hold off negation 
                     -- of AddrValid until last AddrAck is received.
                     (chnl_rnw_reg = '1' and addrack_cnt = CHNL_BUF_CNT_MAX and
                      IP2Chnl_AddrAck = '1') then
                      
                      ipic_addr_valid_reg <= '0';
                  else
                      ipic_addr_valid_reg <= ipic_addr_valid_com;
                  end if;
               end if;
            end process ADDRVALID_REG;  
          end generate AV_SNG_WR_GEN;
        end generate XCL_AV_SNG_WR_GEN;
        
        -----------------------------------------------------------------------
        -- XCL2 AV_SNG_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read operations are cacheline transactions.
        -- All write operations are single transactions.
        XCL2_AV_SNG_WR_GEN: if C_MCH_PROTOCOL = 1 generate
	  xcl2_AV_SNG_WR_GEN: if (C_XCL_WRITEXFER = 1) generate
          begin        

            -- Resets on 1st and only AddrAck during a single write operation.
            -- Resets on last AddrAck during a cacheline read operation.
            ADDRVALID_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    if (Sys_Rst = RESET_ACTIVE) or 

                       -- If single write operation
                       (chnl_rnw_reg = '0' and IP2Chnl_AddrAck = '1') or
                       -- If cacheline read operation
                       -- In case of pause (ie. IP is busy), hold off negation 
                       -- of AddrValid until last AddrAck is received.
                       (chnl_rnw_reg = '1' and addrack_cnt = CHNL_BUF_CNT_MAX 
                       		and IP2Chnl_AddrAck = '1') then
                        
                        ipic_addr_valid_reg <= '0';
                    else
                        ipic_addr_valid_reg <= ipic_addr_valid_com;
                    end if;
                end if;
            end process ADDRVALID_REG;  
          end generate xcl2_AV_SNG_WR_GEN;
        end generate XCL2_AV_SNG_WR_GEN;        

        -----------------------------------------------------------------------
        -- AV_LINE_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read and write transactions are cacheline operations
        XCL_AV_LINE_WR_GEN: if C_MCH_PROTOCOL = 0 generate        
          AV_LINE_WR_GEN: if (C_XCL_WRITEXFER = 0 or C_XCL_WRITEXFER = 2)
          							      generate
        begin        
        
           -------------------------------------------------------------------
           -- Resets on last AddrAck during a cacheline write or read operation
           -------------------------------------------------------------------
            ADDRVALID_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                
                    -- In case of pause (ie. IP is busy), hold off negation of
                    -- AddrValid until last AddrAck is received.
                    if (Sys_Rst = RESET_ACTIVE or 
                       (addrack_cnt = CHNL_BUF_CNT_MAX and 
                                                  IP2Chnl_AddrAck = '1')) then
                        ipic_addr_valid_reg <= '0';
                    else
                        ipic_addr_valid_reg <= ipic_addr_valid_com;
                    end if;
                end if;
            end process ADDRVALID_REG;  
          end generate AV_LINE_WR_GEN;
        end generate XCL_AV_LINE_WR_GEN;

        -----------------------------------------------------------------------
        -- XCL2_AV_LINE_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read and write transactions are cacheline operations
        XCL2_AV_LINE_WR_GEN: if C_MCH_PROTOCOL = 1 generate        
          AV_LINE_WR_GEN: if (C_XCL_WRITEXFER = 0 or C_XCL_WRITEXFER = 2 )
          							       generate
        begin        
        
           -------------------------------------------------------------------
           -- Resets on last AddrAck during a cacheline write or read operation
           -------------------------------------------------------------------
            ADDRVALID_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                
                    -- In case of pause (ie. IP is busy), hold off negation of
                    -- AddrValid until last AddrAck is received.
                    if (Sys_Rst = RESET_ACTIVE) or 
                       (chnl_rnw_reg = '0' and IP2Chnl_AddrAck = '1' 
                       and dxcl2_single = '1') or (chnl_rnw_reg = '1' 
                       and addrack_cnt = CHNL_BUF_CNT_MAX and
                        IP2Chnl_AddrAck = '1' and dxcl2_single = '1') then
                        ipic_addr_valid_reg <= '0';
                    else
                        ipic_addr_valid_reg <= ipic_addr_valid_com;
                    end if;
                end if;
            end process ADDRVALID_REG;  
          end generate AV_LINE_WR_GEN;
        end generate XCL2_AV_LINE_WR_GEN;        

    end generate ADDRVAL_LINE_GEN;

    ---------------------------------------------------------------------------
    -- BURST_SNG_GEN Generate
    ---------------------------------------------------------------------------  
    -- Process to generate Burst -- generate based on X_XCL_LINESIZE parameter
    -- All read and write transactions are only a single word 
    -- (no burst necessary)
    BURST_SNG_GEN: if (C_XCL_LINESIZE = 1) generate
        chnl_burst_reg <= '0';
        
        chnl_burstlength_i <= (others => '0');
        
    end generate BURST_SNG_GEN;

    ---------------------------------------------------------------------------
    -- BURST_LINE_GEN Generate
    ---------------------------------------------------------------------------  
    -- Process to generate Burst -- generate based on X_XCL_LINESIZE parameter
    BURST_LINE_GEN: if (C_XCL_LINESIZE /= 1) generate
    begin    
    
        -----------------------------------------------------------------------
        -- XCL BURST_SNG_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read operations are cacheline transactions.
        -- All write operations are single transactions.
        XCL_BURST_SNG_WR_GEN: if C_MCH_PROTOCOL = 0 generate
          BURST_SNG_WR_GEN: if (C_XCL_WRITEXFER = 0 or 
                                C_XCL_WRITEXFER = 1) generate
          begin        

            -------------------------------------------------------------------
            -- Burst stays negated during write operations.
            -- Burst negates on 2nd to last Ack received from IP.
            -------------------------------------------------------------------
            BURST_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    if (Sys_Rst = RESET_ACTIVE or chnl_rnw_reg = '0') or

                       -- If cacheline read operation
                       -- In case of pause (ie. IP is busy), hold off 
                       -- negation of Burst until 2nd to last Ack is received.
                       (chnl_rnw_reg = '1' and ack_cnt = CHNL_BUF_CNT_ALMST_MAX
                                           and IP2Chnl_Ack = '1') then
                        chnl_burst_reg <= '0';
                    else
                        chnl_burst_reg <= chnl_burst_com;
                    end if;
                end if;
            end process BURST_REG;  

            -------------------------------------------------------------------
            -- NOTE: This assumes that C_BRST_CNT_WIDTH will always be greater
            -- than CHNL_BUF_CNT_SIZE
            -------------------------------------------------------------------
            BURSTLENGTH_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    if (Sys_Rst = RESET_ACTIVE or chnl_rnw_reg = '0')then
                        chnl_burstlength_i <= (others => '0');
                    else
                        chnl_burstlength_i(C_BRSTCNT_WIDTH-CHNL_BUF_CNT_SIZE to
                                        C_BRSTCNT_WIDTH-1) <= CHNL_BUF_CNT_MAX;
                    end if;
                end if;
            end process BURSTLENGTH_REG;  
          end generate BURST_SNG_WR_GEN;
        end generate XCL_BURST_SNG_WR_GEN;  
        
        -----------------------------------------------------------------------
        -- XCL BURST_SNG_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read operations are cacheline transactions.
        -- All write operations are single transactions.
        XCL2_BURST_SNG_WR_GEN: if C_MCH_PROTOCOL = 1 generate
          BURST_SNG_WR_GEN: if (C_XCL_WRITEXFER = 0 or C_XCL_WRITEXFER = 1) 
          							       generate
          begin        

            -------------------------------------------------------------------
            -- Burst stays negated during write operations.
            -- Burst negates on 2nd to last Ack received from IP.
            -------------------------------------------------------------------
            BURST_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    if (Sys_Rst = RESET_ACTIVE or chnl_rnw_reg = '0') or

                       -- If cacheline read operation
                       -- In case of pause (ie. IP is busy), hold off 
                       -- negation of Burst until 2nd to last Ack is received.
                       (chnl_rnw_reg = '1' and ack_cnt = CHNL_BUF_CNT_ALMST_MAX
                                           and IP2Chnl_Ack = '1') then
                        chnl_burst_reg <= '0';
                    else
                        chnl_burst_reg <= chnl_burst_com;
                    end if;
                end if;
            end process BURST_REG;  

            -------------------------------------------------------------------
            -- NOTE: This assumes that C_BRST_CNT_WIDTH will always be greater
            -- than CHNL_BUF_CNT_SIZE
            -------------------------------------------------------------------
            BURSTLENGTH_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    if (Sys_Rst = RESET_ACTIVE or chnl_rnw_reg = '0')then
                        chnl_burstlength_i <= (others => '0');
                    else
                        chnl_burstlength_i(C_BRSTCNT_WIDTH-CHNL_BUF_CNT_SIZE to
                                        C_BRSTCNT_WIDTH-1) <= CHNL_BUF_CNT_MAX;
                    end if;
                end if;
            end process BURSTLENGTH_REG;  
          end generate BURST_SNG_WR_GEN;
        end generate XCL2_BURST_SNG_WR_GEN;          

        -----------------------------------------------------------------------
        -- XCL_BURST_LINE_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read and write transactions are cacheline operations
        XCL_BURST_LINE_WR_GEN: if C_MCH_PROTOCOL = 0 generate
          BURST_LINE_WR_GEN: if (C_XCL_WRITEXFER = 2) generate
          begin        
        
            -------------------------------------------------------------------
            -- Resets on 2nd to last Ack during a cacheline write or read 
            -- operation.
            -------------------------------------------------------------------
            BURST_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                
                    -- In case of pause (ie. IP is busy), hold off negation
                    -- of Burst until 2nd to last Ack is received.
                    if (Sys_Rst = RESET_ACTIVE or 
                       (ack_cnt = CHNL_BUF_CNT_ALMST_MAX and 
                                                      IP2Chnl_Ack = '1')) then
                        chnl_burst_reg <= '0';
                    else
                        chnl_burst_reg <= chnl_burst_com;
                    end if;
                end if;
            end process BURST_REG;  

            -------------------------------------------------------------------
            -- chnl_burstlength Registered Process
            -------------------------------------------------------------------
            BURSTLENGTH_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    if (Sys_Rst = RESET_ACTIVE)then
                        chnl_burstlength_i <= (others => '0');
                    else
                        chnl_burstlength_i(C_BRSTCNT_WIDTH-CHNL_BUF_CNT_SIZE to
                                        C_BRSTCNT_WIDTH-1) <= CHNL_BUF_CNT_MAX;
                    end if;
                end if;
            end process BURSTLENGTH_REG;
          end generate BURST_LINE_WR_GEN;
        end generate XCL_BURST_LINE_WR_GEN;
        
        -----------------------------------------------------------------------
        -- XCL2_BURST_LINE_WR_GEN Generate
        -----------------------------------------------------------------------
        -- All read and write transactions are cacheline operations
        XCL2_BURST_LINE_WR_GEN: if C_MCH_PROTOCOL = 1 generate
          BURST_LINE_WR_GEN: if (C_XCL_WRITEXFER = 2 ) generate
          begin        
        
            -------------------------------------------------------------------
            -- Resets on 2nd to last Ack during a cacheline write or read 
            -- operation.
            -------------------------------------------------------------------
            BURST_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                    if (Sys_Rst = RESET_ACTIVE or (chnl_rnw_reg = '0' and 
                       dxcl2_single = '1'))or((ack_cnt = CHNL_BUF_CNT_ALMST_MAX
                       and IP2Chnl_Ack = '1') and ((dxcl2_single = '1' and 
                       chnl_rnw_reg = '0') or dxcl2_single = '0')) then
                        chnl_burst_reg <= '0';
                    else
                        chnl_burst_reg <= chnl_burst_com;
                    end if;                
                end if;
            end process BURST_REG;  

            -------------------------------------------------------------------
            -- chnl_burstlength Registered Process
            -------------------------------------------------------------------
            BURSTLENGTH_REG: process (Sys_Clk)
            begin    
                if (Sys_Clk'event and Sys_Clk = '1') then
                  if (Sys_Rst = RESET_ACTIVE or (chnl_rnw_reg = '0' and 
                  				       dxcl2_single = '1'))then
                        chnl_burstlength_i <= (others => '0');
                  else  
                      if dxcl2_single = '1'then 			
                        chnl_burstlength_i(C_BRSTCNT_WIDTH-CHNL_BUF_CNT_SIZE to
                                        C_BRSTCNT_WIDTH-1) <= CHNL_BUF_CNT_MAX;                      
                      else  
                        chnl_burstlength_i(C_BRSTCNT_WIDTH-CHNL_BUF_CNT_SIZE to
                                        C_BRSTCNT_WIDTH-1) <= CHNL_BUF_CNT_MAX;
                      end if;                  
                    end if;
                end if;
            end process BURSTLENGTH_REG;
          end generate BURST_LINE_WR_GEN;
        end generate XCL2_BURST_LINE_WR_GEN;        
     end generate BURST_LINE_GEN;

    ---------------------------------------------------------------------------
    -- MCH ReadData Buffer Channel Logic
    ---------------------------------------------------------------------------
    -- ReadData_Ctrl = '0' when data is valid to write to ReadData buffer
    -- ReadData_Ctrl = '1' when an error has occured
    ReadData_Ctrl  <= wr_readdata_error;
    ReadData_Write <= wr_readdata_buffer;

    ---------------------------------------------------------------------------
    -- Channel Logic
    ---------------------------------------------------------------------------
    -- Chnl_Req is not registered to improve latency through MCH interface
    -- Use MCH/PLBV46 Arbiter Addr_Master signal input to identify MCH won 
    -- arbitration and Chnl_Req can negate
    Chnl_Req <= '0' when (Addr_Master = '1' and chnl_req_reg='1') else 
                chnl_req_reg;

    ---------------------------------------------------------------------------
    -- Process to register chnl_req_com
    -- Use Addr_Master to reset chnl_req_reg
    ---------------------------------------------------------------------------
    CHNLREQ_REG: process (Sys_Clk)
    begin    
        if (Sys_Clk'event and Sys_Clk = '1') then
            if (Sys_Rst = RESET_ACTIVE or (Addr_Master = '1' and 
                                           chnl_req_reg='1')) then
                chnl_req_reg <= '0';
            else
                chnl_req_reg <= chnl_req_com;
            end if;
        end if;
    end process CHNLREQ_REG;    
           
    ---------------------------------------------------------------------------
    -- CHNL_SNG_GEN Generate
    ---------------------------------------------------------------------------  
    -- Generate channel logic signals to be used by PLBV46/MCH arbitration 
    -- logic.
    -- Channel logic signals generated the same for read or write operations
    CHNL_SNG_GEN: if (C_XCL_LINESIZE = 1) generate
    begin
        
        -- Chnl_Addr_Almost_Done is only asserted for one clock cycle when 1st
        -- and only AddrAck is received from the IP logic
        Chnl_Addr_Almost_Done <= '1' when (chnl_select_reg = '1' and 
                                           IP2Chnl_AddrAck = '1') else 
                                 '0'; 
        
        -- Chnl_Data_Almost_Done is only asserted for one clock cycle when the 
        -- 1st and only Ack is received from the IP logic. If Ack is not 
        -- received, check if Timeout_error condition is asserted.
        Chnl_Data_Almost_Done <=  '1' when (chnl_select_reg = '1' and 
                                           IP2Chnl_Ack = '1') else
                                  '0';   
 
    end generate CHNL_SNG_GEN;
    
    ---------------------------------------------------------------------------
    -- CHNL_LINE_GEN Generate
    ---------------------------------------------------------------------------  
    -- Generate channel logic signals to be used be PLBV46/MCH arbitration 
    -- logic
    -- Channel logic signals generated depend on read or write operation
    CHNL_LINE_GEN: if (C_XCL_LINESIZE /= 1 ) generate    
    begin
     
        -----------------------------------------------------------------------
        -- XCL_CHNL_SNG_WR_GEN Generate
        -- Channel logic signals depend on write transfer size for operation.
        -----------------------------------------------------------------------
        XCL_CHNL_SNG_WR_GEN: if C_MCH_PROTOCOL = 0 generate        
          CHNL_SNG_WR_GEN: if (C_XCL_WRITEXFER = 1) generate
          begin                                          
                        
            -- Chnl_Addr_Almost_Done is only asserted for one clock cycle when 
            -- a) during a write operation, the 1st and only AddrAck is 
            --    received from the IP logic
            -- b) during a read operation, the last AddrAck is received from 
            --    the IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Addr_Almost_Done until last AddrAck is received.
            Chnl_Addr_Almost_Done <= '1' when ((chnl_select_reg = '1') and
                                               ((chnl_rnw_reg = '0' and 
                                                 IP2Chnl_AddrAck = '1') or 
                                                (chnl_rnw_reg = '1' and 
                                                 addrack_cnt = CHNL_BUF_CNT_MAX
                                                 and IP2Chnl_AddrAck = '1')))
                                     else '0'; 
        
            -- Chnl_Data_Almost_Done is only asserted for one clock cycle when 
            -- a) during a write operation, the 1st and only Ack is received 
            --    from the IP logic
            -- b) during a read operation, the last Ack is received from the
            --    IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Data_Almost_Done until last Ack is received.
            -- If Ack is not received, check if Timeout_error condition is 
            -- asserted (only valid during read operations).
            Chnl_Data_Almost_Done <= '1' when ((chnl_select_reg = '1') and
                                               ((chnl_rnw_reg = '0' and 
                                                 IP2Chnl_Ack = '1') or 
                                                (chnl_rnw_reg = '1' and 
                                                 ack_cnt = CHNL_BUF_CNT_MAX
                                                 and IP2Chnl_Ack = '1')))
                                     else '0';   
                                   
          end generate CHNL_SNG_WR_GEN;
        end generate XCL_CHNL_SNG_WR_GEN;
        
        -----------------------------------------------------------------------
        -- XCL2_CHNL_SNG_WR_GEN Generate
        -- Channel logic signals depend on write transfer size for operation.
        -----------------------------------------------------------------------
        XCL2_CHNL_SNG_WR_GEN: if C_MCH_PROTOCOL = 1 generate        
          CHNL_SNG_WR_GEN: if (C_XCL_WRITEXFER = 1) generate
          begin                                          
                        
            -- Chnl_Addr_Almost_Done is only asserted for one clock cycle when 
            -- a) during a write operation, the 1st and only AddrAck is 
            --    received from the IP logic
            -- b) during a read operation, the last AddrAck is received from 
            --    the IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Addr_Almost_Done until last AddrAck is received.
            Chnl_Addr_Almost_Done <= '1' when ((chnl_select_reg = '1') and
                                               ((chnl_rnw_reg = '0' and 
                                                 IP2Chnl_AddrAck = '1') or 
                                                (chnl_rnw_reg = '1' and 
                                                 addrack_cnt = CHNL_BUF_CNT_MAX
                                                 and IP2Chnl_AddrAck = '1')))
                                     else '0'; 
        
            -- Chnl_Data_Almost_Done is only asserted for one clock cycle when 
            -- a) during a write operation, the 1st and only Ack is received 
            --    from the IP logic
            -- b) during a read operation, the last Ack is received from the
            --    IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Data_Almost_Done until last Ack is received.
            -- If Ack is not received, check if Timeout_error condition is 
            -- asserted (only valid during read operations).
            Chnl_Data_Almost_Done <= '1' when ((chnl_select_reg = '1') and
                                               ((chnl_rnw_reg = '0' and 
                                                 IP2Chnl_Ack = '1') or 
                                                (chnl_rnw_reg = '1' and 
                                                 ack_cnt = CHNL_BUF_CNT_MAX
                                                 and IP2Chnl_Ack = '1')))
                                     else '0';   
                                   
          end generate CHNL_SNG_WR_GEN;
        end generate XCL2_CHNL_SNG_WR_GEN;        

        -----------------------------------------------------------------------
        -- XCL_CHNL_LINE_WR_GEN Generate
        -----------------------------------------------------------------------
        XCL_CHNL_LINE_WR_GEN: if C_MCH_PROTOCOL = 0 generate        
          CHNL_LINE_WR_GEN: if (C_XCL_WRITEXFER = 0 or 
                              C_XCL_WRITEXFER = 2) generate
          begin

            -- Chnl_Addr_Almost_Done is only asserted for one clock cycle when
            -- the last AddrAck is received from the IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Addr_Almost_Done until last AddrAck is received.
            Chnl_Addr_Almost_Done <= '1' when (chnl_select_reg = '1' and 
                                               addrack_cnt = CHNL_BUF_CNT_MAX
                                               and IP2Chnl_AddrAck = '1')
                                     else '0'; 
        
            -- Chnl_Data_Almost_Done is only asserted for one clock cycle when
            -- the last Ack is received from the IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Data_Almost_Done until last Ack is received.
            -- If Ack is not received, check if Timeout_error condition is 
            -- asserted (only valid during read operations).
            Chnl_Data_Almost_Done <= '1' when (chnl_select_reg = '1' and 
                                               ack_cnt = CHNL_BUF_CNT_MAX and
                                               IP2Chnl_Ack = '1')
                                     else '0';   

          end generate CHNL_LINE_WR_GEN;        
        end generate XCL_CHNL_LINE_WR_GEN;
        
        -----------------------------------------------------------------------
        -- XCL2_CHNL_LINE_WR_GEN Generate
        -----------------------------------------------------------------------
        XCL2_CHNL_LINE_WR_GEN: if C_MCH_PROTOCOL = 1 generate        
          CHNL_LINE_WR_GEN: if (C_XCL_WRITEXFER = 0 or C_XCL_WRITEXFER = 2) 
          				      			      generate
          begin

            -- Chnl_Addr_Almost_Done is only asserted for one clock cycle when
            -- the last AddrAck is received from the IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Addr_Almost_Done until last AddrAck is received.
            --TXFR size 2
            
            Chnl_Addr_Almost_Done <= '1' when ((chnl_select_reg = '1' and 
            					addrack_cnt = CHNL_BUF_CNT_MAX 
            					and IP2Chnl_AddrAck = '1' and 
            					dxcl2_single = '0') or 
            				       ((chnl_select_reg = '1') and 
            				       ((chnl_rnw_reg = '0' and 
            				       IP2Chnl_AddrAck = '1') or 
            				       (chnl_rnw_reg = '1' and 
            				       addrack_cnt = CHNL_BUF_CNT_MAX 
            				       and IP2Chnl_AddrAck = '1')) 
            				       and dxcl2_single = '1'))
                                     else '0'; 
        
            -- Chnl_Data_Almost_Done is only asserted for one clock cycle when
            -- the last Ack is received from the IP logic
            -- In case of pause (ie. IP is busy), hold off assertion of 
            -- Data_Almost_Done until last Ack is received.
            -- If Ack is not received, check if Timeout_error condition is 
            -- asserted (only valid during read operations).
            Chnl_Data_Almost_Done <= '1' when ((chnl_select_reg = '1' and 
            					ack_cnt = CHNL_BUF_CNT_MAX and 
            					IP2Chnl_Ack = '1' and 
            					dxcl2_single = '0') or
             				       ((chnl_select_reg = '1') and 
             				       ((chnl_rnw_reg = '0' and 
             				       IP2Chnl_Ack = '1') or 
             				       (chnl_rnw_reg = '1' and 
             				       ack_cnt = CHNL_BUF_CNT_MAX and 
             				       IP2Chnl_Ack = '1'))and 
             				       dxcl2_single = '1'))
                                     else '0';   
          end generate CHNL_LINE_WR_GEN;
        end generate XCL2_CHNL_LINE_WR_GEN;
      end generate CHNL_LINE_GEN;   
    
    ---------------------------------------------------------------------------
    -- Channel State Machine Registered Process
    ---------------------------------------------------------------------------
    CHNLSM_REG: process (Sys_Clk)
    begin    
        if (Sys_Clk'event and Sys_Clk = '1') then
            if (Sys_Rst = RESET_ACTIVE) then
                chnlsm_cs       <= IDLE;
                chnl_select_reg <= '0';
                chnl_rnw_reg    <= '0';
            else
                chnlsm_cs       <= chnlsm_ns;
                chnl_select_reg <= chnl_select_com;
                chnl_rnw_reg    <= chnl_rnw_com;
            end if;
        end if;
    end process CHNLSM_REG;    

    ---------------------------------------------------------------------------
    -- dxcl2_single_d1 Registered Process
    ---------------------------------------------------------------------------
    DXCL2_REG: process (Sys_Clk)
    begin    
        if (Sys_Clk'event and Sys_Clk = '1') then
            if (Sys_Rst = RESET_ACTIVE) then
		dxcl2_single_d1_reg <= '0';
            else
		dxcl2_single_d1_reg <= dxcl2_single_d1;
            end if;
        end if;
    end process DXCL2_REG;      

    ---------------------------------------------------------------------------
    -- Channel State Machine Combinational Process
    ---------------------------------------------------------------------------
    CHNLSM_CMB: process (chnlsm_cs, Access_Exists, Access_Ctrl, 
    			 dxcl2_single,Access_Ctrl_d,IP2Chnl_Ack,chnl_burst_reg,
    			 dxcl2_single_d1_reg,byte_wr,
                         chnl_buf_cnt, ack_cnt, ipic_addr_valid_reg,
                         chnl_select_reg, chnl_req_reg, chnl_rnw_reg, 
                         chnl_rdreq_reg, chnl_wrreq_reg, dxcl2_single_d2)
    begin           
    
        chnlsm_ns             <= chnlsm_cs;
        rd_access_buffer      <= '0';
        wr_readdata_buffer    <= '0';
        chnl_buf_ld           <= '0';
        chnl_buf_cnt_en       <= '0';
        ack_cnt_en            <= '0';
        chnl_addr_valid_i     <= '0';
        chnl_data_valid_i     <= '0';      
        Chnl_start_data_valid <= '0';
        chnl_rdce_i           <= '0';
        chnl_wrce_i           <= '0';
        chnl_burst_com        <= chnl_burst_reg;
        chnl_rnw_com          <= chnl_rnw_reg;
        chnl_rdreq_com        <= chnl_rdreq_reg;
        chnl_wrreq_com        <= chnl_wrreq_reg;
        chnl_select_com       <= chnl_select_reg;
        chnl_req_com          <= chnl_req_reg;
        ipic_addr_valid_com   <= ipic_addr_valid_reg;
        wr_readdata_error     <= '0';      -- By default all data written into 
                                           -- ReadData Buffer is valid
        dxcl2_single_d1	    <= dxcl2_single_d1_reg;
        
        case chnlsm_cs is
        
            ---------------------------- IDLE ---------------------------
            when IDLE =>
                
                -- Clear channel buffer counter
                chnl_buf_ld         <= '1';
                chnl_select_com     <= '0';
                chnl_req_com        <= '0';
                ipic_addr_valid_com <= '0';
                chnl_rdreq_com      <= '0';
                chnl_wrreq_com      <= '0';
                chnl_rnw_com        <= '0'; 
                --dxcl2_single 	    <= '0';
                dxcl2_single_d1	    <= '0';

                -- Wait for valid data in channel access buffer.
                if (Access_Exists = '1') then
                
                    chnl_select_com     <= '1';
                    chnl_req_com        <= '1';
                    chnl_addr_valid_i   <= '1';
                    ipic_addr_valid_com <= '1';
                    rd_access_buffer    <= '1';
                    
                    -- Decode read operation early during 1st write in Access
                    -- buffer.
                    -- Read address from channel access buffer.
                    if (Access_Ctrl = '0') then
                        chnl_rnw_com <= '1';
                        chnlsm_ns    <= RD_OP_ADDR;
                   
                    -- Decode write operation early during 1st write in Access
                    -- buffer.
                    -- Read address from channel access buffer.
                    elsif (Access_Ctrl = '1') then                   
                        chnl_rnw_com <= '0';
	                if C_MCH_PROTOCOL=0 then
	                  chnlsm_ns    <= WR_OP_ADDR;
	                else        
	                  chnlsm_ns    <= WR_OP_DXCL2_ADDR;
	                end if;  
                    end if;
                end if;
                
            -------------------------- RD_OP_ADDR ---------------------------
            when RD_OP_ADDR =>                
                
                -- Read address from Access buffer.
                -- Go wait for IP2Chnl_Ack to be asserted.
                chnl_rdreq_com  <= '1';          
                chnl_rnw_com    <= '1';
                chnl_rdce_i     <= '1';
                chnlsm_ns       <= WAIT_ACK;               
                dxcl2_single_d1	    <= '0';

                -- MCH reads are always cacheline transfers.
                -- Assert burst if cacheline size is greater than 1.
                if (C_XCL_LINESIZE /= 1) then
                    chnl_burst_com <= '1';
                end if;
               
            -------------------------- WR_OP_ADDR ---------------------------
            when WR_OP_ADDR =>                
               
                -- Read address from Access buffer.
                chnl_rnw_com <= '0';

                -- During write operation, see if valid data exists in channel
                -- access buffer.
                -- Assert chnl_wrreq_com to start write operation (registered
                -- signal creates Chnl2IP_WrReq)
                -- Only check for write operation if C_XCL_WRITEXFER /= 0
                if (C_XCL_WRITEXFER /= 0 and Access_Exists = '1') then
                
                    -- Read data from channel access buffer
                    rd_access_buffer  <= '1';
                    chnl_wrreq_com    <= '1'; 
                    chnl_wrce_i       <= '1';
                    chnl_data_valid_i <= '1';
                                          
                    -- If cacheline transaction, wait for multiple Acks from IP  
                    -- Enable counter
                    if (C_XCL_WRITEXFER = 2) then
                        Chnl_start_data_valid <= '1';
                        chnl_buf_cnt_en       <= '1';
                    end if;

                    -- Only assert burst during cacheline transfers (more than
                    -- a single word)
                    if (C_XCL_LINESIZE /= 1 and C_XCL_WRITEXFER = 2) then
                        chnl_burst_com <= '1';
                    end if;

                    chnlsm_ns <= RD_DATA;
 
                end if;
                
            when WR_OP_DXCL2_ADDR =>                
               
                -- Read address from Access buffer.
                chnl_rnw_com <= '0';

                -- During write operation, see if valid data exists in channel
                -- access buffer.
                -- Assert chnl_wrreq_com to start write operation (registered
                -- signal creates Chnl2IP_WrReq)
                -- Only check for write operation if C_XCL_WRITEXFER /= 0
                if (C_XCL_WRITEXFER /= 0 and Access_Exists = '1') then
                
                    -- Read data from channel access buffer
                    rd_access_buffer  <= '1';
                    chnl_wrreq_com    <= '1'; 
                    chnl_wrce_i       <= '1';
                    chnl_data_valid_i <= '1';

                    -- If cacheline transaction, wait for multiple 
                    -- Acks from IP Enable counter
                    if (C_XCL_WRITEXFER = 2) then
                    	Chnl_start_data_valid <= '1';
                    	chnl_buf_cnt_en       <= '1';
                    	if dxcl2_single_d2 = '1' then
                    		dxcl2_single_d1	      <= byte_wr;
                    	else 
                    		dxcl2_single_d1	      <= '1';
                    	end if;	
                    end if;
                    -- Only assert burst during cacheline transfers 
                    -- (more than a single word)
                    if (C_XCL_LINESIZE /= 1 and C_XCL_WRITEXFER = 2 and 
                    		     dxcl2_single_d2 = '1' ) then
                    	 chnl_burst_com <= '1';
                    end if;
                    chnlsm_ns <= RD_DATA;
                end if;


            -------------------------- RD_DATA ---------------------------
            when RD_DATA =>
                                
                chnl_wrce_i     <= '1';
                chnl_rnw_com    <= '0';       
                
                -- Only assert burst during cacheline transfers (more than a 
                -- single word)
                if (C_XCL_LINESIZE /= 1 and C_XCL_WRITEXFER = 2 and 
                				dxcl2_single_d1_reg = '0') then
                    chnl_burst_com <= '1';
                else    
                    chnl_burst_com <= '0';                
                end if;
                
                -- Wait for IP2Chnl_Ack to be asserted before reading
                -- subsequent data words out of channel access buffer
                if (IP2Chnl_Ack = '1') then
                
                    chnl_req_com <= '0';        -- Negate Chnl_Req
                
                    -- Determine next state based on type of transaction
                    -- If single byte/hw/word transaction or cacheline size = 1
                    -- then done with transaction (only one Ack to receive)
                    if (C_XCL_LINESIZE = 1 or C_XCL_WRITEXFER = 1 or 
                    				dxcl2_single_d1_reg = '1') then
                                
                        chnl_wrreq_com <= '0';        
                                
                        -- Check if next operation is valid in channel access 
                        -- buffer
                        -- If no operation is pending, proceed to IDLE state to
                        -- wait for next transaction
                        if (Access_Exists = '0') then
                            chnl_select_com     <= '0';
                            ipic_addr_valid_com <= '0';
                            chnlsm_ns           <= IDLE;
                        
                        -- If subsequent operation is waiting in channel access
                        -- buffer
                        -- Then start next transaction (bypass IDLE state)
                        elsif (Access_Exists = '1') then
                                        
                            chnl_select_com     <= '1';
                            chnl_req_com        <= '1';
                            chnl_addr_valid_i   <= '1';
                            chnl_buf_ld         <= '1';    -- Clear channel 
                                                           -- buffer counter
                            ipic_addr_valid_com <= '1';
                            rd_access_buffer    <= '1';
                            
                            -- Decode read operation early during 1st write in 
                            -- Access buffer.
                            -- Read address from channel access buffer.
                            -- Assert chnl_rdreq_com to start read operation 
                            -- (registered signal creates Chnl2IP_RdReq)
                            if (Access_Ctrl = '0') then
                                chnl_rnw_com <= '1';
                                chnlsm_ns    <= RD_OP_ADDR;
                            
                            -- Decode write operation early during 1st write in
                            -- Access buffer.
                            -- Read address from channel access buffer.
                            elsif (Access_Ctrl = '1') then                                                   
                                chnl_rnw_com <= '0';
	                	if C_MCH_PROTOCOL=0 then
	                	  chnlsm_ns    <= WR_OP_ADDR;
	                	else        
	                	  chnlsm_ns    <= WR_OP_DXCL2_ADDR;
	                	end if;  
                            end if;                                  
                            
                        end if;
   
                    -- If cacheline transaction, wait for multiple Acks from IP    
                    elsif (C_XCL_LINESIZE /= 1 and C_XCL_WRITEXFER = 2 and 
                				dxcl2_single_d1_reg = '0') then
                
                        -- Continue to read data from channel access buffer
                        ack_cnt_en        <= '1';      -- Increment Ack counter
                        rd_access_buffer  <= '1';
                        chnl_data_valid_i <= '1';
                        chnl_buf_cnt_en   <= '1';

                        -- End of transaction (wait for last ACK from IP)
                        if (chnl_buf_cnt = CHNL_BUF_CNT_MAX) then
                            chnlsm_ns <= WAIT_LAST_ACK;
                        end if;
                        
                    end if;   
                    
                end if;

            ------------------------- WAIT_ACK ---------------------------
            when WAIT_ACK =>
                
                chnl_rdce_i  <= '1';
                chnl_rnw_com <= '1';
                
                -- MCH reads are always cacheline transfers (assert burst)
                -- if cacheline size is /= 1
                -- Negate burst upon 2nd to last IP2Chnl_Ack
                if (C_XCL_LINESIZE /= 1 and ack_cnt < CHNL_BUF_CNT_MAX) then
                    chnl_burst_com <= '1';
                end if;
               
                -- Wait for IP2Chnl_Ack to be asserted before writing
                -- data to channel readdata buffer
                if (IP2Chnl_Ack = '1') then   
                
                    chnl_req_com       <= '0';        -- Negate Chnl_Req
                    wr_readdata_buffer <= '1';  -- Write data read from IP into
                                                -- ReadData buffer
                    
                    -- Only enable buffer counter when C_XCL_LINESIZE /= 1
                    -- Only increment Ack counter when C_XCL_LINESIZE /= 1
                    if (C_XCL_LINESIZE /= 1) then
                        ack_cnt_en      <= '1';       -- Increment Ack counter
                        chnl_buf_cnt_en <= '1';
                    end if;

                    -- End of transaction
                    -- If C_XCL_LINESIZE /= 1 then read all data for size of 
                    -- cacheline
                    if (C_XCL_LINESIZE /= 1 and 
                        chnl_buf_cnt = CHNL_BUF_CNT_MAX) then
                        
                        chnl_burst_com <= '0';
                        chnl_rdreq_com <= '0';
                        
                        -- Check if next operation is valid in channel 
                        -- access buffer
                        -- If no operation is pending, proceed to IDLE state to
                        -- wait for next transaction
                        if (Access_Exists = '0') then                        
                            chnl_select_com     <= '0';
                            ipic_addr_valid_com <= '0';
                            chnlsm_ns           <= IDLE;
                            
                        -- If subsequent operation is waiting in channel access
                        -- buffer 
                        --Then start next transaction (bypass IDLE state)
                        elsif (Access_Exists = '1') then
                                        
                            chnl_select_com     <= '1';
                            chnl_req_com        <= '1';
                            chnl_addr_valid_i   <= '1';
                            chnl_buf_ld         <= '1';   -- Clear channel 
                                                          -- buffer counter
                            ipic_addr_valid_com <= '1';
                            rd_access_buffer    <= '1';
                            
                            -- Decode read operation early during 1st write in 
                            -- Access buffer.
                            -- Read address from channel access buffer.
                            -- Assert chnl_rdreq_com to start read operation
                            -- (registered signal creates Chnl2IP_RdReq)
                            if (Access_Ctrl = '0') then
                                chnl_rnw_com <= '1';
                                chnlsm_ns    <= RD_OP_ADDR;
                            
                            -- Decode write operation early during 1st write in
                            -- Access buffer.
                            -- Read address from channel access buffer.
                            elsif (Access_Ctrl = '1') then  
                                chnl_rnw_com <= '0';
	                	if C_MCH_PROTOCOL=0 then
	                	  chnlsm_ns    <= WR_OP_ADDR;
	                	else        
	                	  chnlsm_ns    <= WR_OP_DXCL2_ADDR;
	                	end if;  
                            end if;                                  
                            
                        end if;                 
                        
                    -- If C_XCL_LINESIZE = 1, then only read one data word for
                    -- cacheline read operation, go ahead and finish 
                    -- transaction
                    elsif (C_XCL_LINESIZE = 1) then
                    
                         chnl_rdreq_com <= '0';
                         
                         -- Check if next operation is valid in channel access
                         -- buffer
                         -- If no operation is pending, proceed to IDLE state 
                         -- to wait for next transaction
                         if (Access_Exists = '0') then                        

                             chnl_select_com     <= '0';
                             ipic_addr_valid_com <= '0';
                             chnlsm_ns           <= IDLE;
                         
                        -- If subsequent operation is waiting in channel access
                        -- buffer
                        -- Then start next transaction (bypass IDLE state)
                        elsif (Access_Exists = '1') then
                                        
                            chnl_select_com     <= '1';
                            chnl_req_com        <= '1';
                            chnl_addr_valid_i   <= '1';
                            rd_access_buffer    <= '1';
                            ipic_addr_valid_com <= '1';
                            chnl_buf_ld         <= '1';    -- Clear channel 
                                                           -- buffer counter
                            
                            -- Decode read operation early during 1st write in 
                            -- Access buffer.
                            -- Read address from channel access buffer.
                            -- Assert chnl_rdreq_com to start read operation
                            -- (registered signal creates Chnl2IP_RdReq)
                            if (Access_Ctrl = '0') then
                                chnl_rnw_com  <= '1';
                                chnlsm_ns     <= RD_OP_ADDR;
                            
                            -- Decode write operation early during 1st write in
                            -- Access buffer.
                            -- Read address from channel access buffer.
                            elsif (Access_Ctrl = '1') then
                                chnl_rnw_com <= '0';
	                	if C_MCH_PROTOCOL=0 then
	                	  chnlsm_ns    <= WR_OP_ADDR;
	                	else        
	                	  chnlsm_ns    <= WR_OP_DXCL2_ADDR;
	                	end if;  
                            end if;                                  
                            
                        end if;                                          
                         
                    end if;
                end if;

            ---------------------- WAIT_LAST_ACK -------------------------
            when WAIT_LAST_ACK =>
                
                -- Only get to this state during a cacheline write 
                -- transaction
                -- Should be optimized away if C_XCL_LINESIZE = 1 or 
                -- C_XCL_WRITEXFER = 1 or C_XCL_WRITEXFER = 0
                
                chnl_rnw_com   <= '0';
                chnl_wrce_i    <= '1';
                chnl_burst_com <= '0';
                
                -- Wait for last IP2Chnl_Ack to be asserted
                if (IP2Chnl_Ack = '1') then                  
                    
                    -- Increment Ack counter
                    ack_cnt_en     <= '1';
                    
                    chnl_wrreq_com <= '0'; 

                    -- Check if next operation is valid in channel access
                    -- buffer.
                    -- If no operation is pending, proceed to IDLE state 
                    -- to wait for next transaction
                    if (Access_Exists = '0') then   
                    
                        chnl_select_com     <= '0';
                        ipic_addr_valid_com <= '0';
                        chnlsm_ns           <= IDLE; 
                        
                    -- If subsequent operation is waiting in channel access 
                    -- buffer
                    -- Then start next transaction (bypass IDLE state)
                    elsif (Access_Exists = '1') then
                        
                        chnl_select_com     <= '1';
                        chnl_req_com        <= '1';
                        chnl_addr_valid_i   <= '1';
                        chnl_buf_ld         <= '1';   -- Clear channel buffer 
                        ipic_addr_valid_com <= '1';   -- counter
                        rd_access_buffer    <= '1';
                        
                        -- Decode read operation early during 1st write in 
                        -- Access buffer.
                        -- Read address from channel access buffer.
                        -- Assert chnl_rdreq_com to start read operation 
                        -- (registered signal creates Chnl2IP_RdReq)
                        if (Access_Ctrl = '0') then
                            chnl_rnw_com <= '1';
                            chnlsm_ns    <= RD_OP_ADDR;
                        
                        -- Decode write operation early during 1st write in 
                        -- Access buffer.
                        -- Read address from channel access buffer.
                        elsif (Access_Ctrl = '1') then
                            chnl_rnw_com <= '0';
	                	if C_MCH_PROTOCOL=0 then
	                	  chnlsm_ns    <= WR_OP_ADDR;
	                	else        
	                	  chnlsm_ns    <= WR_OP_DXCL2_ADDR;
	                	end if;  
                        end if;                                  
                        
                    end if;                                          
                
                end if;
            --------------------------- DEFAULT -------------------------
            -- coverage off
            when others => 
                chnlsm_ns <= IDLE;
            -- coverage on
                
        end case;

    end process CHNLSM_CMB;

end imp;
