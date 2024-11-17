library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_transmitter is
	generic (
		clk_pulses_per_baud:	integer range 50 to 200000;
		data_bits:				integer range 8 to 32;
		parity:					integer range 0 to 2			-- 0: no parity; 1: even; 2: odd
	);
	
	port (
		clk:			in	std_logic;
		rst:			in	std_logic;
		send_frame:		in	std_logic;
		ready:			out	std_logic;
		data_2_send:	in	std_logic_vector (data_bits-1 downto 0);
		tx:				out	std_logic
	);
end entity uart_transmitter;

architecture rtl of uart_transmitter is

	type state_t is (idle, send_start_bit, send_data, set_parity, send_parity, send_stop, wait_for_deassert_send);
	signal state: state_t;
	
	signal transmit_buffer:	std_logic_vector (data_bits-1 downto 0);
	signal bit_pointer:		integer range 0 to data_bits-1;
	signal delay_counter:	integer range 0 to clk_pulses_per_baud;

begin

	L_TRANSMITTER: process ( clk, rst )
		variable even_parity:	std_logic;
	begin
		if ( rst = '1' ) then
			state <= idle;
			tx <= '1';
			ready <= '1';
			transmit_buffer <= (others => '0');
			bit_pointer <= 0;
			delay_counter <= 0;
		elsif ( rising_edge(clk) ) then
			case state is
				when idle	=>	if ( send_frame = '1' ) then
									ready <= '0';
									transmit_buffer <= data_2_send;
									state <= send_start_bit;
								end if;
												
				when send_start_bit =>	tx <= '0';
										if ( delay_counter < clk_pulses_per_baud ) then
											delay_counter <= delay_counter + 1;
										else
											delay_counter <= 0;
											state <= send_data;
										end if;
										
				when send_data	=>	tx <= transmit_buffer(bit_pointer);
									
									if ( delay_counter < clk_pulses_per_baud ) then
										delay_counter <= delay_counter + 1;
									else
										delay_counter <= 0;
										
										if ( bit_pointer < data_bits-1 ) then
											bit_pointer <= bit_pointer + 1;
										else
											bit_pointer <= 0;
											if ( parity /= 0 ) then state <= set_parity;
											else state <= send_stop;
											end if;
										end if;
										
									end if;
												
				when set_parity	=>	even_parity := '0';
				
									for i in 0 to data_bits-1 loop
										even_parity := even_parity xor transmit_buffer(i);
									end loop;
									
									if ( parity = 2 ) then tx <= not even_parity;
									else tx <= even_parity; end if;
									
									state <= send_parity;
									
				when send_parity	=>	if ( delay_counter < clk_pulses_per_baud ) then
											delay_counter <= delay_counter + 1;
										else
											delay_counter <= 0;
											state <= send_stop;
										end if;
										
				when send_stop	=>	tx <= '1';
									if ( delay_counter < clk_pulses_per_baud ) then
										delay_counter <= delay_counter + 1;
									else
										delay_counter <= 0;
										ready <= '1';
										state <= wait_for_deassert_send;
									end if;
									
				when wait_for_deassert_send	=>	state <= idle;
				
				when others	=>	null;
				
			end case;
		end if;
	end process;

end architecture rtl;