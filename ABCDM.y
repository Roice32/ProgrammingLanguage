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

char errmsg[128];
class IDList ids;
class CustomTypesList cts;
%}

%union {
     char* id;
     char* rawValue;
     char varType;
     class IDList* carryOver; // Might rename later on.
}

%token BGIN END ASSIGN
%token <id> ID
%type <varType> TYPE
%token <varType> INT FLOAT CHAR STRING BOOL
%token CUSTOM
%type <carryOver> CONTENTS
%type <rawValue> VALUE
%token <rawValue> INT_VAL FLOAT_VAL CHAR_VAL STRING_VAL BOOL_VAL
%start progr

%%
progr: userDefined declarations block    { printf("\tThe program is correct!\n"); } // TO DO: MAKE SURE THIS F-ER DOESN'T PRINT WHEN ERRORS
     ;

// TO DO: INITIALIZED VALS, ARRAYS, METHODS (BASICALLY COPY FROM DECL WHEN IT'S DONE)
userDefined: CUSTOM ID '{' CONTENTS '}' ';'    { if(!cts.existsCustom($2))
                                                     cts.addCustom($2, *$4);
                                                 else
                                                 {
                                                     sprintf(errmsg, "Custom type '%s' already declared.", $2);
                                                     yyerror(errmsg);
                                                 }
                                                 delete $4;
                                               }
           | userDefined CUSTOM ID '{' CONTENTS '}' ';'    { if(!cts.existsCustom($3))
                                                                 cts.addCustom($3, *$5);
                                                             else
                                                             {
                                                                 sprintf(errmsg, "Custom type '%s' already declared.", $3);
                                                                 yyerror(errmsg);
                                                             }
                                                            delete $5;
                                                            }
           ;

// TO DO: ALSO LET IT CONTAIN METHODS
CONTENTS: TYPE ID ';'    { $$ = new IDList;  // I AIN'T DEALING WITH NO EMPTY CLASSES
                           $$->addVar($2, $1);
                         }
        | CONTENTS TYPE ID ';'    { $$ = $1;
                                    if(!$$->existsVar($3))
                                        $$->addVar($3, $2);
                                    else
                                    {
                                        sprintf(errmsg, "Field '%s' already declared.", $3);
                                        yyerror(errmsg);
                                    }
                                  }
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
                   else
                   {
                       sprintf(errmsg, "Variable '%s' already declared.", $2);
                       yyerror(errmsg);
                   }
                 }
    | TYPE ID ASSIGN VALUE    { if(!ids.existsVar($2)) // TO DO: MAKE SURE TYPEOF(VALUE) = TYPE
                                {
                                    ids.addVar($2,$1);
                                    ids.setValue($2,$4);
                                }
                                else
                                {
                                    sprintf(errmsg, "Variable '%s' already declared.", $2);
                                    yyerror(errmsg);
                                }
                              }
    | TYPE ID '[' INT_VAL ']'    { if(!ids.existsVar($2)) // TO DO: MAKE IT TAKE EXPRESSIONS
                                   {
                                        int size;
                                        sscanf($4, "%d", &size);
                                        if(size>0)
                                             ids.addArrayVar($2, $1, size);
                                        else
                                             yyerror("Size of array must be positive integer.");
                                   }
                                   else
                                   {
                                        sprintf(errmsg, "Variable '%s' already declared.", $2);
                                        yyerror(errmsg);
                                   }
                                 }
    // TO DO: ALSO LET ARRAYS BE INITIALIZED
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

call_list: INT_VAL // SHOULD ONLY THIS BE HERE?
         | call_list ',' INT_VAL
         ;
%%

void yyerror(const char* s)
{ printf("Error: \"%s\"\n\tAt line: %d.\n",s,yylineno); }

int main(int argc, char** argv)
{
     yyin = fopen(argv[1],"r");
     yyparse();
     cout << "Variables:" << endl;
     ids.printVars();
     cts.printCustoms();
}
// TO DO OVERALL: CONST/VAR
//              | METHODS. FUNCTIONS