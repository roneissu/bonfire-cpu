

TARGET_PREFIX ?= riscv32-unknown-elf
TARGET_CC := $(TARGET_PREFIX)-gcc
TARGET_LD := $(TARGET_PREFIX)-gcc
TARGET_SIZE := $(TARGET_PREFIX)-size
TARGET_OBJCOPY := $(TARGET_PREFIX)-objcopy
ARCH= rv32im
ABI = ilp32
HEXDUMP ?= hexdump
LINKDEF?=lxp.ld

%.elf : %.S
	$(TARGET_CC) -march=$(ARCH) -mabi=$(ABI)  -nostartfiles -T$(LINKDEF) -o $@ $<


%.hex : %.elf
	$(TARGET_OBJCOPY) -j .text -O binary $< $(basename $@).bin
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $(basename $@).bin >$@
	$(TARGET_PREFIX)-objdump -d $< >$(basename $@).lst
	$(TARGET_PREFIX)-size  $<

test02.hex : test02.S
test01.hex : test01.S
test03.hex : test03.S
branch.hex : branch.S
mult.hex : mult.S
slt.hex : slt.S
loadsave.hex : loadsave.S
csr.hex : csr.S
trap01.hex : trap01.S
fence.hex : fence.S
loop.hex : loop.S
timer_irq.hex : timer_irq.S
sstep.hex : sstep.S
#fence_soc.hex : fence_soc.S

all: test02.hex test01.hex test03.hex branch.hex mult.hex slt.hex loadsave.hex csr.hex trap01.hex fence.hex loop.hex timer_irq.hex sstep.hex 
