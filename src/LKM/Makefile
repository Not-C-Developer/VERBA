MODULE		= %%LKM_MOD%%
MAKE		= make
ccflags-y	= -Wall -fno-stack-protector
obj-m		= $(MODULE).o
$(MODULE)-y	+= LKM.o

all:
	$(MAKE) -C /lib/modules/%%VER%%/build M=$$PWD
clean:
	$(MAKE) -C /lib/modules/%%VER%%/build M=$$PWD clean

