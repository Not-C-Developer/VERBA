SHELL           = /bin/sh
CC              = gcc

FLAGS           = -std=gnu99
CFLAGS          = -fomit-frame-pointer -fPIC -s -Wall -Wextra -Wshadow -Wno-unused-function -fstack-protector-all -funroll-loops -fno-jump-tables -Os -g0 -I./
LDFLAGS         = -shared -Wl,--build-id=none,-z,relro,-z,now -ldl -lcrypt -lpam -lssl

TARGET          = LD.so
SOURCES         = LD.c
OBJECTS         = $(SOURCES:.c=.o)

UNAME_P := $(shell uname -p)
ifneq ($(filter %86,$(UNAME_P)),)
	FLAGS += -m32
endif

$(TARGET): $(OBJECTS)
	$(CC) $(FLAGS) $(CFLAGS) $^ -o $@ $(LDFLAGS)

clean:
	rm -f $(OBJECTS) $(TARGET)
