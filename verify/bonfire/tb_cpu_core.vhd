--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   18:17:47 02/04/2017
-- Design Name:
-- Module Name:   /home/thomas/riscv/lxp32-cpu/verify/bonfire/tb_cpu_core.vhd
-- Project Name:  bonfire
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: lxp32u_top
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

use work.log2;
use work.common_pkg.all;

--library std;
--use std.env.all;

ENTITY tb_cpu_core IS
END tb_cpu_core;

ARCHITECTURE behavior OF tb_cpu_core IS

constant ram_size : natural := 4096;
constant ram_adr_width : natural := log2.log2(ram_size);

constant BRANCH_PREDICTOR : boolean := true;

constant LLI_WAIT_CYCLES : natural := 1;

constant USE_ICACHE : boolean := true;
constant LINE_SIZE : natural := 8;

--constant TestFile : string :=  "../src/bonfire-cpu_0/ise/tb_bonfire_cpu/compiled_tests/timer_irq.hex";
--constant TestFile : string :=  "../src/bonfire-cpu_0/riscv_test/timer_irq.hex";
constant TestFile : string :=  "../src/bonfire-cpu_0/riscv_test/loop.hex";
--constant TestFile : string :=  "../src/bonfire-cpu_0/riscv_test/branch.hex";
--constant TestFile : string :=  "../src/bonfire-cpu_0/riscv_test/sstep.hex";
--constant TestFile : string :=  "../src/bonfire-cpu_0/riscv_test/fence.hex";

    -- Component Declaration for the Unit Under Test (UUT)

    component lxp32_cpu
    generic (
      DBUS_RMW: boolean:=false;
      DIVIDER_EN: boolean:=true;
      MUL_ARCH: string:="dsp";
      START_ADDR: std_logic_vector(29 downto 0):=(others=>'0');
      USE_RISCV : boolean := false;
      REG_RAM_STYLE : string := "block";
      BRANCH_PREDICTOR : boolean := false
    );
    port (
      clk_i               : in  std_logic;
      rst_i               : in  std_logic;
      lli_re_o            : out std_logic;
      lli_adr_o           : out std_logic_vector(29 downto 0);
      lli_dat_i           : in  std_logic_vector(31 downto 0);
      lli_busy_i          : in  std_logic;
      lli_cc_invalidate_o : out std_logic;
      dbus_cyc_o          : out std_logic;
      dbus_stb_o          : out std_logic;
      dbus_we_o           : out std_logic;
      dbus_sel_o          : out std_logic_vector(3 downto 0);
      dbus_ack_i          : in  std_logic;
      dbus_adr_o          : out std_logic_vector(31 downto 2);
      dbus_dat_o          : out std_logic_vector(31 downto 0);
      dbus_dat_i          : in  std_logic_vector(31 downto 0);
      irq_i               : in  std_logic_vector(7 downto 0)
    );
    end component lxp32_cpu;



   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal lli_dat_i : std_logic_vector(31 downto 0) := (others => '0');
   signal lli_busy_i : std_logic := '0';

   signal irq_i : std_logic_vector(7 downto 0) := (others => '0');

    --Outputs
   signal lli_re_o : std_logic;
   signal lli_adr_o : std_logic_vector(29 downto 0);
   signal lli_cc_invalidate_o : std_logic;


   -- Wishbone DB Master
   signal dbus_ack_i : std_logic := '0';
   signal dbus_dat_i : std_logic_vector(31 downto 0) := (others => '0');

   signal dbus_cyc_o : std_logic;
   signal dbus_stb_o : std_logic;
   signal dbus_we_o :  std_logic;
   signal dbus_cti_o : std_logic_vector(2 downto 0):="000";
   signal dbus_bte_o : std_logic_vector(1 downto 0):="00";
   signal dbus_sel_o : std_logic_vector(3 downto 0);
   signal dbus_adr_o : std_logic_vector(31 downto 2);
   signal dbus_dat_o : std_logic_vector(31 downto 0);

   -- I Cache Wishbone MASTER
   signal ic_cyc                : std_logic;
   signal ic_stb                : std_logic;
   signal ic_cti                : std_logic_vector(2 downto 0);
   signal ic_bte                : std_logic_vector(1 downto 0);
   signal ic_ack                : std_logic;
   signal ic_adr                : std_logic_vector(29 downto 0);
   signal ic_dat                : std_logic_vector(31 downto 0);

   constant slave_adr_high : natural := 27;

   -- Memory bus
   signal mem_cyc,mem_stb,mem_we,mem_ack : std_logic;
   signal mem_sel :  std_logic_vector(3 downto 0);
   signal mem_dat_rd,mem_dat_wr : std_logic_vector(31 downto 0);
   signal mem_adr : std_logic_vector(slave_adr_high downto 2);
   signal mem_cti : std_logic_vector(2 downto 0);

 -- monitor bus
   signal mon_cyc,mon_stb,mon_we,mon_ack : std_logic;
   signal mon_sel :  std_logic_vector(3 downto 0);
   signal mon_dat_rd,mon_dat_wr : std_logic_vector(31 downto 0);
   signal mon_adr : std_logic_vector(slave_adr_high downto 2);


