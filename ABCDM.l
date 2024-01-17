%{
#include <stdio.h>
#include "ABCDM.tab.h"
%}
%option noyywrap
%%
"Changing"    { yylval.typeInfo = strdup("v"); return VARIABLE; }
"Neverchanging"    { yylval.typeInfo = strdup("c"); return CONSTANT; } 

"Int"    { yylval.typeInfo = strdup("i"); return INT; }
[0]|[-]?[1-9][0-9]*    { yylval.rawValue = strdup(yytext); return INT_VAL; }
"Float"    { yylval.typeInfo = strdup("f"); return FLOAT; }
[0]|[-]?[1-9][0-9]*[.][0-9]* { yylval.rawValue = strdup(yytext); return FLOAT_VAL; }
"Char"     { yylval.typeInfo = strdup("c"); return CHAR; }
['].[']    { yylval.rawValue = strdup(yytext+1); yylval.rawValue[1]='\0'; return CHAR_VAL; }
"String"    { yylval.typeInfo = strdup("s"); return STRING; }
[""][^\"]*["] { yylval.rawValue = strdup(yytext+1); yylval.rawValue[strlen(yylval.rawValue)-1] = '\0'; return STRING_VAL; }
"Bool"    { yylval.typeInfo = strdup("b"); return BOOL; }
"true"|"false" { yylval.rawValue = strdup(yytext); return BOOL_VAL; }

"Custom" { sprintf(yylval.typeInfo, "u"); return CUSTOM; }
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

"Return"    { return RETURN; }

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

[a-zA-Z][a-zA-Z0-9]*    { yylval.ID = strdup(yytext); return ID; }

[ \t]    ;
\n    { yylineno++; }
.    { return yytext[0]; }
