%{
#include <string.h>
#include "Code.h"

extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();

void yyerror(const char* s);

char errmsg[128];
int nErr = 0;

char scope[256];
char prevScope[256];
class IDList ids;
//class CustomTypesList cts;
class FunctionsList fs;
%}

%union {
     char* ID;
     char* typeInfo;
     char* rawValue;
     class IDList* fieldsList;
     class ASTNode* exprAST;
}

%token BEGINC ENDC BEGINGV ENDGV BEGINGF ENDGF BEGINP ENDP
%token EVAL TYPEOF
%type <typeInfo> variability
%token <typeInfo> VARIABLE CONSTANT
%type <typeInfo> typeUnion type
%token <typeInfo> INT FLOAT CHAR STRING BOOL
%type <ID> varDecl member
%token <ID> ID
%token CUSTOM ACCESS ASSIGN
%token ADD SUB MUL DIV MOD POW
%token EQ NEQ LEQ GEQ LESS MORE
%token NOT AND OR
%type <fieldsList> contents
%type <rawValue> value
%token <rawValue> INT_VAL FLOAT_VAL CHAR_VAL STRING_VAL BOOL_VAL
%type <exprAST> expr
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

userDefined: BEGINC { strcpy(scope, "Custom Types"); } ENDC
           //| BEGINC { strcpy(scope, "Custom Types"); } userDefinedTypes ENDC
           ;

// IF VARDECL WORK PROPERLY, THIS SHOULD BE DONE
userDefinedTypes: CUSTOM ID { strcpy(prevScope, scope);
                              snprintf(scope, 256, "%s > %s", prevScope, $2); } '{' contents '}' ';'    { if(!cts.existsCustom($2))
                                                                                                              cts.addCustom($2, $5);
                                                                                                          else
                                                                                                          {
                                                                                                              sprintf(errmsg, "Custom-type '%s' already declared.", $2);
                                                                                                              yyerror(errmsg);
                                                                                                          } 
                                                                                                          strcpy(scope, prevScope); }
                | userDefinedTypes CUSTOM ID { strcpy(prevScope, scope);
                                               snprintf(scope, 256, "%s > %s", prevScope, $3); } '{' contents '}' ';'    { if(!cts.existsCustom($3))
                                                                                                                               cts.addCustom($3, $6);
                                                                                                                           else
                                                                                                                           {
                                                                                                                               sprintf(errmsg, "Custom-type '%s' already declared.", $3);
                                                                                                                               yyerror(errmsg);
                                                                                                                           }
                                                                                                                           strcpy(scope, prevScope); }
               ;

contents: member ';'    { $$ = new class IDList;
                          if(strlen($1)>0)
                          {
                              $$->IDs.insert({$1, ids.IDs.at($1)});
                              ids.IDs.erase($1);
                          } } 
        | contents member ';'    { $$ = $1;
                                   if(strlen($2)>0)
                                       if(!$$->existsVar($2))
                                       {
                                           $$->IDs.insert({$2, ids.IDs.at($2)});
                                           ids.IDs.erase($2);
                                       }
                                       else
                                       {
                                           sprintf(errmsg, "Field '%s' already declared.", $2);
                                           yyerror(errmsg);
                                       } }
        ;

// TO DO: ALSO LET IT BE A METHOD
member: varDecl    { $$ = $1; }
      ;

globalVariables: BEGINGV { sprintf(scope, "Global Variables"); } ENDGV
               | BEGINGV { sprintf(scope, "Global Variables"); } varDeclarations ENDGV
               ;

varDeclarations: varDecl ';'          
	          | varDeclarations varDecl ';'   
	          ;

