
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dmem is
    port (
        clk          : in  std_logic;
        endereco     : in  std_logic_vector(31 downto 0);
        dado_entrada : in  std_logic_vector(31 downto 0);
        escrever     : in  std_logic;
        ler          : in  std_logic;
        dado_saida   : out std_logic_vector(31 downto 0)
    );
end entity dmem;

architecture rtl of dmem is

    type tipo_memoria is array (0 to 255)
        of std_logic_vector(31 downto 0);

    signal memoria : tipo_memoria :=
        (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if escrever = '1' then
                memoria(to_integer(unsigned(endereco(9 downto 2))))
                    <= dado_entrada;
            end if;
        end if;
    end process;

    process(all)
    begin
        dado_saida <= (others => '0');

        if ler = '1' then
            dado_saida <= memoria(
                to_integer(unsigned(endereco(9 downto 2)))
            );
        end if;
    end process;

end architecture;
