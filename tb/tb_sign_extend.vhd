
library ieee;
use ieee.std_logic_1164.all;

entity tb_sign_extend is
end entity;

architecture sim of tb_sign_extend is
    signal entrada : std_logic_vector(15 downto 0);
    signal saida   : std_logic_vector(31 downto 0);
begin

    dut: entity work.sign_extend
        port map (
            imediato_16 => entrada,
            imediato_32 => saida
        );

    process
    begin
        entrada <= x"0005";
        wait for 10 ns;
        assert saida = x"00000005"
            report "Erro ao estender +5"
            severity error;

        entrada <= x"FFFB";
        wait for 10 ns;
        assert saida = x"FFFFFFFB"
            report "Erro ao estender -5"
            severity error;

        entrada <= x"7FFF";
        wait for 10 ns;
        assert saida = x"00007FFF"
            report "Erro no maior valor positivo"
            severity error;

        entrada <= x"8000";
        wait for 10 ns;
        assert saida = x"FFFF8000"
            report "Erro no menor valor negativo"
            severity error;

        report "Testes do extensor concluidos";
        std.env.stop;
        wait;
    end process;

end architecture;
