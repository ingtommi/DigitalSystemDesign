library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
    port(   
      value : in std_logic_vector(11 downto 0); -- MSB represents sign
      sel_disp : in std_logic; -- 2 oprtions: R1, R2
      sel_add_sub : in std_logic; -- 2 options: ADD, SUB
      sel_mux : in std_logic_vector(2 downto 0); -- 6 options: ADD/SUB, MUL, NAND, NOR, SRA, L2
      en_r1, en_r2 : in std_logic;
      clk, rst : in std_logic;
      res : out std_logic_vector(16 downto 0)); -- R2 length (1 sign + 16 magnitude)
end datapath;

architecture behavioral of datapath is
    signal res_2c : std_logic_vector(16 downto 0);
    signal value_2c : std_logic_vector(11 downto 0) := (others => '0');
    signal register1 : std_logic_vector(11 downto 0) := (others => '0'); -- 0 for simulation
    signal r1_sg : signed(11 downto 0);
    signal register2: std_logic_vector(16 downto 0) := (others => '0'); -- 0 for simulation
    signal r2_sg : signed(16 downto 0);
    signal res_addsub, res_nand, res_nor, res_sra : std_logic_vector(16 downto 0) := (others => '0');
    signal res_addsub_sg : signed(16 downto 0) := (others => '0');
    signal res_mul : std_logic_vector(28 downto 0) := (others => '0');
    signal res_mul_sg : signed(28 downto 0);
    signal res_mux : std_logic_vector(16 downto 0); -- R2 length
    signal count : integer := 0;
    
begin
    r1_sg <= signed(register1);
    r2_sg <= signed(register2);
    -- sign-magnitude to 2's complement: A'=not(A)+1
    value_2c <= '1' & std_logic_vector(not(unsigned(value(value'high-1 downto 0))) + 1) when (value(value'high) = '1') else
                value;
    
    -- adder/subtracter
    res_addsub <= std_logic_vector(res_addsub_sg);
    res_addsub_sg <= r2_sg + r1_sg when (sel_add_sub = '0') else
                     r2_sg - r1_sg;
    
    -- multiplier
    res_mul <= std_logic_vector(res_mul_sg);
    res_mul_sg <= r2_sg * r1_sg;
    
    -- nand
    res_nand <= register2 nand "11111" & register1;
    --res_nand <= register2(register2'high downto register1'high+1) & register2(register1'high) nand register1
    
    -- nor
    res_nor <= register2 nor "00000" & register1;
    --res_nor <= register2(register2'high downto register1'high+1) & register2(register1'high) nor register1
    
    -- shift-right arithmetic
    count <= to_integer(unsigned(register1(2 downto 0)));
    res_sra <= std_logic_vector(shift_right(r2_sg, count));

    -- multiplexer1
    res_mux <= res_addsub when (sel_mux = "001") else
               res_mul(16 downto 0) when (sel_mux = "010") else -- 29 to 17 reduction
               res_nand when (sel_mux = "011") else
               res_nor when (sel_mux = "100") else
               res_sra when (sel_mux = "101") else
               -- padding
               "11111" & value_2c when (value(value'high) = '1') else
               "00000" & value_2c;

    -- register1
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                register1 <= (others => '0');
            elsif en_r1 = '1' then
                -- 2's complement conversion
                register1 <= value_2c;
            end if;
        end if;
    end process;

    -- register2
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                register2 <= (others => '0');
            elsif en_r2 = '1' then
                register2 <= res_mux;
            end if;
        end if;
    end process;

    -- output
    res_2c <= "11111" & register1 when (sel_disp = '1' and register1(register1'high) = '1') else
              "00000" & register1 when (sel_disp = '1' and register1(register1'high) = '0') else
              register2;
    -- 2's complement to sign-magnitude: A'=not(A-1)
    res <= '1' & std_logic_vector(not(unsigned(res_2c(res_2c'high-1 downto 0)) - 1)) when (res_2c(res_2c'high) = '1') else
           res_2c;
end behavioral;