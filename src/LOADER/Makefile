TARGET		= %%LOADER_MOD%%
MODULE		= %%ORIG_LKM_PATH%%
EKEY		= %%EKEY%%
EFILE		= %%EFILE%%

obj-m		+= $(TARGET).o
$(TARGET)-y	+= LOADER.o

ccflags-y	+= $(CFLAGS) -Os -fno-stack-protector

KBUILD_CFLAGS	:= $(subst -pg,,$(KBUILD_CFLAGS))
KBUILD_CFLAGS	:= $(subst -mfentry,,$(KBUILD_CFLAGS))

all: encode
	$(MAKE) -C /lib/modules/%%VER%%/build M=$$PWD

encode:
	$(MAKE) -C encrypt
	encrypt/encrypt $(MODULE) $(EKEY) > $(EFILE)

clean:
	$(MAKE) -C encrypt clean
	$(MAKE) -C /lib/modules/%%VER%%/build M=$$PWD clean
	rm -f $(EFILE)
