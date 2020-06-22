--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:24:53 12/02/2017
-- Design Name:   
-- Module Name:   /home/thomas/fusesoc_projects/bonfire/bonfire-cpu/ut/tb_irq_unit.vhd
-- Project Name:  bonfire-soc_0
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: riscv_interrupts
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.csr_def.all;

library STD;
use STD.textio.all;

use work.txt_util.all;

USE ieee.numeric_std.ALL;
 
ENTITY tb_irq_unit IS
END tb_irq_unit;
 
ARCHITECTURE behavior OF tb_irq_unit IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT riscv_interrupts
    PORT(
         mie : IN  std_logic;
         ir_in : IN  t_irq_enable;
         ir_out : OUT  t_irq_pending;
         interrupt_exec_o : OUT  std_logic;
         interrupt_ack_i : IN  std_logic;
         mcause_o : OUT  std_logic_vector(4 downto 0);
         ext_irq_in : IN  std_logic;
         timer_irq_in : IN  std_logic;
         software_irq_in : IN  std_logic;
         l_irq_in : IN  std_logic_vector(15 downto 0);
         clk_i : IN  std_logic;
         rst_i : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal mie : std_logic := '1';
   signal ir_in : t_irq_enable := ('0','0','0',(others=>'0'));
   signal interrupt_ack_i : std_logic := '0';
   signal ext_irq_in : std_logic := '1';
   signal timer_irq_in : std_logic := '1';
   signal software_irq_in : std_logic := '1';
   signal l_irq_in : std_logic_vector(15 downto 0) := (others => '1');
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';

 	--Outputs
   signal ir_out : t_irq_pending:=c_pending_init;
   signal interrupt_exec_o : std_logic;
   signal mcause_o : std_logic_vector(4 downto 0);

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
   
   
   -- Simulation control
   
   signal all_processed : boolean := false;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: riscv_interrupts PORT MAP (
          mie => mie,
          ir_in => ir_in,
          ir_out => ir_out,
          interrupt_exec_o => interrupt_exec_o,
          interrupt_ack_i => interrupt_ack_i,
          mcause_o => mcause_o,
          ext_irq_in => ext_irq_in,
          timer_irq_in => timer_irq_in,
          software_irq_in => software_irq_in,
          l_irq_in => l_irq_in,
          clk_i => clk_i,
          rst_i => rst_i
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 
 
   -- Simulates behaviour of the execution unit
   exec_sim : process
   variable mcause : integer;
   begin
    
   
     wait until rising_edge(clk_i) and interrupt_exec_o='1';
     mcause := to_integer(unsigned(mcause_o));
     print("IRQ detected with cause " & str(mcause));
     mie <= '0'; -- disable interupts
     interrupt_ack_i <= '1';
     wait until rising_edge(clk_i);
     interrupt_ack_i <= '0';
     
     wait for clk_i_period*2; -- very fast IRQ handler :-)
     -- clear the pending IRQ just handled...
     if mcause >= IRQ_CODE_LOCAL_BASE then
       l_irq_in(mcause-IRQ_CODE_LOCAL_BASE) <='0';
     else 
       case mcause is 
         when IRQ_CODE_MEXTERNAL =>
           ext_irq_in <= '0';
         when IRQ_CODE_MTIMER =>
           timer_irq_in <= '0';
         when IRQ_CODE_MSOFTWARE =>           
           software_irq_in <= '0';
         when others=>
           report "Unexpected mcause: " & str(mcause)
           severity failure;
       end case;           
     end if;     
     wait until rising_edge(clk_i);
     mie <= '1'; -- enable again 
     
     -- Timer IRQ has lowed prio, so test is finished when this is raised
     if mcause_o=irq_cause(IRQ_CODE_MTIMER) then
       all_processed <= true;
     end if;  
 
   end process;   
  
 
 

   -- Stimulus process
   stim_proc: process
   
   procedure print_mip is
   begin
     print("MIP: " & str(get_mip(ir_out)));
     print("MSIP: " & str(ir_out.msip));
     print("MTIP: " & str(ir_out.mtip));
     print("MEIP: " & str(ir_out.meip));
     print("LIP: "  & str(ir_out.lip));
     
   
   end procedure;
   
   
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
   
    
    
      ir_in <= ('1','1','1',(others=>'1'));
      while not all_processed loop
        wait until rising_edge(clk_i);
        print_mip;
      end loop;  
         
     
      
      
      wait until all_processed;
     

     

      wait;
   end process;

END;
