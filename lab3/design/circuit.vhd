library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity circuit is
    port(
    clk, rst: std_logic;
    image_num : in std_logic_vector(6 downto 0);
    prediction : out std_logic_vector(3 downto 0);  -- 0 to 9
    neuron_value : out std_logic_vector(26 downto 0); -- Q13.14
    done : out std_logic
    );
end circuit;

architecture Behavioral of circuit is

    component control
    port(
        clk, rst : in std_logic;
        layer1_done, layer2_done : in std_logic;
        enables : out std_logic_vector(2 downto 0);
        resets : out std_logic_vector(2 downto 0);
        done : out std_logic);
    end component;
        
    component datapath
    port (
    clk : in std_logic;
    image_num : in std_logic_vector(6 downto 0);
    l1_en, l2_en, out_en : in std_logic;
    l1_rst, l2_rst, out_rst : in std_logic;
    lay1_done, lay2_done : out std_logic;
    prediction : out std_logic_vector(3 downto 0);
    neuron_value : out std_logic_vector(26 downto 0)
    );
    end component;
    
    signal layer1_done : std_logic;
    signal layer2_done : std_logic;
    signal enables : std_logic_vector(2 downto 0);
    signal resets : std_logic_vector(2 downto 0);
    
begin 
    inst_control: control port map(
    clk => clk,
    rst => rst,
    layer1_done => layer1_done,
    layer2_done => layer2_done,
    enables => enables,
    resets => resets,
    done => done
    );
    
    inst_datapath: datapath port map(
    clk => clk, 
    image_num => image_num,
    l1_en => enables(0),
    l2_en => enables(1),
    out_en => enables(2),
    l1_rst => resets(0),
    l2_rst => resets(1),
    out_rst => resets(2),
    lay1_done => layer1_done,
    lay2_done => layer2_done,
    prediction => prediction,
    neuron_value => neuron_value
    );
     
end Behavioral;