library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity fed_tb is
end entity fed_tb;

architecture arc_fed_tb of fed_tb is
   signal   clk          : std_logic := '0';
   signal   rst          : std_logic := '0';
   signal   en           : std_logic := '1';
   signal   val          : std_logic;
   signal   val_out      : std_logic;
   signal   data         : std_logic_vector(7 downto 0) := (others => '0');
   signal   dout         : std_logic_vector(7 downto 0);
   signal   codeword     : std_logic_vector(11 downto 0);
   signal   data_to_recv : std_logic_vector(11 downto 0) := (others => '0');
begin
   DUT1 : entity work.encoder  -- Use the encoder entity here
      port map (
         clk        => clk,
         rst        => rst,
         enable     => en,
         data_in    => data,
         valid      => val,
         data_out   => codeword);

   DUT2 : entity work.decoder  -- Use the decoder entity here
      port map (
         clk        => clk,
         rst        => rst,
         enable     => val,            
         data_in_d  => data_to_recv,
         data_out_d => dout,
         valid_d    => val_out);

   -- Clock generation
   clk <= not clk after 10 ns;

   -- Reset signal
   process
   begin
      rst <= '1';
      wait for 20 ns;
      rst <= '0';
      wait;
   end process;

   -- Stimulus process
   process is
      variable seed1        : integer := 100;
      variable seed2        : integer := 105;
      variable rand_v       : real;
      variable bit_position : integer range data_to_recv'high downto 0 := 0;
   begin
      -- Wait for reset release
      wait until rst = '0';

      -- Send initial data
      data <= x"ac";
      wait for 20 ns;
      data_to_recv <= codeword;
      wait until rising_edge(clk);

      -- Additional data transactions
      data <= x"31";
      wait for 20 ns;
      data_to_recv <= codeword;
      wait until rising_edge(clk);

      data <= x"12";
      wait for 20 ns;
      data_to_recv <= codeword;
      wait until rising_edge(clk);

      -- 10 packets with injected errors
      for i in 0 to 9 loop
         data <= data + x"7";
         wait for 20 ns;

         uniform(seed1, seed2, rand_v);
         bit_position := integer(real(codeword'high) * rand_v);

         -- Introduce an error in a random bit position
         data_to_recv <= codeword;
         data_to_recv(bit_position) <= not codeword(bit_position);
         
         wait until rising_edge(clk);
         seed1 := seed1 + 1;
         seed2 := seed2 + 1;
      end loop;

      wait;
   end process;
end architecture arc_fed_tb;