// TO DO: CHECK TYPE COMPATIBILITY WHERE NEEDED
//      | CHECK SCOPE WHEN ASSIGNING
varDecl : variability typeUnion ID    { $$ = strdup("");
                                        if(!ids.existsVar($3))
                                        {
                                            if($1[0]=='c')
                                            { sprintf(errmsg, "Constant identifier '%s' must be initalized.", $3);
                                              yyerror(errmsg); }
                                            else if(isPlainType($2))
                                            {
                                                ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                                $$ = strdup($3);
                                            }
                                            else if(/*cts.existsCustom($2)*/false)
                                            {
                                                ;//ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, &cts); TO DO: IMPLEMENT DEFAULT FOR THIS
                                                ;//$$ = stdup($3);
                                            }
                                            else
                                            { sprintf(errmsg, "Custom-type '%s' not declared.", $2);
                                              yyerror(errmsg); }
                                        }
                                        else
                                        { sprintf(errmsg, "Redeclaration of identifier '%s'.", $2);
                                          yyerror(errmsg); } }
       | variability typeUnion ID ASSIGN value    { $$ = strdup("");
                                                    if(!ids.existsVar($3))
                                                    {
                                                        if(isPlainType($2))
                                                        {
                                                            ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                                            ids.setValue($3, $5); // CHECK TYPEOF== FIRST
                                                            $$ = strdup($3);
                                                        }
                                                        else
                                                        { sprintf(errmsg, "Custom variable '%s' cannnot be initialized with plain value.", $3);
                                                          yyerror(errmsg); }
                                                    }
                                                    else
                                                    { sprintf(errmsg, "Redeclaration of identifier '%s'.", $2);
                                                      yyerror(errmsg); } }
       | variability typeUnion ID ASSIGN ID    { $$ = strdup("");
                                                 if(!ids.existsVar($3))
                                                 {
                                                     if(ids.existsVar($5))
                                                     {
                                                         if(isPlainType($2))
                                                         {
                                                             ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                                             ids.copyValue($3, &ids.IDs.at($5));
                                                             $$ = strdup($3);
                                                         }
                                                         else if(/*cts.existsCustom($2)*/false)
                                                         {
                                                             ;//ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, scope, &cts); TO DO: IMPLEMENT DEFAULT FOR THIS
                                                             ;//setFields
                                                             ;// ids.copyValue($3, &ids.IDs.at($5));
                                                             ;//$$ = strdup($3);
                                                         }
                                                         else
                                                         { sprintf(errmsg, "Custom-type '%s' not declared.", $2);
                                                           yyerror(errmsg); }
                                                     }
                                                     else
                                                     { sprintf(errmsg, "Use of identifier not declared in this scope: '%s'.", $5);
                                                       yyerror(errmsg); }
                                                 }
                                                 else
                                                 { sprintf(errmsg, "Redeclaration of identifier '%s'.", $3);
                                                   yyerror(errmsg); } }
       | variability typeUnion ID '(' initList ')'    { $$ = strdup("");
                                                        if(!ids.existsVar($3))
                                                        {
                                                            if(!isPlainType($2))
                                                            {
                                                                 if(/*cts.existsCustom($2)*/false)
                                                                 {
                                                                      ;//ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, scope, &cts);
                                                                      ;// SET FIELDS
                                                                      ;// $$ = strdup($3);
                                                                 }
                                                                 else
                                                                 { sprintf(errmsg, "Custom-type '%s' not declared.", $2);
                                                                   yyerror(errmsg); }
                                                            }
                                                            else
                                                            { sprintf(errmsg, "Plain type '%s' cannot be initialized with Custom-type initialization list.", $3);
                                                              yyerror(errmsg); }
                                                        }
                                                        else
                                                        { sprintf(errmsg, "Redeclaration of identifier '%s'.", $3);
                                                          yyerror(errmsg); }}
       | variability typeUnion ID '[' value ']'    { $$ = strdup("");
                                                     if(!ids.existsVar($3)) // TO DO: MAKE IT TAKE EXPRESSIONS
                                                     {
                                                         int size; // ALSO CHECK TYPE
                                                         sscanf($5, "%d", &size);
                                                         if(size>0)
                                                         {
                                                             ids.addArrayVar($3, ($1[0]=='v'?true:false), $2, size, scope);
                                                             $$ = strdup($3);
                                                         }
                                                         else
                                                             yyerror("Size of array must be positive integer.");
                                                     }
                                                     else
                                                     { sprintf(errmsg, "Variable '%s' already declared.", $2);
                                                       yyerror(errmsg); } }
       | variability typeUnion ID '[' value ']' ASSIGN '[' initList ']'    { $$ = strdup("");
                                                                             if(!ids.existsVar($3)) // SAME THING FOR EXPRESSIONS
                                                                             {
                                                                                 int size; // ALSO CHECK TYPE
                                                                                 sscanf($5, "%d", &size);
                                                                                 if(size>0)
                                                                                 {
                                                                                     ids.addArrayVar($3, ($1[0]=='v'?true:false), $2, size, scope);
                                                                                     // INIT VALUES
                                                                                     $$ = strdup($3);
                                                                                 }
                                                                                 else
                                                                                     yyerror("Size of array must be positive integer.");
                                                                             }
                                                                             else
                                                                             { sprintf(errmsg, "Redeclaration of identifier '%s'.", $3);
                                                                               yyerror(errmsg); } }
       ;

variability: VARIABLE    { $$ = $1; }
           | CONSTANT    { $$ = $1; }
           ;

typeUnion: type    { $$ = $1; }
         | CUSTOM ID    { $$ = $2; }
         ;

initList: initArg
        | initList ',' initArg
        ;

