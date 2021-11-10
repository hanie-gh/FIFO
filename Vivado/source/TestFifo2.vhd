library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;

entity fifo_test_v2 is
end fifo_test_v2;

architecture rtl of fifo_test_v2 is
	
	-- String padding with spaces
	function pad_string(s : string; strlen : natural) return string is
	 	variable retStr : string(1 to strlen);
	begin
  		assert strlen >= s'LENGTH report "String length must be less than strlen" severity error;
   		for n in 1 to s'HIGH loop
		    	retStr(n) := s(n);
		end loop;
 		for n in s'HIGH+1 to strlen loop
			retStr(n) := ' ';
		end loop;
	  	return retStr;
	end function pad_string;

	function str64(s : string) return string is
	begin
		return pad_string(s, 64);
	end function str64;


    --Implementing to_string function 
    function to_string (arg : std_logic_vector) return string is
    variable result : string (1 to arg'length);
    variable v : std_logic_vector (result'range) := arg;
    begin
    for i in result'range loop
    case v(i) is
    when 'U' =>
    result(i) := 'U';
    when 'X' =>
    result(i) := 'X';
    when '0' =>
    result(i) := '0';
    when '1' =>
    result(i) := '1';
    when 'Z' =>
    result(i) := 'Z';
    when 'W' =>
    result(i) := 'W';
    when 'L' =>
    result(i) := 'L';
    when 'H' =>
    result(i) := 'H';
    when '-' =>
    result(i) := '-';
    end case;
    end loop;
    return result;
    end;

    -- define constants 		
    constant wr_data_width      : integer := 8;  
    constant rd_data_width      : integer := 8;  
    constant usedw_width        : integer := 5;  -- equal to log2(FIFO_DEPTH)+1 
    constant test_usedw_width   : integer := 5;  -- equal to log2(FIFO_DEPTH)+1  
    
    constant FIFO_READ_LATENCY  : integer := 1;  
    constant add_ram_output_register  : string := "OFF";  
    
    constant FIFO_WRITE_DEPTH   : integer := 16; 
    
    constant PROG_EMPTY_THRESH  : integer := 6;  
    constant almost_empty_value : integer := 6; 
    
    constant PROG_FULL_THRESH   : integer := 7;  
    constant almost_full_value  : integer := 7;  
    
    constant READ_MODE          : string := "std";  
    constant lpm_showahead      : string := "OFF";  
    
    constant USE_ADV_FEATURES   : string := "0707";   
    
    
	-- internal signals
	signal aclr		    :	std_logic := '0';
	signal almost_empty	:	std_logic;
	signal almost_full	:	std_logic;
	signal clock		:	std_logic;
	signal data		    :	std_logic_vector(wr_data_width-1 downto 0);
	signal empty		:	std_logic;
	signal full		    :	std_logic;
	signal q		    :	std_logic_vector(rd_data_width-1 downto 0);
	signal rdreq		:	std_logic;
	signal sclr		    :	std_logic := '0';
	signal usedw		:	std_logic_vector(usedw_width-1 downto 0);
	signal wrreq		:	std_logic;	

	--Introduce the record type (similar to a C struct)
	type test_vec_t is record
		data  : std_logic_vector(wr_data_width-1 downto 0);	-- Input data
		rdreq : std_logic;			-- rdreq input	
		wrreq : std_logic;			-- wrreq input
		sclr  : std_logic;			-- sclr  intput	
		usedw : std_logic_vector(test_usedw_width-1 downto 0);	-- Expected Output - number of used words in fifo
		q     : std_logic_vector(rd_data_width-1 downto 0);	-- Expected Output - value from last successful read
		empty : std_logic;			-- Expected Output - High when buffer is empty	
		full  : std_logic;			-- Expected Output - High when buffer is full
		msg   : string(1 to 64);			-- Error string on assert failure
	end record;
	
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Xilinx: Normal FIFO
-- asserting empty from rdreq and deasserting it from wrreq has a latency of 1 clock cycle.
-- asserting full from wrreq and deasserting it from rereq has a latency of 1 clock cycle.
-- usedw or rd/wr_data_count updates after 2 clock cycle after rdreq or wrreq 
-- when usedw=7 it means that there are 8 words writen in the memory
-- when usedw=6 it means that there are 7 words writen in the memory
-- when usedw=5 it means that there are 6 words writen in the memory
-- when usedw=4 it means that there are 5 words writen in the memory
-- *when almost_full value=7, usedw=7, almost_full=1 it means that there are 8 words available in the memory
-- when almost_full value=7, usedw=6, almost_full=0 it means that there are 5 words available in the memory
-- when almost_empty value=6, usedw=7, almost_empty=0 it means that there are 8 words available in the memory
-- *when almost_empty value=6, usedw=6, almost_empty=1 it means that there are 5 words available in the memory
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Intel: Normal FIFO
-- asserting empty from rdreq and deasserting it from wrreq has a latency of 1 clock cycle.
-- asserting full from wrreq and deasserting it from rereq has a latency of 1 clock cycle.
-- usedw or rd/wr_data_count updates after 2 clock cycle after rdreq or wrreq 
-- when usedw=6 it means that there are 6 words writen in the memory
-- when usedw=7 it means that there are 7 words writen in the memory
-- *when almost_full value=7, usedw=7, almost_full=1 it means that there are 7 words available in the memory
-- when almost_full value=7, usedw=6, almost_full=0 it means that there are 6 words available in the memory
-- when almost_empty value=6, usedw=6, almost_empty=0 it means that there are 6 words available in the memory
-- *when almost_empty value=6, usedw=5, almost_empty=1 it means that there are 5 words available in the memory
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Altera to Xilinx
-- Altera almost_full value=7 -usedw=7 there are 7 words available in the memory
-- Xilinx almost_full value=6 -usedw=6 there are 7 words available in the memory

-- Altera almost_empty value=6 -usedw=5 there are 5 words available in the memory
-- Xilinx almost_empty value=4 -usedw=4 there are 5 words available in the memory

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	type lookuptable_t is array (0 to 42) of test_vec_t;
		
	constant tests_empty_full : lookuptable_t := (
		(data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "00000000", empty => '1', full => '0', msg=>str64("Empty buffer - no read or write")), --00
		(data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "00000000", empty => '1', full => '0', msg=>str64("Empty buffer - no read or write")), --01
		(data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "00000000", empty => '1', full => '0', msg=>str64("Empty buffer - no read or write")), --02
		(data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "00000000", empty => '1', full => '0', msg=>str64("Empty buffer - no read or write")), --03
		(data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "00000000", empty => '1', full => '0', msg=>str64("Empty buffer - no read or write")), --04
		(data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "00000000", empty => '1', full => '0', msg=>str64("Empty buffer - no read or write")), --05
		(data => "00000001", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00000", q => "00000000", empty => '1', full => '0', msg=>str64("Write to empty buffer, 1st word") ),          --06
		(data => "00000010", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "00000000", empty => '0', full => '0', msg=>str64("Do nothing - output should still be zero") ), --07
		(data => "00000011", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00001", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 2nd word") ), --08
		(data => "00000100", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00001", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 3rd word") ), --09
		(data => "00000101", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00010", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 4th word") ), --10
		(data => "00000110", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00011", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 5th word") ), --11
		(data => "00000111", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00100", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 6th word") ), --12
		(data => "00001000", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00101", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 7th word") ), --13
		(data => "00001001", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00110", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 8th word") ), --14
		(data => "00001010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "00111", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 9th word") ), --15
		(data => "00001011", rdreq => '0', wrreq => '1', sclr => '0', usedw => "01000", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 10th word") ), --16
		(data => "00001100", rdreq => '0', wrreq => '1', sclr => '0', usedw => "01001", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 11th word") ), --17
		(data => "00001101", rdreq => '0', wrreq => '1', sclr => '0', usedw => "01010", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 12th word") ), --18
		(data => "00001110", rdreq => '0', wrreq => '1', sclr => '0', usedw => "01011", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 13th word") ), --19
		(data => "00001111", rdreq => '0', wrreq => '1', sclr => '0', usedw => "01100", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 14th word") ), --20
		(data => "00010000", rdreq => '0', wrreq => '1', sclr => '0', usedw => "01101", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 15th word") ), --21
		(data => "00010001", rdreq => '0', wrreq => '1', sclr => '0', usedw => "01110", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word, 16th word") ), --22
		(data => "00010010", rdreq => '0', wrreq => '0', sclr => '0', usedw => "01111", q => "00000000", empty => '0', full => '1', msg=>str64("Add one more word, unsuccessful") ), --23
		(data => "00010010", rdreq => '0', wrreq => '0', sclr => '0', usedw => "01111", q => "00000000", empty => '0', full => '1', msg=>str64("Add one more word, unsuccessful") ), --24
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01111", q => "--------", empty => '0', full => '1', msg=>str64("Read 1st word") ), --25 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "10000", q => "--------", empty => '0', full => '0', msg=>str64("Read 2nd word") ), --26 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01111", q => "--------", empty => '0', full => '0', msg=>str64("Read 3rd word") ), --27 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01110", q => "--------", empty => '0', full => '0', msg=>str64("Read 4th word") ), --28 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01101", q => "--------", empty => '0', full => '0', msg=>str64("Read 5th word") ), --29 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01100", q => "--------", empty => '0', full => '0', msg=>str64("Read 6th word") ), --30 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01011", q => "--------", empty => '0', full => '0', msg=>str64("Read 7th word") ), --31 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01010", q => "--------", empty => '0', full => '0', msg=>str64("Read 8th word") ), --32 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01001", q => "--------", empty => '0', full => '0', msg=>str64("Read 9th word") ), --33 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "01000", q => "--------", empty => '0', full => '0', msg=>str64("Read 10th word") ), --34 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "00111", q => "--------", empty => '0', full => '0', msg=>str64("Read 11th word") ), --35 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "00110", q => "--------", empty => '0', full => '0', msg=>str64("Read 12th word") ), --36 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "00101", q => "--------", empty => '0', full => '0', msg=>str64("Read 13th word") ), --37 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "00100", q => "--------", empty => '0', full => '0', msg=>str64("Read 14th word") ), --38 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "00011", q => "--------", empty => '0', full => '0', msg=>str64("Read 15th word") ), --39 
        (data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "00010", q => "--------", empty => '0', full => '0', msg=>str64("Read 16th word") ), --40 
        (data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00001", q => "--------", empty => '1', full => '0', msg=>str64("Read next word, unsuccessful") ), --41
        (data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "00000", q => "--------", empty => '1', full => '0', msg=>str64("Read next word, unsuccessful") )  --42
		);		
	constant tests : lookuptable_t := tests_empty_full;