-- Simulation control
   signal finished :  std_logic :='0';
   signal result   :  std_logic_vector(31 downto 0);
   signal tbSimEnded : std_logic := '0'; -- Simulation End Flag


   -- Clock period definitions
   constant clk_i_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
   uut: lxp32_cpu
   generic map (
     USE_RISCV=>true,
     MUL_ARCH=>"spartandsp",
     BRANCH_PREDICTOR=>BRANCH_PREDICTOR
   )
   PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          lli_re_o => lli_re_o,
          lli_adr_o => lli_adr_o,
          lli_dat_i => lli_dat_i,
          lli_busy_i => lli_busy_i,
          lli_cc_invalidate_o => lli_cc_invalidate_o,
          dbus_cyc_o => dbus_cyc_o,
          dbus_stb_o => dbus_stb_o,
          dbus_we_o => dbus_we_o,
          dbus_sel_o => dbus_sel_o,
          dbus_ack_i => dbus_ack_i,
          dbus_adr_o => dbus_adr_o,
          dbus_dat_o => dbus_dat_o,
          dbus_dat_i => dbus_dat_i,
          irq_i => irq_i
        );

ic : if USE_ICACHE generate

  bonfire_dm_icache_i : entity work.bonfire_dm_icache
  generic map (
       LINE_SIZE    => LINE_SIZE
  --   CACHE_SIZE   => CACHE_SIZE,
  --   ADDRESS_BITS => ADDRESS_BITS
  )
  port map (
    clk_i                    => clk_i,
    rst_i                    => rst_i,
    lli_re_i                 => lli_re_o,
    lli_adr_i                => lli_adr_o,
    lli_dat_o                => lli_dat_i,
    lli_busy_o               => lli_busy_i,
    wbm_cyc_o                => ic_cyc,
    wbm_stb_o                => ic_stb,
    wbm_cti_o                => ic_cti,
    wbm_bte_o                => ic_bte,
    wbm_ack_i                => ic_ack,
    wbm_adr_o                => ic_adr,
    wbm_dat_i                => ic_dat,
    cc_invalidate_i          => lli_cc_invalidate_o,
    cc_invalidate_complete_o => open
  );

  mem: entity work.sim_burst_memory_interface
  generic map (
      ram_size => ram_size,
      ram_adr_width =>ram_adr_width,
      RamFileName =>TestFile,
      mode=>"H",
      wbs_adr_high => mem_adr'high,
      Swapbytes=>false
  )
  PORT MAP(
      clk_i => clk_i,
      rst_i => rst_i,
      wbs_cyc_i =>mem_cyc ,
      wbs_stb_i => mem_stb,
      wbs_we_i => mem_we,
      wbs_sel_i =>mem_sel ,
      wbs_ack_o => mem_ack,
      wbs_adr_i => mem_adr,
      wbs_dat_i => mem_dat_wr,
      wbs_dat_o => mem_dat_rd,
      wbs_cti_i => mem_cti

  );


