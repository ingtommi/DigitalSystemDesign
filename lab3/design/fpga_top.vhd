library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fpga_top is
  port(
    clk: in std_logic;                            -- 100MHz clock
    btnC, btnU, btnL, btnR, btnD: in std_logic;   -- buttons
    sw: in std_logic_vector(15 downto 0);         -- switches
    led: out std_logic_vector(15 downto 0);       -- leds
    an: out std_logic_vector(3 downto 0);         -- display selectors
    seg: out std_logic_vector(6 downto 0);        -- display 7-segments
    dp: out std_logic                             -- display point
	);
end fpga_top;

architecture Behavioral of fpga_top is
  signal prediction : std_logic_vector(3 downto 0);
  signal neuron_value : std_logic_vector(26 downto 0);
  signal neuron_value_small : std_logic_vector(16 downto 0);
  signal btn, btnDeBnc : std_logic_vector(4 downto 0);
  signal btnCreg, btnUreg, btnLreg, btnRreg, btnDreg: std_logic; 
  signal done, dp3, dp1 : std_logic;
  signal dact : std_logic_vector(3 downto 0);
  signal digits : std_logic_vector(15 downto 0);
  signal sw_reg : std_logic_vector(15 downto 0); 
  signal rst : std_logic;
  
  component disp7m
  port(
    digit3, digit2, digit1, digit0 : in std_logic_vector(3 downto 0);
    dp3, dp2, dp1, dp0 : in std_logic;
    clk : in std_logic;
    dactive : in std_logic_vector(3 downto 0);
    en_disp_l : out std_logic_vector(3 downto 0);
    segm_l : out std_logic_vector(6 downto 0);
    dp_l : out std_logic
	);
  end component;
  
  component debouncer
  generic(
    DEBNC_CLOCKS : integer;
    PORT_WIDTH : integer
	);
  port(
    signal_i : in std_logic_vector(4 downto 0);
    clk_i : in std_logic;          
    signal_o : out std_logic_vector(4 downto 0)
	);
  end component;
  
  component circuit
    port(
    clk, rst: std_logic;
    image_num : in std_logic_vector(6 downto 0);
    prediction : out std_logic_vector(3 downto 0);  -- 0 to 9
    neuron_value : out std_logic_vector(26 downto 0); -- Q13.14
    done : out std_logic
    );
  end component;

begin

  dact <= "1111";
  
  rst <= not(sw_reg(15));
  
  led(15) <= rst;
  led(14) <= done;
  led(6 downto 0) <= sw_reg(6 downto 0);
  
  neuron_value_small <= neuron_value(26 downto 10); -- Q13.14 --> Q.13.4
  
  digits <= "000000000000" & prediction when (btnRreg = '0') else
            neuron_value_small(15 downto 0);
  
  -- minus sign          
  dp3 <= '1' when (btnRreg = '1' and neuron_value_small(16) = '1') else
         '0';
  
  -- decimal divider       
  dp1 <= '1' when (btnRreg = '1') else
         '0';

  inst_disp7: disp7m port map(
      digit3 => digits(15 downto 12), digit2 => digits(11 downto 8), digit1 => digits(7 downto 4), digit0 => digits(3 downto 0),
      dp3 => dp3, dp2 => '0', dp1 => dp1, dp0 => '0',  
      clk => clk,
      dactive => dact,
      en_disp_l => an,
      segm_l => seg,
      dp_l => dp 
	  );

  inst_circuit: circuit port map(
      clk => clk,
      rst => rst,
      image_num => sw_reg(6 downto 0),
	  prediction => prediction,
      neuron_value => neuron_value,
      done => done
	  );
     
  -- Debounces btn signals
  btn <= btnC & btnU & btnL & btnR & btnD;    
  Inst_btn_debounce: debouncer 
    generic map(
        DEBNC_CLOCKS => (2**20),
        PORT_WIDTH => 5
		)
    port map(
		signal_i => btn,
		clk_i => clk,
		signal_o => btnDeBnc 
		);
         
  process(clk)
    begin
     if rising_edge(clk) then
       btnCreg <= btnDeBnc(4); 
       btnUreg <= btnDeBnc(3); 
       btnLreg <= btnDeBnc(2); 
       btnRreg <= btnDeBnc(1); 
       btnDreg <= btnDeBnc(0);
       sw_reg <= sw;
     end if; 
    end process; 
       
end Behavioral;