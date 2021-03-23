analizador: lex.yy.c sintactico.tab.c main_sintactico.c listaSimbolos.c listaCodigo.c
	gcc lex.yy.c sintactico.tab.c main_sintactico.c listaSimbolos.c listaCodigo.c -g -lfl -o analizador
lex.yy.c: lexico2.l sintactico.tab.h
	flex lexico2.l
sintactico.tab.c sintactico.tab.h: sintactico.y
	bison -dv -t sintactico.y
clean: 
	rm -f sintactico.tab.* analizador lex.yy.c








