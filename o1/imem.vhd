library  ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity imem is
    generic (
        PROG_FILE : string := "tracos/t0.hex"
    );
    port (
        addr : in  std_logic_vector(31 downto 0);
        instr : out std_logic_vector(31 downto 0)
    );
end entity imem;

architecture imem_arch of imem is
    type mem_t is array (0 to 255) of std_logic_vector(31 downto 0);

    impure function carrega(nome : string) return mem_t is
        file f     : text open read_mode is nome;
        variable l : line;
        variable m : mem_t := (others => (others => '0'));  -- posicoes nao usadas = 0
        variable i : natural := 0;
    begin
        while not endfile(f) and i <= mem_t'high loop
            readline(f, l);       -- le uma linha do arquivo
            hread(l, m(i));       -- converte os 8 digitos hexadecimais em 32 bits
            i := i + 1;
        end loop;
        return m;
    end function;

    signal mem : mem_t := carrega(PROG_FILE);
begin
    instr <= mem(to_integer(unsigned(addr(9 downto 2))));
end architecture imem_arch;
