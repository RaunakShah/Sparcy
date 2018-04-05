.PHONY: all clean

CC ?= gcc

CFILES=$(wildcard *.c)
HFILES=$(wildcard *.h)
ALL_OBJS=$(patsubst %.c,%.o,$(CFILES))

all: $(ALL_OBJS)

clean:
	rm -rf *.o

%.o: %.c
	$(CC) -c -w -o $@ $<
