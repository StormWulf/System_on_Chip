-------------------------------------------------------------------------------
-- mem_state_machine.vhd - entity/architecture pair
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
-- Filename:        mem_state_machine.vhd
-- Description:     State machine controller for memory reads and writes
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--                  emc.vhd
--                      -- ipic_if.vhd
--                      -- addr_counter_mux.vhd
--                      -- counters.vhd
--                      -- select_param.vhd
--                      -- mem_state_machine.vhd
--                      -- mem_steer.vhd
--                      -- io_registers.vhd
-------------------------------------------------------------------------------
-- Author:          NSK
-- History:
-- NSK             02/01/08    First Version
-- ^^^^^^^^^^
-- This file is same as in version v2_01_c - no change in the logic of this 
-- module. Deleted the history from version v2_01_c.
-- ~~~~~~
-- NSK         05/08/08    version v3_00_a
-- ^^^^^^^^
-- 1. This file is same as in version v2_02_a.
-- 2. Upgraded to version v3.00.a to have proper versioning to fix CR #472164.
-- 3. No change in design.
--
-- KSB         05/08/08    version v4_00_a
-- ^^^^^^^^
-- 1. Modified for Page mdoe read
-- 2. Modified for 64 Bit memory address align
-- ~~~~~~~~
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- vcomponents package of the unisim library is used for the FDR component
-- declaration
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- Definition of Generics:
--
-- Definition of Ports:
-- The signal list is aligned as per the port list in entity
-------------------------------------------------------------------------------
--      Bus2IP_RNW                  -- Processor read/write transfer control
--      Bus2IP_RdReq                -- Processor Read Request
--      Bus2IP_WrReq                -- Processor Write Request
--      Synch_mem                   -- Current transaction is for synchronous
--                                     memory
--      Two_pipe_delay              -- Two pipe delay for synchronous memory
--      Cycle_End                   -- Current Cycle Complete

--      Read_data_en                -- Enable for read data registers
--      Read_ack                    -- Read cycle data acknowledge
--
--      Address_strobe              -- Address strobe signal
--      Data_strobe                 -- Data and BEs strobe signal

--      CS_Strobe                   -- Chip select strobe signal to store the
--                                  -- status of Bus2IP_CS

--      Addr_cnt_ce                 -- Address counter count enable
--      Addr_cnt_rst                -- Address counter reset
--      Cycle_cnt_ld                -- Cycle end counter count load
--      Cycle_cnt_en                -- Cycle end counter count enable
--
--      Trd_cnt_en                  -- Read Cycle Count Enable
--      Twr_cnt_en                  -- Write Cycle Count Enable
--      Trd_load                    -- Read Cycle Timer Load
--      Twr_load                    -- Write Cycle Timer Load
--      Thz_load                    -- Read Recovery to Write Timer Load
--      Tlz_load                    -- Write Recovery to Read Timer Load
--      Trd_end                     -- Read Cycle Complete
--      Twr_end                     -- Write Cycle Complete
--      Thz_end                     -- Read Recovery Complete
--      Tlz_end                     -- Write Recovery Complete
--      Tpacc_end                   -- page access read end
--
--      Mem_CEN_cmb                 -- Memory Chip Enable
--      Mem_OEN_cmb                 -- Memory Output Enable
--      Mem_WEN_cmb                 -- Memory Write Enable
--
--      Write_req_ack               -- Write address acknowledge
--      Read_req_ack                -- Read address acknowledge
--      Transaction_done            -- Operation complete indication for 
--                                  -- current transaction
--      Mem_Addr_rst                -- Memory address bus reset
--
--      Clk                         -- System Clock
--      Rst                         -- System Read
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Entity section
-----------------------------------------------------------------------------

