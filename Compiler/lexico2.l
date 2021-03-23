%{
#include "listaCodigo.h"
#include "sintactico.tab.h"
#include <math.h>
#include <string.h>
void overflow_checker();
void id_length_checker();
%}
entero              [0-9]+
cadena              \"([^"\n]|\\\")*\"
%option yylineno


%%

\"([^"\n]|\\\")*                                     printf("ERROR : Cadena sin cerrar en linea %d \n",yylineno);

"/*"([^*]|[*]+[^*/])*           printf("ERROR : Comentario sin cerrar en linea %d \n",yylineno);	

"/*"([^*]|[*]+[^*/])*[*]+"/"		        ;


[ \n\t\r]+                                    ;
"//"(.*)[\n]                                ;


"func"                                      return FUNC;
"const"                                     return CONST;
"var"                                       return VAR;
"if"                                        return IF;
"else"                                      return ELSE;
"do"					    return DO;
"while"                                     return WHILE;
"read"                                      return READ;
"print"                                     return PRINT;
[a-zA-Z_][a-zA-Z_0-9]*  {id_length_checker(); yylval.cadena = strdup(yytext);return ID;}
{entero}              {overflow_checker(); yylval.cadena = strdup(yytext); return INT;}
{cadena}                                    {yylval.cadena = strdup(yytext);return STRING;}
"("                                         return LPAREN;		
")"                                         return RPAREN;
";"                                         return SEMICOLON;
","                                         return COMMA;
"="                                         return ASSIGNOP;
"+"                                         return PLUSOP;
"*"                                         return MULTOP;
"/"                                         return DIVOP;
"-"                                         return MINUSOP;
"{"                                         return LLLAVE;
"}"                                         return RLLAVE;


[^ a-zA-Z_0-9();\",=+{}\-/*\n\t\r]+                printf("Error en cadena '%s' en linea %d \n",yytext,yylineno);


%%
void overflow_checker(){
    
    if(atoll(yytext) > pow(2,31)){
        printf("Error : Entero '%s' fuera del rango permitido en linea %d \n",yytext,yylineno);
    }
}

void id_length_checker(){
    
    if(yyleng > 16){
        printf("Error : Identificador '%s' excede los 16 caracteres en linea %d \n",yytext,yylineno);
    }
}
