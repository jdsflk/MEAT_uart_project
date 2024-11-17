library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity my_divisor is
	generic (
		data_width:		integer range 4 to 32
	);
	
	port (
		clk:				in	std_logic;
		rst:				in	std_logic;
		start:				in	std_logic;
		done:				out	std_logic;
		zero_divisor:		out	std_logic;
		divisor:			in	std_logic_vector (data_width-1 downto 0);
		dividend:			in	std_logic_vector (data_width-1 downto 0);
		quotient:			out	std_logic_vector (data_width-1 downto 0);
		remainder:			out	std_logic_vector (data_width-1 downto 0)
	);
end entity my_divisor;

architecture rtl of my_divisor is

	signal tmp:					std_logic_vector (data_width-1 downto 0);
	signal ce_r:				std_logic;
	signal ce_t:				std_logic;
	signal ce_q:				std_logic;
	signal sel_r:				std_logic;
	signal sel_t:				std_logic;
	signal sel_q:				std_logic;
	signal c1:					std_logic;
	signal c2:					std_logic;
	
	type state_t is (s1, s2, s3);
	signal pres_state, next_state: state_t;

begin

	L_TMP: process ( clk, rst ) begin
		if ( rst = '1' ) then tmp <= (others => '0');
		elsif ( rising_edge(clk) ) then
			if ( ce_t = '1' ) then
				if ( sel_t = '0' ) then tmp <= dividend;
				else tmp <= std_logic_vector(unsigned(tmp) - unsigned(divisor));
				end if;
			end if;
		end if;
	end process;
	
	
	
	L_QUOTIENT: process ( clk, rst ) begin
		if ( rst = '1' ) then quotient <= (others => '0');
		elsif ( rising_edge(clk) ) then
			if ( ce_q = '1' ) then
				if ( sel_q = '0' ) then quotient <= (others => '0');
				else quotient <= std_logic_vector(unsigned(quotient) + 1);
				end if;
			end if;
		end if;
	end process;
	
	
	
	L_REMAINDER: process ( clk, rst ) begin
		if ( rst = '1' ) then remainder <= (others => '0');
		elsif ( rising_edge(clk) ) then
			if ( ce_r = '1' ) then
				if ( sel_r = '0' ) then remainder <= (others => '0');
				else remainder <= tmp;
				end if;
			end if;
		end if;
	end process;
	
	
	
	-- Comparators
	c1 <= '1' when unsigned(divisor) = 0 else '0';
	c2 <= '1' when unsigned(divisor) <= unsigned(tmp) else '0';
	
	
	
	L_CTRL_FSM: block begin
	
		L_STATE_REG: process ( clk, rst ) begin
			if ( rst = '1' ) then pres_state <= s1;
			elsif ( rising_edge(clk) ) then pres_state <= next_state;
			end if;
		end process;
		
		L_FSM_LOGIC: process ( pres_state, start, c1, c2 ) begin
			
			-- defaults to prevent latch synthesis...
			next_state <= pres_state;
			done <= '0';
			zero_divisor <= '0';
			ce_r <= '0'; ce_t <= '0'; ce_q <= '0';
			sel_r <= '0'; sel_t <= '0'; sel_q <= '0';
			
			case ( pres_state ) is
			
				when s1	=>	done <= '1';
							zero_divisor <= c1;
							if ( start = '1' and c1 = '0' ) then
								sel_q <= '0'; sel_t <= '0'; sel_r <= '0';
								ce_q <= '1'; ce_t <= '1'; ce_r <= '1';
								next_state <= s2;
							end if;
							
				when s2	=>	next_state <= s3;
				
				when s3	=>	if ( c2 = '1' ) then
								sel_t <= '1'; ce_t <= '1';
								sel_q <= '1'; ce_q <= '1';
								next_state <= s2;
							else
								sel_r <= '1'; ce_r <= '1';
								next_state <= s1;
							end if;
			
				when others	=>	null;
			
			end case;
			
		end process;
	
	end block L_CTRL_FSM;

end architecture rtl;