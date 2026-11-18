library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Registrador entre os estagios EX e MEM do pipeline

entity ex_mem is
  port (
    clk            : in  std_logic; --Clock
    rst            : in  std_logic; -- Reset do registrador
    freeze         : in  std_logic; -- Congela o conteúdo do registrador
    valid_in       : in  std_logic; -- Recebe a indicação de validade dos dados
    valid_out      : out std_logic; -- Disponibiliza a indicação de validade dos dados armazenados
    alu_result_in  : in  std_logic_vector(31 downto 0); -- Recebe o resultado da ULA
    alu_result_out : out std_logic_vector(31 downto 0); -- Disponibiliza o resultado da ULA
    store_data_in  : in  std_logic_vector(31 downto 0); -- Recebe o dado que será escrito na memória
    store_data_out : out std_logic_vector(31 downto 0); -- Disponibiliza o dado para escrita na memória
    dest_in        : in  std_logic_vector(4 downto 0); -- Recebe o registrador de destino
    dest_out       : out std_logic_vector(4 downto 0); -- Disponibiliza o registrador de destino
    reg_write_in   : in  std_logic; -- Recebe o controle de escrita no banco de registradores
    reg_write_out  : out std_logic; -- Disponibiliza o controle de escrita
    mem_to_reg_in  : in  std_logic; -- Recebe o controle de seleção do dado para o registrador
    mem_to_reg_out : out std_logic; -- Disponibiliza o controle de seleção
    mem_read_in    : in  std_logic; -- Recebe o controle de leitura da memória
    mem_read_out   : out std_logic; -- Disponibiliza o controle de leitura
    mem_write_in   : in  std_logic; -- Recebe o controle de escrita na memória
    mem_write_out  : out std_logic; -- Disponibiliza o controle de escrita
    pc_in          : in  std_logic_vector(31 downto 0); -- Recebe o endereço da instrução
    pc_out         : out std_logic_vector(31 downto 0); -- Disponibiliza o endereço da instrução
    zero_in        : in  std_logic; -- Recebe a indicação de resultado zero da ULA
    zero_out       : out std_logic; -- Disponibiliza a indicação de resultado zero
    branch_in      : in  std_logic; -- Recebe a indicação de uma instrução de desvio
    branch_out     : out std_logic; -- Disponibiliza a indicação de desvio
    branch_target_in  : in  std_logic_vector(31 downto 0); -- Recebe o endereço de destino do desvio
    branch_target_out : out std_logic_vector(31 downto 0); -- Disponibiliza o endereço de destino do desvio
    halt_in        : in  std_logic; -- Recebe a indicação de uma instrução de parada
    halt_out       : out std_logic -- Disponibiliza a indicação de parada
  );
end entity ex_mem;

-- Descreve o funcionamento interno do registrador de pipeline.
architecture comportamento of ex_mem is
begin

  -- Processo sequencial: atualiza os dados na borda de subida do clock.
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then -- Reseta todas as saídas, inserindo uma bolha no pipeline.
        valid_out      <= '0';
        alu_result_out <= (others => '0');
        store_data_out <= (others => '0');
        dest_out       <= (others => '0');
        reg_write_out  <= '0';
        mem_to_reg_out <= '0';
        mem_read_out   <= '0';
        mem_write_out  <= '0';
        pc_out         <= (others => '0');
        zero_out       <= '0';
        branch_out     <= '0';
        branch_target_out <= (others => '0');
        halt_out       <= '0';

      elsif freeze = '1' then
        null;  -- congelado: as saidas mantem o valor

      else
        -- Funcionamento normal: transfere as entradas para as saídas.
        valid_out      <= valid_in;
        alu_result_out <= alu_result_in;
        store_data_out <= store_data_in;
        dest_out       <= dest_in;
        reg_write_out  <= reg_write_in;
        mem_to_reg_out <= mem_to_reg_in;
        mem_read_out   <= mem_read_in;
        mem_write_out  <= mem_write_in;
        pc_out         <= pc_in;
        zero_out       <= zero_in;
        branch_out     <= branch_in;
        branch_target_out <= branch_target_in;
        halt_out       <= halt_in;
      end if;
    end if;
  end process;

end architecture comportamento;