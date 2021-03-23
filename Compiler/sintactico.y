%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "listaSimbolos.h"
#include "listaCodigo.h"
extern FILE * yyout;
int contCadenas=1;
int contEtiquetas=1;
Tipo tipoId;
Lista l;
extern int yylineno;
extern int yylex();
void yyerror();
char* generarEtiqueta();
char* nuevoRegistro();
void anadeEntradaCadena(char* s1);
void marcarRegistroLibre(char* reg);
char* concatenaCadenas(char* s1, char* s2);
void anadeEntradaVar(char *valor, Tipo tipoId);
int perteneceTablaS(char* valor);
int esConstante(char *valor);
void imprimirListaC(ListaC lista);
void imprimirTablaS();
void imprimirTablaSCadenas(PosicionLista p,int contador);
int registros[10]={0}; // array para registros
%}
%union {char* cadena; ListaC codigo;} 
%token  LPAREN RPAREN LLLAVE RLLAVE VAR CONST SEMICOLON
        COMMA ASSIGNOP ELSE IF WHILE FUNC PRINT READ DO
%token <cadena>STRING INT ID 
%type  <codigo> expression statement statements_list print_list print_item read_list declarations identifier_list asig
%expect 1 // para que bison omita el warning de d/r
%left MINUSOP PLUSOP
%left MULTOP DIVOP
%left UMINUS // Mayor precedencia al "menos" unario

%%
program :{l=creaLS();} FUNC ID LPAREN RPAREN LLLAVE declarations statements_list RLLAVE 
   		{

		fprintf(yyout,"###############\n");
    		fprintf(yyout,"# Seccion de datos\n");
    		fprintf(yyout,"    .data\n");
		imprimirTablaSCadenas(inicioLS(l),contCadenas);
		imprimirTablaS();
		fprintf(yyout,"\n");
		fprintf(yyout,"###################\n");
		fprintf(yyout,"# Seccion de codigo\n");
		fprintf(yyout,"   .text\n");
		fprintf(yyout,"   .globl main\n");
		fprintf(yyout,"main:\n");
		imprimirListaC($7);
		imprimirListaC($8);

		fprintf(yyout,"\n");
		fprintf(yyout,"################\n");
		fprintf(yyout,"# Fin\n");
		fprintf(yyout,"    li $v0, 10\n");
		fprintf(yyout,"    syscall\n");





		liberaLS(l);}
;
  
declarations : declarations VAR {tipoId=VARIABLE;} identifier_list SEMICOLON{$$=$1; concatenaLC($$, $4); liberaLC($4);} 
            | declarations CONST {tipoId=CONSTANTE;} identifier_list SEMICOLON{$$=$1; concatenaLC($$, $4); liberaLC($4);}
	| declarations VAR error SEMICOLON {$$ = creaLC();} 
	| declarations CONST error SEMICOLON {$$ = creaLC();} 
            |	{$$=creaLC();}
	
            ;

identifier_list : asig {$$=$1;}
                | identifier_list COMMA asig{$$=$1;concatenaLC($$, $3); liberaLC($3);}
		
                ;

asig : ID {$$= creaLC();
if (!(perteneceTablaS($1))) {anadeEntradaVar($1,tipoId);}
 				else {printf("Error, Variable %s ya declarada \n",$1);}}
    | ID ASSIGNOP expression {
				$$=creaLC();	
			if (!(perteneceTablaS($1))) { 
				anadeEntradaVar($1,tipoId);
				concatenaLC($$,$3);
				char * arg1 = concatenaCadenas("_",$1);
				Operacion operacion = {"sw",recuperaResLC($3),arg1,NULL};
				insertaLC($$, finalLC($$), operacion);

				marcarRegistroLibre(operacion.res);
				liberaLC($3);
				
}
 
    									else {printf("Error, Variable %s ya declarada \n",$1);}}
     
	;

statements_list : statements_list statement {$$=$1; concatenaLC($1, $2); liberaLC($2); }
        | {$$=creaLC();}
	
        ;

