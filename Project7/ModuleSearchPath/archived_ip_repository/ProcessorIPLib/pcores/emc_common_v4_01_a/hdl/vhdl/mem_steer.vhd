-------------------------------------------------------------------------------
-- mem_steer.vhd - entity/architecture pair
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
-- Filename:        mem_steer.vhd
-- Description:     This file contains the logic for steering the read data,
--                  write data and memory controls to the appropriate memory
--                  and data byte lane.
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
-- NSK         02/12/08    Updated
-- ^^^^^^^^
-- Removed the unused part of code (not supporting C_MAX_MEM_WIDTH = 64): -
-- 1. Deleted the generate block lebelled "WRITE_DATABE_MUX_64_GEN".
-- 2. Deleted the generate block lebelled "READ_DATA_64_GEN".
-- Removed the unused part of code (not supporting C_IPIF_DWIDTH = 64): -
-- 1. Deleted the generate block lebelled "READ_DATA_CE_64_GEN".
-- ~~~~~~~~
-- NSK         05/08/08    version v3_00_a
-- ^^^^^^^^
-- 1. This file is same as in version v2_02_a.
-- 2. Upgraded to version v3.00.a to have proper versioning to fix CR #472164.
-- 3. No change in design.

-- KSB 	       05/08/08    version v4_00_a
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- proc common package of the proc common library is used for the function
-- declarations
-------------------------------------------------------------------------------

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.all;

-------------------------------------------------------------------------------
-- vcomponents package of the unisim library is used for the FDS, FDR and FDCE
-- component declarations
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- Definition of Generics:

--      C_NUM_BANKS_MEM             -- Number of Memory Banks
--      C_MAX_MEM_WIDTH             -- Maximum memory width of all memory banks
--      C_MIN_MEM_WIDTH             -- Minimum memory width (set to 8 bits)    
--      C_IPIF_DWIDTH               -- Width of IPIF data bus           
--      C_ADDR_CNTR_WIDTH           -- Width of address counter     
--      C_GLOBAL_DATAWIDTH_MATCH    -- Indicates if datawidth matching is 
--                                     implemented in any memory bank
--      C_GLOBAL_SYNC_MEM           -- Indicates if any memory bank is 
--                                     synchronous      
--
-- Definition of Ports:

-- EMC signals    
--      Bus2IP_Data                 -- Processor Data Bus     
--      Bus2IP_BE                   -- Processor Byte Enable     
--      Bus2IP_Mem_CS               -- Memory Channel Chip Select
--
-- Memory state machine signals
--      Write_req_ack               -- Memory Write Acknowledge
--      Read_req_ack                -- Memory Read Address Acknowledge
--      Read_ack                    -- Memory Read Acknowledge
--      Read_data_en                -- Read Data Enable for read registers
--      Data_strobe                 -- Data Strobe signal 
--      MSM_Mem_CEN                 -- Memory Chip Enable
--      MSM_Mem_OEN                 -- Memory Output Enable
--      MSM_Mem_WEN                 -- Memory Write Enable
--      Mem2Bus_WrAddrAck           -- Memory Write Address Acknowledge
--      Mem2Bus_WrAck               -- Memory Write Data Acknowledge
--      Mem2Bus_RdAddrAck           -- Memory Read Address Acknowledge
--      Mem2Bus_RdAck               -- Memory Read Data Acknowledge
--      Mem2Bus_Data                -- Memory Read Data

-- Select Param signals        
--      Mem_width_bytes             -- Memory Device Width in Bytes
--      Synch_mem                   -- Synchronous Memory Control
--      Two_pipe_delay              -- Synchronous pipeline stages

-- Addr counter mux signals
--      Addr_cnt                    -- Address Count

-- IO Register signals    
--      MemSteer_Mem_DQ_I           -- Memory Device Data In
--      MemSteer_Mem_DQ_O           -- Memory Device Data Out
--      MemSteer_Mem_DQ_T           -- Memory Device FPGA Impedance Control
--      MemSteer_Mem_CEN            -- Memory Device Chip Enable (Active Low)
--      MemSteer_Mem_OEN            -- Memory Device Output Enable
--      MemSteer_Mem_WEN            -- Memory Device Write Enable
--      MemSteer_Mem_QWEN           -- Memory Device Qualified Write Enabled
--      MemSteer_Mem_BEN            -- Memory Device Byte Enable
--      MemSteer_Mem_CE             -- Memory Device Chip Enable (Active High)
--      MemSteer_Mem_RNW            -- Memory Device Read/Write 
--
--  Clock and reset 
--      Clk                         -- System Clock
--      Rst                         -- System Reset
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity mem_steer is
    generic ( 
        C_NUM_BANKS_MEM           : integer;
        C_MAX_MEM_WIDTH           : integer;
        C_MIN_MEM_WIDTH           : integer;
        C_IPIF_DWIDTH             : integer;
        C_ADDR_CNTR_WIDTH         : integer range 1 to 5;
        C_GLOBAL_DATAWIDTH_MATCH  : integer range 0 to 1;
        C_GLOBAL_SYNC_MEM         : integer range 0 to 1
    );
    port (
        -- EMC signals    
        Bus2IP_Data         : in  std_logic_vector(0 to C_IPIF_DWIDTH-1);
        Bus2IP_BE           : in  std_logic_vector(0 to C_IPIF_DWIDTH/8-1);
        Bus2IP_Mem_CS       : in  std_logic_vector(0 to C_NUM_BANKS_MEM-1);

        -- Memory state machine signals
        Write_req_ack       : in  std_logic;
        Read_req_ack        : in  std_logic;
        Read_ack            : in  std_logic;
        Read_data_en        : in  std_logic;
        Data_strobe         : in  std_logic;        
        MSM_Mem_CEN         : in  std_logic;
        MSM_Mem_OEN         : in  std_logic;
        MSM_Mem_WEN         : in  std_logic;
        Mem2Bus_WrAddrAck   : out std_logic;
        Mem2Bus_WrAck       : out std_logic;
        Mem2Bus_RdAddrAck   : out std_logic;
        Mem2Bus_RdAck       : out std_logic;
        Mem2Bus_Data        : out std_logic_vector(0 to C_IPIF_DWIDTH - 1);

        -- Select param signals        
        Mem_width_bytes     : in  std_logic_vector(0 to 3);
        Synch_mem           : in  std_logic;
        Two_pipe_delay      : in  std_logic;
 
        -- Addr counter mux signal
        Addr_cnt            : in  std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
        Addr_align          : in  std_logic;
        Addr_align_rd       : in  std_logic;
        
        -- IO register signals    
        MemSteer_Mem_DQ_I   : in  std_logic_vector(0 to C_MAX_MEM_WIDTH-1); 
        MemSteer_Mem_DQ_O   : out std_logic_vector(0 to C_MAX_MEM_WIDTH-1); 
        MemSteer_Mem_DQ_T   : out std_logic_vector(0 to C_MAX_MEM_WIDTH-1); 
        MemSteer_Mem_CEN    : out std_logic_vector(0 to C_NUM_BANKS_MEM-1); 
        MemSteer_Mem_OEN    : out std_logic_vector(0 to C_NUM_BANKS_MEM-1); 
        MemSteer_Mem_WEN    : out std_logic; 
        MemSteer_Mem_QWEN   : out std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
        MemSteer_Mem_BEN    : out std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
        MemSteer_Mem_CE     : out std_logic_vector(0 to C_NUM_BANKS_MEM-1);
        MemSteer_Mem_RNW    : out std_logic; 

        -- Clock and reset
        Clk                 : in  std_logic;
        Rst                 : in  std_logic
    );
