library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity circuito_tb is
end circuito_tb;

architecture Behavioral of circuito_tb is

    -- Component declaration for the Unit Under Test (UUT)
    component circuito
    port(
         clk, rst, exec, sel_disp : in  std_logic;
         instr : in  std_logic_vector(2 downto 0);
         value : in  std_logic_vector(11 downto 0);
         res : out  std_logic_vector(16 downto 0)
        );
    end component;

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal exec : std_logic := '0';
   signal sel_disp : std_logic := '0';
   signal instr : std_logic_vector(2 downto 0) := (others => '0');
   signal value : std_logic_vector(11 downto 0) := (others => '0');

 	--Outputs
   signal res : std_logic_vector(16 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
begin
 
	-- Instantiate the Unit Under Test (UUT)
   uut: circuito port map (
          clk => clk,
          rst => rst,
          exec => exec,
          sel_disp => sel_disp,
          instr => instr,
          value => value,
          res => res
        );

   -- Clock definition
   clk <= not clk after clk_period/2;

    -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
      wait for clk_period*10;
      -- insert stimulus here 
      -- note that input signals should never change at the positive edge of the clock
	  rst <= '1' after 20 ns,
			 '0' after 40 ns;
	  value <= X"FFF" after  40 ns, -- -2047
	           X"00F" after 360 ns; -- +16
	  instr <= "110" after  40 ns, -- load1
	           "111" after 120 ns, -- load2
			   "000" after 200 ns, -- add
			   "001" after 280 ns, -- sub
			   "110" after 360 ns, -- load1
			   "010" after 440 ns, -- mul
			   "011" after 520 ns, -- nand
			   "100" after 600 ns, -- nor
			   "101" after 680 ns; -- sra
	  exec  <= '1' after  40 ns, -- 1
	           '0' after  80 ns,
			   '1' after 120 ns, -- 2
			   '0' after 160 ns,
			   '1' after 200 ns, -- 3
			   '0' after 240 ns,
			   '1' after 280 ns, -- 4
			   '0' after 320 ns,
			   '1' after 360 ns, -- 5
			   '0' after 400 ns,
			   '1' after 440 ns, -- 6
			   '0' after 480 ns,
			   '1' after 520 ns, -- 7
			   '0' after 560 ns,
			   '1' after 600 ns, -- 8
			   '0' after 640 ns,
			   '1' after 680 ns, -- 9
			   '0' after 720 ns;
	   sel_disp <= '1' after 640ns; -- show R1
      wait;
   end process;
end Behavioral;
