library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity client_top is
  port (
    clk           : in std_logic;
    rst_n         : in std_logic;
    TX            : out std_logic;
    RX            : in std_logic;
    leds          : out std_logic_vector (9 downto 0);
    switches      : in std_logic_vector (9 downto 0);
    trigger_btn_n : in std_logic;
    ssd_digit_0   : out std_logic_vector (7 downto 0);
    ssd_digit_1   : out std_logic_vector (7 downto 0);
    ssd_digit_2   : out std_logic_vector (7 downto 0);
    ssd_digit_3   : out std_logic_vector (7 downto 0)
  );
end entity client_top;

architecture rtl of client_top is

  signal rst      : std_logic;
  signal rst_df0  : std_logic;
  signal rst_sync : std_logic;

  signal trigger           : std_logic;
  signal trg_debounced     : std_logic;
  signal trg_debounced_df0 : std_logic;
  signal trg_rising        : std_logic;

  type state_t is (
    wait_for_op_a, wait_for_op_b, wait_for_opcode, send_command, get_reply
  );
  signal state : state_t;

  signal ut_send_frame         : std_logic;
  signal ut_ready              : std_logic;
  signal ut_data_2_send        : std_logic_vector (17 downto 0);
  signal ur_new_frame_received : std_logic;
  signal ur_frame_out          : std_logic_vector (17 downto 0);
  signal op_a                  : std_logic_vector (7 downto 0);
  signal op_b                  : std_logic_vector (7 downto 0);
  signal opcode                : std_logic_vector (1 downto 0);
  signal error_code            : std_logic_vector (1 downto 0);
  signal disp_digit_0          : std_logic_vector (3 downto 0);
  signal disp_digit_1          : std_logic_vector (3 downto 0);
  signal disp_digit_2          : std_logic_vector (3 downto 0);
  signal disp_digit_3          : std_logic_vector (3 downto 0);
  signal dbg_state_indicator   : std_logic_vector (2 downto 0);

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

  trigger <= not trigger_btn_n;

  L_DEBOUNCER : entity work.debouncer(rtl)
    generic map(
      -- 10 -> 200ns
      counter_max => 10 -- 0.4 ms @ 50 MHz
    )

    port map
    (
      clk        => clk,
      rst => rst_sync,
      signal_in  => trigger,
      signal_out => trg_debounced
    );

  L_EDGE_DETECTOR : process (clk, rst_sync) begin
    if (rst_sync = '1') then
      trg_debounced_df0 <= '0';
    elsif (rising_edge(clk)) then
      trg_debounced_df0 <= trg_debounced;
    end if;
  end process;
  trg_rising <= trg_debounced and not trg_debounced_df0;

  L_UART_TRANSM : entity work.uart_transmitter(rtl)
    generic map(
      clk_pulses_per_baud => 434, -- 115.2 kbps @ 50 MHz
      data_bits           => 18,
      parity              => 0 -- none
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

  L_UART_REC : entity work.uart_receiver(rtl)
    generic map(
      clk_pulses_per_baud => 434, -- 115.2 kbps @ 50 MHz
      data_bits           => 18,
      parity              => 0 -- none
    )

    port map
    (
      clk                => clk,
      rst                => rst_sync,
      rx                 => RX,
      new_frame_received => ur_new_frame_received,
      frame_out          => ur_frame_out,
      parity_error       => open
    );

  CTRL_FSM : process (clk, rst_sync) begin
    if (rst_sync = '1') then
      state               <= wait_for_op_a;
      ut_send_frame       <= '0';
      ut_data_2_send      <= (others => '0');
      op_a                <= X"00";
      op_b                <= X"00";
      opcode              <= "00";
      error_code          <= "00";
      disp_digit_3        <= X"0";
      disp_digit_2        <= X"0";
      disp_digit_1        <= X"0";
      disp_digit_0        <= X"0";
      dbg_state_indicator <= "000";
    elsif (rising_edge(clk)) then
      case state is

        when wait_for_op_a => dbg_state_indicator <= "000";

          if (trg_rising = '1') then
            op_a  <= switches(7 downto 0);
            state <= wait_for_op_b;
          end if;

        when wait_for_op_b => dbg_state_indicator <= "001";

          if (trg_rising = '1') then
            op_b  <= switches(7 downto 0);
            state <= wait_for_opcode;
          end if;

        when wait_for_opcode => dbg_state_indicator <= "010";

          if (trg_rising = '1') then
            opcode <= switches(1 downto 0);
            state  <= send_command;
          end if;

        when send_command => dbg_state_indicator <= "011";

          ut_data_2_send <= opcode & op_a & op_b;
          ut_send_frame  <= '1';
          state          <= get_reply;

        when get_reply => dbg_state_indicator <= "100";
          ut_send_frame                         <= '0';

          if (ur_new_frame_received = '1') then
            error_code <= ur_frame_out(17 downto 16);

            disp_digit_3 <= ur_frame_out(15 downto 12);
            disp_digit_2 <= ur_frame_out(11 downto 8);
            disp_digit_1 <= ur_frame_out(7 downto 4);
            disp_digit_0 <= ur_frame_out(3 downto 0);

            state <= wait_for_op_a;
          end if;

        when others => null;

      end case;
    end if;
  end process;

  L_SSD_ENCODER_DIGIT_0 : entity work.seven_segment_encoder(rtl)
    port map
    (
      data_in  => disp_digit_0,
      dp_off   => '1',
      data_out => ssd_digit_0
    );

  L_SSD_ENCODER_DIGIT_1 : entity work.seven_segment_encoder(rtl)
    port map
    (
      data_in  => disp_digit_1,
      dp_off   => '1',
      data_out => ssd_digit_1
    );

  L_SSD_ENCODER_DIGIT_2 : entity work.seven_segment_encoder(rtl)
    port map
    (
      data_in  => disp_digit_2,
      dp_off   => '1',
      data_out => ssd_digit_2
    );

  L_SSD_ENCODER_DIGIT_3 : entity work.seven_segment_encoder(rtl)
    port map
    (
      data_in  => disp_digit_3,
      dp_off   => '1',
      data_out => ssd_digit_3
    );
  -- LED-ek meghajtása...
  leds(9 downto 8) <= error_code;
  leds(2 downto 0) <= dbg_state_indicator;
  leds(7 downto 3) <= (others => '0');

end architecture rtl;