end generate;

noic: if not USE_ICACHE generate

  Inst_sim_memory_interface: entity work.sim_memory_interface
  generic map (
      ram_size => ram_size,
      ram_adr_width =>ram_adr_width,
      RamFileName =>TestFile,
      mode=>"H",
      wbs_adr_high => mem_adr'high,
      LLI_WAIT_CYCLES => LLI_WAIT_CYCLES
  )
  PORT MAP(
      clk_i => clk_i,
      rst_i => rst_i,
      wbs_cyc_i =>mem_cyc ,
      wbs_stb_i => mem_stb,
      wbs_we_i => mem_we,
      wbs_sel_i =>mem_sel ,
      wbs_ack_o => mem_ack,
      wbs_adr_i => mem_adr,
      wbs_dat_i => mem_dat_wr,
      wbs_dat_o => mem_dat_rd,
      lli_re_i =>lli_re_o ,
      lli_adr_i =>lli_adr_o ,
      lli_dat_o =>lli_dat_i ,
      lli_busy_o => lli_busy_i
  );

  ic_cyc <= '0';
  ic_stb <= '0';

end generate;


    Inst_sim_bus:  entity work.sim_bus
      PORT MAP(
      clk_i    => clk_i,
      rst_i    => rst_i,
      s0_cyc_i => dbus_cyc_o,
      s0_stb_i => dbus_stb_o,
      s0_we_i  => dbus_we_o,
      s0_sel_i => dbus_sel_o,
      s0_cti_i => dbus_cti_o,
      s0_bte_i => dbus_bte_o,
      s0_ack_o => dbus_ack_i,
      s0_adr_i => dbus_adr_o,
      s0_dat_i => dbus_dat_o,
      s0_dat_o => dbus_dat_i,

      s1_cyc_i => ic_cyc,
      s1_stb_i => ic_stb,
      s1_we_i  => '0',
      s1_sel_i => "1111",
      s1_cti_i => ic_cti,
      s1_bte_i => ic_bte,
      s1_ack_o => ic_ack,
      s1_adr_i => ic_adr,
      s1_dat_i => (others =>'0'),
      s1_dat_o => ic_dat,

      m0_cyc_o => mem_cyc,
      m0_stb_o => mem_stb,
      m0_we_o =>  mem_we,
      m0_sel_o => mem_sel,
      m0_ack_i => mem_ack,
      m0_adr_o => mem_adr,
      m0_dat_o => mem_dat_wr,
      m0_dat_i => mem_dat_rd,
      m0_cti_o => mem_cti,
      m0_bte_o => open,

      m1_cyc_o => mon_cyc,
      m1_stb_o => mon_stb,
      m1_we_o =>  mon_we,
      m1_sel_o => mon_sel,
      m1_ack_i => mon_ack,
      m1_adr_o => mon_adr,
      m1_dat_o => mon_dat_wr,
      m1_dat_i => mon_dat_rd,
      m1_cti_o => open,
      m1_bte_o => open
    );





    Inst_monitor:  entity work.monitor
    generic map(
      VERBOSE=>true
    )
    PORT MAP(
        clk_i => clk_i,
        rst_i => rst_i,
        wbs_cyc_i => mon_cyc,
        wbs_stb_i => mon_stb,
        wbs_we_i => mon_we,
        wbs_sel_i => mon_sel,
        wbs_ack_o => mon_ack,
        wbs_adr_i => mon_adr,
        wbs_dat_i => mon_dat_wr,
        wbs_dat_o => mon_dat_rd,
        finished_o => finished,
        result_o => result
    );



    -- Clock
    clk_i <= not clk_i after clk_i_period/2 when TbSimEnded /= '1' else '0';

   -- Stimulus process
   stim_proc: process
   begin


      wait until finished='1';
      report "Test finished with result "& hex_string(result);
      --severity failure; -- ugly but portable ....

      tbSimEnded <= '1'; -- End Simulation

   end process;

END;
