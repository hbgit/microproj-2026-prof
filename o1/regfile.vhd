library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--================================================
-- ENTITY: DEFINE AS ENTRADAS E SAÍDAS DO REGFILE
-- ==================================================

entity regfile is
  port (
    clk       : in  std_logic; -- Relógio: controla o momento da escrita
    rst       : in  std_logic; -- Reset: zera todos os registradores
    reg_write : in  std_logic; -- Autoriza ou bloqueia a escrita
    ra1       : in  std_logic_vector(4 downto 0); -- Endereço do 1º registrador que queremos ler
    ra2       : in  std_logic_vector(4 downto 0); -- Endereço do 2º registrador que queremos ler
    wa        : in  std_logic_vector(4 downto 0); -- Endereço do registrador onde vamos escrever
    wd        : in  std_logic_vector(31 downto 0); -- Valor que será armazenado
    rd1       : out std_logic_vector(31 downto 0); -- Valor obtido na primeira leitura
    rd2       : out std_logic_vector(31 downto 0); -- Valor obtido na segunda leitura
    dbg_addr  : in  std_logic_vector(4 downto 0); -- Endereço escolhido para depuração
    dbg_data  : out std_logic_vector(31 downto 0) -- Valor encontrado na leitura de depuração
  );
end entity regfile;


-- =====================================================
-- ARCHITECTURE: DEFINE COMO O REGFILE FUNCIONA
-- =====================================================

architecture comportamento of regfile is
-- 32 registradores de 32 bits (indices de 0 ate 31)

  type reg_array is array (0 to 31) of std_logic_vector(31 downto 0); 
  -- Cria um conjunto de 32 registradores (de 0 até 31).
  -- Cada registrador possui 32 bits para armazenar informações.

  signal regs : reg_array := (others => (others => '0'));
begin -- Cria o banco de registradores chamado "regs".
      -- Todos começam com o valor zero.

  -- leituras (sem relogio):

  -- Primeira leitura:
  rd1 <= regs(to_integer(unsigned(ra1)));
   -- ra1 escolhe qual registrador queremos consultar.
   -- O conteúdo encontrado é enviado para rd1.

   -- Segunda leitura:
  rd2 <= regs(to_integer(unsigned(ra2)));
  -- ra2 escolhe outro registrador.
  -- O conteúdo encontrado é enviado para rd2.
  -- As duas leituras podem acontecer simultaneamente.

  -- Leitura de depuração:
  dbg_data <= regs(to_integer(unsigned(dbg_addr)));
  -- dbg_addr escolhe um registrador para consulta.
  -- Seu conteúdo é enviado para dbg_data.
  -- Serve para acompanhar os valores durante os testes.
  
  -- escrita (na borda de subida do relogio):
  -- Este processo controla a escrita utilizando o clock.
  process (clk)
  begin
    if rising_edge(clk) then -- A escrita só é executada na borda de subida do clock.
      if rst = '1' then -- PRIMEIRA CONDIÇÃO: RESET
        regs <= (others => (others => '0')); -- Se rst for 1, todos os registradores são zerados.
      elsif reg_write = '1' and wa /= "00000" then -- SEGUNDA CONDIÇÃO: ESCRITA
      -- A escrita acontece somente se:
      -- 1. reg_write estiver ativado ( reg_write igual a 1).
      -- 2. O endereço wa não for zero.
      -- O registrador de endereço zero fica protegido contra escrita.

        regs(to_integer(unsigned(wa))) <= wd;
        -- wa escolhe onde escrever.
        -- wd informa qual valor será armazenado.
        -- to_integer e unsigned convertem o endereço
        -- para que ele possa selecionar a posição do array.
      end if;
    end if;
  end process;

end architecture comportamento;