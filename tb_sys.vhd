library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sys is
end entity tb_sys;

architecture bhv of tb_sys is

	-- Deklarációk
	--...
	signal clk_client: std_logic := '0';
	signal clk_server: std_logic:= '0';

	signal rst_n_client: std_logic := '1';
	signal rst_n_server: std_logic:= '1';

	signal client_leds: std_logic_vector (9 downto 0);
	signal server_leds: std_logic_vector (9 downto 0):= (others => '0');

	signal client_switches: std_logic_vector (9 downto 0);

	signal client_trigger_btn_n: std_logic := '1';

	signal client_ssd_digit_0: std_logic_vector (7 downto 0) := X"00";
	signal client_ssd_digit_1: std_logic_vector (7 downto 0) := X"00";
	signal client_ssd_digit_2: std_logic_vector (7 downto 0) := X"00";
	signal client_ssd_digit_3: std_logic_vector (7 downto 0) := X"00";
	
	signal client_tx: std_logic;
	signal server_tx: std_logic;
begin

	-- Kliens órajele (clk_client)
	L_CLK_CLIENT: process begin
		wait for 10 ns;
		clk_client <= not clk_client;
	end process;	
	
	-- Kiszolgáló órajele
	--...
	L_CLK_SERVER: process begin
		wait for 10 ns;
		clk_server <= not clk_server;
	end process;

	-- Kliens példányosítása
	--...
	L_CLIENT: entity work.client_top(rtl)
	port map (
		clk => clk_client,
		rst_n => rst_n_client,
		leds => client_leds,
		switches => client_switches,
		trigger_btn_n => client_trigger_btn_n,
		ssd_digit_0 => client_ssd_digit_0,
		ssd_digit_1 => client_ssd_digit_1,
		ssd_digit_2 => client_ssd_digit_2,
		ssd_digit_3 => client_ssd_digit_3,
		TX => client_tx,
		Rx => server_tx
	);

	
		
	-- Kiszolgáló példányosítása
	--...
	L_SERVER: entity work.server_top(rtl)
	port map (
		clk => clk_server,
		rst_n => rst_n_server,
		leds => server_leds,
		RX => client_tx,
		TX => server_tx
	);
	
	-- Tesztvezérlő
	L_TEST_SEQ: process begin
		
		-- Gerjesztési minták (tesztesetek)
		--... 6 * 7
		wait for 100 ns;
		rst_n_client <= '0';
		rst_n_server <= '0';
		wait for 50 ns;
		rst_n_client <= '1';
		rst_n_server <= '1';

		-- op_a: 7
		wait for 100 ns;
		client_switches <= "0000000111";
		wait for 210 ns;
		client_trigger_btn_n <= '0';
		wait for 210 ns;
		client_trigger_btn_n <= '1';

		-- op_b: 6
		wait for 100 ns;
		client_switches <= "0000000110";
		wait for 210 ns;
		client_trigger_btn_n <= '0';
		wait for 210 ns;
		client_trigger_btn_n <= '1';

		--op_code: 10 (*)
		-- add: 00 sub: 01 mul: 10 div: 11
		wait for 100 ns;
		client_switches <= "0000000010";
		wait for 210 ns;
		client_trigger_btn_n <= '0';
		wait for 210 ns;
		client_trigger_btn_n <= '1';
		
		wait;
	end process;

end architecture bhv;