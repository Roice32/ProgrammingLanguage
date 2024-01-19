%{
#include <string.h>
#include "Code.h"

extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();

char errmsg[128];
int nErr = 0;
bool ASTErr, prevErr, copyA, copyP, canBeDetermined;
void yyerror(const char* s);
void ASTErrThrow(const char* type, const char* op);

char scope[256];
char prevScope[256];
class IDList ids;
class CustomTypesList cts;
class FunctionsList fs;
string retType;
%}

%union {
     char* ID;
     char* typeInfo;
     char* rawValue;
     class IDList* innerIDs;
     class ASTNode* exprAST;
     class VarInfo* assignTo;
}

%token BEGINC ENDC BEGINGV ENDGV BEGINGF ENDGF BEGINP ENDP
%token IF ELSE WHILE FOR DO
%token EVAL TYPEOF
%token RETURN
%type <typeInfo> variability
%token <typeInfo> VARIABLE CONSTANT
%type <typeInfo> type typeUnion returnType
%token <typeInfo> INT FLOAT CHAR STRING BOOL VOID
%token <rawValue> INT_VAL FLOAT_VAL CHAR_VAL STRING_VAL BOOL_VAL
%type <innerIDs> contents paramList funBody block statement
%type <assignTo> assignable
%type <exprAST> expr
%type <ID> varDecl member param
%token <ID> ID
%token CUSTOM ACCESS ASSIGN
%token ADD SUB MUL DIV MOD POW
%token EQ NEQ LEQ GEQ LESS MORE
%token NOT AND OR
%start progr

%left ADD SUB
%left MUL DIV MOD
%left POW
%left AND OR EQ NEQ LEQ GEQ LESS MORE
%left NOT

%%
progr: userDefined globalVariables globalFunctions mainProgram    { if(nErr==0)
                                                                        printf("\tThe program is correct!\n");
                                                                    else
                                                                        printf("\tThe program is not correct: %d errors!\n", nErr); }
     ;

