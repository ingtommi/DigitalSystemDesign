library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control is
 port(
    clk, rst : in std_logic;
    layer1_done, layer2_done : in std_logic;
    w_enables : out std_logic_vector(1 downto 0);
    w_resets : out std_logic_vector(1 downto 0)
    );
end control;

architecture Behavioral of control is 
    type fsm_states is (init, layer1, layer2, finish);
    signal currstate, nextstate: fsm_states;

begin

process(clk)
  begin
    if rising_edge(clk) then
        if rst = '1' then
          currstate <= init;
        else
          currstate <= nextstate;
        end if;
    end if;
  end process;
  
  process(currstate, rst, layer1_done)
  begin
    nextstate <= currstate;
    case currstate is 
        when init => 
            nextstate <= layer1;
            w_enables <= "00"; -- TODO: change
            w_resets <= "01"; -- TODO: change
            
        when layer1 =>
            w_enables <= "01"; -- TODO: change
            w_resets <= "10"; -- TODO: change
            if layer1_done = '1' then
                nextstate <= layer2;
            end if;
            
        when layer2 =>
            w_enables <= "01"; -- TODO: change
            w_resets <= "00"; -- TODO: change
            if layer2_done = '1' then
                nextstate <= finish;
            end if;
            
        when finish =>
            w_enables <= "00"; -- TODO: change
            w_resets <= "00"; -- TODO: change
            
      end case;
    end process;   
end Behavioral;