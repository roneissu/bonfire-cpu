.section .text
.global _start
.extern monitor
_start:


la s1, monitor
li a1,5
la t1, trap_handler
csrw mtvec,t1
li a2,0
ebreak

// "debuggee"

loop:
addi a1,a1,-1
//sw a1, 8(s1) // test output
j loop
//

trap_handler:
csrs 0x7c0,1 // set sstep flag
csrr t2,mepc
// check for first call (a2==0)
bnez a2, l1
// jump over hard coded break instruction
addi t2,t2,4
csrw mepc,t2
addi a2,a2,1 // adjust

l1:
sw t2,4(s1) // print mepc
bnez a1, l2 // check "debuggee" loop counter
sw a1,0(s1) // stop
l2:
sret
