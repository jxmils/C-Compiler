#CS370
# Make file for Compiler2
#Jason Miller

# flags and defs for built-in compiler rules
CFLAGS = -I. -Wall -g -Wno-unused-function
CC = gcc

# default rule, build the parser into a 'ptest' executable
all: ptest

# yacc "-d" flag creates y.tab.h header
y.tab.c: parser.y
	yacc -d parser.y

# lex rule includes y.tab.c to force yacc to run first
# lex "-d" flag turns on debugging output
lex.yy.c: scanner.l y.tab.c
	lex scanner.l

# ptest executable needs scanner and parser object files
ptest: lex.yy.o y.tab.o symtable.o astree.o
	gcc -o ptest y.tab.o lex.yy.o symtable.o astree.o

astree.o: astree.c astree.h
	gcc -c -g astree.c
	
symtable.o: symtable.c symtable.h
	gcc -c -g symtable.c

# ltest is a standalone lexer (scanner)
# build this by doing "make ltest"
# -ll for compiling lexer as standalone
ltest: scanner.l
	lex scanner.l
	gcc -DLEXONLY lex.yy.c -o ltest -ll

test: ptest test.c
	make
	./ptest test.c > test.s
	gcc test.s -o test
	./test

memcheck: ptest test.c
		make
		valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./ptest test.c

# clean the directory for a pure rebuild (do "make clean")
clean:
	rm -f lex.yy.c a.out y.tab.c y.tab.h *.o ptest ltest *.S *.s test