begin

   xpm_fifo_sync_inst : xpm_fifo_sync
   generic map (
      CASCADE_HEIGHT => 0,        -- DECIMAL
      DOUT_RESET_VALUE => "0",    -- String
      ECC_MODE => "no_ecc",       -- String
      FIFO_MEMORY_TYPE => "auto", -- String
      FIFO_READ_LATENCY => FIFO_READ_LATENCY,     -- DECIMAL
      FIFO_WRITE_DEPTH => FIFO_WRITE_DEPTH,   -- DECIMAL
      FULL_RESET_VALUE => 0,      -- DECIMAL
      PROG_EMPTY_THRESH => PROG_EMPTY_THRESH,    -- DECIMAL
      PROG_FULL_THRESH => PROG_FULL_THRESH,     -- DECIMAL
      RD_DATA_COUNT_WIDTH => usedw_width,   -- DECIMAL
      READ_DATA_WIDTH => rd_data_width,      -- DECIMAL
      READ_MODE => READ_MODE,         -- String
      SIM_ASSERT_CHK => 0,        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      USE_ADV_FEATURES => USE_ADV_FEATURES, -- String
      WAKEUP_TIME => 0,           -- DECIMAL
      WRITE_DATA_WIDTH => wr_data_width,     -- DECIMAL
      WR_DATA_COUNT_WIDTH => usedw_width   -- DECIMAL
   )
   port map (
      almost_empty => open,   -- 1-bit output: Almost Empty : When asserted, this signal indicates that
                                      -- only one more read can be performed before the FIFO goes to empty.

      almost_full => open,     -- 1-bit output: Almost Full: When asserted, this signal indicates that
                                      -- only one more write can be performed before the FIFO is full.

      data_valid => open,       -- 1-bit output: Read Data Valid: When asserted, this signal indicates
                                      -- that valid data is available on the output bus (dout).

      dbiterr => open,             -- 1-bit output: Double Bit Error: Indicates that the ECC decoder
                                      -- detected a double-bit error and data in the FIFO core is corrupted.

      dout => q,                   -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                      -- when reading the FIFO.

      empty => empty,                 -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                                      -- the FIFO is empty. Read requests are ignored when the FIFO is empty,
                                      -- initiating a read while empty is not destructive to the FIFO.

      full => full,                   -- 1-bit output: Full Flag: When asserted, this signal indicates that the
                                      -- FIFO is full. Write requests are ignored when the FIFO is full,
                                      -- initiating a write when the FIFO is full is not destructive to the
                                      -- contents of the FIFO.

      overflow => open,           -- 1-bit output: Overflow: This signal indicates that a write request
                                      -- (wren) during the prior clock cycle was rejected, because the FIFO is
                                      -- full. Overflowing the FIFO is not destructive to the contents of the
                                      -- FIFO.

      prog_empty => almost_empty,       -- 1-bit output: Programmable Empty: This signal is asserted when the
                                      -- number of words in the FIFO is less than or equal to the programmable
                                      -- empty threshold value. It is de-asserted when the number of words in
                                      -- the FIFO exceeds the programmable empty threshold value.

      prog_full => almost_full,         -- 1-bit output: Programmable Full: This signal is asserted when the
                                      -- number of words in the FIFO is greater than or equal to the
                                      -- programmable full threshold value. It is de-asserted when the number
                                      -- of words in the FIFO is less than the programmable full threshold
                                      -- value.

      rd_data_count => open, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates
                                      -- the number of words read from the FIFO.

      rd_rst_busy => open,     -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO
                                      -- read domain is currently in a reset state.

      sbiterr => open,             -- 1-bit output: Single Bit Error: Indicates that the ECC decoder
                                      -- detected and fixed a single-bit error.

      underflow => open,         -- 1-bit output: Underflow: Indicates that the read request (rd_en)
                                      -- during the previous clock cycle was rejected because the FIFO is
                                      -- empty. Under flowing the FIFO is not destructive to the FIFO.

      wr_ack => open,               -- 1-bit output: Write Acknowledge: This signal indicates that a write
                                      -- request (wr_en) during the prior clock cycle is succeeded.

      wr_data_count => usedw, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                      -- the number of words written into the FIFO.

      wr_rst_busy => open,     -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                      -- write domain is currently in a reset state.

      din => data,                     -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                      -- writing the FIFO.

      injectdbiterr => '0', -- 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                      -- the ECC feature is used on block RAMs or UltraRAM macros.

      injectsbiterr => '0', -- 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                      -- the ECC feature is used on block RAMs or UltraRAM macros.

      rd_en => rdreq,                 -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                      -- signal causes data (on dout) to be read from the FIFO. Must be held
                                      -- active-low when rd_rst_busy is active high.

      rst => aclr,                     -- 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                      -- unstable at the time of applying reset, but reset must be released
                                      -- only after the clock(s) is/are stable.

      sleep => '0',                 -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                      -- block is in power saving mode.

      wr_clk => clock,               -- 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                      -- free running clock.

      wr_en => wrreq                  -- 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                      -- signal causes data (on din) to be written to the FIFO Must be held
                                      -- active-low when rst or wr_rst_busy or rd_rst_busy is active high

   );
