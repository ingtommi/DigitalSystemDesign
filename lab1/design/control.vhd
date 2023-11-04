library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control is
  port(
    clk, rst, exec : in std_logic;
    instr : in std_logic_vector(2 downto 0); -- 3 bits for 8 options
    enables : out std_logic_vector(1 downto 0);
    selectors : out std_logic_vector(3 downto 0)); 
end control;

architecture Behavioral of control is
  type fsm_states is (s_init, s_wait, s_add, s_sub, s_mul, s_nand, s_nor, s_sra, s_load1, s_load2);
  signal currstate, nextstate: fsm_states;

begin
  state_reg: process(clk)
  begin 
    if rising_edge(clk) then
      if rst = '1' then
        currstate <= s_init ;
      else
        currstate <= nextstate ;
      end if ;
    end if ;
  end process;

  state_comb: process(currstate, instr, exec)
  begin  --  process
    nextstate <= currstate ;  
    -- by default, does not change the state.
    
    case currstate is
      when s_init =>
        if exec = '1' then
          if instr = "000" then
            nextstate <= s_add;
          elsif instr = "001" then
            nextstate <= s_sub ;
          elsif instr = "010" then
            nextstate <= s_mul;
          elsif instr = "011" then
            nextstate <= s_nand;
          elsif instr = "100" then
            nextstate <= s_nor;
          elsif instr = "101" then
            nextstate <= s_sra;
          elsif instr = "110" then
            nextstate <= s_load1;
          elsif instr = "111" then
            nextstate <= s_load2;
          end if;
        end if;
        selectors <= "0000";
        enables <= "00";
        
      when s_add =>
        nextstate <= s_wait;
        selectors <= "0001";
        enables <= "10";
        
      when s_sub =>
        nextstate <= s_wait;
        selectors <= "1001";
        enables <= "10";
        
      when s_mul =>
        nextstate <= s_wait;
        selectors <= "X010";
        enables <= "10";
        
      when s_nand =>
        nextstate <= s_wait;
        selectors <= "X011";
        enables <= "10";
        
      when s_nor =>
        nextstate <= s_wait;
        selectors <= "X100";
        enables <= "10";
        
      when s_sra =>
        nextstate <= s_wait;
        selectors <= "X101";
        enables <= "10";
        
      when s_load1 =>
        nextstate <= s_wait;
        selectors <= "XXXX";
        enables <= "01";
        
      when s_load2 =>
        nextstate <= s_wait;
        selectors <= "X111";
        enables <= "10";
        
      when s_wait =>
        if exec = '0' then
          nextstate <= s_init;
        end if;
        selectors <= "0000";
        enables <= "00";

    end case;
  end process;
end Behavioral;