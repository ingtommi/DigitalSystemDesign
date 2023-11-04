library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
    port(
     clk, rst : in std_logic;
     p1, p2, p3, p4 : in std_logic_vector(7 downto 0); -- data
     w1, w2, w3, w4 : in std_logic_vector(7 downto 0); -- data
     e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12 : in std_logic; -- enables
     s1, s2, s3, s4, s5 : in std_logic; -- selectors
     res : out std_logic_vector(17 downto 0) -- result
    );
end datapath;


architecture Behavioral of datapath is
    signal rp1, rp2, rp3, rp4 : std_logic_vector(8 downto 0); -- input storage (additional bit for sign)
    signal rw1, rw2, rw3, rw4 : std_logic_vector(7 downto 0); -- input storage

    signal r1, r2 : signed(15 downto 0); -- multiplication storages
    signal r2_temp : std_logic_vector(15 downto 0);
    signal r3, r4 : signed(17 downto 0); -- addition storages (2 additional bits to store max value)
    
    signal mul1, mul2 : signed(16 downto 0);
    signal add1, add2 : signed(17 downto 0);
    
    signal mux1, mux3 : signed(8 downto 0);
    signal mux2, mux4 : signed(7 downto 0);
    signal mux5 : signed(17 downto 0);
    
begin
    -- multiplier 1
    mul1 <= mux1 * mux2;
    
    -- multiplier 2
    mul2 <= mux3 * mux4;

    -- adder 1
    add1 <= r1 + mux5;
    
    -- adder 2
    add2 <= r2 + add1;
    
    -- mux 1
    mux1 <= signed(rp3) when (s1 = '0') else
            signed(rp2);
     
    -- mux 2
    mux2 <= signed(rw3) when (s2 = '0') else
            signed(rw2);
    
    -- mux 3
    mux3 <= signed(rp4) when (s3 = '0') else
            signed(rp1);
    
    -- mux 4
    mux4 <= signed(rw4) when (s4 = '0') else
            signed(rw1);
     
    -- mux 5
    r2_temp <= std_logic_vector(r2);
    mux5 <= signed("00" & r2_temp) when (s5 = '0' and r2_temp(r2_temp'high) = '0') else -- padding
            signed("11" & r2_temp) when (s5 = '0' and r2_temp(r2_temp'high) = '1') else -- padding
            r3;
            
    -- output
    res <= std_logic_vector(r4);
            
    -- register 1
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r1 <= (others => '0');
            elsif e1 = '1' then
                r1 <= mul1(15 downto 0); -- MSB always 0 (sign of p)
            end if;
        end if;
    end process;
     
    -- register 2
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r2 <= (others => '0');
            elsif e2 = '1' then
                r2 <= mul2(15 downto 0); -- MSB always 0 (sign of p)
            end if;
        end if;
    end process;
     
    -- register 3
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r3 <= (others => '0');
            elsif e3 = '1' then
                r3 <= add1;
            end if;
         end if;
    end process;
    
    -- register 4
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r4 <= (others => '0');
            elsif e4 = '1' then
                r4 <= add2;
            end if;
         end if;
    end process;
     
    -- register p1
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rp1 <= (others => '0');
            elsif e5 = '1' then
                rp1 <= '0' & p1;
            end if;
        end if;
    end process;
     
    -- register p2
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rp2 <= (others => '0');
            elsif e6 = '1' then
                rp2 <= '0' & p2;
            end if;
        end if;
    end process;
     
    -- register p3
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rp3 <= (others => '0');
            elsif e7 = '1' then
                rp3 <= '0' & p3;
            end if;
        end if;
    end process;
     
    -- register p4
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rp4 <= (others => '0');
            elsif e8 = '1' then
                rp4 <= '0' & p4;
            end if;
        end if;
    end process;
     
    -- register w1
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rw1 <= (others => '0');
            elsif e9 = '1' then
                rw1 <= w1;
            end if;
        end if;
    end process;
     
    -- register w2
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rw2 <= (others => '0');
            elsif e10 = '1' then
                rw2 <= w2;
            end if;
        end if;
    end process;
     
    -- register w3
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rw3 <= (others => '0');
            elsif e11 = '1' then
                rw3 <= w3;
            end if;
        end if;
    end process;
     
    -- register w4
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rw4 <= (others => '0');
            elsif e12 = '1' then
                rw4 <= w4;
            end if;
        end if;
    end process;

end Behavioral;