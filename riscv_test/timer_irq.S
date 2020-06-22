.section .text
.global _start
.extern monitor
.extern mtime

#include "encoding.h"

_start:

la s0, monitor
la s1,mtime

la a1, trap_handler
csrw mtvec,a1

jal set_timer

li a3, 5 // iteration counter
li a1,MIP_MTIP
csrs mie, a1 // Enable timer interrupt
csrsi mstatus,MSTATUS_MIE
loop:
sw a3,8(s0)
ecall // a software trap, interrupts are disabled during the trap
j loop // just wait....

set_timer:
lw t1,0(s1) // get timer
addi t1,t1,50 // increment timer value by 100
sw t1,8(s1) // write to timer compare register, this will also clear pending timer interrupt
ret

trap_handler:
csrr t4,mcause
sw t4,4(s0) // write mcause to monitor port
bgtz t4, sw_trap

jal set_timer
addi a3,a3,-1 // iteration counter
beqz a3, finish
mret // return from interrupt

sw_trap:
csrr t1,mepc
addi t1,t1,4
csrw mepc,t1
mret


finish:
li t4,1
sw t4,0(s0)
f0:
j f0