entity mem_state_machine is
    port (
        Bus2IP_RNW          : in  std_logic;
        Bus2IP_RdReq        : in  std_logic;
        Bus2IP_WrReq        : in  std_logic;
        Synch_mem           : in  std_logic;
        Two_pipe_delay      : in  std_logic;
        Cycle_End           : in  std_logic;
        
        Read_data_en        : out std_logic;
        Read_ack            : out std_logic;

        Address_strobe      : out std_logic;
        Data_strobe         : out std_logic;
        CS_Strobe           : out std_logic;

        Addr_cnt_ce         : out std_logic;
        Addr_cnt_rst        : out std_logic;
        Cycle_cnt_ld        : out std_logic;
        Cycle_cnt_en        : out std_logic;

        Trd_cnt_en          : out std_logic;
        Twr_cnt_en          : out std_logic;
        Tpacc_cnt_en        : out std_logic;
        Trd_load            : out std_logic;
        Twr_load            : out std_logic;
        Tpacc_load          : out std_logic;
        Thz_load            : out std_logic;
        Tlz_load            : out std_logic;
        Trd_end             : in  std_logic;
        Twr_end             : in  std_logic;
        Thz_end             : in  std_logic;
        Tlz_end             : in  std_logic;
        Tpacc_end           : in  std_logic;
        
        New_page_access     : in  std_logic;

        MSM_Mem_CEN         : out std_logic;
        MSM_Mem_OEN         : out std_logic;
        MSM_Mem_WEN         : out std_logic;

        Write_req_ack       : out std_logic;
        Read_req_ack        : out std_logic;
        Transaction_done    : out std_logic;

        Mem_Addr_rst        : out std_logic;
        Addr_align          : in  std_logic; 
        Addr_align_rd       : out std_logic;   
    
        Clk                 : in  std_logic;
        Rst                 : in  std_logic
    );
end entity mem_state_machine;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture imp of mem_state_machine is

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------

type MEM_SM_TYPE is (IDLE,
             WRITE,
             DASSERT_WEN,
             WAIT_WRITE_ACK,
             READ,
             PAGE_READ,
             WAIT_RDDATA_ACK
             );

signal crnt_state               : MEM_SM_TYPE := IDLE;
signal next_state               : MEM_SM_TYPE;

signal write_req_ack_cmb        : std_logic;
signal read_req_ack_cmb         : std_logic;
signal read_data_en_cmb         : std_logic;
signal read_data_en_reg         : std_logic;

signal read_ack_cmb             : std_logic;
signal read_ack_reg             : std_logic;

signal addr_cnt_ce_cmb          : std_logic;
signal addr_cnt_rst_cmb         : std_logic;
signal addr_cnt_ce_reg          : std_logic;
signal addr_cnt_rst_reg         : std_logic;


signal addressData_strobe_cmb   : std_logic;
signal cs_strobe_cmb            : std_logic;
signal cs_strobe_reg            : std_logic;
signal cycle_cnt_ld_cmb         : std_logic;
signal cycle_cnt_en_cmb         : std_logic;

signal trd_cnt_en_cmb           : std_logic;
signal twr_cnt_en_cmb           : std_logic;
signal tpacc_cnt_en_cmb         : std_logic;

signal trd_load_cmb             : std_logic;
signal twr_load_cmb             : std_logic;
signal thz_load_cmb             : std_logic;
signal tlz_load_cmb             : std_logic;
signal tpacc_load_cmb           : std_logic;

signal new_page			: std_logic;
signal new_page_d1      	: std_logic;


signal mem_cen_cmb              : std_logic;
signal mem_oen_cmb              : std_logic;
signal mem_wen_cmb              : std_logic;
signal mem_cen_reg              : std_logic;
signal mem_oen_reg              : std_logic;
signal mem_wen_reg              : std_logic;

signal read_complete_cmb        : std_logic;
signal read_complete_d          : std_logic_vector(0 to 7);
signal read_complete            : std_logic;

signal mem_Addr_rst_cmb         : std_logic;

signal transaction_done_cmb     : std_logic;
signal transaction_done_reg     : std_logic;

signal addr_align_reg           : std_logic;
signal addr_align_rd_d1     : std_logic;



