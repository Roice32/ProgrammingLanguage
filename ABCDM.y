%{
#include <iostream>
#include <vector>
#include "IDList.h"
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();
void yyerror(const char * s);
class IDList ids;
%}
%union {
     char* string;
     char chr;
}
%token  BGIN END ASSIGN NR CHAR
%token<string> ID TYPE
%start progr
%%
progr: declarations block {printf("The programme is correct!\n");}
     ;

declarations :  decl ';'          
	      |  declarations decl ';'   
	      ;

decl       :  TYPE ID { if(!ids.existsVar($2)) {
                          ids.addVar($2,$1);
                     }
                    }
           | TYPE ID '(' list_param ')'  
           | TYPE ID '(' ')' 
     
           ;

list_param : param
            | list_param ','  param 
            ;
            
param : TYPE ID 
      ; 
      

block : BGIN list END  
     ;
     

list :  statement ';' 
     | list statement ';'
     ;

statement: ID ASSIGN ID
         | ID ASSIGN value
         | ID '(' call_list ')'
         ;

value: NR
    | CHAR
    ;

call_list : NR
           | call_list ',' NR
           ;
%%
void yyerror(const char * s){
printf("error: %s at line:%d\n",s,yylineno);
}

int main(int argc, char** argv){
     yyin=fopen(argv[1],"r");
     yyparse();
     cout << "Variables:" <<endl;
     ids.printVars();
    
} 