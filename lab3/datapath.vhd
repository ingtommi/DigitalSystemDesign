library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
  port (
    clk, rst : in std_logic;
    image_num : in std_logic_vector(6 downto 0); -- 0 to 119 max
    w1_en, w1_rst : in std_logic;
    lay1_done, lay2_done : out std_logic
    );
end datapath;

architecture Behavioral of datapath is
COMPONENT images_mem
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
  );
END COMPONENT;

COMPONENT weights1
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0) 
  );
END COMPONENT;

COMPONENT weights2
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
  );
END COMPONENT;

  -- ADDRESSES
  signal image_addr_temp : std_logic_vector(13 downto 0);
  signal image_addr : std_logic_vector(11 downto 0); -- base address
  signal image_offs : std_logic_vector(4 downto 0) := (others => '0'); -- 32 rows
  signal image_curr : std_logic_vector(11 downto 0); -- 3840 depth
  
  signal w1_addr : std_logic_vector(12 downto 0) := (others => '0'); -- 8192 depth
  signal w2_addr : std_logic_vector(6 downto 0) := (others => '0'); -- 80 depth
  
  -- MEMORY DATA
  signal im_row, w2_4 : std_logic_vector(31 downto 0);
  signal w1_4 : std_logic_vector(15 downto 0);
  
  -- OTHERS
  signal pixel : std_logic_vector(3 downto 0);
  signal sel_pixel : std_logic_vector(2 downto 0);
  
  signal mul1, mul2, mul3, mul4 : std_logic_vector(3 downto 0);
  signal add1, add2 : signed(4 downto 0);
  signal add3 : signed(5 downto 0);
  
  type accum1_t is array(31 downto 0) of signed(13 downto 0);
  signal accum1 : accum1_t; -- 14-bits
  signal acc1_en : std_logic_vector(31 downto 0);

begin

  -- image memory address generator
  -- TODO: check if correct
  image_addr_temp <= std_logic_vector(32 * unsigned(image_num));
  image_addr <= image_addr_temp(11 downto 0); -- base address
  image_curr <= std_logic_vector(unsigned(image_addr) + unsigned(image_offs)); -- current address
  
  -------------------------- LAYER 1 ------------------------
  
  -- w1 rows counter
  process(clk)
  begin
    -- check reset (must be set by C.U. the first time)
    if w1_rst = '1' then
      w1_addr <= (others => '0');
    -- otherwise check clock
    elsif rising_edge(clk) then
      -- check enable
      if w1_en = '1' then
        -- increment address
        w1_addr <= std_logic_vector(unsigned(w1_addr) + 1);
      end if;
    end if;
  end process;
  
   -- end of layer check
  lay1_done <= '1' when w1_addr = "1111111111111" else
               '0';
  
  -- sub-signals from w1_addr
  sel_pixel <= w1_addr(2 downto 0);
  image_offs <= w1_addr(7 downto 3);
  
  -- pixels selection
  pixel <= im_row(3 downto 0) when (sel_pixel = "000") else -- [p1, p2, p3, p4]
           im_row(7 downto 4) when (sel_pixel = "001") else
           im_row(11 downto 8) when (sel_pixel = "010") else
           im_row(15 downto 12) when (sel_pixel = "011") else
           im_row(19 downto 16) when (sel_pixel = "100") else
           im_row(23 downto 20) when (sel_pixel = "101") else
           im_row(27 downto 24) when (sel_pixel = "110") else
           im_row(31 downto 28);    
 
  -- arithmetic
  mul1 <= w1_4(3 downto 0) when pixel(0) = '1' else "0000"; -- w1 * p1
  mul2 <= w1_4(7 downto 4) when pixel(1) = '1' else "0000"; -- w2 * p2
  mul3 <= w1_4(11 downto 8) when pixel(2) = '1' else "0000"; -- w3 * p3
  mul4 <= w1_4(15 downto 12) when pixel(3) = '1' else "0000"; -- w4 * p4
  -- TODO: check if correct
  add1 <= signed(mul1(3) & mul1) + signed(mul2(3) & mul2);
  add2 <= signed(mul3(3) & mul3) + signed(mul4(3) & mul4); 
  add3 <= (add1(4) & add1) + (add2(4) & add2);
  
  -- registers
  -- TODO: design acc1_en
  accum: for i in 0 to 31 generate
    process(clk)
    begin
      if rst = '1' then
        accum1(i) <= (others => '0');
      elsif rising_edge(clk) then
        if acc1_en(i) = '1' then
          accum1(i) <= accum1(i) + add3;
        end if;
      end if;
    end process;
  end generate;
  
  -------------------------- LAYER 2 ------------------------
  
  -- implement ReLu directly when data is used

instance_images : images_mem
  PORT MAP (
    clka => clk,
    wea => "0",
    addra => image_curr,
    dina => (others => '0'),  
    douta => im_row,
    clkb => clk,
    web => "0",
    addrb => (others => '0'),  
    dinb => (others => '0'),
    doutb => open              -- port B not used
  );

instance_weights1 : weights1
  PORT MAP (
    clka => clk,
    wea => "0",
    addra => w1_addr,
    dina => (others => '0'),
    douta => w1_4,
    clkb => clk,
    web => "0",
    addrb => (others => '0'),
    dinb => (others => '0'),
    doutb => open               -- port B not used
  );
  
  instance_weights2 : weights2
  PORT MAP (
    clka => clk,
    wea => "0",
    addra => w2_addr,
    dina => (others => '0'),
    douta => w2_4,
    clkb => clk,
    web => "0",
    addrb => (others => '0'),
    dinb => (others => '0'),
    doutb => open               -- port B not used
  );
   
end Behavioral;