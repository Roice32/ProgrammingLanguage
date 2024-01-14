%{
#include <iostream>
#include <vector>
#include <string>
#include "Code.h"

extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();

void yyerror(const char* s);

class IDList ids;
%}

%union {
     char* id;
     char* rawValue;
     char varType;
}

%token BGIN END ASSIGN
%token <id> ID
%type <varType> TYPE
%token <varType> INT FLOAT CHAR STRING BOOL
%type <rawValue> VALUE
%token <rawValue> INT_VAL FLOAT_VAL CHAR_VAL STRING_VAL BOOL_VAL
%start progr

%%
progr: declarations block    { printf("\tThe program is correct!\n"); }
     ;

declarations: decl ';'          
	       | declarations decl ';'   
	       ;

TYPE: INT    { $$ = $1; }
    | FLOAT    { $$ = $1; }
    | CHAR    { $$ = $1; }
    | STRING    { $$ = $1; }
    | BOOL    { $$ = $1; }
    ;


decl: TYPE ID    { if(!ids.existsVar($2))
                       ids.addVar($2,$1);
                 }
    | TYPE ID ASSIGN VALUE    { if(!ids.existsVar($2)) // TO DO: MAKE SURE TYPEOF(VALUE) = TYPE
                                {
                                    ids.addVar($2,$1);
                                    ids.setValue($2,$4);
                                }
                              }
    | TYPE ID '(' list_param ')'  
    | TYPE ID '(' ')'  
    ;

list_param: param
          | list_param ',' param 
          ;
            
param: TYPE ID 
     ; 
      

block: BGIN list END  
     ;
     

list: statement ';' 
    | list statement ';'
    ;

statement: ID ASSIGN ID
         | ID ASSIGN VALUE    {;} // TO DO
         | ID '(' call_list ')'
         ;

VALUE: INT_VAL    { $$ = $1; }
     | CHAR_VAL    { $$ = $1; }
     | FLOAT_VAL    { $$ = $1; }
     | STRING_VAL    { $$ = $1; }
     | BOOL_VAL    { $$ = $1; }
     ;

call_list: INT_VAL
         | call_list ',' INT_VAL
         ;
%%

void yyerror(const char * s)
{ printf("Error: \"%s\"\n\tAt line: %d.\n",s,yylineno); }

int main(int argc, char** argv)
{
     yyin = fopen(argv[1],"r");
     yyparse();
     cout << "Variables:" << endl;
     ids.printVars();    
} 