initArg: value
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
         | IF '(' expr ')' { strcpy(prevScope, scope);
                             snprintf(scope, 256, "%s > If(L%d)", prevScope, yylineno); } '{' block '}' ELSE { snprintf(scope, 256, "%s > Otherwise(L%d)", prevScope, yylineno); } '{' block '}'
         | WHILE '(' expr ')' { strcpy(prevScope, scope);
                                snprintf(scope, 256, "%s > LoopWhile(L%d)", prevScope, yylineno); } '{' block '}'
         | FOR '(' assignment ';' expr ';' assignment ')' { strcpy(prevScope, scope);
                                                            snprintf(scope, 256, "%s > For(L%d)", prevScope, yylineno); } DO '{' block '}' // MIGHT NEED MODIFYING
         | EVAL '(' expr ')'
         | TYPEOF '(' expr ')'    { const char* exprType = $3->computeType();
                                    printf("TypeOf expression at line %d: %s.\n", yylineno, exprType);
                                    $3->destroyTree(); }
         ;

assignment: assignable ASSIGN expr
          ;

assignable: ID
          //| ID ACCESS ID
          | ID '[' expr ']'
          ;

functionCall: ID '(' ')'
            | ID '(' argList ')'
            ;

argList: expr
       | argList ',' expr
       ;

expr: '(' expr ')'    { $$ = $2; }
    | NOT expr    { $$ = new class ASTNode("!bOp!", "!"); $$->right = $2; }
    | expr AND expr    { $$ = new class ASTNode("!bOp!", "&&"); $$->left = $1; $$->right = $3; }
    | expr OR expr    { $$ = new class ASTNode("!bOp!", "||"); $$->left = $1; $$->right = $3; }
    | expr EQ expr    { $$ = new class ASTNode("!rOP!", "=="); $$->left = $1; $$->right = $3; }
    | expr NEQ expr    { $$ = new class ASTNode("!rOP!", "=/="); $$->left = $1; $$->right = $3; }
    | expr LEQ expr    { $$ = new class ASTNode("!rOP!", "<="); $$->left = $1; $$->right = $3; }
    | expr GEQ expr    { $$ = new class ASTNode("!rOP!", "=>"); $$->left = $1; $$->right = $3; }
    | expr LESS expr    { $$ = new class ASTNode("!rOP!", "<"); $$->left = $1; $$->right = $3; }
    | expr MORE expr    { $$ = new class ASTNode("!rOP!", ">"); $$->left = $1; $$->right = $3; }
    | expr ADD expr    { $$ = new class ASTNode("!aOp!", "+"); $$->left = $1; $$->right = $3; }
    | expr SUB expr    { $$ = new class ASTNode("!aOp!", "-"); $$->left = $1; $$->right = $3; }
    | expr MUL expr    { $$ = new class ASTNode("!aOp!", "*"); $$->left = $1; $$->right = $3; }
    | expr DIV expr    { $$ = new class ASTNode("!aOp!", "/"); $$->left = $1; $$->right = $3; }
    | expr MOD expr    { $$ = new class ASTNode("!aOp!", "%"); $$->left = $1; $$->right = $3; }
    | expr POW expr    { $$ = new class ASTNode("!aOp!", "^^"); $$->left = $1; $$->right = $3; }
    | ID    { if(ids.existsVar($1))
              {
                class VarInfo& data = ids.IDs[$1];
                $$ = new class ASTNode(data);
              }
              else
              {
                sprintf(errmsg, "Use of identifier not declared in this scope: '%s'.", $1);
                yyerror(errmsg);
                $$ = new class ASTNode("!nE!", "");
              } }
    //| functionCall // TO DO
    //| ID ACCESS ID // ONLY IF CLASSES
    //| ID ACCESS functionCall // ONLY IF CLASSES
    | INT_VAL    { $$ = new class ASTNode("i", $1); }
    | FLOAT_VAL    { $$ = new class ASTNode("f", $1); }
    | CHAR_VAL    { $$ = new class ASTNode("c", $1); }
    | STRING_VAL    { $$ = new class ASTNode("s", $1); }
    | BOOL_VAL    { $$ = new class ASTNode("b", $1); }
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
     //cout << "Custom-types:" << endl;
     //cts.printCustoms();
     cout << "Variables:" << endl;
     ids.printVars();
}
// CLASSES MIGHT WORK WITH [KEY] INSTEAD OF .AT(KEY)
// TO DO OVERALL: CONST & VAR
//              | METHODS & FUNCTIONS
//              | EVAL & TYPEOF
//              | NO FUNCTIONS & CLASSES DEFINITIONS IN MAIN
//              | COMMENTS?