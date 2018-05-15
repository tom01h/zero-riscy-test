PREFIX  = /opt/riscv
ARCH    = riscv32-unknown-elf
BINDIR  = $(PREFIX)/bin
ADDNAME = $(ARCH)-

AR      = $(BINDIR)/$(ADDNAME)ar
AS      = $(BINDIR)/$(ADDNAME)as
CC      = $(BINDIR)/$(ADDNAME)gcc
LD      = $(BINDIR)/$(ADDNAME)ld
NM      = $(BINDIR)/$(ADDNAME)nm
OBJCOPY = $(BINDIR)/$(ADDNAME)objcopy
OBJDUMP = $(BINDIR)/$(ADDNAME)objdump
RANLIB  = $(BINDIR)/$(ADDNAME)ranlib
STRIP   = $(BINDIR)/$(ADDNAME)strip

OBJS  = startup.o main.o bnn.o param.o
OBJS += lib.o
ifeq ($(UART),ps7)
OBJS += serial_ps7.o ff.o diskio.o
else
ifeq ($(UART),uartlite)
OBJS += serial.o ff.o diskio.o
else
OBJS += serial.o ff_sim.o
UART_FLAG = -DUARTSIM
endif
endif

TARGET = hardbnn

CFLAGS = -nostdinc -nostdlib -fno-builtin
CFLAGS += -I.
#CFLAGS += -g
CFLAGS += -O
CFLAGS += -DHARDBNN

LFLAGS = -static -n -T ld.scr -L.

.SUFFIXES: .c .o
.SUFFIXES: .s .o

all :		$(TARGET)

$(TARGET) :	$(OBJS)
		$(CC) $(OBJS) -o $(TARGET) $(CFLAGS) $(LFLAGS)
		cp $(TARGET) $(TARGET).elf
		$(STRIP) $(TARGET)

.c.o :		$<
		$(CC) -c $(CFLAGS) $(UART_FLAG) $<

.s.o :		$<
		$(CC) -c $(CFLAGS) $<

.S.o :		$<
		$(CC) -c $(CFLAGS) $<

clean :
		rm -f $(OBJS) $(TARGET) $(TARGET).elf $(TARGET).ihex
