CC=gcc
LEX=flex
CFLAGS=-O

all: rtf2rtf

rtf2rtf: rtf2rtf.c
	$(CC) $(CFLAGS) -o rtf2rtf rtf2rtf.c -lfl

rtf2rtf.c: rtf2rtf.l
	$(LEX) -t rtf2rtf.l>rtf2rtf.c

install: rtf2rtf
	cp rtf2rtf /usr/local/bin

clean: 
	/bin/rm -f rtf2rtf.c rtf2rtf core
      
