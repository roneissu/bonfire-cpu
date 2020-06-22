----------------------------------------------------------------------------------

-- Module Name:    sim_uart - Behavioral

-- The Bonfire Processor Project, (c) 2016,2017 Thomas Hornschuh

--  Simulation UART, compatible with zpuino UART, tx only
--  does write all tx output to a file and to std outputs
--  The status register will always state TX ready, RX not ready
--  Therefore the UART appears much faster than a real UART for the code running on the simulation 


-- License: See LICENSE or LICENSE.txt File in git project root.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library STD;
use STD.textio.all;

use work.txt_util.all;


entity sim_uart is
generic (
  SEND_LOG_NAME : string := "send.log";
  stop_mark : std_logic_vector(7 downto 0) := X"1A"; -- Stop marker byte
  --status : std_logic_vector(31 downto 0) :=  X"00000002"; -- TX ready, RX not ready
  maxIObit : natural :=3;
  minIObit : natural :=2
);
port (
    -- Wishbone Bus
    wb_clk_i: in std_logic;
    wb_rst_i: in std_logic;
    wb_dat_o: out std_logic_vector(31 downto 0);
    wb_dat_i: in std_logic_vector(31 downto 0);
    wb_adr_i: in std_logic_vector(maxIObit downto minIObit);
    wb_we_i:  in std_logic;
    wb_cyc_i: in std_logic;
    wb_stb_i: in std_logic;
    wb_ack_o: out std_logic;

    stop_o : out boolean -- will go to true when a stop marker is found
);
end sim_uart;

architecture testbench of  sim_uart  is

  subtype t_byte is std_logic_vector(7 downto 0);
  signal f_stop : boolean := false;

  signal ack : std_logic;

  -- Register addresses
  constant data_reg : std_logic_vector(wb_adr_i'range ) := (others=>'0');
  constant status_reg : std_logic_vector(wb_adr_i'range ) := std_logic_vector(to_unsigned(1,wb_adr_i'length));

  constant status : std_logic_vector(31 downto 0) :=  X"00000002"; -- TX ready, RX not ready

begin

  ack <= wb_stb_i and wb_cyc_i;
  wb_ack_o <= ack;
  stop_o <= f_stop;


  -- Simulated "Status" register
  wb_dat_o <= status when ack='1' and wb_we_i='0' and wb_adr_i=status_reg else (others=>'-');


  tx: process

     file s_file: TEXT; -- open write_mode is send_logfile;
     variable byte : t_byte;
     variable f_e : natural :=0;
     variable cnt : natural :=0;

     begin

       file_open(s_file,SEND_LOG_NAME,WRITE_MODE);
       byte:=(others=>'U');
       while byte/=stop_mark loop
         wait until rising_edge(wb_clk_i);
         if  ack='1' and wb_adr_i=data_reg then
            byte := wb_dat_i(byte'range);
            write_charbyte(s_file,byte);
            write_charbyte(output,byte);
         end if;
       end loop;
       file_close(s_file);
       f_stop <= true;

     end process;

end architecture;
