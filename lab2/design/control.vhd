library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control is
  port(
    clk, rst : in std_logic;
    done : out std_logic := '0';
    enables : out std_logic_vector(11 downto 0);
    selectors : out std_logic_vector(4 downto 0)); 
end control;

architecture Behavioral of control is
  type fsm_states is (init, cycle1, cycle2, cycle3, finish);
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
  
  process(currstate, rst)
  begin
    nextstate <= currstate;
    case currstate is
    
        when init => 
            nextstate <= cycle1;
            enables <= "000000110011";
            selectors <= "XXXXX";
            done <= '0';
            
        when cycle1 => 
            nextstate <= cycle2; 
            enables <= "110011001100";
            selectors <= "0000X";
            done <= '0';
            
        when cycle2 => 
            nextstate <= cycle3;
            enables <= "111000000000";
            selectors <= "11110";
            done <= '0';
           
        when cycle3 => 
            nextstate <= finish;
            enables <= "000100000000";
            selectors <= "XXXX1";
            done <= '0';
            
        when finish =>
            enables <= "000000000000";
            selectors <= "XXXXX";
            done <= '1';
           
    end case;
  end process;
  
end Behavioral;
