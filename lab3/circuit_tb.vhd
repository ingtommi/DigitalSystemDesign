library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity circuit_tb is
end circuit_tb;

architecture Behavioral of circuit_tb is

    component circuit
    port(
        clk, rst: std_logic;
        image_num : in std_logic_vector(6 downto 0)
        );
    end component;
    
    -- inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    
    -------- USER INPUT ------
    signal image_num : std_logic_vector(6 downto 0) := "0000000";
    -------------------------
    
    -- clk period definitions 
    constant clk_period : time := 10ns;
    
begin
    
    -- Instantiate the Unit Under Test (UUT
    uut: circuit port map(
        clk => clk,
        rst => rst,
        image_num => image_num
        );
    
    --clk definition
    clk <= not clk after clk_period/2;
    
    -- Simulation for adress generation
    stim_proc: process
    
    begin
      -- hold reset state for 100ns
      wait for 100ns;
      wait for clk_period*10;
      rst <= '0';
      wait;
    end process;
    
end Behavioral;