statement : ID ASSIGNOP expression SEMICOLON {

		$$=creaLC();
		if (!(perteneceTablaS($1))) {printf("Error, Variable %s no declarada \n",$1);} 
		else if (esConstante($1)) {printf("Error, Asignacion a constante %s\n", $1);}
			else{
				concatenaLC($$,$3);
    			char * arg1 = concatenaCadenas("_",$1);
				Operacion operacion = {"sw",recuperaResLC($3),arg1,NULL};
    			insertaLC($$, finalLC($$), operacion);
    			marcarRegistroLibre(operacion.res);
    			liberaLC($3);
			
				
			}}
		 
        | LLLAVE statements_list RLLAVE { $$=$2;}
        | IF LPAREN expression RPAREN statement ELSE statement{
		$$=$3;
		
			Operacion operacion = {"beqz",recuperaResLC($3),generarEtiqueta(),NULL};
    		insertaLC($$, finalLC($$), operacion);
			marcarRegistroLibre(operacion.res);
			concatenaLC($$, $5);
  		
    
    
    		char* etiqueta1= operacion.arg1;
    
    		operacion.op= "b";
    		operacion.res=generarEtiqueta();
    		operacion.arg1=NULL;
    		operacion.arg2=NULL;
    		insertaLC($$, finalLC($$), operacion);

		
    		char* etiqueta2= operacion.res;
    
    		operacion.op = "\r"; 
    		operacion.res= concatenaCadenas(etiqueta1,":");
   		operacion.arg1= NULL;
    		operacion.arg2=NULL;
    		insertaLC($$, finalLC($$), operacion);
    
    		concatenaLC($$, $7);
    
    		operacion.op = "\r";
    		operacion.res= concatenaCadenas(etiqueta2,":");
   		operacion.arg1= NULL;
    		operacion.arg2=NULL;
    		insertaLC($$, finalLC($$), operacion);
    		liberaLC($5);
    		liberaLC($7);	






	}
        | IF LPAREN expression RPAREN statement{

		$$=$3;
		
		Operacion operacion = {"beqz",recuperaResLC($3),generarEtiqueta(),NULL};
    		insertaLC($$, finalLC($$), operacion);
		marcarRegistroLibre(operacion.res);
		concatenaLC($$, $5);
		
		char* etiqueta = operacion.arg1;
		operacion.op= "\r";
    		operacion.res= concatenaCadenas(etiqueta,":");
    		operacion.arg1=NULL;
    		operacion.arg2=NULL;
		insertaLC($$, finalLC($$), operacion);		
		liberaLC($5);
    		
		
		
	}

	| DO statement WHILE LPAREN expression RPAREN{


	$$=creaLC();
	
	char* etiq1= generarEtiqueta();
   	 Operacion operacion;
    	operacion.op="\r";
    	operacion.res=concatenaCadenas(etiq1,":");
    	operacion.arg1=NULL;
    	operacion.arg2=NULL;
    	insertaLC($$, finalLC($$), operacion);
	concatenaLC($$,$2);
	concatenaLC($$,$5);

	operacion.op = "bnez";
    	operacion.res= recuperaResLC($5);
    	operacion.arg1= etiq1;
    	operacion.arg2=NULL;
    	insertaLC($$, finalLC($$), operacion);        
    	
	
	marcarRegistroLibre(operacion.res);
    	liberaLC($2);
    	liberaLC($5);
}


        | WHILE LPAREN expression RPAREN statement {
	
	$$= creaLC();
    
	 char* etiq1= generarEtiqueta();
    Operacion operacion;
    operacion.op="\r";
    operacion.res=concatenaCadenas(etiq1,":");
    operacion.arg1=NULL;
    operacion.arg2=NULL;
    insertaLC($$, finalLC($$), operacion);
   
    
    concatenaLC($$,$3);
    
    operacion.op = "beqz";
    operacion.res= recuperaResLC($3);
    operacion.arg1=generarEtiqueta();
    operacion.arg2=NULL;
    insertaLC($$, finalLC($$), operacion);        
    marcarRegistroLibre(operacion.res);

    concatenaLC($$, $5);
    char* etiq2= operacion.arg1;
    
    operacion.op= "b";

    operacion.res=etiq1;
    operacion.arg1=NULL;
    operacion.arg2=NULL;
    insertaLC($$, finalLC($$), operacion);
    
    operacion.op="\r";
    operacion.res= concatenaCadenas(etiq2,":");
    operacion.arg1=NULL;
    operacion.arg2=NULL;
    insertaLC($$, finalLC($$), operacion);
    liberaLC($3);
    liberaLC($5);}


        | PRINT print_list SEMICOLON {$$ = $2;}
        | READ read_list SEMICOLON{$$= $2;}
	| error SEMICOLON {$$ = creaLC();}      
	;

print_list : print_item {$$=$1;}
            | print_list COMMA print_item{$$=$1; concatenaLC($$, $3); liberaLC($3);
} 
            ;

