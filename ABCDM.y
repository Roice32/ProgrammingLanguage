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

char scope[128] = "Global";
class IDList ids;
class CustomTypesList cts;
class FunctionsList fs;
%}

%union {
     char* ID;
     char* typeInfo;
     char* rawValue;
     class IDList* carryOver; // Might rename later on.
}

%token BEGINC ENDC BEGINGV ENDGV BEGINGF ENDGF BEGINP ENDP
%token EVAL TYPEOF
%type <typeInfo> variability
%token <typeInfo> VARIABLE CONSTANT
%type <typeInfo> typeUnion type
%token <typeInfo> INT FLOAT CHAR STRING BOOL
%token <ID> ID
%token CUSTOM ACCESS ASSIGN
%token ADD SUB MUL DIV MOD POW
%token EQ NEQ LEQ GEQ LESS MORE
%token NOT AND OR
%type <carryOver> contents member
%type <rawValue> value
%token <rawValue> INT_VAL FLOAT_VAL CHAR_VAL STRING_VAL BOOL_VAL
%token IF ELSE WHILE FOR DO
%token RETURN
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

userDefined: BEGINC { sprintf(scope, "Custom Types"); } ENDC
           | BEGINC { sprintf(scope, "Custom Types"); } userDefinedTypes ENDC
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

contents: member ';'    /*{ $$ = new IDList;  // I AIN'T DEALING WITH NO EMPTY CLASSES
                           $$->addVar($2, $1); } */
        | contents member ';'    /*{ $$ = $1;
                                    if(!$$->existsVar($3))
                                        $$->addVar($3, $2);
                                    else
                                    {
                                        sprintf(errmsg, "Field '%s' already declared.", $3);
                                        yyerror(errmsg);
                                    } }*/
        ;

// TO DO: ALSO LET IT BE A METHOD
member: varDecl
      ;

globalVariables: BEGINGV { sprintf(scope, "Global Variables"); } ENDGV
               | BEGINGV { sprintf(scope, "Global Variables"); } varDeclarations ENDGV
               ;

varDeclarations: varDecl ';'          
	          | varDeclarations varDecl ';'   
	          ;

// TO DO: CHECK TYPE COMPATIBILITY WHERE NEEDED
//      | CHECK SCOPE WHEN ASSIGNING
varDecl : variability typeUnion ID    { if(!ids.existsVar($3))
                                       {
                                           if($1[0]=='c')
                                           {
                                             sprintf(errmsg, "Constant identifier '%s' must be initalized.", $3);
                                             yyerror(errmsg);
                                           }
                                           else if(isPlainType($2))
                                                  ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                           else if(cts.existsCustom($2))
                                               ;//ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, &cts); TO DO: IMPLEMENT DEFAULT FOR THIS
                                           else
                                           {
                                               sprintf(errmsg, "Custom type '%s' not declared.", $2);
                                               yyerror(errmsg);
                                           }
                                       }
                                       else
                                       {
                                           sprintf(errmsg, "Redeclaration of identifier '%s'.", $2);
                                           yyerror(errmsg);
                                       } }
       | variability typeUnion ID ASSIGN value    { if(!ids.existsVar($3))
                                                    {
                                                        if(isPlainType($2))
                                                        {
                                                            ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                                            ids.setValue($3, $5);
                                                        }
                                                        else if(cts.existsCustom($2))
                                                        {
                                                            ;//ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, &cts); TO DO: IMPLEMENT DEFAULT FOR THIS
                                                            ;//setFields
                                                        }
                                                        else
                                                        {
                                                            sprintf(errmsg, "Custom type '%s' not declared.", $2);
                                                            yyerror(errmsg);
                                                        }
                                                    }
                                                    else
                                                    {
                                                        sprintf(errmsg, "Redeclaration of identifier '%s'.", $2);
                                                        yyerror(errmsg);
                                                    } }
       | variability typeUnion ID ASSIGN ID    { if(!ids.existsVar($3))
                                                 {
                                                     if(ids.existsVar($5))
                                                     {
                                                         if(isPlainType($2))
                                                         {
                                                             ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                                             ids.copyValue($3, &ids.IDs.at($5));
                                                         }
                                                         else if(cts.existsCustom($2))
                                                         {
                                                             ;//ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, &cts); TO DO: IMPLEMENT DEFAULT FOR THIS
                                                             ;//setFields
                                                             ;// ids.copyValue($3, &ids.IDs.at($5));
                                                         }
                                                         else
                                                         {
                                                             sprintf(errmsg, "Custom type '%s' not declared.", $2);
                                                             yyerror(errmsg);
                                                         }
                                                     }
                                                     else
                                                     {
                                                         sprintf(errmsg, "Use of identifier not declared in this scope: '%s'.", $5);
                                                         yyerror(errmsg);
                                                     }
                                                 }
                                                 else
                                                 {
                                                     sprintf(errmsg, "Redeclaration of identifier '%s'.", $2);
                                                     yyerror(errmsg);
                                                 } }
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

variability: VARIABLE    { $$ = $1; }
           | CONSTANT    { $$ = $1; }
           ;

typeUnion: type    { $$ = $1; }
         | CUSTOM ID    { $$ = $2; }
         ;

initList: initArg
        | initList ',' initArg
        ;

initArg: expr
       ;

globalFunctions: BEGINGF { sprintf(scope, "Global Functions"); } ENDGF
               | BEGINGF { sprintf(scope, "Global Functions"); } funDeclarations ENDGF
               ;

funDeclarations: funDecl
               | funDeclarations funDecl
               ;

funDecl: type ID '(' ')' '{' funBody '}' // NO EMPTY FUNCTION BODIES
       | type ID '(' paramList ')' '{' funBody'}'
       ;

funBody: RETURN expr ';'
       | block RETURN expr ';'
       | block
       ;

paramList: param
         | paramList ',' param 
         ;
            
param: type ID 
     ; 
      
mainProgram: BEGINP { sprintf(scope, "Main Program"); } ENDP
           | BEGINP { sprintf(scope, "Main Program"); } block ENDP
           ;

block: statement ';' 
     | block statement ';'
     ;

statement: varDecl
         | functionCall
         | assignment
         | ID ACCESS functionCall
         | IF '(' expr ')' '{' block '}'
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
//              | NO FUNCTIONS & CLASSES DEFINITIONS IN MAIN
//              | COMMENTS?