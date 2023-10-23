library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
  port (
    clk, rst : in std_logic;
    image_num : in std_logic_vector(6 downto 0); -- 0 to 119 max
    w1_en, w2_en : in std_logic;
    w1_rst, w2_rst : in std_logic;
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
  signal w1_4 : std_logic_vector(15 downto 0); --first row of weight file
  
  -- OTHERS
  signal pixel : std_logic_vector(3 downto 0); 
  signal sel_pixel : std_logic_vector(2 downto 0); -- selector
  
  signal l1_done : std_logic;
  
  -- MAC 4 layer 1
  signal mul1_l1, mul2_l1, mul3_l1, mul4_l1 : std_logic_vector(3 downto 0); 
  signal add1_l1, add2_l1 : signed(4 downto 0);
  signal add3_l1 : signed(5 downto 0);
  
  -- MAC 4 layer 2
  signal mul1_l2, mul2_l2, mul3_l3, mul4_l4 : signed(21 downto 0);
  signal add1_l2, add2_l2 : signed(22 downto 0);
  signal add3_l2 : signed(23 downto 0);
  
  type accum1_t is array(31 downto 0) of signed(13 downto 0); --matrix of neurons
  signal accum1 : accum1_t; -- 14-bits signed
  signal acc1_en : std_logic_vector(31 downto 0) := (0 => '1', others => '0'); --enable for the 32 neurons
  signal op_count : std_logic_vector(7 downto 0); -- 256 counter

begin

  -- image memory address generator
  -- TODO: change with shift left
  image_addr_temp <= std_logic_vector(32 * unsigned(image_num));
  image_addr <= image_addr_temp(11 downto 0); -- base address (12 digit for 32x120 row)
  image_curr <= std_logic_vector(unsigned(image_addr) + unsigned(image_offs)); -- current address
  
  -------------------------- LAYER 1 ------------------------
  
  -- w1 rows and operation counter
  process(clk)
  begin
    -- check reset (must be set by C.U. the first time)
    if w1_rst = '1' then
      w1_addr <= (others => '0');
      op_count <= (others => '0');
    -- otherwise check clock
    elsif rising_edge(clk) then
      -- check done
      if l1_done = '0' then
        -- check enable
        if w1_en = '1' then
          -- increment
          w1_addr <= std_logic_vector(unsigned(w1_addr) + 1);
          op_count <= std_logic_vector(unsigned(op_count) + 1);
        end if;
      end if;
    end if;
  end process;
  
  -- end of layer check (8191)
  l1_done <= '1' when w1_addr = "1111111111111" else
               '0';
  lay1_done <= l1_done;
  
  -- end of neuron check (256)         
  acc1_en <= acc1_en(30 downto 0) & '0' when op_count = "11111111" else -- shift left (every 256 clk cycle)
             acc1_en;                                                   -- maintain
  
  -- sub-signals from w1_addr
  sel_pixel <= w1_addr(2 downto 0); -- selector
  image_offs <= w1_addr(7 downto 3); -- offset row 0 to 31
  
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
  mul1_l1 <= w1_4(3 downto 0) when pixel(0) = '1' else "0000"; -- w1 * p1
  mul2_l1 <= w1_4(7 downto 4) when pixel(1) = '1' else "0000"; -- w2 * p2
  mul3_l1 <= w1_4(11 downto 8) when pixel(2) = '1' else "0000"; -- w3 * p3
  mul4_l1 <= w1_4(15 downto 12) when pixel(3) = '1' else "0000"; -- w4 * p4
  
  -- TODO: check if correct padding
  add1_l1 <= signed(mul1_l1(3) & mul1_l1) + signed(mul2_l1(3) & mul2_l1); --a sign-extended addition operation
  add2_l1 <= signed(mul3_l1(3) & mul3_l1) + signed(mul4_l1(3) & mul4_l1); 
  add3_l1 <= (add1_l1(4) & add1_l1) + (add2_l1(4) & add2_l1);
  
  -- registers
  accum: for i in 0 to 31 generate
    process(clk)
    begin
      if rst = '1' then
        accum1(i) <= (others => '0');
      elsif rising_edge(clk) then
        if acc1_en(i) = '1' then
          accum1(i) <= accum1(i) + add3_l1;
        end if;
      end if;
    end process;
  end generate;
  
  -------------------------- LAYER 2 ------------------------
  
  -- w2 rows counter
  process(clk)
  begin
    -- check reset (must be set by C.U. the first time)
    if w2_rst = '1' then
      w2_addr <= (others => '0');
    -- otherwise check clock
    elsif rising_edge(clk) then
      -- check enable
      if w2_en = '1' then
        -- increment
        w2_addr <= std_logic_vector(unsigned(w2_addr) + 1);
      end if;
    end if;
  end process;
  
  -- end of layer check (79)
  -- TODO: check if we should consider w2_addr = 80
  lay2_done <= '1' when w2_addr = "1001111" else
               '0';
  
  -- arithmetic
  -- TODO: how to switch between accum(i)?
  --mul1_l2 <= signed(w2_4(7 downto 0)) * accum1(i) when accum1(0)(13) = '0' else (others => '0'); -- w2 * n1

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
