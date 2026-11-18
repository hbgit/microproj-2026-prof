library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Registrador entre os estagios ID e EX do pipeline

entity id_ex is
  port (
    clk       : in  std_logic; -- Clock
    rst       : in  std_logic; -- Reset do registrador
    freeze    : in  std_logic; -- Congela o conteúdo do registrador
    valid_in  : in  std_logic; -- Indica se os dados de entrada são válidos
    valid_out : out std_logic; -- Indica se os dados armazenados são válidos
    pc_in     : in  std_logic_vector(31 downto 0); -- Endereço da instrução
    pc_out    : out std_logic_vector(31 downto 0); -- Disponibiliza o endereço da instrução
    rs_val_in : in  std_logic_vector(31 downto 0); -- Recebe o valor do registrador RS
    rs_val_out: out std_logic_vector(31 downto 0); -- Disponibiliza o valor do registrador RS
    rt_val_in : in  std_logic_vector(31 downto 0);  -- Recebe o valor do registrador RT
    rt_val_out: out std_logic_vector(31 downto 0); -- Disponibiliza o valor do registrador RT
    imm_in    : in  std_logic_vector(31 downto 0); -- Recebe o valor imediato da instrução
    imm_out   : out std_logic_vector(31 downto 0); -- Disponibiliza o valor imediato
    dest_in   : in  std_logic_vector(4 downto 0); -- Recebe o registrador de destino
    dest_out  : out std_logic_vector(4 downto 0); -- Disponibiliza o registrador de destino
    aluop_in  : in  std_logic_vector(1 downto 0); -- Recebe o código de controle da ULA
    aluop_out : out std_logic_vector(1 downto 0); -- Disponibiliza o código de controle da ULA
    reg_write_in  : in  std_logic; -- Recebe o controle de escrita no banco de registradores
    reg_write_out : out std_logic; -- Disponibiliza o controle de escrita
    mem_to_reg_in : in  std_logic; -- Recebe o controle de seleção do dado para o registrador
    mem_to_reg_out: out std_logic; -- Disponibiliza o controle de seleção
    mem_read_in   : in  std_logic; -- Recebe o controle de leitura da memória
    mem_read_out  : out std_logic; -- Disponibiliza o controle de leitura
    mem_write_in  : in  std_logic; -- Recebe o controle de escrita na memória 
    mem_write_out : out std_logic; -- Disponibiliza o controle de escrita
    branch_in : in std_logic; -- Recebe a indicação de uma instrução de desvio
    branch_out: out std_logic; -- Disponibiliza a indicação de desvio
    alu_src_in: in std_logic; -- Recebe o controle de seleção da segunda entrada da ULA
    alu_src_out:  out std_logic; -- Disponibiliza o controle de seleção da ULA
    halt_in   : in std_logic; -- Recebe a indicação de uma instrução de parada
    halt_out  : out std_logic -- Disponibiliza a indicação de parada
  );

end entity id_ex;

-- Descreve o funcionamento interno do registrador de pipeline.
architecture comportamento of id_ex is
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then -- Reseta todas as saídas, inserindo uma bolha no pipeline.
        valid_out <= '0';
        pc_out    <= (others => '0');
        rs_val_out    <= (others => '0');
        rt_val_out    <= (others => '0');
        imm_out    <= (others => '0');
        dest_out    <= (others => '0');
        aluop_out    <= (others => '0');
        reg_write_out <= '0';
        mem_to_reg_out <= '0';
        mem_read_out <= '0';
        mem_write_out <= '0';
        branch_out <= '0';
        alu_src_out <= '0';
        halt_out <= '0';
      
      elsif freeze = '1' then
        null;  -- congelado: as saidas mantem o valor

      else
        -- caso normal: transfere as entradas para as saidas
        valid_out <= valid_in;
        pc_out <= pc_in;
        rs_val_out    <= rs_val_in;
        rt_val_out    <= rt_val_in;
        imm_out    <= imm_in;
        dest_out    <= dest_in;
        aluop_out    <= aluop_in;
        reg_write_out    <= reg_write_in;
        mem_to_reg_out    <= mem_to_reg_in;
        mem_read_out    <= mem_read_in;
        mem_write_out    <= mem_write_in;
        branch_out    <= branch_in;
        alu_src_out    <= alu_src_in;
        halt_out    <= halt_in;
        
      end if;
    end if;
  end process;

end architecture comportamento;