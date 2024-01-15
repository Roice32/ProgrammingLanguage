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
int nErr = 0;

class IDList ids;
class CustomTypesList cts;
class FunctionsList fs;
%}

%union {
     char* id;
     char* rawValue;
     char varType;
     class IDList* carryOver; // Might rename later on.
}

%token BEGINC ENDC BEGINGV ENDGV BEGINGF ENDGF BEGINP ENDP
%token EVAL TYPEOF
%token <id> ID
%type <varType> type
%token <varType> INT FLOAT CHAR STRING BOOL
%token CUSTOM ACCESS VARIABLE CONSTANT ASSIGN
%token ADD SUB MUL DIV MOD POW
%token EQ NEQ LEQ GEQ LESS MORE
%token NOT AND OR
//%type <carryOver> contents
%type <rawValue> value
%token <rawValue> INT_VAL FLOAT_VAL CHAR_VAL STRING_VAL BOOL_VAL
%token IF ELSE WHILE FOR DO
%start progr

%left NOT
%left AND OR EQ NEQ LEQ GEQ LESS MORE
%left POW
%left MUL DIV MOD
%left ADD SUB

%%
progr: userDefined globalVariables globalFunctions mainProgram    { if(nErr==0)
                                                                        printf("\tThe program is correct!\n");
                                                                    else
                                                                        printf("\tThe program is not correct: %d errors!\n", nErr); }
     ;

userDefined: BEGINC ENDC
           | BEGINC userDefinedTypes ENDC
           ;

// TO DO: INITIALIZED VALS, ARRAYS, METHODS (BASICALLY COPY FROM DECL WHEN IT'S DONE)
userDefinedTypes: CUSTOM ID '{' contents '}' ';'    /*{ if(!cts.existsCustom($2))
                                                         cts.addCustom($2, *$4);
                                                     else
                                                     {
                                                         sprintf(errmsg, "Custom type '%s' already declared.", $2);
                                                         yyerror(errmsg);
                                                     }
                                                     delete $4; }*/
               | userDefinedTypes CUSTOM ID '{' contents '}' ';'    /*{ if(!cts.existsCustom($3))
                                                                         cts.addCustom($3, *$5);
                                                                     else
                                                                     {
                                                                         sprintf(errmsg, "Custom type '%s' already declared.", $3);
                                                                         yyerror(errmsg);
                                                                     }
                                                                     delete $5; }*/
               ;

// TO DO: ALSO LET IT CONTAIN METHODS
contents: member ';'    /*{ $$ = new IDList;  // I AIN'T DEALING WITH NO EMPTY CLASSES
                           $$->addVar($2, $1); }*/
        | contents member ';'    /*{ $$ = $1;
                                    if(!$$->existsVar($3))
                                        $$->addVar($3, $2);
                                    else
                                    {
                                        sprintf(errmsg, "Field '%s' already declared.", $3);
                                        yyerror(errmsg);
                                    } }*/
        ;

member: varDecl
      | funDecl
      ;

globalVariables: BEGINGV ENDGV
               | BEGINGV varDeclarations ENDGV
               ;

varDeclarations: varDecl ';'          
	          | varDeclarations varDecl ';'   
	          ;

varDecl: variability typeUnion ID    /*{ if(!ids.existsVar($2))
                          ids.addVar($2,$1);
                      else
                      {
                          sprintf(errmsg, "Variable '%s' already declared.", $2);
                          yyerror(errmsg);
                      } }*/
       | variability typeUnion ID ASSIGN value    /*{ if(!ids.existsVar($2)) // TO DO: MAKE SURE TYPEOF(VALUE) = TYPE
                                   {
                                       ids.addVar($2,$1);
                                       ids.setValue($2,$4);
                                   }
                                   else
                                   {
                                       sprintf(errmsg, "Variable '%s' already declared.", $2);
                                       yyerror(errmsg);
                                   } }*/
       | variability typeUnion ID ASSIGN ID 
       | variability typeUnion ID '(' initList ')'
       | variability typeUnion ID '[' expr ']'    /*{ if(!ids.existsVar($2)) // TO DO: MAKE IT TAKE EXPRESSIONS
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
                                      } }*/
       | variability typeUnion ID '[' expr ']' ASSIGN '[' initList ']'
       ;

       /*| CUSTOM ID ID    { if(cts.existsCustom($2))
                               if(!ids.existsVar($3))
                                   ids.addCustomVar($3, $2, &cts);
                               else
                               {
                                   sprintf(errmsg, "Variable '%s' already declared.", $3);
                                   yyerror(errmsg);
                               }
                           else
                           {
                               sprintf(errmsg, "Custom type '%s' not declared.", $2);
                               yyerror(errmsg);
                           } }
       |*/ 

