library ieee;
use ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity fifo_test is
end fifo_test;

architecture rtl of fifo_test is
	--Component declaration
	component scfifo
		generic (
			add_ram_output_register	:	string := "OFF";
			allow_rwcycle_when_full	:	string := "OFF";
			almost_empty_value	:	natural := 0;
			almost_full_value	:	natural := 0;
			intended_device_family	:	string := "Cyclone V";
			enable_ecc		:	string := "FALSE";
			lpm_numwords		:	natural;
			lpm_showahead		:	string := "OFF";
			lpm_width		:	natural;
			lpm_widthu		:	natural := 1;
			overflow_checking	:	string := "ON";
			ram_block_type		:	string := "AUTO";
			underflow_checking	:	string := "ON";
			use_eab			:	string := "ON";
			lpm_hint		:	string := "UNUSED";
			lpm_type		:	string := "scfifo"
		);
		port(
			aclr		:	in std_logic := '0';
			almost_empty	:	out std_logic;
			almost_full	:	out std_logic;
			clock		:	in std_logic;
			data		:	in std_logic_vector(lpm_width-1 downto 0);
			eccstatus	:	out std_logic_vector(1 downto 0);
			empty		:	out std_logic;
			full		:	out std_logic;
			q		:	out std_logic_vector(lpm_width-1 downto 0);
			rdreq		:	in std_logic;
			sclr		:	in std_logic := '0';
			usedw		:	out std_logic_vector(lpm_widthu-1 downto 0);
			wrreq		:	in std_logic
		);
	end component;
	
	-- internal signals
	signal aclr		:	std_logic := '0';
	signal almost_empty	:	std_logic;
	signal almost_full	:	std_logic;
	signal clock		:	std_logic;
	signal data		:	std_logic_vector(7 downto 0);
	signal eccstatus	:	std_logic_vector(1 downto 0);
	signal empty		:	std_logic;
	signal full		:	std_logic;
	signal q		:	std_logic_vector(7 downto 0);
	signal rdreq		:	std_logic;
	signal sclr		:	std_logic := '0';
	signal usedw		:	std_logic_vector(2 downto 0);
	signal wrreq		:	std_logic;	

begin

