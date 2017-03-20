--   Bonfire CPU 
--   (c) 2016,2017 Thomas Hornschuh
--   See license.md for License 

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package csr_def is

subtype t_csr_adrprefix is std_logic_vector(3 downto 0);
constant m_stdprefix : t_csr_adrprefix := x"3";
constant m_nonstdprefix : t_csr_adrprefix :=x"7";
constant m_roprefix : t_csr_adrprefix :=x"F";

subtype t_csr_adr is std_logic_vector(7 downto 0);
subtype t_csr_word is std_logic_vector(31 downto 0);

-- trap setup registers
constant status : t_csr_adr:= x"00"; --  Machine status register.
constant isa    : t_csr_adr:=x"01";
constant edeleg : t_csr_adr:= x"02";
constant ideleg : t_csr_adr:= x"03";
constant a_ie   : t_csr_adr:= x"04";
constant tvec : t_csr_adr:=   x"05";

--Read only Machine Information Registers
constant vendorid : t_csr_adr:=  X"11";
constant marchid :  t_csr_adr:=  X"12";
constant impid   :  t_csr_adr:=  X"13";
constant hartid  :  t_csr_adr:=  X"14";

--Trap Handling
constant scratch : t_csr_adr:=   x"40";
constant epc: t_csr_adr:=        x"41";
constant cause : t_csr_adr:=     x"42";
constant badaddr : t_csr_adr:=   x"43";
constant a_ip : t_csr_adr:=      x"44";

-- non standard registers
constant icontrol : t_csr_adr:=x"C0"; -- full address is 0x7C0

constant impvers : std_logic_vector(31 downto 0) := X"0001000E";

-- Interrupts
type t_irq_enable is record
   msie,mtie : std_logic;
   meie : std_logic_vector(7 downto 0);
end record;   
   
type t_irq_pending is record   
   msip,mtip : std_logic;
   meip : std_logic_vector(7 downto 0);
end record;



function get_misa(divider_en:boolean;mul_arch:string) return t_csr_word;
function get_mstatus(pie : std_logic; ie : std_logic) return t_csr_word;
function get_mip(ir: t_irq_pending) return t_csr_word;
function get_mie(ir: t_irq_enable) return t_csr_word;

procedure set_mip(csr: in t_csr_word;signal ir : out t_irq_pending);
procedure set_mie(csr: in t_csr_word;signal ir : out t_irq_enable);


end csr_def;

package body csr_def is

function get_misa(divider_en:boolean;mul_arch:string) return t_csr_word is
variable misa : t_csr_word := "0100" & X"0000000";
begin
  misa(8):='1';
  if divider_en and mul_arch /= "none" then
    misa(12):='1';
  end if;
  return misa;
end;    

function get_mstatus(pie : std_logic; ie : std_logic) return t_csr_word is
variable s : t_csr_word := (others=>'0');
begin
  s(12 downto 11) := "11"; -- MPP previous privilege level, always "machine" currently
  s(7) := pie;
  s(3) := ie;
  
  return s;

end;

function get_mip(ir: t_irq_pending) return t_csr_word is
variable s : t_csr_word := (others=>'0');
begin
  s(3):=ir.msip;
  s(7):=ir.mtip;
  s(11+ir.meip'high downto 11):=ir.meip;
  return s;
end;

function get_mie(ir: t_irq_enable) return t_csr_word is
variable s : t_csr_word := (others=>'0');
begin
  s(3):=ir.msie;
  s(7):=ir.mtie;
  s(11+ir.meie'high downto 11):=ir.meie;
  return s;
end;

procedure set_mip(csr: in t_csr_word;signal ir : out t_irq_pending) is
begin
  ir.msip <= csr(3);
  ir.mtip <= csr(7);
  ir.meip <= csr(11+ir.meip'high downto 11);
end;

procedure set_mie(csr: in t_csr_word;signal ir : out t_irq_enable) is
begin
  ir.msie <= csr(3);
  ir.mtie <= csr(7);
  ir.meie <= csr(11+ir.meie'high downto 11);
end;
    

end csr_def;
