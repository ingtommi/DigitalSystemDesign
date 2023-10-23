library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity circuito_tb is
end circuito_tb;

architecture Behavioral of circuito_tb is

    component circuito
    port(
        clk, rst: std_logic;
        image_num : in std_logic_vector(6 downto 0)
        );
    end component;
    
    -- inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    
    -------- USER INPUT ------
    
    signal image_num : std_logic_vector(6 downto 0) := "00000000";
    
    
    -------------------------
    
    -- clk period definitions 
    constant clk_period : time := 10ns;
    
begin
    
    -- Instantiate the Unit Under Test (UUT
    uut: circuito port map(
        clk => clk,
        rst => rst,
        image_num => image_num
        );
    
    --clk definition
    clk <= not clk after clk_period/2;
    
    -- Simulatoin for adress generation
    stim_proc: process
    
    begin
    -- hold reset state for 100ns
      wait for 100ns;
      wait for clk_period*10;
      
      
      
      --should never change at the positive edge of the clock
      -- synchronize input variation with positive clock edge + hdelay 
     -- wait until rising_edge(clk);
      --for imn in 0 to 119 loop   -- iterate through 120 images
       -- for i in 0 to 31 loop    -- iterate through 32 rows
         --   addr_im <= std_logic_vector(to_unsigned (imn*32+i,addr_im'length ));
           -- wait for clk_period;
        --end loop;
        --end loop;
     wait;
        -- Stimulus process

    end process;
end Behavioral;
