all:
	make clean
	lex --nounistd --always-interactive -D=_CRT_SECURE_NO_WARNINGS -D=_CRT_SECURE_NO_DEPRECATE lex.l
	bison -d gram.y
	gcc gram.tab.c lex.yy.c -o polinoms -lm
	
clean:
	rm -rf polinoms gram.tab.h gram.tab.c lex.yy.c