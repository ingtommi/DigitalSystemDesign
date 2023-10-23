library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity circuito is
    port(
    clk, rst: std_logic;
    image_num : in std_logic_vector(6 downto 0)
    --res : std_logic_vector (3 downto 0)
    );
end circuito;

architecture Behavioral of circuito is

    component control
    port(
        clk, rst : in std_logic;
        layer1_done, layer2_done : in std_logic;
        w_enables : out std_logic_vector(1 downto 0);
        w_resets : out std_logic_vector(1 downto 0));
   end component;
        
    component datapath
    port (
    clk, rst : in std_logic;
    image_num : in std_logic_vector(6 downto 0); -- 0 to 119 max
    w1_en, w2_en : in std_logic;
    w1_rst, w2_rst : in std_logic;
    lay1_done, lay2_done : out std_logic
    );
    end component;
    
    signal layer1 : std_logic;
    signal layer2 : std_logic;
    signal w_enables : std_logic_vector(1 downto 0);
    signal w_resets : std_logic_vector(1 downto 0);
    
    
begin 
    inst_control: control port map(
    clk => clk,
    rst => rst,
    layer1_done => layer1,
    layer2_done => layer2,
    w_enables => w_enables,
    w_resets => w_resets
    );
    
    inst_datapath: datapath port map(
    clk => clk,
    rst => rst, 
    image_num => image_num,
    w1_en => w_enables(0),
    w2_en => w_enables(1),
    w1_rst => w_resets(0),
    w2_rst => w_resets(1),
    lay1_done => layer1,
    lay2_done => layer2
    );
    
          
end Behavioral;

