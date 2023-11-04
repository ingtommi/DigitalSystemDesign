library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity fpga_basicIO is
  port(
    clk: in std_logic;                            -- 100MHz clock
    btnC, btnU, btnL, btnR, btnD: in std_logic;   -- buttons
    sw: in std_logic_vector(15 downto 0);         -- switches
    led: out std_logic_vector(15 downto 0);       -- leds
    an: out std_logic_vector(3 downto 0);         -- display selectors
    seg: out std_logic_vector(6 downto 0);        -- display 7-segments
    dp: out std_logic                             -- display point
	);
end fpga_basicIO;

architecture Behavioral of fpga_basicIO is
  signal res : std_logic_vector(16 downto 0);
  signal dact : std_logic_vector(3 downto 0);
  signal btn, btnDeBnc : std_logic_vector(4 downto 0);
  signal btnCreg, btnUreg, btnLreg, btnRreg, btnDreg: std_logic;   -- registered input buttons
  signal sw_reg : std_logic_vector(15 downto 0);  -- registered input switches
  
  component disp7
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
  
  component circuito
    port(
      clk : in std_logic;
      rst : in std_logic;
      exec : in std_logic;
	  sel_disp : in std_logic;
      instr : in std_logic_vector(2 downto 0);
      value : in std_logic_vector(11 downto 0);         
      res : out std_logic_vector(16 downto 0)
      );
  end component;

begin
  led <= sw_reg;
  dact <= "1111";

  inst_disp7: disp7 port map(
      digit3 => res(15 downto 12), digit2 => res(11 downto 8), digit1 => res(7 downto 4), digit0 => res(3 downto 0),
      dp3 => res(16), dp2 => '0', dp1 => '0', dp0 => '0',  
      clk => clk,
      dactive => dact,
      en_disp_l => an,
      segm_l => seg,
      dp_l => dp 
	  );

  inst_circuito: circuito port map(
      clk => clk,
      rst => btnUreg,
      exec => btnRreg,
	  sel_disp => sw_reg(15),
      instr => sw_reg(14 downto 12),
      value => sw_reg(11 downto 0),
      res => res 
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