variability: VARIABLE
           | CONSTANT
           ;

typeUnion: type
         | CUSTOM ID
         ;

initList: initArg
        | initList ',' initArg
        ;

initArg: expr
       ;

globalFunctions: BEGINGF ENDGF
               | BEGINGF funDeclarations ENDGF
               ;

funDeclarations: funDecl
               | funDeclarations funDecl
               ;

funDecl: type ID '(' ')' '{' block '}' // NO EMPTY FUNCTION BODIES
       | type ID '(' paramList ')' '{' block '}'
       ;

paramList: param
         | paramList ',' param 
         ;
            
param: type ID 
     ; 
      
mainProgram: BEGINP ENDP
           | BEGINP block ENDP
           ;

block: statement ';' 
     | block statement ';'
     ;

statement: varDecl
         | functionCall
         | assignment
         | ID ACCESS functionCall
         | IF '(' expr ')' '{' block '}' ELSE '{' block '}'
         | WHILE '(' expr ')' '{' block '}'
         | FOR '(' assignment ';' expr ';' assignment ')' DO '{' block '}' // MIGHT NEED MODIFYING
         | EVAL '(' expr ')'
         | TYPEOF '(' expr ')'
         ;
         /*| ID ACCESS ID    { if(ids.existsVar($1)) // HERE ONLY TEMPORARILY; ALSO CHECK CUSTOM-TYPE ONLY
                                 if(ids.IDs.find($1)->second.fields->IDs.find($3) != ids.IDs.find($1)->second.fields->IDs.end())
                                 {
                                     class VarInfo* r = ids.accessCustomField($1, $3); // PLACEHOLDER FOR TESTING
                                     r->printType();
                                     r->printPlainVal();
                                 }
                                 else
                                 {
                                     sprintf(errmsg, "Variable '%s' has no field '%s'.", $1, $3);
                                     yyerror(errmsg);
                                 }
                             else
                             {
                                 sprintf(errmsg, "Variable '%s' not declared.", $1);
                                 yyerror(errmsg);
                             }
                           }*/

assignment: assignable ASSIGN expr
          ;

assignable: ID
          | ID ACCESS ID
          | ID '[' expr ']'
          ;

functionCall: ID '(' ')'
            | ID '(' argList ')'
            ;

argList: expr
       | argList ',' expr
       ;

expr: exprTerm  // HOW TO DISTINGUISH BOOL & ARITHMETIC EXPRESSIONS??
    | '(' expr ')'
    | NOT expr
    | expr EQ expr
    | expr NEQ expr
    | expr LEQ expr
    | expr GEQ expr
    | expr LESS expr
    | expr MORE expr
    | expr ADD expr
    | expr SUB expr
    | expr MUL expr
    | expr DIV expr
    | expr MOD expr
    | expr POW expr
    | expr NOT expr
    | expr AND expr
    | expr OR expr
    ;

exprTerm: value
    | functionCall
    | ID
    | ID ACCESS ID
    | ID ACCESS functionCall
    ;

type: INT    { $$ = $1; }
    | FLOAT    { $$ = $1; }
    | CHAR    { $$ = $1; }
    | STRING    { $$ = $1; }
    | BOOL    { $$ = $1; }
    ;

value: INT_VAL    { $$ = $1; }
     | CHAR_VAL    { $$ = $1; }
     | FLOAT_VAL    { $$ = $1; }
     | STRING_VAL    { $$ = $1; }
     | BOOL_VAL    { $$ = $1; }
     ;



%%

void yyerror(const char* s)
{ printf("Error: \"%s\"\n\tAt line: %d.\n",s,yylineno); ++nErr; }

int main(int argc, char** argv)
{
     yyin = fopen(argv[1],"r");
     yyparse();
     cout << "Variables:" << endl;
     ids.printVars();
     cts.printCustoms();
}
// TO DO OVERALL: CONST & VAR
//              | METHODS & FUNCTIONS
//              | EVAL & TYPEOF