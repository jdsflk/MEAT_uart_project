library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_receiver is
	generic (
		clk_pulses_per_baud:	integer range 50 to 200000;
		data_bits:				integer range 8 to 32;
		parity:					integer range 0 to 2			-- 0: no parity; 1: even; 2: odd
	);
	
	port (
		clk:				in	std_logic;
		rst:				in	std_logic;
		rx:					in	std_logic;
		new_frame_received:	out	std_logic;
		frame_out:			out	std_logic_vector (data_bits-1 downto 0);
		parity_error:		out	std_logic
	);
end entity uart_receiver;

architecture rtl of uart_receiver is

	signal rx_dff0, rx_dff1, rx_dff2:		std_logic;
	signal rx_falling:						std_logic;

	type state_t is (idle, get_start, get_data, get_parity, check_parity, write_output);
	signal state: state_t;
	
	signal delay_counter:					integer range 0 to clk_pulses_per_baud;
	signal bit_pointer:						integer range 0 to data_bits-1;
	signal receive_buffer:					std_logic_vector (data_bits-1 downto 0);
	signal received_parity:					std_logic;
	signal sample_1, sample_2, sample_3:	std_logic;

begin

	L_INOUT_META_FILTER: process ( clk, rst )
	begin
		if ( rst = '1' ) then
			rx_dff0 <= '1';
			rx_dff1 <= '1';
			rx_dff2 <= '1';
		elsif ( rising_edge(clk) ) then
			rx_dff0 <= rx;
			rx_dff1 <= rx_dff0;
			rx_dff2 <= rx_dff1;
		end if;
	end process;
	rx_falling <= rx_dff2 and not rx_dff1;

	L_FSM: process ( clk, rst )
		variable even_parity: std_logic;
	begin
		if ( rst = '1' ) then
			state <= idle;
			new_frame_received <= '0';
			frame_out <= (others => '0');
			bit_pointer <= 0;
			delay_counter <= 0;
			receive_buffer <= (others => '0');
			received_parity <= '0';
			sample_1 <= '0';
			sample_2 <= '0';
			sample_3 <= '0';
			parity_error <= '0';
		elsif ( rising_edge(clk) ) then
			case state is 
				when idle	=>	new_frame_received <= '0';
								parity_error <= '0';
								
								if ( rx_falling = '1' ) then
									state <= get_start;
								end if;
								
				when get_start	=>	if ( delay_counter < clk_pulses_per_baud ) then
										delay_counter <= delay_counter + 1;
									else
										delay_counter <= 0;
										state <= get_data;
									end if;
									
				when get_data	=>	if ( delay_counter = clk_pulses_per_baud/3 ) then sample_1 <= rx_dff2; end if;
									if ( delay_counter = clk_pulses_per_baud/2 ) then sample_2 <= rx_dff2; end if;
									if ( delay_counter = (2*clk_pulses_per_baud)/3 ) then sample_3 <= rx_dff2; end if;
									
									if ( delay_counter = clk_pulses_per_baud ) then
										delay_counter <= 0;
										receive_buffer(bit_pointer) <= (sample_1 and sample_2) or (sample_1 and sample_3) or (sample_2 and sample_3);
										
										if ( bit_pointer < data_bits-1 ) then
											bit_pointer <= bit_pointer + 1;
										else
											bit_pointer <= 0;
											
											if ( parity /= 0 ) then
												state <= get_parity;
											else
												state <= write_output;
											end if;
											
										end if;
										
									else
										delay_counter <= delay_counter + 1;
									end if;
									
				when get_parity	=>	if ( delay_counter = clk_pulses_per_baud/3 ) then sample_1 <= rx_dff2; end if;
									if ( delay_counter = clk_pulses_per_baud/2 ) then sample_2 <= rx_dff2; end if;
									if ( delay_counter = (2*clk_pulses_per_baud)/3 ) then sample_3 <= rx_dff2; end if;
									
									if ( delay_counter = clk_pulses_per_baud ) then
										delay_counter <= 0;
										received_parity <= (sample_1 and sample_2) or (sample_1 and sample_3) or (sample_2 and sample_3);
										state <= check_parity;
									else
										delay_counter <= delay_counter + 1;
									end if;
									
				when check_parity	=>	even_parity := '0';
				
										for i in 0 to data_bits-1 loop
											even_parity := even_parity xor receive_buffer(i);
										end loop;
										
										if ( parity = 1 ) then	-- even
											if ( received_parity /= even_parity ) then parity_error <= '1';
											else parity_error <= '0'; end if;
										else	-- odd
											if ( received_parity = even_parity ) then parity_error <= '1';
											else parity_error <= '0'; end if;
										end if;
										
										new_frame_received <= '1';
										frame_out <= receive_buffer;
										state <= idle;
										
				when write_output	=>	new_frame_received <= '1';
										frame_out <= receive_buffer;
										state <= idle;
				
				when others	=>	null;
			end case;
		end if;
	end process;

end architecture rtl;