
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_extend is
    port (
        imediato_16 : in std_logic_vector(15 downto 0);
        imediato_32 : out std_logic_vector(31 downto 0)
    );
end entity sign_extend;

architecture rtl of sign_extend is
begin

   imediato_32 <= std_logic_vector(resize(signed(imediato_16), 32));

end architecture;
