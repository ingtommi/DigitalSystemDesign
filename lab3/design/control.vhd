library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control is
 port(
    clk, rst : in std_logic;
    layer1_done, layer2_done : in std_logic;
    enables : out std_logic_vector(2 downto 0);
    resets : out std_logic_vector(2 downto 0);
    done : out std_logic
    );
end control;

architecture Behavioral of control is 
    type fsm_states is (init, layer1, layer2, finish);
    signal currstate, nextstate: fsm_states;

begin

done <= layer2_done;

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
  
  process(currstate, rst, layer1_done, layer2_done)
  begin
    nextstate <= currstate;
    case currstate is 
        when init => 
            nextstate <= layer1;
            enables <= "000";
            resets <= "111";
            
        when layer1 =>
            enables <= "001";
            resets <= "110";
            if layer1_done = '1' then
                nextstate <= layer2;
            end if;
            
        when layer2 =>
            enables <= "010";
            resets <= "100";
            if layer2_done = '1' then
                nextstate <= finish;
            end if;
            
        when finish =>
            enables <= "100";
            resets <= "000";
            
      end case;
    end process;   
end Behavioral;