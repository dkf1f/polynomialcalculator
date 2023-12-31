%{

#include "header.h"
#include "gram.tab.h"
int line_counter = 0;
%}


/* recognize tokens for the calculator and print them out */

%%

"\n" 									{line_counter++; return EOL;}
"#".*      								; 	{}// comments 
" \t\r"      							;	// skip
";"										{ return END; }
"^" 									{ return POW; }
"("	 									{ return LBR; }
")" 									{ return RBR; }
(PRINT|print)+							{ return PRINT; }
[0-9a-zA-Z]\^\(*[a-zA-z]+.*\)*			{ return UNSUPPORTED;}
"*"|"+"|"-"|"/"|"$"|"="|"$"				{ return yytext[0]; }
[1-9]{1}[0-9]*	 						{ char* pEnd;yylval.num=strtol(yytext, &pEnd, 10); return NUMBER; }
[0]{1}[0-9]+ 							{ return NUMERR; } // mask for errors
"0"										{char* pEnd;yylval.num=strtol(yytext, &pEnd, 10); return NUMBER;}
[a-zA-Z]+ 								{ yylval.string=(char*)malloc(sizeof(char)*(yyleng+1)); strncpy(yylval.string, yytext, yyleng+1); yylval.string[yyleng]='\0'; ; return STRING; }

%%

int yywrap()
{
}