end entity mem_steer;

-------------------------------------------------------------------------------
-- Architecture section
-------------------------------------------------------------------------------

architecture imp of mem_steer is

-------------------------------------------------------------------------------
-- Constant declarations
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Signal declarations
-------------------------------------------------------------------------------
signal mem_cen_cmb          : std_logic;
signal mem_oen_cmb          : std_logic;
signal read_ack_d           : std_logic_vector(0 to 5);
signal addr_align_d         : std_logic_vector(0 to 5);
signal addr_align_read	    : std_logic;
signal write_data           : std_logic_vector(0 to C_IPIF_DWIDTH-1);
signal write_data_cmb       : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal read_data            : std_logic_vector(0 to C_IPIF_DWIDTH-1);
signal write_data_d1        : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal write_data_d2        : std_logic_vector(0 to C_MAX_MEM_WIDTH-1);
signal mem_be_i             : std_logic_vector(0 to C_MAX_MEM_WIDTH/8-1);
signal mem_dq_t_cmb         : std_logic_vector(0 to 3);
signal addr_cnt_d1          : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
signal addr_cnt_d2          : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1); 
signal addr_cnt_d3          : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
signal addr_cnt_d4          : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
signal addr_cnt_sel         : std_logic_vector(0 to C_ADDR_CNTR_WIDTH-1);
signal mem_dqt_t_d          : std_logic;
signal mem_dqt_t_async      : std_logic;
signal read_data_ce         : std_logic_vector(0 to 7);
signal read_data_en_d       : std_logic_vector(0 to 4);
signal read_data_en_sel     : std_logic;

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
function "and"  ( l : std_logic_vector; r : std_logic )
return std_logic_vector is
    variable rex : std_logic_vector(l'range);
begin
    rex := (others => r);
    return( l and rex );
end function "and";

-------------------------------------------------------------------------------
-- Begin Architecture
-------------------------------------------------------------------------------

begin  -- architecture imp

MemSteer_Mem_BEN   <= not mem_be_i; 
MemSteer_Mem_RNW   <= MSM_Mem_WEN;
MemSteer_Mem_QWEN  <= not(mem_be_i and (not MSM_Mem_WEN));
MemSteer_Mem_WEN   <= MSM_Mem_WEN;

-------------------------------------------------------------------------------
-- Memory chip enable control generation.
-------------------------------------------------------------------------------

mem_cen_cmb  <= MSM_Mem_CEN;

MEM_CEN_SINGLE_BANK_GEN: if C_NUM_BANKS_MEM = 1 generate
begin
    MemSteer_Mem_CEN(0)  <= mem_cen_cmb;
    MemSteer_Mem_CE(0)   <= not mem_cen_cmb;
end generate MEM_CEN_SINGLE_BANK_GEN;

-------------------------------------------------------------------------------
-- Generate chip enable signals for multiple memory banks.
-------------------------------------------------------------------------------

MEM_CEN_MULTI_BANK_GEN: if C_NUM_BANKS_MEM > 1 generate
begin

-------------------------------------------------------------------------------
-- Chip enable steer process steers the chip enable to the corresponding memory
-- bank.
-------------------------------------------------------------------------------

MEM_CEN_STEER_PROCESS: process(mem_cen_cmb, Bus2IP_Mem_CS)
    begin
        MemSteer_Mem_CEN  <= (others => '1');
        MemSteer_Mem_CE   <= (others => '0');
        for i in 0 to C_NUM_BANKS_MEM -1 loop
            if(Bus2IP_Mem_CS(i) = '1')then
                MemSteer_Mem_CEN(i)  <= mem_cen_cmb;
                MemSteer_Mem_CE(i)   <= not mem_cen_cmb;
            end if;
        end loop;
    end process MEM_CEN_STEER_PROCESS;

end generate MEM_CEN_MULTI_BANK_GEN;

-------------------------------------------------------------------------------
-- Memory output enable control generation.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 1 -------------------------------
-------------------------------------------------------------------------------

SYNC_MEM_OEN : if C_GLOBAL_SYNC_MEM = 1 generate
    signal mem_oen_d            : std_logic_vector(0 to 2);
    signal mem_oen_sync         : std_logic;
begin
    mem_oen_d(0)  <= MSM_Mem_OEN;

-------------------------------------------------------------------------------
-- FDS primitive is used for output enable pipe generation.
-------------------------------------------------------------------------------
    
    OEN_PIPE_GEN : for i in 0 to 1 generate
    begin
        OEN_PIPE: FDS
            port map (
                Q   => mem_oen_d(i+1), --[out]
                C   => Clk,            --[in]
                D   => mem_oen_d(i),   --[in]
                S   => Rst             --[in]
                );
    end generate OEN_PIPE_GEN;
    mem_oen_sync  <= mem_oen_d(2) and mem_oen_d(1) when Two_pipe_delay = '1'
    		     else mem_oen_d(1) and mem_oen_d(0);
    mem_oen_cmb   <= mem_oen_d(0) when Synch_mem = '0'
    		     else mem_oen_sync;
end generate SYNC_MEM_OEN;

-------------------------------------------------------------------------------
-- Generate output enable signals when C_GLOBAL_STNC_MEM = 0.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 0 -------------------------------
-------------------------------------------------------------------------------

ASYNC_MEM_OEN : if C_GLOBAL_SYNC_MEM = 0 generate
begin
    mem_oen_cmb  <= MSM_Mem_OEN;                 
end generate ASYNC_MEM_OEN;

-------------------------------------------------------------------------------
-- Generate output enable signals for multiple memory banks.
-------------------------------------------------------------------------------
MEM_OEN_SINGLE_BANK_GEN: if C_NUM_BANKS_MEM = 1 generate
begin
    MemSteer_Mem_OEN(0)  <= mem_oen_cmb;          
end generate MEM_OEN_SINGLE_BANK_GEN;

-------------------------------------------------------------------------------
-- Generate output enable signals for multiple memory banks.
-------------------------------------------------------------------------------

MEM_OEN_MULTI_BANK_GEN: if C_NUM_BANKS_MEM > 1 generate
begin

-------------------------------------------------------------------------------
-- Output enable steer process is used to steer the output enable to the 
-- corresponding memory bank.
-------------------------------------------------------------------------------

    MEM_OEN_STEER_PROCESS: process(mem_oen_cmb, Bus2IP_Mem_CS)
    begin
        MemSteer_Mem_OEN  <= (others => '1');
        for i in 0 to C_NUM_BANKS_MEM -1 loop
            if(Bus2IP_Mem_CS(i) = '1')then
                MemSteer_Mem_OEN(i)  <= mem_oen_cmb;
            end if;
        end loop;
    end process MEM_OEN_STEER_PROCESS;
    
end generate MEM_OEN_MULTI_BANK_GEN;

-------------------------------------------------------------------------------
-- Address and Data ack generation.
-------------------------------------------------------------------------------

Mem2Bus_WrAddrAck  <= Write_req_ack;
Mem2Bus_WrAck      <= Write_req_ack;
Mem2Bus_RdAddrAck  <= Read_req_ack;
read_ack_d(0)      <= Read_ack;

addr_align_d(0)    <=  Addr_align_rd;

-------------------------------------------------------------------------------
-- Geneartion of Mem2Bus_RdAck signal when external memory bank has at least
-- one synchronous memory
-------------------------------------------------------------------------------

GSYNC_MEM_RDACK_GEN : if C_GLOBAL_SYNC_MEM = 1 generate
begin

    ---------------------------------------------------------------------------
    -- Read ack pipe generation.
    ---------------------------------------------------------------------------

    RDACK_PIPE_GEN_SYNC : for i in 0 to 3 generate
    begin
    ---------------------------------------------------------------------------
    -- FDR primitive is used for read data ack pipe generation.
    ---------------------------------------------------------------------------
        RDACK_PIPE_SYNC: FDR
            port map (
                Q   => read_ack_d(i+1), --[out]
                C   => Clk,             --[in]
                D   => read_ack_d(i),   --[in]
                R   => Rst              --[in]
                );      
    end generate RDACK_PIPE_GEN_SYNC;

    Mem2Bus_RdAck      <= read_ack_d(2) when (Synch_mem = '0') else
                          read_ack_d(3) when 
                            Synch_mem = '1' and (Two_pipe_delay = '0') else
                          read_ack_d(4);
      
      
      
    ADDR_ALIGN_PIPE_GEN : for i in 0 to 3 generate
    begin
    ---------------------------------------------------------------------------
    -- FDR primitive is used for Address align pipe generation.
    ---------------------------------------------------------------------------
    	ALIGN_PIPE: FDR
        port map (
        	Q   => addr_align_d(i+1), --[out]
                C   => Clk,             --[in]
                D   => addr_align_d(i),   --[in]
                R   => Rst              --[in]
               );      
        end generate ADDR_ALIGN_PIPE_GEN;
      
    addr_align_read      <= addr_align_d(0)when Synch_mem = '0' else
                            addr_align_d(1) when 
                            	Synch_mem = '1' and Two_pipe_delay = '0' else
                            addr_align_d(2);
end generate GSYNC_MEM_RDACK_GEN;

-------------------------------------------------------------------------------
-- Geneartion of Mem2Bus_RdAck signal when external memory bank has only
-- asynchronous memory
-------------------------------------------------------------------------------

ASYNC_MEM_RDACK_GEN : if (C_GLOBAL_SYNC_MEM = 0) generate
begin
    ---------------------------------------------------------------------------
    -- Read ack pipe generation.
    ---------------------------------------------------------------------------
    RDACK_PIPE_GEN_ASYNC : for i in 0 to 1 generate
    begin
    ---------------------------------------------------------------------------
    -- FDR primitive is used for read data ack pipe generation.
    ---------------------------------------------------------------------------
        RDACK_PIPE_ASYNC: FDR
            port map (
                Q   => read_ack_d(i+1), --[out]
                C   => Clk,             --[in]
                D   => read_ack_d(i),   --[in]
                R   => Rst              --[in]
                );      
    end generate RDACK_PIPE_GEN_ASYNC;
    
    Mem2Bus_RdAck      <= read_ack_d(2);

    ---------------------------------------------------------------------------
    -- ADDR ALLIGN pipe generation.
    ---------------------------------------------------------------------------
    AALIGN_PIPE_GEN : for i in 0 to 1 generate
    begin
    ---------------------------------------------------------------------------
    -- FDR primitive is used for Address align pipe generation.
    ---------------------------------------------------------------------------
        AALIGN_PIPE: FDR
            port map (
                Q   => addr_align_d(i+1), --[out]
                C   => Clk,             --[in]
                D   => addr_align_d(i),   --[in]
                R   => Rst              --[in]
                );      
    end generate AALIGN_PIPE_GEN;
    
    addr_align_read      <= addr_align_d(0);    
end generate ASYNC_MEM_RDACK_GEN;

-------------------------------------------------------------------------------
-- Store the data coming from bus, as address ack and data ack is issued early, 
-- and to make burst appear as continuous on memory side.
-------------------------------------------------------------------------------

DATA_STORE_GEN: for i in 0 to C_IPIF_DWIDTH - 1 generate
begin

-------------------------------------------------------------------------------
-- FDCE primitive is used for latching Bus2IP_Data when Data_strobe = 1.
-------------------------------------------------------------------------------

    WRDATA_REG: FDRE
        port map (
            Q   => write_data(i),     --[out]
            C   => Clk,               --[in]
            CE  => Data_strobe,       --[in]
            D   => Bus2IP_Data(i),    --[in]
            R   => Rst                --[in]
            );

end generate DATA_STORE_GEN;

-------------------------------------------------------------------------------
-- When one of the memory bank has different data width than OPB/MCH data 
-- width, data steering logic is required.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------- C_GLOBAL_DATAWIDTH_MATCH = 1 ------------------------
-------------------------------------------------------------------------------

WRITE_DATABE_MUX_GEN: if C_GLOBAL_DATAWIDTH_MATCH = 1 generate
begin

-------------------------------------------------------------------------------
-- Write data path
-------------------------------------------------------------------------------
-- Write data mux is used to multiplex write_data out to memories. This will 
-- vary on whether the max memory data width is 8, 16, 32 or 64. Separate 
-- generate statements are used for each of them. If the memory is synchronous,
-- the BEs assert at the same time. However, the write data  goes out one or 
-- two clocks later (depending on Two_pipe_delay). Therefore, separate 
-- processes are used for the write data and byte enables. 
-------------------------------------------------------------------------------
WRITE_DATABE_MUX_64_GEN: if (C_MAX_MEM_WIDTH=64 and C_IPIF_DWIDTH=64) generate
begin

-------------------------------------------------------------------------------
-- Write data path for 64 bit maximum memory width. Write data mux process is 
-- used to multiplex the write_data depending on the addr_cnt.
-------------------------------------------------------------------------------

    WRITE_DATA_MUX_PROCESS_64: process(Mem_width_bytes, Addr_cnt, write_data)
    begin
                    write_data_cmb   <= (others => '0');
       case Mem_width_bytes is
          when "0001"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
                if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                    write_data_cmb(0 to C_MIN_MEM_WIDTH-1) <= 
                       write_data(i*C_MIN_MEM_WIDTH to 
                                  i*C_MIN_MEM_WIDTH + C_MIN_MEM_WIDTH-1);
                end if;
             end loop;
          when "0010" =>
              for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
                if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                    write_data_cmb(0 to 2*C_MIN_MEM_WIDTH-1) <=
                       write_data(i*2*C_MIN_MEM_WIDTH to
                                  i*2*C_MIN_MEM_WIDTH + 2*C_MIN_MEM_WIDTH-1);
                end if;
              end loop;
          when "0100" =>
              for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
                if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                    write_data_cmb(0 to 4*C_MIN_MEM_WIDTH-1) <=
                        write_data(i*4*C_MIN_MEM_WIDTH to
                                   i*4*C_MIN_MEM_WIDTH + 4*C_MIN_MEM_WIDTH-1);
                end if;
              end loop;
          when "1000" =>
                if Addr_cnt = conv_std_logic_vector(0, C_ADDR_CNTR_WIDTH) then
                    write_data_cmb(0 to C_MAX_MEM_WIDTH-1) <=
                        write_data(0 to C_MAX_MEM_WIDTH-1);
                end if;
          when others =>
                    write_data_cmb <= (others => '0');
       end case;
    end process WRITE_DATA_MUX_PROCESS_64;

-------------------------------------------------------------------------------
-- Write data path for 64 bit maximum memory width. Write byte enable mux 
-- process is used to multiplex the byte enable depending on the addr_cnt.
-------------------------------------------------------------------------------

    WRITE_BE_MUX_PROCESS_64: process(Mem_width_bytes, Addr_cnt, Bus2IP_BE)
    begin
                   mem_be_i      <= (others => '0');
       case Mem_width_bytes is
          when "0001"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*C_MIN_MEM_WIDTH/8 to
                                i*C_MIN_MEM_WIDTH/8 + C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "0010" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to 2*C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*2*C_MIN_MEM_WIDTH/8 to
                                i*2*C_MIN_MEM_WIDTH/8 + 2*C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "0100" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to 4*C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*4*C_MIN_MEM_WIDTH/8 to
                                i*4*C_MIN_MEM_WIDTH/8 + 4*C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "1000" =>
               if Addr_cnt = conv_std_logic_vector(0, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to C_MIN_MEM_WIDTH-1) <=
                      Bus2IP_BE(0 to C_MIN_MEM_WIDTH-1);
               end if;
          when others =>
                   mem_be_i   <= (others => '0');
       end case;
    end process WRITE_BE_MUX_PROCESS_64;
    
end generate WRITE_DATABE_MUX_64_GEN;
 
-------------------------------------------------------------------------------
-- Write data path
-------------------------------------------------------------------------------
-- Write data mux is used to multiplex write_data out to memories. This will 
-- vary on whether the max memory data width is 8, 16, 32 or 64. Separate 
-- generate statements are used for each of them. If the memory is synchronous,
-- the BEs assert at the same time. However, the write data  goes out one or 
-- two clocks later (depending on Two_pipe_delay). Therefore, separate 
-- processes are used for the write data and byte enables. 
-------------------------------------------------------------------------------
WRITE_DATABE_MUX_32_64_GEN: if (C_MAX_MEM_WIDTH=64 and 
					C_IPIF_DWIDTH=32) generate
begin

-------------------------------------------------------------------------------
-- Write data path for 64 bit maximum memory width. Write data mux process is 
-- used to multiplex the write_data depending on the addr_cnt.
-------------------------------------------------------------------------------

    WRITE_DATA_MUX_PROCESS_32_64: process(Mem_width_bytes, Addr_cnt, write_data, 
    								Addr_align)
    begin
                    write_data_cmb   <= (others => '0');
       case Mem_width_bytes is
          when "0001"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
                if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                    write_data_cmb(0 to C_MIN_MEM_WIDTH-1) <= 
                       write_data(i*C_MIN_MEM_WIDTH to 
                                  i*C_MIN_MEM_WIDTH + C_MIN_MEM_WIDTH-1);
                end if;
             end loop;
          when "0010" =>
              for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
                if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                    write_data_cmb(0 to 2*C_MIN_MEM_WIDTH-1) <=
                       write_data(i*2*C_MIN_MEM_WIDTH to
                                  i*2*C_MIN_MEM_WIDTH + 2*C_MIN_MEM_WIDTH-1);
                end if;
              end loop;
          when "0100" =>
              for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
                if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                    write_data_cmb(0 to 4*C_MIN_MEM_WIDTH-1) <=
                        write_data(i*4*C_MIN_MEM_WIDTH to
                                   i*4*C_MIN_MEM_WIDTH + 4*C_MIN_MEM_WIDTH-1);
                end if;
              end loop;
          when "1000" =>
               case (Addr_align) is
                 when '0' =>
                   write_data_cmb(0 to 4*C_MIN_MEM_WIDTH-1) <= write_data;
                   write_data_cmb(4*C_MIN_MEM_WIDTH to 8*C_MIN_MEM_WIDTH-1) 
                   					    <= (others => '0');
                 when '1' =>
                   write_data_cmb(0 to 4*C_MIN_MEM_WIDTH-1) <= (others => '0');
                   write_data_cmb(4*C_MIN_MEM_WIDTH to 8*C_MIN_MEM_WIDTH-1) 
                   				            <= write_data;
                 when others =>
                   write_data_cmb <= (others => '0'); 
                end case;
          when others =>
                    write_data_cmb <= (others => '0');
       end case;
    end process WRITE_DATA_MUX_PROCESS_32_64;

-------------------------------------------------------------------------------
-- Write data path for 64 bit maximum memory width. Write byte enable mux 
-- process is used to multiplex the byte enable depending on the addr_cnt.
-------------------------------------------------------------------------------

    WRITE_BE_MUX_PROCESS_32_64: process(Mem_width_bytes, Addr_cnt, Bus2IP_BE, 
    								Addr_align)
    begin
                   mem_be_i      <= (others => '0');
       case Mem_width_bytes is
          when "0001"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*C_MIN_MEM_WIDTH/8 to
                                i*C_MIN_MEM_WIDTH/8 + C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "0010" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to 2*C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*2*C_MIN_MEM_WIDTH/8 to
                                i*2*C_MIN_MEM_WIDTH/8 + 2*C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "0100" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to 4*C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*4*C_MIN_MEM_WIDTH/8 to
                                i*4*C_MIN_MEM_WIDTH/8 + 4*C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "1000" =>
            case Addr_align is
	      when '0' =>
	        mem_be_i(0 to 4*C_MIN_MEM_WIDTH/8-1)      <= Bus2IP_BE;
	        mem_be_i(4*C_MIN_MEM_WIDTH/8 to 8*C_MIN_MEM_WIDTH/8-1) 
	        					  <= (others => '0');
	      when '1' =>
	        mem_be_i(0 to 4*C_MIN_MEM_WIDTH/8-1)      <= (others => '0');
	        mem_be_i(4*C_MIN_MEM_WIDTH/8 to 8*C_MIN_MEM_WIDTH/8-1) 
	        					  <= Bus2IP_BE;
	      when others =>
                   mem_be_i   <= (others => '0');
            end case;
          when others =>
                   mem_be_i   <= (others => '0');
       end case;
    end process WRITE_BE_MUX_PROCESS_32_64;
    
end generate WRITE_DATABE_MUX_32_64_GEN;
 

-------------------------------------------------------------------------------
-- Write data byte enable generation for 32 bit.
-------------------------------------------------------------------------------

WRITE_DATABE_MUX_32_GEN: if (C_MAX_MEM_WIDTH=32) generate
begin

-------------------------------------------------------------------------------
-- Write data path for 32 bit maximum memory width. Write data mux process is 
-- used to multiplex the write_data depending on the addr_cnt.
-------------------------------------------------------------------------------

    WRITE_DATA_MUX_PROCESS_32: process(Mem_width_bytes, Addr_cnt, write_data)
    begin
                   write_data_cmb   <= (others => '0');
          case Mem_width_bytes(1 to 3) is
          when "001"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   write_data_cmb(0 to C_MIN_MEM_WIDTH-1) <=
                      write_data(i*C_MIN_MEM_WIDTH to 
                                 i*C_MIN_MEM_WIDTH + C_MIN_MEM_WIDTH-1);
               end if;
             end loop;
          when "010" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   write_data_cmb(0 to 2*C_MIN_MEM_WIDTH-1) <=
                      write_data(i*2*C_MIN_MEM_WIDTH to 
                                 i*2*C_MIN_MEM_WIDTH + 2*C_MIN_MEM_WIDTH-1);
               end if;
             end loop;
          when "100" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   write_data_cmb(0 to 4*C_MIN_MEM_WIDTH-1) <=
                      write_data(i*4*C_MIN_MEM_WIDTH to 
                                 i*4*C_MIN_MEM_WIDTH + 4*C_MIN_MEM_WIDTH-1);
               end if;
             end loop;
          when others =>
                   write_data_cmb <= (others => '0');
       end case;
    end process WRITE_DATA_MUX_PROCESS_32;

-------------------------------------------------------------------------------
-- Write data path for 32 Bit maximum memory width. Write byte enable mux 
-- process is used to multiplex the byte enable depending on the addr_cnt.
-------------------------------------------------------------------------------
         
    WRITE_BE_MUX_PROCESS_32: process(Mem_width_bytes, Addr_cnt, Bus2IP_BE)
    begin
                   mem_be_i      <= (others => '0');
          case Mem_width_bytes(1 to 3) is
          when "001"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*C_MIN_MEM_WIDTH/8 to 
                                i*C_MIN_MEM_WIDTH/8 + C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "010" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to 2*C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*2*C_MIN_MEM_WIDTH/8 to 
                                i*2*C_MIN_MEM_WIDTH/8 + 2*C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "100" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to 4*C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*4*C_MIN_MEM_WIDTH/8 to 
                                i*4*C_MIN_MEM_WIDTH/8 + 4*C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when others =>
                  mem_be_i   <= (others => '0');
       end case;
    end process WRITE_BE_MUX_PROCESS_32;
    
end generate WRITE_DATABE_MUX_32_GEN;

-------------------------------------------------------------------------------
-- Write data byte enable generation for 16 bit.
-------------------------------------------------------------------------------

WRITE_DATABE_MUX_16_GEN: if C_MAX_MEM_WIDTH=16 generate
begin

-------------------------------------------------------------------------------
-- Write data path for 16 bit maximum memory width. Write data mux process is 
-- used to multiplex the write_data depending on the addr_cnt.
-------------------------------------------------------------------------------

    WRITE_DATA_MUX_PROCESS_16: process(Mem_width_bytes, Addr_cnt, write_data)
    begin
                   write_data_cmb   <= (others => '0');
          case Mem_width_bytes(2 to 3) is
          when "01"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   write_data_cmb(0 to C_MIN_MEM_WIDTH-1) <=
                      write_data(i*C_MIN_MEM_WIDTH to 
                                 i*C_MIN_MEM_WIDTH + C_MIN_MEM_WIDTH-1);
               end if;
             end loop;
          when "10" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   write_data_cmb(0 to 2*C_MIN_MEM_WIDTH-1) <=
                      write_data(i*2*C_MIN_MEM_WIDTH to 
                                 i*2*C_MIN_MEM_WIDTH + 2*C_MIN_MEM_WIDTH-1);
               end if;
             end loop;
          when others =>
                   write_data_cmb <= (others => '0');
       end case;
    end process WRITE_DATA_MUX_PROCESS_16;

-------------------------------------------------------------------------------
-- Write data path for 16 bit maximum memory width. Write byte enable mux 
-- process is  used to multiplex the byte enable depending on the addr_cnt.
-------------------------------------------------------------------------------
    
    WRITE_BE_MUX_PROCESS_16: process(Mem_width_bytes, Addr_cnt, Bus2IP_BE)
    begin
                   mem_be_i      <= (others => '0');
          case Mem_width_bytes(2 to 3) is
          when "01"  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*C_MIN_MEM_WIDTH/8 to 
                                i*C_MIN_MEM_WIDTH/8 + C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when "10" =>
             for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to 2*C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*2*C_MIN_MEM_WIDTH/8 to 
                                i*2*C_MIN_MEM_WIDTH/8 + 2*C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when others =>
                   mem_be_i   <= (others => '0');
       end case;
    end process WRITE_BE_MUX_PROCESS_16;
    
end generate WRITE_DATABE_MUX_16_GEN;

-------------------------------------------------------------------------------
-- Write data byte enable generation for 8 bit.
-------------------------------------------------------------------------------

WRITE_DATABE_MUX_8_GEN: if C_MAX_MEM_WIDTH=8 generate
begin

-------------------------------------------------------------------------------
-- Write data path for 8 bit maximum memory width. Write data mux process is 
-- used to multiplex the write_data depending on the addr_cnt.
-------------------------------------------------------------------------------

    WRITE_DATA_MUX_PROCESS_8: process(Mem_width_bytes, Addr_cnt, write_data)
    begin
                   write_data_cmb   <= (others => '0');
     case Mem_width_bytes(3) is
          when '1'  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   write_data_cmb(0 to C_MIN_MEM_WIDTH-1) <=
                      write_data(i*C_MIN_MEM_WIDTH to 
                                 i*C_MIN_MEM_WIDTH + C_MIN_MEM_WIDTH-1);
               end if;
             end loop;
          when others =>
                   write_data_cmb <= (others => '0');
       end case;
    end process WRITE_DATA_MUX_PROCESS_8;

-------------------------------------------------------------------------------
-- Write data path for 8 bit maximum memory width. Write byte enable mux 
-- process is  used to multiplex the byte enable depending on the addr_cnt.
-------------------------------------------------------------------------------
    
    WRITE_BE_MUX_PROCESS_8: process(Mem_width_bytes, Addr_cnt, Bus2IP_BE)
    begin
                   mem_be_i      <= (others => '0');
          case Mem_width_bytes(3) is
          when '1'  =>
             for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
               if Addr_cnt = conv_std_logic_vector(i, C_ADDR_CNTR_WIDTH) then
                   mem_be_i(0 to C_MIN_MEM_WIDTH/8-1) <=
                      Bus2IP_BE(i*C_MIN_MEM_WIDTH/8 to 
                                i*C_MIN_MEM_WIDTH/8 + C_MIN_MEM_WIDTH/8-1);
               end if;
             end loop;
          when others =>
                   mem_be_i   <= (others => '0');
       end case;
    end process WRITE_BE_MUX_PROCESS_8;
    
end generate WRITE_DATABE_MUX_8_GEN;

end generate WRITE_DATABE_MUX_GEN;

-------------------------------------------------------------------------------
-- When all the memory banks has same data width as OPB/MCH data width,
-- data steering logic is not required.
-------------------------------------------------------------------------------
------------------------- C_GLOBAL_DATAWIDTH_MATCH = 0 ------------------------
-------------------------------------------------------------------------------

WRITE_DATABE_GEN: if C_GLOBAL_DATAWIDTH_MATCH = 0 generate
begin
    
    write_data_cmb  <= write_data(0 to C_MAX_MEM_WIDTH-1);
    mem_be_i        <= Bus2IP_BE(0 to C_MAX_MEM_WIDTH/8-1);
    
end generate WRITE_DATABE_GEN;

-------------------------------------------------------------------------------
-- Write data generation for synchronous memory.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 1 -------------------------------
-------------------------------------------------------------------------------
    
SYNC_MEM_WRITE_DATA : if C_GLOBAL_SYNC_MEM = 1 generate
begin

-------------------------------------------------------------------------------
-- Write data pipeline process is used to pipeline write_data_cmb.
-------------------------------------------------------------------------------

    WRITE_DATA_PIPE_PROCESS : process(Clk)
    begin
       if(Clk'EVENT and Clk = '1')then
          if(Rst = '1')then
              write_data_d1 <= (others => '0');
              write_data_d2 <= (others => '0');
          else
              write_data_d1 <= write_data_cmb;
              write_data_d2 <= write_data_d1;
          end if;
     end if;
    end process WRITE_DATA_PIPE_PROCESS;


-------------------------------------------------------------------------------
-- Write data process is used to multiplex the write data on the memory 
-- depending on the type of memory.
-------------------------------------------------------------------------------

    WRITE_DATA_PROCESS: process(write_data_cmb, Synch_mem, Two_pipe_delay, 
                                write_data_d1, write_data_d2)
    begin
       if Synch_mem = '1' then
          if Two_pipe_delay = '1' then
              MemSteer_Mem_DQ_O <= write_data_d2;
          else
              MemSteer_Mem_DQ_O <= write_data_d1;
          end if;
       else
          MemSteer_Mem_DQ_O <= write_data_cmb;
       end if;
    end process WRITE_DATA_PROCESS;
    
end generate SYNC_MEM_WRITE_DATA;

-------------------------------------------------------------------------------
-- Memory write data generation for asynchronous memory.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 0 -------------------------------
-------------------------------------------------------------------------------

ASYNC_MEM_WRITE_DATA : if C_GLOBAL_SYNC_MEM = 0 generate
begin
    MemSteer_Mem_DQ_O <= write_data_cmb;    
end generate ASYNC_MEM_WRITE_DATA;

-------------------------------------------------------------------------------
-- Memory data bus high impedance buffer control.
-------------------------------------------------------------------------------

mem_dq_t_cmb(0) <= MSM_Mem_WEN;
mem_dqt_t_async <= MSM_Mem_WEN and mem_dqt_t_d;

-------------------------------------------------------------------------------
-- Asynchronous memory DQT process is used to generate impedance control 
-- signal.
-------------------------------------------------------------------------------

MEM_DQT_D_ASYNC_PROCESS: process(Clk)
begin
    if Clk'event and Clk = '1' then
       if Rst = '1' then
          mem_dqt_t_d  <= '1';
       else
          mem_dqt_t_d  <= MSM_Mem_WEN;
       end if;
    end if;
end process MEM_DQT_D_ASYNC_PROCESS;

-------------------------------------------------------------------------------
-- Impedance generation for synchronous memory.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 1 -------------------------------
-------------------------------------------------------------------------------
    
SYNC_MEM_DQT : if C_GLOBAL_SYNC_MEM = 1 generate
begin

    REG_DQT_GEN : for i in 0 to 2 generate
    begin
        
-------------------------------------------------------------------------------
-- FDS primitive is used for mem_dq_t_cmb pipe generation.
-------------------------------------------------------------------------------

        DQT_REG: FDS
        port map (
            Q   => mem_dq_t_cmb(i+1), --[out]
            C   => Clk,               --[in]
            D   => mem_dq_t_cmb(i),   --[in]
            S   => Rst                --[in]
            );      
    end generate REG_DQT_GEN;

-------------------------------------------------------------------------------
-- Memory dqt process is used to multiplex the impeadance control signal on to 
-- the memory depending on the type of memory.
-------------------------------------------------------------------------------
                
    MEM_DQT_PROCESS_SYNC: process(Synch_mem, Two_pipe_delay, mem_dq_t_cmb,
                             mem_dqt_t_async)
    begin
        MemSteer_Mem_DQ_T <= (others => '1');
        for i in 0 to C_MAX_MEM_WIDTH-1 loop
          if(Synch_mem = '1')then
              if(Two_pipe_delay = '1')then
                  MemSteer_Mem_DQ_T(i) <= mem_dq_t_cmb(2);
              else
                  MemSteer_Mem_DQ_T(i) <= mem_dq_t_cmb(1);
              end if;
          else
              MemSteer_Mem_DQ_T(i) <= mem_dqt_t_async;
          end if;
        end loop;        
    end process MEM_DQT_PROCESS_SYNC;
    
end generate SYNC_MEM_DQT;    

-------------------------------------------------------------------------------
-- Impedance generation for asynchronous memory.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 0 -------------------------------
-------------------------------------------------------------------------------

ASYNC_MEM_DQT : if C_GLOBAL_SYNC_MEM = 0 generate
begin

-------------------------------------------------------------------------------
-- Memory dqt process is used to generate impeadance control signal on to 
-- the memory.
-------------------------------------------------------------------------------

    MEM_DQT_PROCESS_ASYNC: process(mem_dqt_t_async)
    begin
        for i in 0 to C_MAX_MEM_WIDTH-1 loop
          MemSteer_Mem_DQ_T(i) <= mem_dqt_t_async;
        end loop;
    end process MEM_DQT_PROCESS_ASYNC;
    
end generate ASYNC_MEM_DQT;

-------------------------------------------------------------------------------
-- Read data path.
-- Read data and byte enable generation.
-------------------------------------------------------------------------------

RDDATA_GEN: for j in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH - 1 generate
begin

    RDDATA_BYTE_GEN:for i in 0 to C_MIN_MEM_WIDTH - 1 generate
    begin

-------------------------------------------------------------------------------
-- FDCE primitive is used for latching read_data when read_data_ce = 1.
-------------------------------------------------------------------------------

        RDDATA_REG: FDRE
        port map (
            Q   => Mem2Bus_Data(C_MIN_MEM_WIDTH*j+i), --[out]
            C   => Clk,                               --[in]
            CE  => read_data_ce(j),                   --[in]
            D   => read_data(C_MIN_MEM_WIDTH*j+i),    --[in]
            R   => Rst                                --[in]
            );
    end generate RDDATA_BYTE_GEN;
end generate RDDATA_GEN;

-------------------------------------------------------------------------------
------------------------- C_GLOBAL_DATAWIDTH_MATCH = 0 ------------------------
-------------------------------------------------------------------------------

RDDATA_PATH_GEN : if C_GLOBAL_DATAWIDTH_MATCH = 0 generate
begin
    read_data    <= MemSteer_Mem_DQ_I;
    read_data_ce <= (others=>'1');   
end generate RDDATA_PATH_GEN;

-------------------------------------------------------------------------------
------------------------- C_GLOBAL_DATAWIDTH_MATCH = 1 ------------------------
-------------------------------------------------------------------------------

RDDATA_PATH_MUX_GEN : if C_GLOBAL_DATAWIDTH_MATCH = 1 generate
begin

-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 1 -------------------------------
-------------------------------------------------------------------------------

    SYNC_ADDR_CNT_GEN: if C_GLOBAL_SYNC_MEM = 1 generate
    begin

-------------------------------------------------------------------------------
-- Address count pipeline process is used to pipeline address count.
-------------------------------------------------------------------------------

        ADDR_CNT_PIPE_PROCESS_SYN: process(Clk)
        begin
          if Clk'event and Clk = '1' then
              if Rst = '1' then
                  addr_cnt_d1 <= (others => '0');
                  addr_cnt_d2 <= (others => '0');
                  addr_cnt_d3 <= (others => '0');
                  addr_cnt_d4 <= (others => '0');
              else
                  addr_cnt_d1 <= Addr_cnt;
                  addr_cnt_d2 <= addr_cnt_d1;
                  addr_cnt_d3 <= addr_cnt_d2;
                  addr_cnt_d4 <= addr_cnt_d3;
             end if;
          end if;
        end process ADDR_CNT_PIPE_PROCESS_SYN;

-------------------------------------------------------------------------------
-- Synchonous address counter process is used to multiplex the address counter
-- select signal depending on the type of memory.
-------------------------------------------------------------------------------

        SYNC_ADDR_CNT_PROCESS: process(Synch_mem, Two_pipe_delay,
                                       addr_cnt_d2, addr_cnt_d3, addr_cnt_d4)
        begin
          if Synch_mem = '1' then
              if Two_pipe_delay = '1' then
                  addr_cnt_sel <= addr_cnt_d4;
              else
                  addr_cnt_sel <= addr_cnt_d3;
              end if;
          else
              addr_cnt_sel <= addr_cnt_d2;
          end if;
        end process SYNC_ADDR_CNT_PROCESS;

---------------------------- Read Data Enable Logic ---------------------------

    read_data_en_d(0)  <= Read_data_en;

    RDDATA_EN_GEN_SYNC: for i in 0 to 3 generate
    begin
    
-------------------------------------------------------------------------------
-- FDR primitive is used for read_data_en_d pipe generation.
-------------------------------------------------------------------------------

        RDDATA_EN_REG_SYNC: FDR
            port map (
                Q   => read_data_en_d(i+1),          --[out]
                C   => Clk,                          --[in]
                D   => read_data_en_d(i),            --[in]
                R   => Rst                           --[in]
                );
    end generate RDDATA_EN_GEN_SYNC;

-------------------------------------------------------------------------------
-- Read data enable select process is used to multiplex the read data enable
-- depending on the type of memory.
-------------------------------------------------------------------------------

        READ_DATA_EN_SEL_PROCESS: process(read_data_en_d, Synch_mem, 
                                          Two_pipe_delay)
        begin
          if Synch_mem = '1' then
              if Two_pipe_delay = '1' then
                  read_data_en_sel <= read_data_en_d(4);
              else
                  read_data_en_sel <= read_data_en_d(3);
              end if;
          else
              read_data_en_sel     <= read_data_en_d(2);
          end if;
        end process READ_DATA_EN_SEL_PROCESS;
    
    end generate SYNC_ADDR_CNT_GEN;

-------------------------------------------------------------------------------
-- Address count select generation for asynchronous memory.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------- C_GLOBAL_SYNC_MEM = 0 -------------------------------
-------------------------------------------------------------------------------

    ASYNC_ADDR_CNT_GEN: if C_GLOBAL_SYNC_MEM = 0 generate
    begin
        addr_cnt_sel      <= addr_cnt_d2;

-------------------------------------------------------------------------------
-- Address count pipeline process is used to pipeline address count.
-------------------------------------------------------------------------------

        ADDR_CNT_PIPE_PROCESS_ASYNC: process(Clk)
        begin
          if Clk'event and Clk = '1' then
              if Rst = '1' then
                  addr_cnt_d1 <= (others => '0');
                  addr_cnt_d2 <= (others => '0');
              else
                  addr_cnt_d1 <= Addr_cnt;
                  addr_cnt_d2 <= addr_cnt_d1;
             end if;
          end if;
        end process ADDR_CNT_PIPE_PROCESS_ASYNC;

---------------------------- Read Data Enable Logic ---------------------------

        read_data_en_d(0)  <= Read_data_en;
        read_data_en_sel   <= read_data_en_d(2);

    RDDATA_EN_GEN_ASYNC: for i in 0 to 3 generate
    begin

-------------------------------------------------------------------------------
-- FDR primitive is used for read_data_en_d pipe generation.
-------------------------------------------------------------------------------
    
            RDDATA_EN_REG_ASYNC: FDR
            port map (
                    Q   => read_data_en_d(i+1),      --[out]
                    C   => Clk,                      --[in]
                    D   => read_data_en_d(i),        --[in]
                    R   => Rst                       --[in]
                    );
    end generate RDDATA_EN_GEN_ASYNC;    
    end generate ASYNC_ADDR_CNT_GEN;


-------------------------------------------------------------------------------
-- Read Data CE generation For 64 Bit DWidth.
-------------------------------------------------------------------------------
    
    READ_DATA_CE_64_GEN: if C_IPIF_DWIDTH = 64 generate
    begin
--signal test :std_logic_vector(0 downto 7);
--test <= read_data_ce(conv_integer(addr_cnt_sel)*4+i);
-------------------------------------------------------------------------------
-- Read data CE process is used to generate read data chip enable for 64 Bit 
-- DWidth.
-------------------------------------------------------------------------------
    
        READ_DATA_CE_PROCESS_64: process(read_data_en_sel,addr_cnt_sel,
        						Mem_width_bytes)
        begin
                read_data_ce  <= (others => '0');
          case Mem_width_bytes is
             when "0001"  =>         
                read_data_ce(conv_integer(addr_cnt_sel)) 
                   <= read_data_en_sel;     
             when "0010" =>
               for i in 0 to 1 loop
                read_data_ce(conv_integer(addr_cnt_sel)*2+i)
                   <= read_data_en_sel;
               end loop;
             when "0100" =>
               for i in 0 to 3 loop
                read_data_ce(conv_integer(addr_cnt_sel)*4+i)
                   <= read_data_en_sel;
               end loop;
             when "1000" =>
               for i in 0 to 7 loop
                read_data_ce(i)  <= read_data_en_sel;
               end loop;                
             when others =>
                read_data_ce <= (others => '0');
          end case;
        end process READ_DATA_CE_PROCESS_64;
        
    end generate READ_DATA_CE_64_GEN;


-------------------------------------------------------------------------------
-- Read data CE generation For 32 Bit DWidth.
-------------------------------------------------------------------------------

    READ_DATA_CE_32_GEN: if C_IPIF_DWIDTH = 32 generate
    begin
    
-------------------------------------------------------------------------------
-- Read data CE process is used to generate read data chip enable for 32 Bit 
-- DWidth.
-------------------------------------------------------------------------------

        READ_DATA_CE_PROCESS_32: process(Mem_width_bytes, addr_cnt_sel,
                                      read_data_en_sel)
        begin
                read_data_ce  <= (others => '0');
          case Mem_width_bytes is
             when "0001"  =>          
                read_data_ce(conv_integer(addr_cnt_sel))   
                   <= read_data_en_sel;   
             when "0010" =>
               for i in 0 to 1 loop
                read_data_ce(conv_integer(addr_cnt_sel)*2+i)
                   <= read_data_en_sel;
               end loop;
             when "0100" =>
               for i in 0 to 3 loop
                read_data_ce(i)  <= read_data_en_sel;
               end loop;
             when "1000" =>
               for i in 0 to 3 loop
                   read_data_ce(i)  <= read_data_en_sel;
               end loop;
             when others =>
                read_data_ce <= (others => '0');
          end case;
        end process READ_DATA_CE_PROCESS_32;
        
    end generate READ_DATA_CE_32_GEN;


-------------------------------------------------------------------------------
-- Read Data Path For 64 Bit Maximum Memory Width.
-------------------------------------------------------------------------------

    READ_DATA_64_GEN: if (C_MAX_MEM_WIDTH=64 and C_IPIF_DWIDTH=64) generate
    begin
    
-------------------------------------------------------------------------------
-- Read data process is used to generate read data for 64 Bit DWidth.
-------------------------------------------------------------------------------

       READ_DATA_PROCESS_64_64: process(Mem_width_bytes, MemSteer_Mem_DQ_I )
       begin
                   read_data     <= (others => '0');
          case Mem_width_bytes is
             when "0001"  =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
                   read_data(i*C_MIN_MEM_WIDTH to 
                             i*C_MIN_MEM_WIDTH+C_MIN_MEM_WIDTH-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH-1);
               end loop;
             when "0010" =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
                   read_data(i*C_MIN_MEM_WIDTH*2 to 
                             i*C_MIN_MEM_WIDTH*2+C_MIN_MEM_WIDTH*2-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*2-1);
               end loop;
             when "0100" =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
                   read_data(i*C_MIN_MEM_WIDTH*4 to 
                             i*C_MIN_MEM_WIDTH*4+C_MIN_MEM_WIDTH*4-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*4-1);
               end loop;
             when "1000" =>
                   read_data <= MemSteer_Mem_DQ_I;      
             when others =>
                   read_data <= (others => '0');
          end case;
        end process READ_DATA_PROCESS_64_64;
        
    end generate READ_DATA_64_GEN;



-------------------------------------------------------------------------------
-- Read Data Path For 64 Bit Maximum Memory Width.
-------------------------------------------------------------------------------

    READ_DATA_32_64_GEN: if (C_MAX_MEM_WIDTH=64 and C_IPIF_DWIDTH=32)generate
    begin
    
-------------------------------------------------------------------------------
-- Read data process is used to generate read data for 64 Bit DWidth.
-------------------------------------------------------------------------------

       READ_DATA_PROCESS_32_64: process(Mem_width_bytes, MemSteer_Mem_DQ_I,
       							addr_align_read)
       begin
                   read_data     <= (others => '0');
          case Mem_width_bytes is
             when "0001"  =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
                   read_data(i*C_MIN_MEM_WIDTH to 
                             i*C_MIN_MEM_WIDTH+C_MIN_MEM_WIDTH-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH-1);
               end loop;
             when "0010" =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2) -1 loop
                   read_data(i*C_MIN_MEM_WIDTH*2 to 
                             i*C_MIN_MEM_WIDTH*2+C_MIN_MEM_WIDTH*2-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*2-1);
               end loop;
             when "0100" =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4) -1 loop
                   read_data(i*C_MIN_MEM_WIDTH*4 to 
                             i*C_MIN_MEM_WIDTH*4+C_MIN_MEM_WIDTH*4-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*4-1);
               end loop;
             when "1000" =>
               if addr_align_read = '0' then
                   read_data <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*4-1);
	       else    	
                   read_data <= MemSteer_Mem_DQ_I(C_MIN_MEM_WIDTH*4 to 
                   					C_MIN_MEM_WIDTH*8-1);
	       end if;
             when others => 
                   read_data <= (others => '0');
          end case;
        end process READ_DATA_PROCESS_32_64;
    end generate READ_DATA_32_64_GEN;