-------------------------------------------------------------------------------
-- Begin architecture
-------------------------------------------------------------------------------

begin

Write_req_ack       <= write_req_ack_cmb;
Read_req_ack        <= read_req_ack_cmb;
Read_data_en        <= read_data_en_reg;
Read_ack            <= Read_ack_reg;
Read_ack_cmb        <= read_data_en_cmb and Cycle_End;

Addr_cnt_ce         <= addr_cnt_ce_reg;
Addr_cnt_rst        <= addr_cnt_rst_reg;
Address_strobe      <= addressData_strobe_cmb;
CS_Strobe           <= cs_strobe_reg;

Cycle_cnt_ld        <= cycle_cnt_ld_cmb;
Cycle_cnt_en        <= cycle_cnt_en_cmb;

Trd_cnt_en          <= trd_cnt_en_cmb;
Tpacc_cnt_en        <= tpacc_cnt_en_cmb;
Twr_cnt_en          <= twr_cnt_en_cmb;
Trd_load            <= trd_load_cmb;
Tpacc_load          <= tpacc_load_cmb;
Twr_load            <= twr_load_cmb;
Thz_load            <= thz_load_cmb;
Tlz_load            <= tlz_load_cmb;

MSM_Mem_CEN         <= mem_cen_reg;
MSM_Mem_OEN         <= mem_oen_reg;
MSM_Mem_WEN         <= mem_wen_reg;

Mem_Addr_rst        <= mem_Addr_rst_cmb;
Transaction_done    <= transaction_done_reg;

-------------------------------------------------------------------------------
-- Controls the flow of Read and write transaction performed based on type of
-- memory (synchronous/asynchronous) connected.
-------------------------------------------------------------------------------