print_item : expression {
		$$=$1;
    		Operacion operacion = {"move","$a0",recuperaResLC($1),NULL};
    		insertaLC($$, finalLC($$), operacion);
    		guardaResLC($$, operacion.res);
    		
    		operacion.op="li";
    		operacion.res= "$v0";
    		operacion.arg1= "1";
    		operacion.arg2= NULL;
    		insertaLC($$, finalLC($$), operacion);
    		guardaResLC($$, operacion.res);
    
    		operacion.op="syscall";
    		operacion.res=NULL;
    		operacion.arg1=NULL;
    		operacion.arg2=NULL;
    		insertaLC($$, finalLC($$), operacion);



	}
            | STRING {	
			$$=creaLC();
			anadeEntradaCadena($1);
			contCadenas++;		
			
			Simbolo s = recuperaLS(l,inicioLS(l));
    		char arr[32] = "";
			sprintf(arr, "%d", s.valor);
    		
    		Operacion operacion = {"la","$a0",concatenaCadenas("$str",arr),NULL};
    		insertaLC($$, finalLC($$), operacion);
    		guardaResLC($$, operacion.res);
    
   
   	 	operacion.op="li";
    		operacion.res= "$v0";
    		operacion.arg1= "4";
    		operacion.arg2= NULL;
    		insertaLC($$, finalLC($$), operacion);
    		guardaResLC($$, operacion.res); 
    
    		operacion.op="syscall";
    		operacion.res=NULL;
    		operacion.arg1=NULL;
    		operacion.arg2=NULL;
    		insertaLC($$, finalLC($$), operacion);	
	}
		
            ;

read_list : ID {
		if (!(perteneceTablaS($1))){$$=creaLC();printf("Error, Variable %s no declarada \n",$1);} 
		else{
                     if (esConstante($1)) {$$=creaLC();printf("Error, Asignacion a constante %s\n", $1);}
		     else{


			$$=creaLC();
    			Operacion operacion = {"li","$v0","5",NULL};
    			insertaLC($$, finalLC($$), operacion);
    			guardaResLC($$, operacion.res);
    
    			operacion.op="syscall";
    			operacion.res=NULL;
    			operacion.arg1=NULL;
    			operacion.arg2=NULL;
    			insertaLC($$, finalLC($$), operacion);
    
    			operacion.op="sw";
    			operacion.res= "$v0";
			char* arg1 = concatenaCadenas("_",$1);
    			operacion.arg1= arg1;
    			operacion.arg2= NULL;
   			insertaLC($$, finalLC($$), operacion);
    			guardaResLC($$, operacion.res);

			
		}

		}}
            | read_list COMMA ID {if (!(perteneceTablaS($3))){printf("Error, Variable %s no declarada \n",$3);}
		else{
                     if (esConstante($3)) {printf("Error, Asignacion a constante %s\n", $3);}
		     else{


				$$=$1;
    			Operacion operacion = {"li","$v0","5",NULL};
    			insertaLC($$, finalLC($$), operacion);
    			guardaResLC($$, operacion.res);
    
    			operacion.op="syscall";
    			operacion.res=NULL;
    			operacion.arg1=NULL;
    			operacion.arg2=NULL;
    			insertaLC($$, finalLC($$), operacion);
    
    			operacion.op="sw";
    			operacion.res= "$v0";
				char* arg1 = concatenaCadenas("_",$3);
    			operacion.arg1= arg1;
    			operacion.arg2= NULL;
   				insertaLC($$, finalLC($$), operacion);
    			guardaResLC($$, operacion.res);
			

		}

		}}

            ;
expression : expression PLUSOP expression{

    	$$=creaLC();
    	concatenaLC($$, $1);
    	concatenaLC($$, $3);
    	Operacion operacion = {"add",nuevoRegistro(),recuperaResLC($1),recuperaResLC($3)};

    	insertaLC($$, finalLC($$), operacion);
    	guardaResLC($$, operacion.res);
    	marcarRegistroLibre(operacion.arg1);
    	marcarRegistroLibre(operacion.arg2);
    	liberaLC($1);  
    	liberaLC($3);    
}
        | expression MINUSOP expression {
	
	$$=creaLC();
    	concatenaLC($$, $1);
    	concatenaLC($$, $3);
    	Operacion operacion = {"sub",nuevoRegistro(),recuperaResLC($1),recuperaResLC($3)};

    	insertaLC($$, finalLC($$), operacion);
    	guardaResLC($$, operacion.res);
    	marcarRegistroLibre(operacion.arg1);
    	marcarRegistroLibre(operacion.arg2);
    	liberaLC($1);  
    	liberaLC($3);    
		



}
        | expression MULTOP expression{
	

	$$=creaLC();
    	concatenaLC($$, $1);
	concatenaLC($$, $3);
    	Operacion operacion = {"mul",nuevoRegistro(),recuperaResLC($1),recuperaResLC($3)};

    	insertaLC($$, finalLC($$), operacion);
    	guardaResLC($$, operacion.res);
    	marcarRegistroLibre(operacion.arg1);
    	marcarRegistroLibre(operacion.arg2);
    	liberaLC($1);  
    	liberaLC($3);    


}
        | expression DIVOP expression{


		$$=creaLC();
    	concatenaLC($$, $1);
		concatenaLC($$, $3);
    	Operacion operacion = {"div",nuevoRegistro(),recuperaResLC($1),recuperaResLC($3)};

    	insertaLC($$, finalLC($$), operacion);
    	guardaResLC($$, operacion.res);
    	marcarRegistroLibre(operacion.arg1);
    	marcarRegistroLibre(operacion.arg2);
    	liberaLC($1);  
    	liberaLC($3); 


}
        | MINUSOP expression %prec UMINUS{

		$$=creaLC();
    	concatenaLC($$, $2);
    	Operacion operacion = {"neg",nuevoRegistro(),recuperaResLC($2),NULL};

    	insertaLC($$, finalLC($$), operacion);
    	guardaResLC($$, operacion.res);
    	marcarRegistroLibre(operacion.arg1);
    	liberaLC($2); 
}
        | LPAREN expression RPAREN {$$= $2;}
        | ID {
	$$=creaLC();
	if (!(perteneceTablaS($1))){ printf("Error, Variable %s no declarada \n",$1);}
	
		
		
		char* arg1 = concatenaCadenas("_",$1);
    	Operacion operacion = {"lw",nuevoRegistro(),arg1,NULL};

    	insertaLC($$, finalLC($$), operacion);
    	guardaResLC($$, operacion.res);
    	




}
        | INT {
	
		$$=creaLC();
    	Operacion operacion = {"li",nuevoRegistro(),$1,NULL};

    	insertaLC($$, finalLC($$), operacion);
    	guardaResLC($$, operacion.res);
    	
	

}
        ;