-------------------------------------------------------------------------------
-- Read data path For 32 bit maximum memory width.
-------------------------------------------------------------------------------

    READ_DATA_32_GEN: if (C_MAX_MEM_WIDTH=32) generate
    begin
    
-------------------------------------------------------------------------------
-- Read data process is used to generate read data for 32 bit DWidth.
-------------------------------------------------------------------------------    
    
        READ_DATA_PROCESS_32: process(Mem_width_bytes, MemSteer_Mem_DQ_I)
        begin
                   read_data <= (others => '0');
          case Mem_width_bytes(1 to 3) is
             when "001"  =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
                   read_data(i*C_MIN_MEM_WIDTH to 
                             i*C_MIN_MEM_WIDTH+C_MIN_MEM_WIDTH-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH-1);
               end loop;
             when "010" =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2)-1 loop
                   read_data(i*C_MIN_MEM_WIDTH*2 to 
                             i*C_MIN_MEM_WIDTH*2+C_MIN_MEM_WIDTH*2-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*2-1);
               end loop;
             when "100" =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*4)-1 loop
                   read_data(i*C_MIN_MEM_WIDTH*4 to 
                             i*C_MIN_MEM_WIDTH*4+C_MIN_MEM_WIDTH*4-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*4-1);
               end loop;
             when others =>
                   read_data <= (others => '0');
          end case;
        end process READ_DATA_PROCESS_32;
    end generate READ_DATA_32_GEN;