SM_COMB_PROCESS: process (
          crnt_state,
              Bus2IP_RNW,
              Bus2IP_RdReq,
              Bus2IP_WrReq,
              Synch_mem,
              Cycle_End,
              Trd_end,
              Tpacc_end,
              Twr_end,
              Thz_end,
              Tlz_end,
              Addr_align,
              New_page_access,
              new_page,
              read_complete
              
              )

    begin

        next_state              <= crnt_state;
        mem_cen_cmb             <= '1';
        mem_oen_cmb             <= '1';
        mem_wen_cmb             <= '1';

        write_req_ack_cmb       <= '0';
        read_req_ack_cmb        <= '0';
        read_data_en_cmb        <= '0';
        addr_cnt_ce_cmb         <= '0';
        addr_cnt_rst_cmb        <= '0';
        addressData_strobe_cmb  <= '0';
        cs_strobe_cmb           <= '0';
        cycle_cnt_ld_cmb        <= '0';
        cycle_cnt_en_cmb        <= '0';

        trd_cnt_en_cmb          <= '0';
        tpacc_cnt_en_cmb        <= '0';
        twr_cnt_en_cmb          <= '0';
        trd_load_cmb            <= '0';
        tpacc_load_cmb          <= '0';
        twr_load_cmb            <= '0';
        thz_load_cmb            <= '0';
        tlz_load_cmb            <= '0';
        read_complete_cmb       <= '0';
        addr_align_reg  	<= addr_align_rd_d1;
        new_page		<= new_page_d1;

        mem_Addr_rst_cmb        <= '0';
        transaction_done_cmb    <= '0';

        case crnt_state is

            -------------------------------------------------------------------
            -- IDLE STATE
            -- Waits in this state untill read and write transaction is
            -- initiated.
            -- Loads the counters.
            -- Generates appropriate gate signal (burst/single) which is used
            -- to let read transfer ack pass to the IPIF.
            -------------------------------------------------------------------

            when IDLE =>

                transaction_done_cmb    <= '1';
                addressData_strobe_cmb  <= '1';
                addr_cnt_rst_cmb        <= '1';
                cycle_cnt_ld_cmb        <= '1';
                cs_strobe_cmb           <= '1';
                mem_Addr_rst_cmb        <= '1';
                new_page       		<= '0';
        	addr_align_reg          <= '0';
                if (Bus2IP_WrReq = '1' and Thz_end = '1') then
                    twr_load_cmb       <= '1';
                    write_req_ack_cmb  <= '1';
                    next_state         <= WRITE;
                    transaction_done_cmb    <= '0';
                    addr_align_reg  	<= '0';
                elsif (Bus2IP_RdReq = '1' and Tlz_end = '1') then
                    read_req_ack_cmb   <= '1';
                    trd_load_cmb       <= '1';
                    next_state         <= READ;
                    transaction_done_cmb    <= '0';
                    addr_align_reg  <= Addr_align;
                end if;

            -------------------------------------------------------------------
            -- WRITE STATE
            -- Controls write operation to the memory.
            -- Generates control signals for write, address, and cycle end
            -- counters.
            -------------------------------------------------------------------

            when WRITE =>

                
                mem_cen_cmb  <= '0';
                mem_wen_cmb  <= '0';

                if (Twr_end = '1') then
                    if Synch_mem = '1' then
                        if (Cycle_End = '1') then
                            if (Bus2IP_WrReq = '1') then
                                write_req_ack_cmb      <= '1';
                                addressData_strobe_cmb <= '1';
                                addr_cnt_rst_cmb       <= '1';
                                cycle_cnt_ld_cmb       <= '1';
                                twr_load_cmb           <= '1';
                            else
                                next_state             <= WAIT_WRITE_ACK;
                            end if;
                        else
                            twr_load_cmb      <= '1';
                            cycle_cnt_en_cmb  <= '1';
                            addr_cnt_ce_cmb   <= '1';
                        end if;
                    else

                        next_state  <= DASSERT_WEN;

                    end if;
                else
                    twr_cnt_en_cmb  <= '1';
                end if;

            -------------------------------------------------------------------
            -- DASSERT_WEN STATE
            -- Comes to this state only when write operation is performed on
            -- asynchronous memory.This state performs NOP cycle on memory side.
            -- Generates control signals for write, address and cycle end
            -- counters.
            -------------------------------------------------------------------

            when DASSERT_WEN =>

                
                if (Cycle_End = '1') then
                    if (Bus2IP_WrReq = '1') then
                        write_req_ack_cmb      <= '1';
                        addressData_strobe_cmb <= '1';
                        addr_cnt_rst_cmb       <= '1';
                        cycle_cnt_ld_cmb       <= '1';
                        twr_load_cmb           <= '1';
                        next_state             <= WRITE;
                    else
                        next_state             <= WAIT_WRITE_ACK;
                    end if;
                else
                    twr_load_cmb      <= '1';
                    cycle_cnt_en_cmb  <= '1';
                    addr_cnt_ce_cmb   <= '1';
                    next_state        <= WRITE;
                end if;

            -------------------------------------------------------------------
            -- WAIT_WRITE_ACK STATE
            -------------------------------------------------------------------

            when WAIT_WRITE_ACK =>

                    next_state    <= IDLE;
                    tlz_load_cmb  <= '1';

            -------------------------------------------------------------------
            -- READ STATE
            -- Controls read operation on memory.
            -- Generates control signals for read, address and cycle end
            -- counters
            -------------------------------------------------------------------

            when READ =>

                
                mem_cen_cmb    <= '0';
                mem_oen_cmb    <= '0';
                new_page       <= '0';
                -- added for abort condition
		if (Trd_end = '1') then
                    read_data_en_cmb  <= '1';
                    addr_align_reg  <= Addr_align;
                    if (Cycle_End = '1') then
                        if (Bus2IP_RdReq = '1') then
                            read_req_ack_cmb       <= '1';
                            addressData_strobe_cmb <= '1';
                            addr_cnt_rst_cmb       <= '1';
                            cycle_cnt_ld_cmb       <= '1';
                            If New_page_access = '0' then
                        	next_state         <= PAGE_READ;
                                tpacc_load_cmb     <= '1';
                            else
                                trd_load_cmb       <= '1';                            
                                next_state         <= READ;
                            end if;                            
                        else
                            next_state             <= WAIT_RDDATA_ACK;
                            read_complete_cmb      <= '1';
                        end if;
                    else
                            trd_load_cmb           <= '1';
                            cycle_cnt_en_cmb       <= '1';
                            addr_cnt_ce_cmb        <= '1';
                    end if;
                else
                    trd_cnt_en_cmb  <= '1';
                end if;
                
            -------------------------------------------------------------------
            -- PAGE_READ State =>
            -- Will do a page read when ever there is a page aligned boundry
            -------------------------------------------------------------------                
            when PAGE_READ =>
            
            
                mem_cen_cmb    <= '0';
                mem_oen_cmb    <= '0';

                -- added for abort condition
                if (Tpacc_end = '1') then
                    addr_align_reg  <= Addr_align;
                    read_data_en_cmb  <= '1';
                    if (Cycle_End = '1') then
                        if (Bus2IP_RdReq = '1') then
                            read_req_ack_cmb       <= '1';
                            addressData_strobe_cmb <= '1';
                            addr_cnt_rst_cmb       <= '1';
                            cycle_cnt_ld_cmb       <= '1';
                            If new_page = '0' then
                                tpacc_load_cmb     <= '1';
                        	next_state         <= PAGE_READ;
                            else
                            	trd_load_cmb       <= '1';
                            	next_state         <= READ;
                            end if;
                        else
                            next_state             <= WAIT_RDDATA_ACK;
                            read_complete_cmb      <= '1';
                        end if;
                    else
                            tpacc_load_cmb         <= '1';
                            cycle_cnt_en_cmb       <= '1';
                            addr_cnt_ce_cmb        <= '1';
                    end if;
                else
                    tpacc_cnt_en_cmb  <= '1';
                    if New_page_access = '1' then
                    	new_page <= '1';
                    end if;	
                end if;            
            
            

            -------------------------------------------------------------------
            -- WAIT_RDDATA_ACK STATE
            -- Waits in this state till read data is received from memory.
            -------------------------------------------------------------------

            when WAIT_RDDATA_ACK =>

                if read_complete = '1' then
                    next_state    <= IDLE;
                    thz_load_cmb  <= '1';
                end if;
                    addr_align_reg  <= Addr_align;
                    new_page 	    <= '0';
                

        end case;
    end process SM_COMB_PROCESS;

    ---------------------------------------------------------------------------
    -- Read complete generation logic.
    -- 2 pipe stages = read command delay from State machine to IO reg.
    -- Delay require to get the data from memory.
    -- 1 pipe stage = Data coming from memory is registered first in IO reg and
    -- then goes to data steering logic.
    -- 2 pipe stage = Async memory, 3 pipe stage = sync memory (PipeDelay=1),
    -- 4 pipe stage = sync memory (PipeDelay=2).
    ---------------------------------------------------------------------------

    read_complete       <= read_complete_d(5) when Synch_mem = '0' else
                       read_complete_d(6) when (Synch_mem = '1' and
                                                Two_pipe_delay = '0') else
                       read_complete_d(7);
    read_complete_d(0)  <= read_complete_cmb;
    
   --test_sig <= '1' when New_page_access = '1' else 
   -- '0' when crnt_state = PAGE_READ;

    READ_COMPLETE_PIPE_GEN : for i in 0 to 6 generate

        READ_COMPLETE_PIPE: FDR
            port map (
                Q   => read_complete_d(i+1), --[out]
                C   => Clk,                  --[in]
                D   => read_complete_d(i),   --[in]
                R   => Rst                   --[in]
              );
    end generate READ_COMPLETE_PIPE_GEN;

    ---------------------------------------------------------------------------
    -- Register state_machine states.
    ---------------------------------------------------------------------------

    REG_STATES_PROCESS : process (Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if(Rst = '1')then
                    crnt_state <= IDLE;
                else
                    crnt_state <= next_state;
                end if;
            end if;
        end process REG_STATES_PROCESS;

    ADDR_ALLIGN_PROCESS : process (Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if(Rst = '1')then
                    Addr_align_rd    <= '0';
                    addr_align_rd_d1 <= '0';
                    new_page_d1	     <= '0'; 	
                else
                    new_page_d1      <= new_page; 	
                    addr_align_rd_d1 <= addr_align_reg;
                    Addr_align_rd    <= addr_align_rd_d1;
                end if;
            end if;
        end process ADDR_ALLIGN_PROCESS ;    

    ---------------------------------------------------------------------------
    -- Register memory control signals.
    ---------------------------------------------------------------------------

    MEM_SIGNALS_REG_PROCESS :process(Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if (Rst = '1') then
                    mem_cen_reg  <='1';
                    mem_oen_reg  <='1';
                    mem_wen_reg  <='1';
                else
                    mem_cen_reg  <=mem_cen_cmb;
                    mem_oen_reg  <=mem_oen_cmb;
                    mem_wen_reg  <=mem_wen_cmb;
                end if;
            end if;
        end process MEM_SIGNALS_REG_PROCESS;

    ---------------------------------------------------------------------------
    -- Data strobe creation process. Used as strobe signal for Bus2Ip_Data and
    -- Bus2IP_BE.
    ---------------------------------------------------------------------------

    DATA_STROBE_PROCESS :process(Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if (Rst = '1') then
                    Data_strobe  <='0';
                else
                    Data_strobe  <= addressData_strobe_cmb;
                end if;
            end if;
        end process DATA_STROBE_PROCESS;

    ---------------------------------------------------------------------------
    -- Register Addr_cnt control signals. 
    ---------------------------------------------------------------------------

    ADDR_CNT_REG_PROCESS : process (Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if(Rst = '1')then
                    addr_cnt_ce_reg <= '0';
                    addr_cnt_rst_reg<= '0';
                else
                    addr_cnt_ce_reg <= addr_cnt_ce_cmb;
                    addr_cnt_rst_reg<= addr_cnt_rst_cmb;
                end if;
            end if;
        end process ADDR_CNT_REG_PROCESS;

    ---------------------------------------------------------------------------
    -- Register cs_strobe_cmb signal.
    ---------------------------------------------------------------------------

    CS_STROBE_REG_PROCESS : process (Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if(Rst = '1')then
                    cs_strobe_reg <= '0';
                else
                    cs_strobe_reg <= cs_strobe_cmb;
                end if;
            end if;
        end process CS_STROBE_REG_PROCESS;

    ---------------------------------------------------------------------------
    -- Register read_data_en_cmb signal.
    ---------------------------------------------------------------------------

    READ_DATA_EN_REG_PROCESS : process (Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if(Rst = '1')then
                    read_data_en_reg <= '0';
                else
                    read_data_en_reg <= read_data_en_cmb;
                end if;
            end if;
        end process READ_DATA_EN_REG_PROCESS;

    ---------------------------------------------------------------------------
    -- Register transaction_done_cmb signal.
    ---------------------------------------------------------------------------

    TRAN_DONE_REG_PROCESS : process (Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if(Rst = '1')then
                    transaction_done_reg <= '0';
                else
                    transaction_done_reg <= transaction_done_cmb;
                end if;
            end if;
        end process TRAN_DONE_REG_PROCESS;

    ---------------------------------------------------------------------------
    -- Register read_ack_cmb signal.
    ---------------------------------------------------------------------------

    READ_ACK_REG_PROCESS : process (Clk)
        begin
            if(Clk'EVENT and Clk = '1')then
                if(Rst = '1')then
                    read_ack_reg <= '0';
                else
                    read_ack_reg <= read_ack_cmb;
                end if;
            end if;
        end process READ_ACK_REG_PROCESS;

    end architecture imp;

-------------------------------------------------------------------------------
-- End of File mem_state_machine.vhd
-------------------------------------------------------------------------------
