
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dmem is
end entity;

architecture sim of tb_dmem is

    signal clk          : std_logic := '0';
    signal endereco     : std_logic_vector(31 downto 0)
        := (others => '0');
    signal dado_entrada : std_logic_vector(31 downto 0)
        := (others => '0');
    signal escrever     : std_logic := '0';
    signal ler          : std_logic := '0';
    signal dado_saida   : std_logic_vector(31 downto 0);

begin

    clk <= not clk after 5 ns;

    dut: entity work.dmem
    port map (
        clk          => clk,
        endereco     => endereco,
        dado_entrada => dado_entrada,
        escrever     => escrever,
        ler          => ler,
        dado_saida   => dado_saida
    );

    process
    begin

        endereco <= x"00000008";
        dado_entrada <= x"00000019";
        escrever <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;
        escrever <= '0';

        ler <= '1';
        wait for 1 ns;

        assert dado_saida = x"00000019"
            report "Erro: leitura do endereco 8"
            severity error;

        ler <= '0';

        wait until falling_edge(clk);

        endereco <= x"0000000C";
        dado_entrada <= x"00000064";
        escrever <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;
        escrever <= '0';

        ler <= '1';
        wait for 1 ns;

        assert dado_saida = x"00000064"
            report "Erro: leitura do endereco 12"
            severity error;

        endereco <= x"00000008";
        wait for 1 ns;

        assert dado_saida = x"00000019"
            report "Erro: memoria nao preservou o valor"
            severity error;

        report "Testes da memoria concluidos com sucesso";

        std.env.stop;
        wait;

    end process;

end architecture;
