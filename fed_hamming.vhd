library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;
use IEEE.NUMERIC_STD.ALL;

entity encoder is
    port(
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        enable    : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR(1 to 8);
        data_out  : out STD_LOGIC_VECTOR(11 downto 0);
        valid     : out STD_LOGIC
    );
end entity encoder;

architecture arc_encoder of encoder is
    signal p : STD_LOGIC_VECTOR(1 to 4);
begin
    process (clk, rst)
    begin
        if rst = '1' then
            p <= (others => '0');
            data_out <= (others => '0');
            valid <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Calculate parity bits
                p(1) <= data_in(1) xor data_in(2) xor data_in(4) xor data_in(5) xor data_in(7);
                p(2) <= data_in(1) xor data_in(3) xor data_in(4) xor data_in(6) xor data_in(7);
                p(3) <= data_in(2) xor data_in(3) xor data_in(4) xor data_in(8);
                p(4) <= data_in(5) xor data_in(6) xor data_in(7) xor data_in(8);

                -- Construct encoded data with parity bits
                data_out <= p(1) & p(2) & data_in(1) & p(3) & data_in(2 to 4) & p(4) & data_in(5 to 8);
                valid <= '1';
            else
                valid <= '0';
            end if;
        end if;
    end process;
end architecture arc_encoder;

entity decoder is 
    port(
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        enable     : in  STD_LOGIC;
        data_in_d  : in  STD_LOGIC_VECTOR(1 to 12);
        data_out_d : out STD_LOGIC_VECTOR(7 downto 0);
        valid_d    : out STD_LOGIC;
        error      : out STD_LOGIC
    );
end entity decoder;

architecture arc_decoder of decoder is
    signal c : STD_LOGIC_VECTOR(1 to 4);
begin
    process(clk, rst)
        variable corrected_data : STD_LOGIC_VECTOR(1 to 12);
    begin
        if rst = '1' then
            c <= (others => '0');
            data_out_d <= (others => '0');
            valid_d <= '0';
            error <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Calculate syndrome bits
                c(1) <= data_in_d(1) xor data_in_d(3) xor data_in_d(5) xor data_in_d(7) xor data_in_d(9) xor data_in_d(11);
                c(2) <= data_in_d(2) xor data_in_d(3) xor data_in_d(6) xor data_in_d(7) xor data_in_d(10) xor data_in_d(11);
                c(3) <= data_in_d(4) xor data_in_d(5) xor data_in_d(6) xor data_in_d(7) xor data_in_d(12);
                c(4) <= data_in_d(8) xor data_in_d(9) xor data_in_d(10) xor data_in_d(11) xor data_in_d(12);

                corrected_data := data_in_d;

                if c /= "0000" then
                    error <= '1';
                    -- Correct single-bit error
                    case to_integer(unsigned(c)) is
                        when 1  => corrected_data(1) := not data_in_d(1);
                        when 2  => corrected_data(2) := not data_in_d(2);
                        when 3  => corrected_data(3) := not data_in_d(3);
                        when 4  => corrected_data(4) := not data_in_d(4);
                        when 5  => corrected_data(5) := not data_in_d(5);
                        when 6  => corrected_data(6) := not data_in_d(6);
                        when 7  => corrected_data(7) := not data_in_d(7);
                        when 8  => corrected_data(8) := not data_in_d(8);
                        when 9  => corrected_data(9) := not data_in_d(9);
                        when 10 => corrected_data(10) := not data_in_d(10);
                        when 11 => corrected_data(11) := not data_in_d(11);
                        when others => corrected_data(12) := not data_in_d(12);
                    end case;
                else
                    error <= '0';
                end if;

                -- Extract original data
                data_out_d <= corrected_data(3) & corrected_data(5 to 7) & corrected_data(9 to 12);
                valid_d <= '1';
            else
                valid_d <= '0';
                error <= '0';
            end if;
        end if;
    end process;
end architecture arc_decoder;