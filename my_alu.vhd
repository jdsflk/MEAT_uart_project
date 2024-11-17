library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity my_alu is
	generic (
		data_width:		integer range 4 to 32
	);
	
	port (
		clk:				in	std_logic;
		rst:				in	std_logic;
		start:				in	std_logic;
		opcode:				in	std_logic_vector (1 downto 0);
		done:				out	std_logic;
		zero_divisor:		out	std_logic;
		op_a:				in	std_logic_vector (data_width-1 downto 0);
		op_b:				in	std_logic_vector (data_width-1 downto 0);
		result_H:			out	std_logic_vector (data_width-1 downto 0);
		result_L:			out	std_logic_vector (data_width-1 downto 0)
	);
end entity my_alu;

architecture rtl of my_alu is

	type state_t is (s1, add_1, add_2, sub_1, sub_2, mul_1, mul_2, div_1, div_2, div_3);
	signal state: state_t;
	
	signal tmp:	unsigned (2*data_width-1 downto 0);
	
	signal start_2_div:			std_logic;
	signal div_zero_divisor:	std_logic;
	signal div_done:			std_logic;
	signal div_quotient:		std_logic_vector (data_width-1 downto 0);
	signal div_remainder:		std_logic_vector (data_width-1 downto 0);

begin

	L_CTRL_FSM: process ( clk, rst ) begin
		if ( rst = '1' ) then
			state <= s1;
			tmp <= (others => '0');
			result_H <= (others => '0');
			result_L <= (others => '0');
			start_2_div <= '0';
		elsif ( rising_edge(clk) ) then
		
			case state is
			
				when s1	=>	done <= '1';
						
							if ( start = '1' ) then
								
								case opcode is
									when "00"	=>	done <= '0'; state <= add_1;
									when "01"	=>	done <= '0'; state <= sub_1;
									when "10"	=>	done <= '0'; state <= mul_1;
									when others	=>	if ( div_zero_divisor = '0' ) then done <= '0'; state <= div_1; end if;
								end case;
								
							end if;
							
				when add_1	=>	tmp(2*data_width-1 downto data_width+1) <= (others => '0');
								tmp(data_width downto 0) <= unsigned('0' & op_a) + unsigned('0' & op_b);
								state <= add_2;
								
				when add_2	=>	result_H <= std_logic_vector(tmp(2*data_width-1 downto data_width));
								result_L <= std_logic_vector(tmp(data_width-1 downto 0));
								state <= s1;
								
				when sub_1	=>	tmp(2*data_width-1 downto data_width+1) <= (others => '0');
								tmp(data_width downto 0) <= unsigned('0' & op_a) - unsigned('0' & op_b);
								state <= sub_2;
								
				when sub_2	=>	result_H <= std_logic_vector(tmp(2*data_width-1 downto data_width));
								result_L <= std_logic_vector(tmp(data_width-1 downto 0));
								state <= s1;
								
				when mul_1	=>	tmp <= unsigned(op_a) * unsigned(op_b);
								state <= mul_2;
								
				when mul_2	=>	result_H <= std_logic_vector(tmp(2*data_width-1 downto data_width));
								result_L <= std_logic_vector(tmp(data_width-1 downto 0));
								state <= s1;
				
				when div_1	=>	start_2_div <= '1';
								state <= div_2;
								
				when div_2	=>	start_2_div <= '0';
								state <= div_3;
								
				when div_3	=>	if ( div_done = '1' ) then
									result_H <= div_quotient;
									result_L <= div_remainder;
									state <= s1;
								end if;
				
				when others	=> null;
			
			end case;
		
		end if;
	end process;
	
	L_DIV:	entity work.my_divisor(rtl)
				generic map (data_width => data_width)
				port map (
					clk				=> clk,
					rst				=> rst,
					start			=> start_2_div,
					done			=> div_done,
					zero_divisor	=> div_zero_divisor,
					dividend		=> op_a,
					divisor			=> op_b,
					quotient		=> div_quotient,
					remainder		=> div_remainder
				);
				
	zero_divisor <= div_zero_divisor when opcode = "11" else '0';

end architecture rtl;