library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declara a unidade de controle da ULA e suas portas de entrada e saída.
entity alu_control is
  port (
    aluop  : in  std_logic_vector(1 downto 0); -- Código de controle recebido da unidade de controle
    funct  : in  std_logic_vector(5 downto 0); -- Código que identifica a operação da instrução
    alu_op : out std_logic_vector(2 downto 0) -- Código enviado para selecionar a operação da ULA
  );
end entity alu_control;

-- Descreve o funcionamento interno da unidade de controle da ULA.
architecture comportamento of alu_control is
begin

  -- Processo combinacional: executa novamente quando aluop ou funct mudam.
  process (aluop, funct)
  begin
    case aluop is -- Define a operação da ULA de acordo com o código aluop.
      when "00" => alu_op <= "000"; -- ADD: seleciona a operação de soma.
      when "01" => alu_op <= "001"; -- SUB: seleciona a operação de subtração.
      when "10" =>  -- Para instruções do tipo R, utiliza funct para identificar a operação.
        case funct is
          when "100000" => alu_op <= "000";   -- add
          when "100010" => alu_op <= "001";   -- sub
          when "100100" => alu_op <= "010";   -- and
          when "100101" => alu_op <= "011";   -- or
          when "101010" => alu_op <= "100";   -- slt
          when others   => alu_op <= "000";   -- Para códigos funct não reconhecidos, seleciona ADD.
        end case;
      when others => alu_op <= "000"; -- Para códigos aluop não reconhecidos, seleciona ADD.
    end case;
  end process;
end architecture comportamento;