-------------------------------------------------------------------------------
-- Read data path for 16 bit maximum memory width.
-------------------------------------------------------------------------------
    
    READ_DATA_16_GEN: if C_MAX_MEM_WIDTH=16 generate
    begin
    
-------------------------------------------------------------------------------
-- Read data process is used to generate read data for 16 bit DWidth.
-------------------------------------------------------------------------------    
    
        READ_DATA_PROCESS_16: process(Mem_width_bytes, MemSteer_Mem_DQ_I)
        begin
                   read_data <= (others => '0');
          case Mem_width_bytes(2 to 3) is
             when "01"  =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
                   read_data(i*C_MIN_MEM_WIDTH to 
                             i*C_MIN_MEM_WIDTH+C_MIN_MEM_WIDTH-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH-1);
               end loop;
             when "10" =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/(C_MIN_MEM_WIDTH*2)-1 loop
                   read_data(i*C_MIN_MEM_WIDTH*2 to 
                             i*C_MIN_MEM_WIDTH*2+C_MIN_MEM_WIDTH*2-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH*2-1);
               end loop;
             when others =>
                   read_data <= (others => '0');
          end case;
        end process READ_DATA_PROCESS_16;
    end generate READ_DATA_16_GEN;    
-------------------------------------------------------------------------------
-- Read data path for 8 bit maximum memory width.
-------------------------------------------------------------------------------

    READ_DATA_8_GEN: if C_MAX_MEM_WIDTH=8 generate
    begin
-------------------------------------------------------------------------------
-- Read data process is used to generate read data for 8 bit DWidth.
-------------------------------------------------------------------------------

        READ_DATA_PROCESS_8: process(Mem_width_bytes, MemSteer_Mem_DQ_I)
        begin
                   read_data <= (others => '0');
          case Mem_width_bytes(3) is
             when '1'  =>
               -- create the input data
               for i in 0 to C_IPIF_DWIDTH/C_MIN_MEM_WIDTH -1 loop
                   read_data(i*C_MIN_MEM_WIDTH to 
                             i*C_MIN_MEM_WIDTH+C_MIN_MEM_WIDTH-1)
                      <= MemSteer_Mem_DQ_I(0 to C_MIN_MEM_WIDTH-1);
               end loop;
             when others =>
                   read_data <= (others => '0');
          end case;
        end process READ_DATA_PROCESS_8;
    end generate READ_DATA_8_GEN;    
end generate RDDATA_PATH_MUX_GEN;
   
end imp;
-------------------------------------------------------------------------------
-- End of file mem_steer.vhd.
-------------------------------------------------------------------------------
