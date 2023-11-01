library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity datapath is
  port (
    clk : in std_logic;
    image_num : in std_logic_vector(6 downto 0); -- 0 to 119 max
    l1_en, l2_en, out_en : in std_logic;
    l1_rst, l2_rst, out_rst : in std_logic;
    lay1_done, lay2_done : out std_logic;
    prediction : out std_logic_vector(3 downto 0); -- 0 to 9
    neuron_value : out std_logic_vector(26 downto 0) -- Q13.14
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

COMPONENT comparator
  PORT (
    vect1 : in std_logic_vector(26 downto 0);
    vect2 : in std_logic_vector(26 downto 0);
    index1 : in std_logic_vector(3 downto 0);
    index2 : in std_logic_vector(3 downto 0);
    max_vector : out std_logic_vector(26 downto 0);
    max_index : out std_logic_vector(3 downto 0)
  );
END COMPONENT;

  -- ADDRESSES
  signal image_num_reg : std_logic_vector(6 downto 0); -- registered input
  signal image_addr : std_logic_vector(11 downto 0); -- base address
  signal image_offs : std_logic_vector(4 downto 0) := (others => '0'); -- 32 rows
  signal image_curr : std_logic_vector(11 downto 0); -- 3840 depth
  
  signal w1_addr : std_logic_vector(12 downto 0) := (others => '0'); -- 8192 depth
  signal w2_addr : std_logic_vector(6 downto 0) := (others => '0'); -- 80 depth
  
  -- MEMORY DATA
  signal im_row, w2_4 : std_logic_vector(31 downto 0);
  signal w1_4 : std_logic_vector(15 downto 0);
  
  -- PIXELS SELECTION
  signal pixel : std_logic_vector(3 downto 0); -- 4 pixels read every cycle
  signal sel_pixel : std_logic_vector(2 downto 0);
  
  -- DONE SIGNALS
  signal l1_done : std_logic;
  signal l2_done : std_logic;
  
  -- ENABLE SIGNALS
  signal w1_count_en : std_logic;
  signal w2_count_en : std_logic;
  
  -- MAC4 LAYER 1
  signal mul1_l1, mul2_l1, mul3_l1, mul4_l1 : signed(3 downto 0); 
  signal add1_l1, add2_l1 : signed(4 downto 0);
  signal add3_l1 : signed(5 downto 0);
  
  -- MAC4 LAYER 2
  signal mul1_l2, mul2_l2, mul3_l2, mul4_l2 : signed(21 downto 0);
  signal add1_l2, add2_l2 : signed(22 downto 0);
  signal add3_l2 : signed(23 downto 0);
  
  -- MAC4 LAYER 2 PIPELINED
  signal mul1_l2_reg, mul2_l2_reg, mul3_l2_reg, mul4_l2_reg : signed(21 downto 0);
  signal w2_4_reg : std_logic_vector(31 downto 0);
  signal sel_neuron_reg : std_logic_vector(2 downto 0);
  signal shift2_reg1, shift2_reg2 : std_logic;
  
  -- ACCUMULATOR LAYER 1
  type accum1_t is array(31 downto 0) of signed(13 downto 0);        -- array of 32 neurons
  signal accum1 : accum1_t := (others => (others => '0'));           -- 14-bits signed
  signal acc1_en : std_logic_vector(31 downto 0) := (others => '0'); -- enable for the 32 neurons
  signal op_count1 : std_logic_vector(7 downto 0) := (others => '0'); -- counter to shift left enable (to enable following neurons)
  signal init_en1 : std_logic;
  signal shift1 : std_logic;
  
  -- RELU
  signal relu : accum1_t; -- 14-bits signed
  
  -- ACCUMULATOR LAYER 2
  type neurons_t is array(3 downto 0) of signed(13 downto 0); -- array of 4 of the first 32 neurons
  signal neurons : neurons_t; -- 14-bits signed
  signal sel_neuron : std_logic_vector(2 downto 0) := (others => '0');
  signal acc2_en : std_logic_vector(9 downto 0) := (others => '0'); -- enable for the 10 neurons
  type accum_t is array(9 downto 0) of signed(26 downto 0); -- array of 10 neurons
  signal accum2 : accum_t := (others => (others => '0')); -- 26-bit signed
  signal op_count2 : std_logic_vector(2 downto 0):= (others => '0'); -- counter to shift left enable (to enable following neurons)
  signal init_en2 : std_logic;
  signal shift2 : std_logic;
  
  -- OUTPUT
  signal vect1, vect2 : signed(26 downto 0);
  signal max_vector, max_vector_reg : std_logic_vector(26 downto 0);
  signal index1, index2 : std_logic_vector(3 downto 0);
  signal max_index, max_index_reg : std_logic_vector(3 downto 0);
  signal upd_en : std_logic;

begin

  -- register input
  input_reg : process(clk)
  begin
    if rising_edge(clk) then
	  image_num_reg <= image_num;
	end if;
  end process;

  -- image memory address generator
  image_addr <= image_num_reg & "00000" ; -- base address (12 digit for 32x120 row), 5 position shift left to multiply by 32
  image_curr <= std_logic_vector(unsigned(image_addr) + unsigned(image_offs)); -- current address
  
  -- set enable for counter
  w1_count_en <= '1' when (l1_done = '0' and l1_en = '1') else
                 '0';
  
  -- w1 rows counter
  w1_counter : process(clk)
  begin
    -- check clock
    if rising_edge(clk) then
      -- check reset
      if l1_rst = '1' then
        w1_addr <= (others => '0');
      -- check enable
      elsif w1_count_en = '1' then
        -- increment
        w1_addr <= std_logic_vector(unsigned(w1_addr) + 1);
      end if;
    end if;
  end process;
  
   -- sub-signals from w1_addr
  image_offs <= w1_addr(7 downto 3);
  op_count1 <= w1_addr(7 downto 0);
  
  -- delay of multiplexer selector
  selector_delay1 : process(clk)
  begin
    if rising_edge(clk) then
      sel_pixel <= w1_addr(2 downto 0);
    end if;
  end process;
  
  -- end of layer check (8191)
  l1_done <= '1' when w1_addr = "1111111111111" else
             '0';
             
  done_layer1 : process(clk)
  begin
    if rising_edge(clk) then
       lay1_done <= l1_done;
    end if;
  end process;
  
  -- set enable to initialize accumulator enable          
  init_en1 <= '1' when (l1_en = '1' and w1_addr = "0000000000000") else
              '0';
  
  -- set enable to shift left accumulator enable            
  shift1 <= '1' when op_count1 = "11111111" else
            '0'; 
              
  enable1 : process(clk)
  begin
    if rising_edge(clk) then
      if init_en1 = '1' then
        -- initialization
        acc1_en <= (0 => '1', others => '0');
      elsif shift1 = '1' then
        -- shift left
        acc1_en <= acc1_en(30 downto 0) & '0';
      end if;
    end if;
  end process;
  
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
  mul1_l1 <= signed(w1_4(3 downto 0)) when pixel(0) = '1' else "0000"; -- w1 * p1
  mul2_l1 <= signed(w1_4(7 downto 4)) when pixel(1) = '1' else "0000"; -- w2 * p2
  mul3_l1 <= signed(w1_4(11 downto 8)) when pixel(2) = '1' else "0000"; -- w3 * p3
  mul4_l1 <= signed(w1_4(15 downto 12)) when pixel(3) = '1' else "0000"; -- w4 * p4
 
  add1_l1 <= (mul1_l1(3) & mul1_l1) + (mul2_l1(3) & mul2_l1);
  add2_l1 <= (mul3_l1(3) & mul3_l1) + (mul4_l1(3) & mul4_l1); 
  add3_l1 <= (add1_l1(4) & add1_l1) + (add2_l1(4) & add2_l1);
  
  -- accumulator for neurons of layer 1
  accum_layer1: for i in 0 to 31 generate
    process(clk)
    begin
      if rising_edge(clk) then
        if l1_rst = '1' then
          accum1(i) <= (others => '0');
        elsif acc1_en(i) = '1' then
          accum1(i) <= accum1(i) + add3_l1;
        end if;
      end if;
    end process;
  end generate;
  
  --------------------------- ReLu --------------------------
  
  relu_layer: for i in 0 to 31 generate
    relu(i) <= accum1(i) when accum1(i)(12) = '0' else
               (others => '0');
  end generate;
  
  -------------------------- LAYER 2 ------------------------
  
  -- set enable for counter
  w2_count_en <= '1' when (l2_done = '0' and l2_en = '1') else
                 '0';
                 
  -- w2 rows counter
  w2_counter: process(clk)
  begin
    -- check clock
    if rising_edge(clk) then
      -- check reset
      if l2_rst = '1' then
        w2_addr <= (others => '0');
      -- check enable
      elsif w2_count_en = '1' then
        -- increment
        w2_addr <= std_logic_vector(unsigned(w2_addr) + 1);
      end if;
    end if;
  end process;
  
  -- pipeline
  delays: process(clk)
  begin
    if rising_edge (clk) then
	  sel_neuron <= w2_addr(2 downto 0);
	  sel_neuron_reg <= sel_neuron;
      op_count2 <= w2_addr(2 downto 0);
      mul1_l2_reg <= mul1_l2;
      mul2_l2_reg <= mul2_l2;
      mul3_l2_reg <= mul3_l2;
      mul4_l2_reg <= mul4_l2;
      w2_4_reg <= w2_4;
      shift2_reg1 <= shift2;
      shift2_reg2 <= shift2_reg1;
    end if;
  end process;
  
  -- end of layer check (79)
  l2_done <= '1' when w2_addr = "1001111" else 
             '0';
             
 done_layer2 : process(clk)
  begin
    if rising_edge(clk) then
      lay2_done <= l2_done;
    end if;
  end process;
  
  -- set enable to initialize accumulator enable   
  init_en2 <= '1' when (l2_en = '1' and w2_addr = "0000010") else
              '0';
  
  -- set enable to shift left accumulator enable               
  shift2 <= '1' when op_count2 = "111" else
            '0';           
  
  enable2 : process(clk)
  begin
    if rising_edge(clk) then
      -- initialization
      if init_en2 = '1' then
        acc2_en <= (0 => '1', others => '0');
      elsif shift2_reg2 = '1' then
        -- shift left
        acc2_en <= acc2_en(8 downto 0) & '0';
      end if;
    end if;
  end process;
  
 
  
  neurons(0) <= relu(0) when (sel_neuron_reg = "000") else
                relu(4) when (sel_neuron_reg = "001") else
                relu(8) when (sel_neuron_reg = "010") else
                relu(12) when (sel_neuron_reg = "011") else
                relu(16) when (sel_neuron_reg = "100") else
                relu(20) when (sel_neuron_reg = "101") else
                relu(24) when (sel_neuron_reg = "110") else
                relu(28);
 
  neurons(1) <= relu(1) when (sel_neuron_reg = "000") else
                relu(5) when (sel_neuron_reg = "001") else
                relu(9) when (sel_neuron_reg = "010") else
                relu(13) when (sel_neuron_reg = "011") else
                relu(17) when (sel_neuron_reg = "100") else
                relu(21) when (sel_neuron_reg = "101") else
                relu(25) when (sel_neuron_reg = "110") else
                relu(29);

  neurons(2) <= relu(2) when (sel_neuron_reg = "000") else
                relu(6) when (sel_neuron_reg = "001") else
                relu(10) when (sel_neuron_reg = "010") else
                relu(14) when (sel_neuron_reg = "011") else
                relu(18) when (sel_neuron_reg = "100") else
                relu(22) when (sel_neuron_reg = "101") else
                relu(26) when (sel_neuron_reg = "110") else
                relu(30);
               
  neurons(3) <= relu(3) when (sel_neuron_reg = "000") else
                relu(7) when (sel_neuron_reg = "001") else
                relu(11) when (sel_neuron_reg = "010") else
                relu(15) when (sel_neuron_reg = "011") else
                relu(19) when (sel_neuron_reg = "100") else
                relu(23) when (sel_neuron_reg = "101") else
                relu(27) when (sel_neuron_reg = "110") else
                relu(31);  
                  
  -- arithmetic
  mul1_l2 <= signed(w2_4_reg(7 downto 0)) * neurons(0); -- w2 * n1
  mul2_l2 <= signed(w2_4_reg(15 downto 8)) * neurons(1); -- w2 * n2
  mul3_l2 <= signed(w2_4_reg(23 downto 16)) * neurons(2); -- w2 * n3
  mul4_l2 <= signed(w2_4_reg(31 downto 24)) * neurons(3); -- w2 * n4

  add1_l2 <= (mul1_l2_reg(21) & mul1_l2_reg) + (mul2_l2_reg(21) & mul2_l2_reg);
  add2_l2 <= (mul3_l2_reg(21) & mul3_l2_reg) + (mul4_l2_reg(21) & mul4_l2_reg);
  add3_l2 <= (add1_l2(22) & add1_l2) + (add2_l2(22) & add2_l2);
  
  -- accumulator for neurons of layer 2
  accum_layer2: for i in 0 to 9 generate
    process(clk)
    begin
      if rising_edge(clk) then
        if l2_rst = '1' then
          accum2(i) <= (others => '0');
        elsif acc2_en(i) = '1' then
          accum2(i) <= accum2(i) + add3_l2;
        end if;
      end if;
    end process;
  end generate;
  
  -------------------------- OUTPUT -------------------------
  
  vect1 <= accum2(0) when (acc2_en = "0000000100") else
           signed(max_vector_reg);

  vect2 <= accum2(1) when (acc2_en = "0000000100") else
           accum2(2) when (acc2_en = "0000001000") else
           accum2(3) when (acc2_en = "0000010000") else
           accum2(4) when (acc2_en = "0000100000") else
           accum2(5) when (acc2_en = "0001000000") else
           accum2(6) when (acc2_en = "0010000000") else
           accum2(7) when (acc2_en = "0100000000") else
           accum2(8) when (acc2_en = "1000000000") else
           accum2(9);


  index1 <= "0000" when (acc2_en = "0000000100") else 
            max_index_reg;

  index2 <= "0001" when (acc2_en = "0000000100") else
            "0010" when (acc2_en = "0000001000") else
            "0011" when (acc2_en = "0000010000") else
            "0100" when (acc2_en = "0000100000") else
            "0101" when (acc2_en = "0001000000") else
            "0110" when (acc2_en = "0010000000") else
            "0111" when (acc2_en = "0100000000") else
            "1000" when (acc2_en = "1000000000") else
            "1001";
  
  upd_en <= '1' when (w2_addr >= "0010001") else
            '0';

  -- no rst needed because for following classification we first load the comparison of accum2(0) and accum2(1)
  update_output : process(clk)
  begin
  if rising_edge(clk) then
    if upd_en = '1' then
      max_vector_reg <= max_vector;
      max_index_reg <= max_index;
    end if;
  end if;
  end process;
  
  write_output : process(clk)
  begin
    if rising_edge(clk) then
      if out_rst = '1' then
        prediction <= (others => '0');
        neuron_value <= (others => '0');
      elsif out_en = '1' then
        prediction <= max_index;
        neuron_value <= max_vector;  
      end if;
    end if;
  end process;
  
  ------------------------ COMPONENTS -----------------------

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
  
  instance_comparator : comparator
  PORT MAP (
     vect1 => std_logic_vector(vect1),
     vect2 => std_logic_vector(vect2),
     index1 => index1,
     index2 => index2,
     max_vector => max_vector,
     max_index => max_index
  );
   
end Behavioral;