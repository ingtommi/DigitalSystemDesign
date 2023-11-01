library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator is
 port(
 vect1, vect2 : in std_logic_vector(26 downto 0);
 index1, index2 : in std_logic_vector(3 downto 0);
 max_vector : out std_logic_vector(26 downto 0); -- max vector
 max_index : out std_logic_vector(3 downto 0)    -- predicted digit
 );           
end comparator;

architecture Behavioral of comparator is

  signal vect1_sg, vect2_sg : signed(26 downto 0);

begin

    vect1_sg <= signed(vect1);
    vect2_sg <= signed(vect2);
    
    max_vector <= vect1 when (vect1_sg > vect2_sg) else
                  vect2;
    
    max_index <= index1 when (vect1_sg > vect2_sg) else
                 index2;

end Behavioral;