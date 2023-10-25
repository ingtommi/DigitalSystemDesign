library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator is
 port(
 vect_1, vect_2 : in std_logic_vector(26 downto 0); -- 2 vectors for comparaison
 index_1, index_2 : in integer;
 result_index : out integer;                          -- index output
 result_vector : out std_logic_vector(26 downto 0)); -- vect output
end comparator;

architecture Behavioral of comparator is
    signal A_sgn,B_sgn: signed(26 downto 0);

begin
    A_sgn <= signed(vect_1); 
    B_sgn <= signed(vect_2);
    process (A_sgn, B_sgn)
    begin 
        if A_sgn > B_sgn then
            result_vector <= std_logic_vector(A_sgn);
            result_index <= index_1;
        else 
            result_vector <= std_logic_vector(B_sgn);
            result_index <= index_2;
        end if;
    end process;

end Behavioral;