userDefined: BEGINC { strcpy(scope, "Custom Types"); } ENDC
           | BEGINC { strcpy(scope, "Custom Types"); } userDefinedTypes ENDC
           ;

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
                              $$->IDs.insert({$1, ids.IDs[$1]});
                              ids.IDs.erase($1);
                          } } 
        | contents member ';'    { $$ = $1;
                                   if(strlen($2)>0)
                                       if(!$$->existsVar($2))
                                       {
                                           $$->IDs.insert({$2, ids.IDs[$2]});
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
      //| funDecl 
      ;

globalVariables: BEGINGV { sprintf(scope, "Global Variables"); } ENDGV
               | BEGINGV { sprintf(scope, "Global Variables"); } varDeclarations ENDGV
               ;

varDeclarations: varDecl ';'          
	          | varDeclarations varDecl ';'   
	          ;

varDecl : variability typeUnion ID    { $$ = strdup("");
                                        if(!ids.existsVar($3))
                                        {
                                            if(isPlainType($2))
                                            {
                                                ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                                $$ = strdup($3);
                                            }
                                            else if(cts.existsCustom($2))
                                            {
                                                ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, scope, &cts); // TO DO: IMPLEMENT DEFAULT FOR THIS
                                                $$ = strdup($3);
                                            }
                                            else
                                            { sprintf(errmsg, "Custom-type '%s' not declared.", $2);
                                              yyerror(errmsg); }
                                        }
                                        else
                                        { sprintf(errmsg, "Redeclaration of identifier '%s'.", $2);
                                          yyerror(errmsg); } }
       | variability typeUnion ID ASSIGN { ASTErr = prevErr = false; }
                                         expr    { $$ = strdup("");
                                                   const char* exprType = $6->computeType(ASTErr);
                                                   if(!ASTErr)
                                                   {
                                                       if(!ids.existsVar($3))
                                                       {
                                                           if(isPlainType($2))
                                                           {
                                                               if($2[0]==exprType[0])
                                                               {
                                                                   ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                                                   ASTErr = false;
                                                                   int resI; float resF; bool resB;
                                                                   switch($2[0])
                                                                   {
                                                                   case 'i': resI = $6->computeIntVal(ASTErr); if(!ASTErr) ids.IDs[$3].intVal = resI; break;
                                                                   case 'f': resF = $6->computeFloatVal(ASTErr); if(!ASTErr) ids.IDs[$3].floatVal = resF; break;
                                                                   case 'c': ids.IDs[$3].charVal = $6->rawValue[0]; break;
                                                                   case 's': ids.IDs[$3].stringVal = $6->rawValue; break;
                                                                   case 'b': resB = $6->computeBoolVal(ASTErr); if(!ASTErr) ids.IDs[$3].boolVal = resB; break;
                                                                   }
                                                                   if(!ASTErr)
                                                                       ids.IDs[$3].wasInitialized = true;
                                                                   else
                                                                   {
                                                                       sprintf(errmsg, "Declaration of '%s' successful, but initialization failed.", $3);
                                                                       yyerror(errmsg);
                                                                   }
                                                                   $$ = strdup($3);
                                                               }
                                                               else
                                                               {
                                                                   sprintf(errmsg, "Attempt to initialize variable '%s' of type '%s' with '%s' value.", $3, $2, exprType);
                                                                   yyerror(errmsg);
                                                               }
                                                           }
                                                           else
                                                           { sprintf(errmsg, "Custom variable '%s' cannot be initialized at declaration.", $3);
                                                             yyerror(errmsg); }
                                                       }
                                                       else
                                                       { sprintf(errmsg, "Redeclaration of identifier '%s'.", $2);
                                                         yyerror(errmsg);
                                                       } 
                                                   }
                                                   $6->destroyTree(); }
       // ONLY IF CLASSES WORK
       /*| variability typeUnion ID '(' initList ')'    { $$ = strdup("");
                                                        if(!ids.existsVar($3))
                                                        {
                                                            if(!isPlainType($2))
                                                            {
                                                                 if(cts.existsCustom($2))
                                                                 {
                                                                      ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, scope, &cts);
                                                                      ;// SET FIELDS
                                                                      $$ = strdup($3);
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
                                                          yyerror(errmsg); }} */
       | variability typeUnion ID { ASTErr = prevErr = false; }
                                  '[' expr ']'    { $$ = strdup("");
                                                    const char* exprType = $6->computeType(ASTErr);
                                                    if(!ids.existsVar($3))
                                                    {
                                                        if(exprType[0]=='i' && exprType[1]=='\0')
                                                        {
                                                            ASTErr = false;
                                                            int size = $6->computeIntVal(ASTErr);
                                                            if(!ASTErr)
                                                                if(size>0)
                                                                {
                                                                    ids.addArrayVar($3, ($1[0]=='v'?true:false), $2, size, scope);
                                                                    $$ = strdup($3);
                                                                }
                                                                else
                                                                    yyerror("Size of array must be positive integer.");
                                                            else
                                                                yyerror("Size of array cannot be 'NaN'.");
                                                        }
                                                        else
                                                            yyerror("Size of array must be of type 'Int'.");
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

globalFunctions: BEGINGF { sprintf(scope, "Global Functions"); } ENDGF
               | BEGINGF { sprintf(scope, "Global Functions"); } funDeclarations ENDGF
               ;

funDeclarations: funDecl
               | funDeclarations funDecl
               ;

funDecl: returnType ID '(' { snprintf(prevScope, 256, "%s", scope);
                             snprintf(scope, 256, "%s > %s", prevScope, $2);
                             retType = $1; }
                          ')' '{' funBody '}'    { fs.addFun($2, $1, nullptr, $7);
                                                   snprintf(scope, 256, "%s", prevScope);
                                                   for(auto& fun: fs.Funs)
                                                       if(fun.first == $2)
                                                           if(fun.second.hasOther)
                                                               for(auto& var: fun.second.other.IDs)
                                                                   ids.IDs.erase(var.first); }
       | returnType ID '(' { snprintf(prevScope, 256, "%s", scope);
                             snprintf(scope, 256, "%s > %s", prevScope, $2);
                             retType = $1; } 
                          paramList ')' '{' funBody'}'    { fs.addFun($2, $1, $5, $8);
                                                            snprintf(scope, 256, "%s", prevScope);
                                                            for(auto& fun: fs.Funs)
                                                                if(fun.first == $2)
                                                                {
                                                                    for(auto& var: fun.second.params.IDs)
                                                                        ids.IDs.erase(var.first);
                                                                    if(fun.second.hasOther)
                                                                        for(auto& var: fun.second.other.IDs)
                                                                            ids.IDs.erase(var.first);
                                                                } }
       ;

returnType: typeUnion    { $$ = $1; }
          | VOID    { $$ = $1; }
          ;

funBody: RETURN { ASTErr = prevErr = false; }
                expr ';'    { if(retType=="v")
                                  yyerror("Return value found inside of 'Void' function.");
                              else
                              {
                                  const char* exprType = $3->computeType(ASTErr);
                                  if(!ASTErr)
                                      if(retType!=exprType)
                                      {
                                          sprintf(errmsg, "Return of '%s' value inside of '%s' function.", prettyExprType(exprType), prettyExprType(retType.c_str()));
                                          yyerror(errmsg);
                                      }
                              } 
                              $$ = nullptr; }
       | block RETURN { ASTErr = prevErr = false; }
                      expr ';'    { if(retType=="v")
                                        yyerror("Return value found inside of 'Void' function.");
                                    else
                                    {
                                        const char* exprType = $4->computeType(ASTErr);
                                        if(!ASTErr)
                                            if(retType!=exprType)
                                            {
                                                sprintf(errmsg, "Return of '%s' value inside of '%s' function.", prettyExprType(exprType), prettyExprType(retType.c_str()));
                                                yyerror(errmsg);
                                            }
                                    }
                                    $$ = $1;}
       | block    { if(retType!="v")
                    {
                        sprintf(errmsg, "Missing Return of '%s' value.", prettyExprType(retType.c_str()));
                        yyerror(errmsg);
                    }
                    $$ = $1; }
       ;

paramList: param    { $$ = new class IDList;
                      if($1[0]!='\0')
                      {
                        $$->IDs.insert({$1, ids.IDs[$1]});
                      } }
         | paramList ',' param    { $$ = $1;
                                    if($3[0]!='\0')
                                        if(!$$->existsVar($3))
                                        {
                                            $$->IDs.insert({$3, ids.IDs[$3]});
                                        }
                                        else
                                        {
                                            sprintf(errmsg, "Redeclaration of identifier '%s'.", $3);
                                            yyerror(errmsg);
                                        } }
         ;
            
param: variability typeUnion ID    { $$ = strdup("");
                                     if(!ids.existsVar($3))
                                     {
                                        if(isPlainType($2))
                                        {
                                            ids.addVar($3, ($1[0]=='v'?true:false), $2[0], scope);
                                            $$ = strdup($3);
                                        }
                                        else if(cts.existsCustom($2))
                                        {
                                            ids.addCustomVar($3, ($1[0]=='v'?true:false), $2, scope, &cts);
                                            $$ = strdup($3);
                                        }
                                        else
                                        {
                                            sprintf(errmsg, "Custom-type '%s' not defined.", $2);
                                            yyerror(errmsg);
                                        }
                                     }
                                     else
                                     {
                                         sprintf(errmsg, "Redeclaration of identifier '%s'.", $3);
                                         yyerror(errmsg);
                                     } }
     ; 
      
mainProgram: BEGINP { sprintf(scope, "Main Program"); } ENDP
           | BEGINP { sprintf(scope, "Main Program"); } block ENDP
           ;

block: statement ';'    { $$ = $1; }
     | block statement ';'    { $$ = $1;
                                if($2!=nullptr)
                                    *$$ += *$2;
                              }
     ;

statement: varDecl    { if(strstr(scope, "Global Variables")!=scope && strstr(scope, "Main Program")!=scope && $1[0]!='\0') 
                        {
                            $$ = new class IDList;
                            $$->IDs.insert({$1, ids.IDs[$1]});
                        } }
         | functionCall    { $$ = nullptr; }
         | assignment    { $$ = nullptr; }
         | ID ACCESS functionCall    { $$ = nullptr; }
         | IF    { ASTErr = prevErr = false; }
              '(' expr ')'    { const char* exprType = $4->computeType(ASTErr);
                                    if(!ASTErr && (exprType[0]!='b' || strlen(exprType)>1))
                                        yyerror("'If' condition must be of 'Bool' type.");
                                    strcpy(prevScope, scope);
                                    snprintf(scope, 256, "%s > If(L%d)", prevScope, yylineno); }
              '{' block '}' ELSE    { snprintf(scope, 256, "%s > Otherwise(L%d)", prevScope, yylineno);}
                                 '{' block '}'    { snprintf(scope, 256, "%s", prevScope);
                                                    $$ = $8;
                                                    if($13!=nullptr)
                                                        if($$!=nullptr)
                                                            *$$ += *$13;
                                                        else
                                                            $$ = $13; }
         | WHILE     { ASTErr = prevErr = false; }
                 '(' expr ')'    { const char* exprType = $4->computeType(ASTErr);
                                   if(!ASTErr && (exprType[0]!='b' || strlen(exprType)>1))
                                       yyerror("'If' condition must be of 'Bool' type.");
                                   strcpy(prevScope, scope);
                                   snprintf(scope, 256, "%s > LoopWhile(L%d)", prevScope, yylineno); }
                              '{' block '}'    { snprintf(scope, 256, "%s", prevScope);
                                                 $$ = $8; }
         | FOR     { ASTErr = prevErr = false; }
               '(' assignment ';' expr ';' assignment ')'     { const char* exprType = $6->computeType(ASTErr);
                                                                    if(!ASTErr && (exprType[0]!='b' || exprType[1]!='\0'))
                                                                        yyerror("'For' condition must be of 'Bool' type.");
                                                                    strcpy(prevScope, scope);
                                                                    snprintf(scope, 256, "%s > For(L%d)", prevScope, yylineno); }
                                                          DO '{' block '}'     { snprintf(scope, 256, "%s", prevScope);
                                                                                 $$ = $13; }
         | EVAL { ASTErr = prevErr = false; } '(' expr ')'    { if(strstr(scope, "Main Program")==scope)
                                                                {
                                                                    const char* exprType = $4->computeType(ASTErr);
                                                                    if(!ASTErr)
                                                                    {
                                                                        if(strlen(exprType)>1 || !(exprType[0]=='i' || exprType[0]=='f' || exprType[0]=='b'))
                                                                        {
                                                                            sprintf(errmsg, "Eval: Cannot compute value of expression that is not of type Int, Float, or Bool.");
                                                                            yyerror(errmsg);
                                                                        }
                                                                        else
                                                                        {
                                                                            ASTErr = false;
                                                                            if(exprType[0]=='i')
                                                                            {
                                                                                int res = $4->computeIntVal(ASTErr);
                                                                                if(!ASTErr)
                                                                                    printf("Value of 'Int' expression at line %d: %d.\n", yylineno, res);
                                                                                else
                                                                                    yyerror("Eval concluded NaN (either division by zero or negative exponent).");
                                                                            } else if(exprType[0]=='f')
                                                                            { 
                                                                                float res = $4->computeFloatVal(ASTErr);
                                                                                if(!ASTErr)
                                                                                    printf("Value of 'Float' expression at line %d: %f.\n", yylineno, res);
                                                                                else
                                                                                    yyerror("Eval concluded NaN (either division by zero or attempt of unsupported '%').");
                                                                            } else
                                                                            {
                                                                                bool res = $4->computeBoolVal(ASTErr);
                                                                                if(!ASTErr)
                                                                                    printf("Value of 'Bool' expression at line %d: %s.\n", yylineno, res?"true":"false");
                                                                                else
                                                                                    yyerror("Eval concluded Maybe (sub-expression evaluated to NaN).");
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                $4->destroyTree(); }
         | TYPEOF { ASTErr = prevErr = false; } '(' expr ')'    { if(strstr(scope, "Main Program")==scope)
                                                                  {
                                                                      const char* exprType = $4->computeType(ASTErr);
                                                                      if(!ASTErr)
                                                                          printf("TypeOf expression at line %d: %s.\n", yylineno, prettyExprType(exprType));
                                                                  }
                                                                  $4->destroyTree(); }
         ;

assignment: assignable ASSIGN { ASTErr = prevErr = false; } expr    { const char* exprType = $4->computeType(ASTErr);
                                                                      if($1!=nullptr && !ASTErr)
                                                                          if(!$1->isVariable && $1->wasInitialized)
                                                                              yyerror("Cannot modify value of 'Neverchanging' type a second time.");
                                                                          else
                                                                          {
                                                                              if($1->type=='u')
                                                                              {
                                                                                  sprintf(errmsg, "Cannot directly assign to whole object of Custom-type '%s'.", $1->customType.c_str());
                                                                                  yyerror(errmsg);
                                                                              } else if($1->type!=$4->type[0])
                                                                              {
                                                                                   char refType[2]; refType[0] = $1->type; refType[1] = '\0';
                                                                                   sprintf(errmsg, "Type mismatch when assigning: '%s' <-- '%s'.",
                                                                                           prettyExprType(refType),
                                                                                           prettyExprType(exprType));
                                                                                   yyerror(errmsg);
                                                                              }
                                                                              else if($1->arrSize>0)
                                                                              {
                                                                                  sprintf(errmsg, "Attempting to assign single-value to array of size %d.", $1->arrSize);
                                                                                  yyerror(errmsg);
                                                                              }
                                                                              else
                                                                              {
                                                                                  ASTErr = false;
                                                                                  int resI; float resF; bool resB;
                                                                                  switch($1->type)
                                                                                  {
                                                                                  case 'i': resI = $4->computeIntVal(ASTErr); if(!ASTErr) $1->intVal = resI; break;
                                                                                  case 'f': resF = $4->computeFloatVal(ASTErr); if(!ASTErr) $1->floatVal = resF; break;
                                                                                  case 'c': $1->charVal = $4->rawValue[0]; break;
                                                                                  case 's': $1->stringVal = $4->rawValue; break;
                                                                                  case 'b': resB = $4->computeBoolVal(ASTErr); if(!ASTErr) $1->boolVal = resB; break;
                                                                                  }
                                                                                  $1->wasInitialized = true;
                                                                              }
                                                                          }
                                                                     $4->destroyTree(); }
          ;

assignable: ID    { $$ = nullptr;
                    if(ids.isInScope($1, scope))
                        $$ = &ids.IDs[$1];
                    else
                    {
                        sprintf(errmsg, "Use of identifier not declared in this scope: '%s'.", $1);
                        yyerror(errmsg);
                    } }
          | ID '[' { copyA = ASTErr; copyP = prevErr; ASTErr = prevErr = false; }
                   expr ']'    { $$ = nullptr;
                                 if(ids.isInScope($1, scope))
                                 {
                                     if(ids.IDs[$1].arrSize>0)
                                     {
                                         const char* exprType = $4->computeType(ASTErr);
                                         if(!ASTErr)
                                             if(strlen(exprType)>1 || exprType[0]!='i')
                                                 yyerror("Array index must be of type 'Int'.");
                                             else
                                             {
                                                 ASTErr = false;
                                                 int index = $4->computeIntVal(ASTErr);
                                                 if(!ASTErr)
                                                     if(index>=0 && index < ids.IDs[$1].arrSize)
                                                         $$ = &ids.IDs[$1].array[index];
                                                     else
                                                     {
                                                         sprintf(errmsg, "Array index '%d' not in range [0,%d].", index, ids.IDs[$1].arrSize);
                                                         yyerror(errmsg);
                                                     }
                                                 else yyerror("Cannot acces array at 'NaN' index.");
                                             }
                                     }
                                     else
                                     {
                                         sprintf(errmsg, "Identifier '%s' does not represent an array.", $1);
                                         yyerror(errmsg);
                                     }
                                 }
                                 else
                                 {
                                     sprintf(errmsg, "Use of identifier non-existent in this scope: '%s'.", $1);
                                     yyerror(errmsg);
                                 }
                                 $4->destroyTree();
                                 ASTErr = copyA; prevErr = copyP; }
          //| ID ACCESS ID
          ;

functionCall: ID '(' ')'    { if(fs.existsFun($1))
                                  ;
                              else
                              {
                                  sprintf(errmsg, "Function '%s' was not found in this scope.", $1);
                                  yyerror(errmsg);
                              } }
            | ID '(' argList ')'    { if(fs.existsFun($1))
                                      ;
                                      else
                                      {
                                          sprintf(errmsg, "Function '%s' was not found in this scope.", $1);
                                          yyerror(errmsg);
                                      } }
            ;

argList: expr
       | argList ',' expr
       ;

expr: '(' expr ')'    { $$ = $2; }
    | NOT expr    { $$ = new class ASTNode("!bOp!", "!"); $$->right = $2;
                    const char* res = $$->computeType(ASTErr);
                    if(ASTErr!=prevErr) ASTErrThrow(res, "!");
                    prevErr = ASTErr; }
    | expr AND expr    { $$ = new class ASTNode("!bOp!", "&&"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "&&");
                         prevErr = ASTErr; }
    | expr OR expr    { $$ = new class ASTNode("!bOp!", "||"); $$->left = $1; $$->right = $3;
                        const char* res = $$->computeType(ASTErr);
                        if(ASTErr!=prevErr) ASTErrThrow(res, "||");
                        prevErr = ASTErr; }
    | expr EQ expr    { $$ = new class ASTNode("!rOp!", "=="); $$->left = $1; $$->right = $3;
                        const char* res = $$->computeType(ASTErr);
                        if(ASTErr!=prevErr) ASTErrThrow(res, "==");
                        prevErr = ASTErr; }
    | expr NEQ expr    { $$ = new class ASTNode("!rOp!", "=/="); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "=/=");
                         prevErr = ASTErr; }
    | expr LEQ expr    { $$ = new class ASTNode("!rOp!", "<="); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "<=");
                         prevErr = ASTErr; }
    | expr GEQ expr    { $$ = new class ASTNode("!rOp!", "=>"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "=>");
                         prevErr = ASTErr; }
    | expr LESS expr    { $$ = new class ASTNode("!rOp!", "<"); $$->left = $1; $$->right = $3;
                          const char* res = $$->computeType(ASTErr);
                          if(ASTErr!=prevErr) ASTErrThrow(res, "<");
                          prevErr = ASTErr; }
    | expr MORE expr    { $$ = new class ASTNode("!rOp!", ">"); $$->left = $1; $$->right = $3;
                          const char* res = $$->computeType(ASTErr);
                          if(ASTErr!=prevErr) ASTErrThrow(res, ">");
                          prevErr = ASTErr; }
    | expr ADD expr    { $$ = new class ASTNode("!aOp!", "+"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "+");
                         prevErr = ASTErr; }
    | expr SUB expr    { $$ = new class ASTNode("!aOp!", "-"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "-");
                         prevErr = ASTErr; }
    | expr MUL expr    { $$ = new class ASTNode("!aOp!", "*"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "*");
                         prevErr = ASTErr; }
    | expr DIV expr    { $$ = new class ASTNode("!aOp!", "/"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "/");
                         prevErr = ASTErr; }
    | expr MOD expr    { $$ = new class ASTNode("!aOp!", "%"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "%");
                         prevErr = ASTErr; }
    | expr POW expr    { $$ = new class ASTNode("!aOp!", "^^"); $$->left = $1; $$->right = $3;
                         const char* res = $$->computeType(ASTErr);
                         if(ASTErr!=prevErr) ASTErrThrow(res, "^^");
                         prevErr = ASTErr; }
    | assignable    { if($1!=nullptr)
                          $$ = new class ASTNode(*$1);
                      else
                      {
                          $$ = new class ASTNode("!nE!", "");
                          ASTErr = prevErr = true;
                      }
                      $$->typeComputed = true; }
    //| functionCall // TO DO
    //| ID ACCESS ID // ONLY IF CLASSES
    //| ID ACCESS functionCall // ONLY IF CLASSES
    | INT_VAL    { $$ = new class ASTNode("i", $1); $$->typeComputed = true; }
    | FLOAT_VAL    { $$ = new class ASTNode("f", $1); $$->typeComputed = true; }
    | CHAR_VAL    { $$ = new class ASTNode("c", $1); $$->typeComputed = true; }
    | STRING_VAL    { $$ = new class ASTNode("s", $1); $$->typeComputed = true; }
    | BOOL_VAL    { $$ = new class ASTNode("b", $1); $$->typeComputed = true; }
    ;

type: INT    { $$ = $1; }
    | FLOAT    { $$ = $1; }
    | CHAR    { $$ = $1; }
    | STRING    { $$ = $1; }
    | BOOL    { $$ = $1; }
    ;
%%

void yyerror(const char* s)
{ printf("Error: \"%s\"\n\tAt line: %d.\n",s,yylineno); ++nErr; }

void ASTErrThrow(const char* type, const char* op)
{
    switch(type[1])
    {
    case 'b': sprintf(errmsg, "TypeOf: Operator '%s' expected operand%s of type 'bool'.", op, op[0]=='!'?"":"s"); break;
    case 't': sprintf(errmsg, "TypeOf: Operator '%s' expected operands of same type.", op); break;
    case 'r':
    case 'a': sprintf(errmsg, "TypeOf: Operator '%s' expected operands of type 'Int' or 'Float'.", op); break;
    }
    yyerror(errmsg);
}

int main(int argc, char** argv)
{
     yyin = fopen(argv[1],"r");
     yyparse();
     printToFile(argv[1], ids, fs);

}
// CLASSES MIGHT WORK WITH [KEY] INSTEAD OF .AT(KEY) - P.S.: THEY WORK MY AHH
// TO DO OVERALL: METHODS & FUNCTIONS
//              | PRINT STUFF TO FILE
//              | COMMENTS?
//              | SPECIAL ASSIGNMENT VALUE WHEN NON-DETERMINABLE
//              | CHECK SCOPE WHEN VERIFYING ID EXISTENCE
//              | fArr[0] <-- fArr[4]+fArr[j[i]]*(-2.0); PUT THIS IN FINAL SAMPLE CODE