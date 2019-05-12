.section .text
.global _start
_start:



la s0, monitor

la t1, trap_failure
csrw mtvec,t1

li a0, -1 // preset a0 with failure code

csrr t1,mvendorid
bnez t1,finish
csrr t1,marchid
bnez t1,finish
csrr t1,mhartid
bnez t1,finish
csrr t1,mimpid
beqz t1, finish
sw t1,4(s0) // write impid to monitor
csrr t1,misa
sw t1,8(s0) // write misa to monitor
beqz t1,finish

// Read mcycle/h and write to monitor
csrr t1,mcycle
sw t1,24(s0)
beqz t1, finish // failure->
csrr t1,mcycleh
sw t1,28(s0)

csrr t1,minstret
sw t1,32(s0)
beqz t1, finish // failure->
csrr t1,minstreth
sw t1,36(s0)


// Test mstatus register
csrr t1,mstatus
sw t1,20(s0) // write to monitor
li t2,0x8 // set MIE bit
csrs mstatus,t2
csrr t1,mstatus
sw t1,20(s0) // write to monitor


// Test IE Bit
la t1,trap_mstatus
csrw mtvec,t1
ecall
csrr t1,mstatus
sw t1,20(s0) // write to monitor
andi t1,t1,0x08  // mask MIE
beqz t1, finish // failure when MIE is not set


li a0,1 // success
j finish

trap_failure: // should not be called
csrr t1,mepc
sw t1,12(s0)
csrr t1,mcause
sw t1,16(s0)
/// fall through finish/failure

finish:
sw a0,0(s0) // write  to monitor result register
f0:
j f0

trap_mstatus:
csrr t1,mepc
sw t1,12(s0)
csrr t1, mstatus
sw t1,20(s0)
andi t1,t1, 0x088 // mask MPIE and MIE
addi t1,t1,-0x80   // result should be 80
bnez t1,finish  // failure.. if not 80
csrr t1,mepc
addi t1,t1,4
csrw mepc,t1
mret
