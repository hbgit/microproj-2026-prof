
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pc is
end entity;

architecture sim of tb_pc is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal next_pc : std_logic_vector(31 downto 0)
        := (others => '0');

    signal pc_out : std_logic_vector(31 downto 0);
begin

    uut: entity work.pc
        port map (
            clk => clk,
            rst => rst,
            next_pc => next_pc,
            pc_out => pc_out
        );

    clk <= not clk after 5 ns;

    process
    begin
        rst <= '1';
        wait for 10 ns;

        rst <= '0';
        next_pc <= x"00000004";
        wait for 10 ns;

        next_pc <= x"00000008";
        wait for 10 ns;

        next_pc <= x"0000000C";
        wait for 10 ns;

        assert pc_out = x"0000000C"
            report "Erro no PC!"
            severity error;

        report "Teste do PC concluido com sucesso!";
        wait;
    end process;

end architecture;
