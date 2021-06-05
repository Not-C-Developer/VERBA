CC              = gcc

FLAGS           = -std=gnu99
CFLAGS          = -fomit-frame-pointer -fPIC -s -Wall -Wextra -Wshadow -Wno-unused-function -fstack-protector-all -funroll-loops -fno-jump-tables -Os -g0 -I%%POSTGRES_I_DIR%% -I./-.
LDFLAGS         = -shared -Wl,--build-id=none,-z,relro,-z,now

TARGET          = UDF.so
SOURCES         = UDF.c
OBJECTS         = $(SOURCES:.c=.o)

$(TARGET): $(OBJECTS)
	$(CC) $(FLAGS) $(CFLAGS) $^ -o $@ $(LDFLAGS)

clean:
	rm -rf $(OBJECTS) $(TARGET)
