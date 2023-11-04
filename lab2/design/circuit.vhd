library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity circuito is
  port(
    clk, rst: in std_logic;
    p1, p2, p3, p4 : in std_logic_vector(7 downto 0);
    w1, w2, w3, w4 : in std_logic_vector(7 downto 0);
    done : out std_logic;
    res : out std_logic_vector(17 downto 0)
    );
end circuito;

architecture Behavioral of circuito is

  component control
      port(
        clk, rst : in std_logic;
        done : out std_logic;
        enables : out std_logic_vector(11 downto 0);
        selectors : out std_logic_vector(4 downto 0));
  end component;
  
  component datapath
      port(   
        clk, rst : in std_logic;
        p1, p2, p3, p4 : in std_logic_vector(7 downto 0);
        w1, w2, w3, w4 : in std_logic_vector(7 downto 0);
        e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12 : in std_logic;
        s1, s2, s3, s4, s5 : in std_logic;
        res : out std_logic_vector(17 downto 0));
  end component;

  signal enables : std_logic_vector(11 downto 0);
  signal selectors : std_logic_vector(4 downto 0);

begin

  inst_control: control port map(
    clk => clk,
    rst => rst,
    enables => enables,
    selectors => selectors,
    done => done
    );
    
  inst_datapath: datapath port map(
    clk => clk,
    rst => rst,
    p4 => p4,
    p3 => p3,
    p2 => p2,
    p1 => p1,
    w4 => w4,
    w3 => w3,
    w2 => w2,
    w1 => w1,
    e1 => enables(11),
    e2 => enables(10),
    e3 => enables(9),
    e4 => enables(8),
    e5 => enables(7),
    e6 => enables(6),
    e7 => enables(5),
    e8 => enables(4),
    e9 => enables(3),
    e10 => enables(2),
    e11 => enables(1),
    e12 => enables(0),
    s1 => selectors(4),
    s2 => selectors(3),
    s3 => selectors(2),
    s4 => selectors(1),
    s5 => selectors(0),
    res => res
    );
    
end Behavioral;