%%

char* generarEtiqueta(){
    char etiq[12]; 
    sprintf(etiq, "$et%d", contEtiquetas++);
    return strdup(etiq);
}

char* nuevoRegistro(){

	int i = 0;
	while(i<10 && registros[i]!=0){
		i++;
	}
	
	if(i != 10){
		registros[i] = 1;
		char registro[4];
		sprintf(registro,"$t%d",i);
		return strdup(registro);


	}else{
		printf("Error fatal, no hay registros libres\n");
    		exit(1);	
	}


}

void anadeEntradaCadena(char* s1){
	Simbolo s = {s1,CADENA,contCadenas};
	insertaLS(l,inicioLS(l),s); 


}
void marcarRegistroLibre(char * reg){
	//Marcamos el registro $tx como libre
	registros[reg[2]-'0'] = 0;

}
char* concatenaCadenas(char* s1, char* s2){
	 
    const size_t len1 = strlen(s1);
    const size_t len2 = strlen(s2);
    char *resultado = malloc(len1 + len2 + 1); // +1 por el null del final

    memcpy(resultado, s1, len1);	//copiamos a s1 el string sin el null
    memcpy(resultado + len1, s2, len2 + 1); //  a partir de lo copiado copiamos s2 en res.+1 para copiar el null del final
    return resultado;
}

void anadeEntradaVar(char *valor, Tipo tipoId){

	
	
	Simbolo s = {strdup(valor),tipoId,0};
	insertaLS(l, finalLS(l), s);


}
int perteneceTablaS(char* valor){
	
	return buscaLS(l,valor) != finalLS(l);
}

int esConstante(char *valor){
	Simbolo tmp = recuperaLS(l,buscaLS(l,valor));
	return tmp.tipo == CONSTANTE;
}

void imprimirListaC(ListaC lista){
  Operacion operacion;
  PosicionListaC p = inicioLC(lista);
  while(p != finalLC(lista)) {
    operacion = recuperaLC(lista,p);
    fprintf(yyout,"    %s",operacion.op);
    if (operacion.res) fprintf(yyout," %s",operacion.res);
    if (operacion.arg1) fprintf(yyout,",%s",operacion.arg1);
    if (operacion.arg2) fprintf(yyout,",%s",operacion.arg2);
    fprintf(yyout,"\n");
    p = siguienteLC(lista,p);
  }
}


void imprimirTablaSCadenas(PosicionLista p,int contador){
	if(contador == 1){
		return;
	}
	imprimirTablaSCadenas(siguienteLS(l,p),contador-1);
	Simbolo s= recuperaLS(l, p);
	fprintf(yyout,"$str%d:\n", s.valor);
    	fprintf(yyout,"    .asciiz  %s\n", s.nombre);


}

void imprimirTablaS(){
    PosicionLista p= inicioLS(l);
    while(p!= finalLS(l)){
    	Simbolo s= recuperaLS(l, p); 
    	if(s.tipo == CONSTANTE || s.tipo == VARIABLE){
     		fprintf(yyout,"_%s : \n .word 0\n", s.nombre);
		}
    
   		 p= siguienteLS(l,p);
    }
}

void yyerror(){
	    
	printf("Error sintactico en linea %d \n",yylineno);
}
