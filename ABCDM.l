%{
#include <stdio.h>
#include "ABCDM.tab.h"
%}
%option noyywrap
%%
"int"|"float"|"char"|"string"|"bool" { yylval.string = strdup(yytext); return TYPE; }
"beginProgram" { return BGIN; }
"endProgram" { return END; }
[a-zA-Z][a-zA-Z0-9]* { yylval.string = strdup(yytext); return ID; }
":=" { return ASSIGN; }
[0-9]+ { return NR; }
"\'"[a-zA-Z]{1}"\'" { yylval.chr = yytext[1]; return CHAR; }
[ \t] ;
\n { yylineno++; }
. { return yytext[0]; }
