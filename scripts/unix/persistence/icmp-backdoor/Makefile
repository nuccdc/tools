CC=gcc
CFLAGS=-Wall -Wextra -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2
LDFLAGS=-Wl,-z,relro,-z,now
TARGET=backdoor
SRC=backdoor.c
OBJ=$(SRC:.c=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(LDFLAGS) $(OBJ) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)
