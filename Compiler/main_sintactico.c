#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char *yytext;
extern int  yyleng;
extern FILE *yyin;
extern FILE *yyout;
extern int yyparse();
FILE *fich;

int main(int argc, char *argv[]) {
	/*if (argc != 2) {
		printf("Uso correcto: %s fichero\n",argv[0]);
		exit(1);
	}
	
	
	FILE *fich = fopen(argv[1],"r");
	if (fich == 0) {
		printf("No se puede abrir %s\n",argv[1]);
		exit(1);
	}*/
	
	int i;
    	char nombre[80];
    	printf("INTRODUCE NOMBRE DE FICHERO FUENTE:");
   	fgets(nombre,80,stdin);
    	nombre[strlen(nombre)-1] = 0;
    	printf("Nombre fichero de entrada: %s\n",nombre);
	printf("Nombre fichero de salida: salida.s \n");
    	if ((fich=fopen(nombre,"r"))==NULL) {
        	printf("***ERROR, no puedo abrir el fichero\n");
		perror("Error leyendo:");
        	exit(1);		
    	}
	yyin = fich;
	yyout = fopen("./salida.s","w");
	yyparse();
	fclose(fich);
}
