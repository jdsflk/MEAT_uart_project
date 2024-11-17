library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- IMPORTANT: removed switches input port

entity server_top is
  port (
    clk      : in std_logic;
    rst_n    : in std_logic;
    TX       : out std_logic;
    RX       : in std_logic;
    leds     : out std_logic_vector (9 downto 0)
  );
end entity server_top;

architecture rtl of server_top is

  signal rst      : std_logic;
  signal rst_df0  : std_logic;
  signal rst_sync : std_logic;

  -- További deklarációk
  --...
  signal ut_send_frame  : std_logic;
  signal ut_ready       : std_logic;
  signal ut_data_2_send : std_logic_vector (17 downto 0);

  signal ur_new_frame_received : std_logic;
  signal ur_frame_out          : std_logic_vector (17 downto 0);

  signal error_code          : std_logic_vector (1 downto 0);
  signal dbg_state_indicator : std_logic_vector (2 downto 0);

  signal start_2_alu      : std_logic;
  signal opcode_2_alu     : std_logic_vector (1 downto 0);
  signal alu_done         : std_logic;
  signal alu_zero_divisor : std_logic;
  signal op_a_2_alu       : std_logic_vector (7 downto 0);
  signal op_b_2_alu       : std_logic_vector (7 downto 0);
  signal alu_result_H     : std_logic_vector (7 downto 0);
  signal alu_result_L     : std_logic_vector (7 downto 0);

  type state_t is (
    wait_for_request,
    start_alu,
    wait_for_alu,
    get_result,
    ut_send_disable
  );
  signal state: state_t;
begin

  rst <= not rst_n;

  L_RESET_SYNCHRONIZER : process (clk, rst) begin
    if (rst = '1') then
      rst_df0  <= '1';
      rst_sync <= '1';
    elsif (rising_edge(clk)) then
      rst_df0  <= '0';
      rst_sync <= rst_df0;
    end if;
  end process;

  -- UART adó példányosítás
  --...
  L_UART_TRANSM : entity work.uart_transmitter(rtl)
    generic map(
      clk_pulses_per_baud => 434,
      data_bits           => 18,
      parity              => 0
    )

    port map
    (
      clk         => clk,
      rst         => rst_sync,
      send_frame  => ut_send_frame,
      ready       => ut_ready,
      data_2_send => ut_data_2_send,
      tx          => TX
    );

  -- UART vevő példányosítása
  --...
  L_UART_REC : entity work.uart_receiver(rtl)
  generic map(
    clk_pulses_per_baud => 434,
    data_bits           => 18,
    parity              => 0
  )
  port map
  (
    clk                => clk,
    rst                => rst_sync,
    new_frame_received => ur_new_frame_received,
    frame_out          => ur_frame_out,
    parity_error       => open,
    rx                 => RX
  );

  -- Vezérlő állapotgép
  CTRL_FSM : process (clk, rst_sync) begin
    if (rst_sync = '1') then
      state               <= wait_for_request;
      ut_send_frame       <= '0';
      ut_data_2_send      <= (others => '0');
      op_a_2_alu          <= X"00";
      op_b_2_alu          <= X"00";
      opcode_2_alu        <= "00";
      error_code          <= "00";
      dbg_state_indicator <= "000";
    elsif (rising_edge(clk)) then
      case state is
        when wait_for_request => dbg_state_indicator <= "000";
          if (ur_new_frame_received = '1') then
            opcode_2_alu <= ur_frame_out (17 downto 16);
            op_a_2_alu   <= ur_frame_out (15 downto 8);
            op_b_2_alu   <= ur_frame_out (7 downto 0);
            state        <= start_alu;
          end if;

        when start_alu => dbg_state_indicator <= "001";
          start_2_alu <= '1';
          state       <= wait_for_alu;

        when wait_for_alu => dbg_state_indicator <= "010";
          state <= get_result;

        when get_result => dbg_state_indicator <= "011";
          start_2_alu <= '0';
          if (alu_done = '1') then
            if (ut_ready = '1') then
              error_code     <= alu_zero_divisor & '0';
              ut_data_2_send <= error_code & alu_result_H & alu_result_L;
              ut_send_frame  <= '1';
              state          <= ut_send_disable;
            end if;
          end if;

        when ut_send_disable => dbg_state_indicator <= "100";
          ut_send_frame <= '0';
          state <= wait_for_request;
        when others => null;

      end case;
    end if;
  end process;

  -- ALU példányosítása
  --...
  L_ALU : entity work.my_alu(rtl)
    generic map(
      data_width => 8
    )
    port map
    (
      clk          => clk,
      rst          => rst_sync,
      start        => start_2_alu,
      opcode       => opcode_2_alu,
      done         => alu_done,
      zero_divisor => alu_zero_divisor,
      op_a         => op_a_2_alu,
      op_b         => op_b_2_alu,
      result_H     => alu_result_H,
      result_L     => alu_result_l
    );

  -- LED-ek meghajtása
  leds(9 downto 8) <= error_code;
  leds(2 downto 0) <= dbg_state_indicator;
  leds(7 downto 3) <= (others => '0');

end architecture rtl;