--Generate the clock
clk:	process
	begin
		clock <= '0';
		wait for 10 ns;
		for n in 1 to 64 loop
			clock <= '1';
			wait for 10 ns;		
			clock <= '0';
			wait for 10 ns;		
		end loop;

		wait;
	end process;

--Perform tests
testv:	process

	begin
		for n in tests'RANGE loop
			data	<= tests(n).data;
			rdreq	<= tests(n).rdreq;
			wrreq	<= tests(n).wrreq;
			sclr    <= tests(n).sclr;
			wait until rising_edge(clock);
			--wait until falling_edge(clock);
-- 			assert false report tests(n).msg severity note;
-- 			assert std_match(usedw,tests(n).usedw) report "Unexpected number of words " & to_string(usedw) & " used in buffer" severity error;
-- 			assert std_match(q,    tests(n).q)     report "Unexpected output: " & to_string(q) severity error;
-- 			assert std_match(empty,tests(n).empty) report "Unexpected empty bit state" severity error;
-- 			assert std_match(full, tests(n).full)  report "Unexpected full bit state" severity error;
		end loop;

		wait;


	end process;

end rtl;

-- //////////////////////////////////////////////////////////////////////////////////////////////////////
-- //////////////////////////////////////////////////////////////////////////////////////////////////////
--/*
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

--LIBRARY altera_mf;
--USE altera_mf.altera_mf_components.all;

--entity fifo_test_v2 is
--end fifo_test_v2;

--architecture rtl of fifo_test_v2 is
--	--Component declaration
--	component scfifo
--		generic (
--			add_ram_output_register	:	string := "OFF";
--			allow_rwcycle_when_full	:	string := "OFF";
--			almost_empty_value	:	natural := 0;
--			almost_full_value	:	natural := 0;
--			intended_device_family	:	string := "Cyclone IV";
--			enable_ecc		:	string := "FALSE";
--			lpm_numwords		:	natural;
--			lpm_showahead		:	string := "OFF";
--			lpm_width		:	natural;
--			lpm_widthu		:	natural := 1;
--			overflow_checking	:	string := "ON";
--			ram_block_type		:	string := "AUTO";
--			underflow_checking	:	string := "ON";
--			use_eab			:	string := "ON";
--			lpm_hint		:	string := "UNUSED";
--			lpm_type		:	string := "scfifo"
--		);
--		port(
--			aclr		:	in std_logic := '0';
--			almost_empty	:	out std_logic;
--			almost_full	:	out std_logic;
--			clock		:	in std_logic;
--			data		:	in std_logic_vector(lpm_width-1 downto 0);
--			eccstatus	:	out std_logic_vector(1 downto 0);
--			empty		:	out std_logic;
--			full		:	out std_logic;
--			q		:	out std_logic_vector(lpm_width-1 downto 0);
--			rdreq		:	in std_logic;
--			sclr		:	in std_logic := '0';
--			usedw		:	out std_logic_vector(lpm_widthu-1 downto 0);
--			wrreq		:	in std_logic
--		);
--	end component;
	
--	-- internal signals
--	signal aclr		:	std_logic := '0';
--	signal almost_empty	:	std_logic;
--	signal almost_full	:	std_logic;
--	signal clock		:	std_logic;
--	signal data		:	std_logic_vector(7 downto 0);
--	signal eccstatus	:	std_logic_vector(1 downto 0);
--	signal empty		:	std_logic;
--	signal full		:	std_logic;
--	signal q		:	std_logic_vector(7 downto 0);
--	signal rdreq		:	std_logic;
--	signal sclr		:	std_logic := '0';
--	signal usedw		:	std_logic_vector(2 downto 0);
--	signal wrreq		:	std_logic;	
	
--	-- String padding with spaces
--	function pad_string(s : string; strlen : natural) return string is
--	 	variable retStr : string(1 to strlen);
--	begin
--  		assert strlen >= s'LENGTH report "String length must be less than strlen" severity error;
--   		for n in 1 to s'HIGH loop
--		    	retStr(n) := s(n);
--		end loop;
-- 		for n in s'HIGH+1 to strlen loop
--			retStr(n) := ' ';
--		end loop;
--	  	return retStr;
--	end function pad_string;

--	function str64(s : string) return string is
--	begin
--		return pad_string(s, 64);
--	end function str64;

--	--Introduce the record type (similar to a C struct)
--	type test_vec_t is record
--		data : std_logic_vector(7 downto 0);	-- Input data
--		rdreq : std_logic;			-- rdreq input	
--		wrreq : std_logic;			-- wrreq input
--		sclr  : std_logic;			-- sclr  intput	
--		usedw : std_logic_vector(2 downto 0);	-- Expected Output - number of used words in fifo
--		q : std_logic_vector(7 downto 0);	-- Expected Output - value from last successful read
--		empty : std_logic;			-- Expected Output - High when buffer is empty	
--		full  : std_logic;			-- Expected Output - High when buffer is full
--		msg : string(1 to 64);			-- Error string on assert failure
--	end record;
	
--	type lookuptable_t is array (0 to 37) of test_vec_t;
--	constant tests : lookuptable_t := (
--		(data => "00000000", rdreq => '0', wrreq => '0', sclr => '0', usedw => "000", q => "00000000", empty => '1', full => '0', msg=>str64("Empty buffer - no read or write")), 
--		(data => "00000011", rdreq => '0', wrreq => '1', sclr => '0', usedw => "001", q => "00000000", empty => '0', full => '0', msg=>str64("Write to empty buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '0', sclr => '0', usedw => "001", q => "00000000", empty => '0', full => '0', msg=>str64("Do nothing - output should still be zero") ),
--		(data => "00001100", rdreq => '0', wrreq => '1', sclr => '0', usedw => "010", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word") ),
--		(data => "00110000", rdreq => '0', wrreq => '1', sclr => '0', usedw => "011", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word") ),
--		(data => "01010101", rdreq => '0', wrreq => '0', sclr => '0', usedw => "011", q => "00000000", empty => '0', full => '0', msg=>str64("Do nothing - output still the same") ),
--		(data => "11000000", rdreq => '0', wrreq => '1', sclr => '0', usedw => "100", q => "00000000", empty => '0', full => '0', msg=>str64("Add one more word") ),
--		(data => "11000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "011", q => "00000011", empty => '0', full => '0', msg=>str64("Read first word") ),
--		(data => "11000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "010", q => "00001100", empty => '0', full => '0', msg=>str64("Read second word") ),
--		(data => "11111111", rdreq => '1', wrreq => '1', sclr => '0', usedw => "010", q => "00110000", empty => '0', full => '0', msg=>str64("Read third word + write") ),
--		(data => "11011101", rdreq => '1', wrreq => '0', sclr => '0', usedw => "001", q => "11000000", empty => '0', full => '0', msg=>str64("Read fourth word") ),
--		(data => "11011101", rdreq => '1', wrreq => '0', sclr => '0', usedw => "000", q => "11111111", empty => '1', full => '0', msg=>str64("Read last word in buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "001", q => "--------", empty => '0', full => '0', msg=>str64("Add to buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "010", q => "--------", empty => '0', full => '0', msg=>str64("Add to buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "011", q => "--------", empty => '0', full => '0', msg=>str64("Add to buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "100", q => "--------", empty => '0', full => '0', msg=>str64("Add to buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "101", q => "--------", empty => '0', full => '0', msg=>str64("Add to buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "110", q => "--------", empty => '0', full => '0', msg=>str64("Add to buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "111", q => "--------", empty => '0', full => '0', msg=>str64("Add to buffer") ),
--		(data => "10101010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "000", q => "--------", empty => '0', full => '1', msg=>str64("Buffer now full") ),
--		(data => "00000000", rdreq => '0', wrreq => '1', sclr => '0', usedw => "000", q => "--------", empty => '0', full => '1', msg=>str64("Add to full buffer") ),
--		(data => "11110000", rdreq => '1', wrreq => '1', sclr => '0', usedw => "111", q => "10101010", empty => '0', full => '0', msg=>str64("Read + Add with full buffer") ),
--		(data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "110", q => "10101010", empty => '0', full => '0', msg=>str64("Read buffer") ),
--		(data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "101", q => "10101010", empty => '0', full => '0', msg=>str64("Read buffer") ),
--		(data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "100", q => "10101010", empty => '0', full => '0', msg=>str64("Read buffer") ),
--		(data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "011", q => "10101010", empty => '0', full => '0', msg=>str64("Read buffer") ),
--		(data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "010", q => "10101010", empty => '0', full => '0', msg=>str64("Read buffer") ),
--		(data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "001", q => "10101010", empty => '0', full => '0', msg=>str64("Read buffer") ),
--		(data => "00000000", rdreq => '1', wrreq => '0', sclr => '0', usedw => "000", q => "10101010", empty => '1', full => '0', msg=>str64("Read and empty buffer") ),
--		(data => "11110000", rdreq => '1', wrreq => '1', sclr => '0', usedw => "001", q => "10101010", empty => '0', full => '0', msg=>str64("Read and write to an empty buffer") ),
--		(data => "10111010", rdreq => '1', wrreq => '0', sclr => '0', usedw => "000", q => "11110000", empty => '1', full => '0', msg=>str64("Read last sample from buffer") ),
--		(data => "00001111", rdreq => '1', wrreq => '0', sclr => '0', usedw => "000", q => "11110000", empty => '1', full => '0', msg=>str64("Read from empty buffer") ),
--		-- Test sclr
--		(data => "00000001", rdreq => '0', wrreq => '1', sclr => '0', usedw => "001", q => "--------", empty => '0', full => '0', msg=>str64("Write 00000001") ),
--		(data => "00000010", rdreq => '0', wrreq => '1', sclr => '0', usedw => "010", q => "--------", empty => '0', full => '0', msg=>str64("Write 00000010") ),
--		(data => "00000100", rdreq => '0', wrreq => '1', sclr => '0', usedw => "011", q => "--------", empty => '0', full => '0', msg=>str64("Write 00000100") ),
--		(data => "00000111", rdreq => '0', wrreq => '0', sclr => '1', usedw => "000", q => "--------", empty => '1', full => '0', msg=>str64("sclr") ),
--		--Does sclr take precedent over wrreq?
--		(data => "00000001", rdreq => '0', wrreq => '1', sclr => '0', usedw => "001", q => "--------", empty => '0', full => '0', msg=>str64("Write 00000001") ),
--		(data => "00000111", rdreq => '0', wrreq => '1', sclr => '1', usedw => "000", q => "--------", empty => '1', full => '0', msg=>str64("sclr with write") )
		
--	); 

--begin
----instantiate a scfifo
--fifo : scfifo 
--	generic map
--	(
--			almost_empty_value	=> 2,
--			almost_full_value	=> 6,
--			lpm_numwords		=> 8,
--			lpm_showahead		=> "OFF",
--			lpm_width		=> 8,
--			lpm_widthu		=> 3,
--			overflow_checking	=> "ON",
--			underflow_checking	=> "ON",
--			use_eab			=> "ON"
--	)
--	port map 
--	(
--			aclr		=> aclr,
--			almost_empty 	=> almost_empty,	
--			almost_full	=> almost_full,
--			clock		=> clock,
--			data		=> data,
--			eccstatus	=> eccstatus,		
--			empty		=> empty,	
--			full		=> full,	
--			q		=> q,
--			rdreq		=> rdreq,	
--			sclr		=> sclr,	
--			usedw		=> usedw,
--			wrreq		=> wrreq
--	);
	

----Generate the clock
--clk:	process
--	begin
--		clock <= '0';
--		wait for 10 ns;
--		for n in 1 to 64 loop
--			clock <= '1';
--			wait for 10 ns;		
--			clock <= '0';
--			wait for 10 ns;		
--		end loop;

--		wait;
--	end process;

----Perform tests
--testv:	process

--	begin
--		for n in tests'RANGE loop
--			data	<= tests(n).data;
--			rdreq	<= tests(n).rdreq;
--			wrreq	<= tests(n).wrreq;
--			sclr    <= tests(n).sclr;
--			wait until rising_edge(clock);
--			wait until falling_edge(clock);
--			assert false report tests(n).msg severity note;
--			assert std_match(usedw,tests(n).usedw) report "Unexpected number of words " & to_string(usedw) & " used in buffer" severity error;
--			assert std_match(q,    tests(n).q)     report "Unexpected output: " & to_string(q) severity error;
--			assert std_match(empty,tests(n).empty) report "Unexpected empty bit state" severity error;
--			assert std_match(full, tests(n).full)  report "Unexpected full bit state" severity error;
--		end loop;

--		wait;


--	end process;

--end rtl;
--*/
