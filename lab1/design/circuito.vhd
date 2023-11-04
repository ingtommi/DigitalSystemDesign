library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity circuito is
  port(
    clk, rst, exec, sel_disp: in std_logic;
    instr : in std_logic_vector(2 downto 0);
    value: in std_logic_vector(11 downto 0);
    res : out std_logic_vector(16 downto 0)
    );
end circuito;

architecture Behavioral of circuito is
  component control
      port(
        clk, rst, exec : in std_logic;
        instr : in std_logic_vector(2 downto 0);
        enables : out std_logic_vector(1 downto 0);
        selectors : out std_logic_vector(3 downto 0));
  end component;
  component datapath
      port(   
        value : in std_logic_vector(11 downto 0);
        sel_disp, sel_add_sub : in std_logic;
        sel_mux : in std_logic_vector(2 downto 0);
        en_r1, en_r2 : in std_logic;
        clk, rst : in std_logic;
        res : out std_logic_vector(16 downto 0));
  end component;

  signal enables : std_logic_vector(1 downto 0);
  signal sels : std_logic_vector(3 downto 0);

begin
  inst_control: control port map(
    clk => clk,
    rst => rst,
    exec => exec,
    instr => instr,
    enables => enables,
    selectors => sels
    );
  inst_datapath: datapath port map(
    value => value,
    rst => rst,
    en_r1 => enables(0),
    en_r2 => enables(1),
    sel_disp => sel_disp,
    sel_add_sub => sels(3),
    sel_mux => sels(2 downto 0),
    clk => clk,
    res => res
    );
end Behavioral;