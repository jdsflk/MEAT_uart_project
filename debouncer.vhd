library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
  generic (
    counter_max:      integer range 10 to 50000000 := 255
  );
  
  port (
    clk, rst:       in  std_logic;
    signal_in:      in  std_logic;
    signal_out:     out std_logic
  );
end entity debouncer;

architecture rtl of debouncer is

  signal signal_in_d:     std_logic;
  signal signal_in_dd:    std_logic;
  signal signal_in_ddd:   std_logic;
  signal signal_in_event: std_logic;
  signal counter:         integer range 0 to counter_max;

begin

  process ( clk, rst )
  begin
    if ( rst = '1' ) then
      signal_in_d <= '0';
      signal_in_dd <= '0';
      signal_in_ddd <= '0';
    elsif ( rising_edge(clk) ) then
      signal_in_d <= signal_in;
      signal_in_dd <= signal_in_d;
      signal_in_ddd <= signal_in_dd;
    end if;
  end process;
  signal_in_event <= signal_in_dd xor signal_in_ddd;
  
  process ( clk, rst )
  begin
    if ( rst = '1' ) then
      counter <= 0;
    elsif ( rising_edge(clk) ) then
      if ( signal_in_event = '1' ) then
        counter <= 0;
      elsif ( counter < counter_max ) then
        counter <= counter + 1;
      end if;
    end if;
  end process;
  
  process ( clk, rst )
  begin
    if ( rst = '1' ) then
      signal_out <= '0';
    elsif ( rising_edge(clk) ) then
      if ( counter = counter_max ) then
        signal_out <= signal_in_ddd;
      end if;
    end if;
  end process;

end architecture rtl;