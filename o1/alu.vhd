-- Bibliotecas necessárias para trabalhar com sinais digitais e operações numéricas.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declaração da ULA e suas portas de entrada e saída.
entity alu is
    port (
        a    : in std_logic_vector(31 downto 0); -- Primeiro operando
        b    : in std_logic_vector(31 downto 0); -- Segundo operando
        alu_op    :  in  std_logic_vector(2 downto 0); -- Código da operação
        result    : out std_logic_vector(31 downto 0); -- Resultado da operação
        zero    : out std_logic -- Indica se o resultado é zero
    );
end entity alu;
 
-- Descreve o funcionamento interno da ULA.
architecture comportamento of alu is
    signal res : std_logic_vector(31 downto 0); -- Sinal interno que armazena temporariamente o resultado.
begin

    -- Processo combinacional: executa novamente quando alguma entrada muda.
    process (a, b , alu_op)
    begin

        -- Seleciona a operação que será realizada de acordo com alu_op.
        case alu_op is
            when "000" => res <= std_logic_vector(signed(a) + signed(b)); -- ADD: soma A com B.
            when "001" => res <= std_logic_vector(signed(a) - signed(b)); -- SUB: subtrai B de A.
            when "010" => res <= a and b; -- AND: realiza a operação lógica AND bit a bit.
            when "011" => res <= a or b; -- OR: realiza a operação lógica OR bit a bit.
            when "100" =>
             if signed(a) < signed(b) then
                res <= x"00000001"; 
             else
                res <= x"00000000";  -- SLT: retorna 1 se A for menor que B; caso contrário, retorna 0
            end if;
           when others => res <= (others => '0'); -- Para códigos de operação não reconhecidos, retorna zero.
          end case;
        end process;

        result <= res; -- Disponibiliza o resultado interno na porta de saída.
        zero   <= '1' when res = x"00000000" else '0'; -- Ativa ZERO quando o resultado da operação for igual a zero.

end architecture comportamento;
