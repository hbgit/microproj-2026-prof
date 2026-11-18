library ieee;
use ieee.std_logic_1164.all;

entity if_id is
    port (
        clk       : in std_logic;
        rst       : in std_logic;
        freeze    : in std_logic;
        instr_in  : in std_logic_vector(31 downto 0);
        pc_in     : in std_logic_vector(31 downto 0);
        valid_in  : in std_logic;
        instr_out : out std_logic_vector(31 downto 0);
        pc_out    : out std_logic_vector(31 downto 0);
        valid_out : out std_logic    
    );
end entity;
architecture if_id_arch of if_id is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then--com reset, saidas sao zero
                instr_out <= (others => '0');
                pc_out <= (others => '0');
                valid_out <= '0';
            elsif freeze = '1' then--com freeze, nada muda
                null;
            else--sem reset e sem freeze, saidas recebem entradas
                instr_out <= instr_in;
                pc_out <= pc_in;
                valid_out <= valid_in;
            end if;
        end if;
    end process;

end architecture;