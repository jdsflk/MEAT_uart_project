library ieee;
use ieee.std_logic_1164.all;
---------------------------------------------------------------------------------------------------
entity seven_segment_encoder is
	port (
		data_in:						in	std_logic_vector (3 downto 0);
		dp_off:							in	std_logic;
		data_out:						out	std_logic_vector (7 downto 0)
	);
end entity seven_segment_encoder;
---------------------------------------------------------------------------------------------------
architecture rtl of seven_segment_encoder is
begin

	process ( data_in, dp_off )
	begin
		case data_in is
			when X"0"	=>	data_out <= dp_off & B"1000000";
			when X"1"	=>	data_out <= dp_off & B"1111001";
			when X"2"	=>	data_out <= dp_off & B"0100100";
			when X"3"	=>	data_out <= dp_off & B"0110000";
			when X"4"	=>	data_out <= dp_off & B"0011001";
			when X"5"	=>	data_out <= dp_off & B"0010010";
			when X"6"	=>	data_out <= dp_off & B"0000010";
			when X"7"	=>	data_out <= dp_off & B"1111000";
			when X"8"	=>	data_out <= dp_off & B"0000000";
			when X"9"	=>	data_out <= dp_off & B"0010000";
			when X"A"	=>	data_out <= dp_off & B"0001000";
			when X"B"	=>	data_out <= dp_off & B"0000011";
			when X"C"	=>	data_out <= dp_off & B"1000110";
			when X"D"	=>	data_out <= dp_off & B"0100001";
			when X"E"	=>	data_out <= dp_off & B"0000110";
			when X"F"	=>	data_out <= dp_off & B"0001110";
			when others	=>	data_out <= dp_off & B"1111111";
		end case;
	end process;
	
end architecture rtl;
---------------------------------------------------------------------------------------------------