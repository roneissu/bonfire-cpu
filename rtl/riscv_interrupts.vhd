----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:04:26 03/10/2017 
-- Design Name: 
-- Module Name:    riscv_interrupts - rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--   Bonfire CPU 
--   (c) 2016,2017 Thomas Hornschuh
--   See license.md for License 

-- RISC-V local interrupt controller
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.csr_def.all;

entity riscv_interrupts is
    Port ( 
      mie : in  STD_LOGIC; -- Global M-Mode Interrupt Enable
      ir_in  : in t_irq_enable;
      ir_out : out t_irq_pending;
      --ir_we_o : out std_logic; -- Interrupt register Write Enable
      interrupt_exec_o : out std_logic;  -- Signal Interrrupt to exec/decode unit
      interrupt_ack_i : in std_logic; --  Interrupt was taken
      interrupt_number_o : out std_logic_vector(2 downto 0);
      mcause_o : out std_logic_vector(3 downto 0);
      
      ext_irq_in : in std_logic_vector(7 downto 0);
      timer_irq_in : in std_logic;
      
      clk_i : in  STD_LOGIC;
      rst_i : in  STD_LOGIC
    );
    
end riscv_interrupts;

architecture rtl of riscv_interrupts is

signal interrupt_exec: std_logic:='0';

signal irq_pending : t_irq_pending:=('0','0',(others=>'0'));

begin

  ir_out<=irq_pending;

  -- register pending interrupts
  process(clk_i) begin    
  
    if rising_edge(clk_i) then
      if rst_i='1' then
          irq_pending<=('0','0',(others=>'0'));
      else  
        irq_pending.mtip<=timer_irq_in;
        irq_pending.meip<=ext_irq_in;
      end if;  
    end if;
  end process;




  interrupt_exec_o<=interrupt_exec;

  -- Interrupt priority decoder
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i='1' then
          interrupt_exec<='0';
      else  
          
          
          if mie='1' then -- process interrupts when globally enabled
            if ir_in.mtie='1' and irq_pending.mtip='1' and interrupt_exec='0' then
              interrupt_exec<='1';
              mcause_o <= X"7";
            else
              for i in ext_irq_in'reverse_range loop
                 if ir_in.meie(i)='1' and irq_pending.meip(i)='1' then
                    interrupt_exec<='1';
                    interrupt_number_o<=std_logic_vector(to_unsigned(i,3));
                    mcause_o <= X"B";
                    exit;
                 end if;                 
              end loop;           
            end if;
          end if;
          if interrupt_exec='1' and interrupt_ack_i='1' then
            interrupt_exec<='0';
          end if;  
      end if; 
    end if;
  
  
  end process;


end rtl;

