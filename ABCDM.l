%{
#include <stdio.h>
#include "ABCDM.tab.h"
%}
%option noyywrap
%%
"Changing"    { return VARIABLE; }
"Neverchanging"    { return CONSTANT; } 

"Int"    { yylval.varType = 'i'; return INT; }
[0]|[-]?[1-9][0-9]*    { yylval.rawValue = strdup(yytext); return INT_VAL; }
"Float"    { yylval.varType = 'f'; return FLOAT; }
[0]|[-]?[1-9][0-9]*[.][0-9]* { yylval.rawValue = strdup(yytext); return FLOAT_VAL; }
"Char"     { yylval.varType = 'c'; return CHAR; }
['].[']    { yylval.rawValue[0] = yytext[1]; yylval.rawValue[1]='\0'; return CHAR_VAL; }
"String"    { yylval.varType = 's'; return STRING; }
[""][^\"]*["] { yylval.rawValue = strdup(yytext+1); yylval.rawValue[strlen(yylval.rawValue)-1] = '\0'; return STRING_VAL; }
"Bool"    { yylval.varType = 'b'; return BOOL; }
"true"|"false" { yylval.rawValue = strdup(yytext); return BOOL_VAL; }

"Custom" { yylval.varType = 'u'; return CUSTOM; }
"//" { return ACCESS; }

"<--"    { return ASSIGN; }

"+"    { return ADD; }
"-"    { return SUB; }
"*"    { return MUL; }
"/"    { return DIV; }
"%"    { return MOD; }
"^^"    { return POW; }

"=="    { return EQ; }
"=/="   { return NEQ; }
"<="    { return LEQ; }
"=>"    { return GEQ; }
"<"    { return LESS; }
">"    { return MORE; }

"!"    { return NOT; }
"&&"    { return AND; }
"||"    { return OR; }

"If"    { return IF; }
"Otherwise"    { return ELSE; }
"LoopWhile"    { return WHILE; }
"For"    { return FOR; }
"Do"    { return DO; }

"Eval"    { return EVAL; }
"TypeOf"    { return TYPEOF; }

"beginCustoms"    { return BEGINC; }
"endCustoms"    { return ENDC; }
"beginGlobalVars"    { return BEGINGV; }
"endGlobalVars"    { return ENDGV; }
"beginGlobalFuns"    { return BEGINGF; }
"endGlobalFuns"    { return ENDGF; }
"beginProgram"    { return BEGINP; }
"endProgram"    { return ENDP; }

[a-zA-Z][a-zA-Z0-9]*    { yylval.id = strdup(yytext); return ID; }

[ \t]    ;
\n    { yylineno++; }
.    { return yytext[0]; }
