.section .text
.global _start
.extern monitor
_start:

li a0,3 // loop counter
la s0, monitor

loop:
addi a0,a0,-1
sw a0,4(s0)
bnez a0, loop
nop

sw a0,0(s0) // write  to monitor result register
f0:
j f0