--instantiate a scfifo
fifo : scfifo 
	generic map
	(
			add_ram_output_register	=>	 "OFF",
			allow_rwcycle_when_full	=>	 "OFF",
			almost_empty_value	=>	2,
			almost_full_value	=>	6,
			intended_device_family	=>	 "Cyclone V",
			enable_ecc		=>	 "FALSE",
			lpm_numwords		=>	8,
			lpm_showahead		=>	 "OFF",
			lpm_width		=>	8,
			lpm_widthu		=>	3,
			overflow_checking	=>	 "ON",
			ram_block_type		=>	 "AUTO",
			underflow_checking	=>	 "ON",
			use_eab			=>	 "ON",
			lpm_hint		=>	 "UNUSED",
			lpm_type		=>	 "scfifo"
	)
	port map 
	(
			aclr		=> aclr,
			almost_empty 	=> almost_empty,	
			almost_full	=> almost_full,
			clock		=> clock,
			data		=> data,
			eccstatus	=> eccstatus,		
			empty		=> empty,	
			full		=> full,	
			q		=> q,
			rdreq		=> rdreq,	
			sclr		=> sclr,	
			usedw		=> usedw,
			wrreq		=> wrreq
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
		data <= "00000000";
		rdreq <= '0';
		wrreq <= '0';
		wait until falling_edge(clock);
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '1' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "00000011";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		-- don't add
		data <= "10101010";
		rdreq <= '0';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "00001100";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "00110000";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "011"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		-- don't add
		data <= "01010101";
		rdreq <= '0';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "011"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "11000000";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "100"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Read a word
		data <= "11000000";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "011"  report "Wrong number of samples" severity error;
		assert q = "00000011" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Read a word
		data <= "11000000";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00001100" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Nothing
		data <= "10011100";
		rdreq <= '0';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00001100" report "Wrong output"            severity error;

		--Add and read a word
		data <= "11111111";
		rdreq <= '1';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00110000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Read a word
		data <= "11011101";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "Wrong number of samples" severity error;
		assert q = "11000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;


		--Read a word
		data <= "11011101";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "11111111" report "Wrong output"            severity error;
		assert empty = '1' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Log to terminal
		assert false report "Next: fill the fifo" severity note;

		--Now we fill the fifo
		data <= "10101010";
		rdreq <= '0';
		wrreq <= '1';		
		for n in 1 to 8 loop
			wait until rising_edge(clock);
			wait until falling_edge(clock);
		end loop;		
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "11111111" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '1' report "Full bit unexpected"        severity error;	

		--Add a word (should be dropped)
		data <= "00000000";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "11111111" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '1' report "Full bit unexpected"        severity error;


		--Add and read a word on a full fifo (edge case - write fails then read succeeds)
		data <= "11110000";
		rdreq <= '1';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "111"  report "edge: Wrong number of samples" severity error;
		assert q = "10101010" report "edge: Wrong output"            severity error;
		assert empty = '0' report "Edge: mpty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;
				

		--Read back remaining 7 words in the buffer
		data <= "00000000";
		rdreq <= '1';
		wrreq <= '0';		
		for n in 1 to 7 loop
			wait until rising_edge(clock);
			wait until falling_edge(clock);
			assert q = "10101010" report "Wrong output"    severity error;
		end loop;	
	
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert empty = '1' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;	

		--Add and read a word on an empty fifo (edge case - read fails, write succeeds - output remains unchanged from previous)
		data <= "11110000";
		rdreq <= '1';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "edge: Wrong number of samples" severity error;
		assert q = "10101010" report "edge: Wrong output"            severity error;
		assert empty = '0' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;

		--Read back last write to empty the buffer once more
		data <= "10111010";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert q = "11110000" report "edge: Wrong output"            severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;

		--Read empty buffer
		data <= "00001111";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert q = "11110000" report "edge: Wrong output"            severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;

		--Add three samples to the empty buffer
		data <= "00000001";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000010";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000100";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		--Clear with sclr
		rdreq <= '0';
		wrreq <= '0';
		sclr <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;
		
		--Add three samples to the empty buffer
		data <= "00000001";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000010";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000100";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		--Clear with sclr and write at the same time
		rdreq <= '0';
		wrreq <= '1';
		sclr <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;
		wait;


	end process;

end rtl;




-- //////////////////////////////////////////////////////////////////////////////////////////////////////
-- //////////////////////////////////////////////////////////////////////////////////////////////////////
/*
library ieee;
use ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity fifo_test is
end fifo_test;

architecture rtl of fifo_test is
	--Component declaration
	component scfifo
		generic (
			add_ram_output_register	:	string := "OFF";
			allow_rwcycle_when_full	:	string := "OFF";
			almost_empty_value	:	natural := 0;
			almost_full_value	:	natural := 0;
			intended_device_family	:	string := "Cyclone IV";
			enable_ecc		:	string := "FALSE";
			lpm_numwords		:	natural;
			lpm_showahead		:	string := "OFF";
			lpm_width		:	natural;
			lpm_widthu		:	natural := 1;
			overflow_checking	:	string := "ON";
			ram_block_type		:	string := "AUTO";
			underflow_checking	:	string := "ON";
			use_eab			:	string := "ON";
			lpm_hint		:	string := "UNUSED";
			lpm_type		:	string := "scfifo"
		);
		port(
			aclr		:	in std_logic := '0';
			almost_empty	:	out std_logic;
			almost_full	:	out std_logic;
			clock		:	in std_logic;
			data		:	in std_logic_vector(lpm_width-1 downto 0);
			eccstatus	:	out std_logic_vector(1 downto 0);
			empty		:	out std_logic;
			full		:	out std_logic;
			q		:	out std_logic_vector(lpm_width-1 downto 0);
			rdreq		:	in std_logic;
			sclr		:	in std_logic := '0';
			usedw		:	out std_logic_vector(lpm_widthu-1 downto 0);
			wrreq		:	in std_logic
		);
	end component;
	
	-- internal signals
	signal aclr		:	std_logic := '0';
	signal almost_empty	:	std_logic;
	signal almost_full	:	std_logic;
	signal clock		:	std_logic;
	signal data		:	std_logic_vector(7 downto 0);
	signal eccstatus	:	std_logic_vector(1 downto 0);
	signal empty		:	std_logic;
	signal full		:	std_logic;
	signal q		:	std_logic_vector(7 downto 0);
	signal rdreq		:	std_logic;
	signal sclr		:	std_logic := '0';
	signal usedw		:	std_logic_vector(2 downto 0);
	signal wrreq		:	std_logic;	

begin

--instantiate a scfifo
fifo : scfifo 
	generic map
	(
			almost_empty_value	=> 2,
			almost_full_value	=> 6,
			lpm_numwords		=> 8,
			lpm_showahead		=> "OFF",
			lpm_width		=> 8,
			lpm_widthu		=> 3,
			overflow_checking	=> "ON",
			underflow_checking	=> "ON",
			use_eab			=> "ON"
	)
	port map 
	(
			aclr		=> aclr,
			almost_empty 	=> almost_empty,	
			almost_full	=> almost_full,
			clock		=> clock,
			data		=> data,
			eccstatus	=> eccstatus,		
			empty		=> empty,	
			full		=> full,	
			q		=> q,
			rdreq		=> rdreq,	
			sclr		=> sclr,	
			usedw		=> usedw,
			wrreq		=> wrreq
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
		data <= "00000000";
		rdreq <= '0';
		wrreq <= '0';
		wait until falling_edge(clock);
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '1' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "00000011";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		-- don't add
		data <= "10101010";
		rdreq <= '0';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "00001100";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "00110000";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "011"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		-- don't add
		data <= "01010101";
		rdreq <= '0';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "011"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Add a word
		data <= "11000000";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "100"  report "Wrong number of samples" severity error;
		assert q = "00000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Read a word
		data <= "11000000";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "011"  report "Wrong number of samples" severity error;
		assert q = "00000011" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Read a word
		data <= "11000000";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00001100" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Nothing
		data <= "10011100";
		rdreq <= '0';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00001100" report "Wrong output"            severity error;

		--Add and read a word
		data <= "11111111";
		rdreq <= '1';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "010"  report "Wrong number of samples" severity error;
		assert q = "00110000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Read a word
		data <= "11011101";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "Wrong number of samples" severity error;
		assert q = "11000000" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;


		--Read a word
		data <= "11011101";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "11111111" report "Wrong output"            severity error;
		assert empty = '1' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;

		--Log to terminal
		assert false report "Next: fill the fifo" severity note;

		--Now we fill the fifo
		data <= "10101010";
		rdreq <= '0';
		wrreq <= '1';		
		for n in 1 to 8 loop
			wait until rising_edge(clock);
			wait until falling_edge(clock);
		end loop;		
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "11111111" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '1' report "Full bit unexpected"        severity error;	

		--Add a word (should be dropped)
		data <= "00000000";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert q = "11111111" report "Wrong output"            severity error;
		assert empty = '0' report "Empty bit unexpected"       severity error;
		assert full  = '1' report "Full bit unexpected"        severity error;


		--Add and read a word on a full fifo (edge case - write fails then read succeeds)
		data <= "11110000";
		rdreq <= '1';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "111"  report "edge: Wrong number of samples" severity error;
		assert q = "10101010" report "edge: Wrong output"            severity error;
		assert empty = '0' report "Edge: mpty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;
				

		--Read back remaining 7 words in the buffer
		data <= "00000000";
		rdreq <= '1';
		wrreq <= '0';		
		for n in 1 to 7 loop
			wait until rising_edge(clock);
			wait until falling_edge(clock);
			assert q = "10101010" report "Wrong output"    severity error;
		end loop;	
	
		assert usedw = "000"  report "Wrong number of samples" severity error;
		assert empty = '1' report "Empty bit unexpected"       severity error;
		assert full  = '0' report "Full bit unexpected"        severity error;	

		--Add and read a word on an empty fifo (edge case - read fails, write succeeds - output remains unchanged from previous)
		data <= "11110000";
		rdreq <= '1';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "001"  report "edge: Wrong number of samples" severity error;
		assert q = "10101010" report "edge: Wrong output"            severity error;
		assert empty = '0' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;

		--Read back last write to empty the buffer once more
		data <= "10111010";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert q = "11110000" report "edge: Wrong output"            severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;

		--Read empty buffer
		data <= "00001111";
		rdreq <= '1';
		wrreq <= '0';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert q = "11110000" report "edge: Wrong output"            severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;

		--Add three samples to the empty buffer
		data <= "00000001";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000010";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000100";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		--Clear with sclr
		rdreq <= '0';
		wrreq <= '0';
		sclr <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;
		
		--Add three samples to the empty buffer
		data <= "00000001";
		rdreq <= '0';
		wrreq <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000010";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		data <= "00000100";
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		--Clear with sclr and write at the same time
		rdreq <= '0';
		wrreq <= '1';
		sclr <= '1';
		wait until rising_edge(clock);
		wait until falling_edge(clock);
		assert usedw = "000"  report "edge: Wrong number of samples" severity error;
		assert empty = '1' report "Edge: Empty bit unexpected"       severity error;
		assert full  = '0' report "Edge: Full bit unexpected"        severity error;
		wait;


	end process;

end rtl;
*/
