library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity circuito_tb is
end circuito_tb;

architecture Behavioral of circuito_tb is

    -- Component declaration for the Unit Under Test (UUT)
    component circuito
    port(
    clk, rst: in std_logic;
    p1, p2, p3, p4 : in std_logic_vector(7 downto 0);
    w1, w2, w3, w4 : in std_logic_vector(7 downto 0);
    done : out std_logic;
    res : out std_logic_vector(17 downto 0)
    );
    end component;

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   
   ----------------- USER INPUT HERE ----------------------
   signal p1 : integer range 0 to 255 := 0;
   signal p2 : integer range 0 to 255 := 0;
   signal p3 : integer range 0 to 255:= 255;
   signal p4 : integer range 0 to 255 := 255;
   signal w1 : integer range -128 to 127 := -128;
   signal w2 : integer range -128 to 127 := -128;
   signal w3 : integer range -128 to 127 := -128;
   signal w4 : integer range -128 to 127 := -128;
   ---------------------------------------------------------
   
   signal temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8 : std_logic_vector(7 downto 0);
 	--Outputs
   signal done : std_logic;
   signal res : std_logic_vector(17 downto 0);

   -- Clock period definitions
   constant clk_period : time := 7 ns;
 
begin

   temp1 <= std_logic_vector(to_unsigned(p1,8));
   temp2 <= std_logic_vector(to_unsigned(p2,8));
   temp3 <= std_logic_vector(to_unsigned(p3,8));
   temp4 <= std_logic_vector(to_unsigned(p4,8));
   temp5 <= std_logic_vector(to_unsigned(w1,8));
   temp6 <= std_logic_vector(to_unsigned(w2,8));
   temp7 <= std_logic_vector(to_unsigned(w3,8));
   temp8 <= std_logic_vector(to_unsigned(w4,8));
 
	-- Instantiate the Unit Under Test (UUT)
   uut: circuito port map (
          clk => clk,
          rst => rst,
          p1 => temp1,
          p2 => temp2,
          p3 => temp3,
          p4 => temp4,
          w1 => temp5,
          w2 => temp6,
          w3 => temp7,
          w4 => temp8,
          done => done,
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
	  rst <= '0';
      wait;
   end process;
end Behavioral;