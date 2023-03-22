/* Jason Miller CS370 Compiler3 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// The ifndef below allows this scanner definition to be
// used either with a yacc generated parser or all by
// itself (if LEXONLY is defined)
#ifndef LEXONLY
// definitions are auto-created by yacc so just include them
#include "y.tab.h"
extern int debug; // declared and set in parser.y
#else
// we must have explicit definitions for standalone mode
typedef union { int ival; char* str; } yystype;
#define YYSTYPE yystype
yystype yylval;
#define LPAREN 1
#define RPAREN 2
#define LBRACE 3
#define RBRACE 4
#define SEMICOLON 5
#define ID 6
#define NUMBER 7
#define ADDOP 8
#define COMMA 9
#define EQUALS 10
#define KWINT 11
#define KWCHARS 12
#define KWWHILE 13
#define KWIF 14
#define KWELSE 15
#define STRING 16
#define RELOP 17
#define RBRACKET 18
#define LBRACKET 19
int debug=0;
#endif
%}

/* This option is useful for printing out a syntax error
*  message and printing out the line # it occurred on
*/
%option yylineno

%%
[ \t\n\r]+ { /* skipping white space */ }

\[       {
            if (debug) printf("LBRACKET");
            yylval.ival = yytext[0];
            return(LBRACKET);
         }
\]       {
            if (debug) printf("RBACKET");
            yylval.ival = yytext[0];
            return(RBRACKET);
         }
\(       {
            if (debug) printf("lex LPAREN\n");
            yylval.ival = yytext[0];
            return(LPAREN);
         }
\)       {
            if (debug) printf("lex RPAREN\n");
            yylval.ival = yytext[0];
            return(RPAREN);
         }
\{       {
            if (debug) printf("lex LBRACE\n");
            yylval.ival = yytext[0];
            return(LBRACE);
         }
\}       {
            if (debug) printf("lex RBRACE\n");
            yylval.ival = yytext[0];
            return(RBRACE);
         }
\;       {
            if (debug) printf("lex SEMICOLON\n");
            yylval.ival = yytext[0];
            return(SEMICOLON);
         }
\+       {
            if (debug) printf("lex PLUS_ADDOP\n");
            yylval.ival = yytext[0];
            return(ADDOP);
          }
\-       {
            if (debug) printf("lex MINUS_ADDOP\n");
            yylval.ival = yytext[0];
            return(ADDOP);
          }
\,        {
            if (debug) printf("lex COMMA\n");
            yylval.ival = yytext[0];
            return(COMMA);
          }
\=        {
            if (debug) printf("lex ASSIGN\n");
            yylval.ival = yytext[0];
            return(EQUALS);
          }
"<"       {
            if (debug) printf("lex LESS\n");
            yylval.ival = yytext[0];
            return(RELOP);
          }
">"       {
            if (debug) printf("lex GREATER\n");
            yylval.ival = yytext[0];
            return(RELOP);
          }
"=="      {
            if (debug) printf("lex EQUALS\n");
            yylval.ival = yytext[0];
            return(RELOP);
          }
"!="      {
            if (debug) printf("lex NOTEQUAL\n");
            yylval.ival = yytext[0];
            return(RELOP);
          }
(int)     {
            if ( debug ) printf("INT\n");
            char* pchar = strdup(yytext);
            yylval.str = pchar;
            free(pchar);
            return(KWINT);
          }
char\*    {
            if ( debug ) printf("CHAR*\n");
            char* pchar = strdup(yytext);
            yylval.str = pchar;
            free(pchar);
            return(KWCHARS);
          }
while     {
            if ( debug ) printf("while\n");
            char* pchar = strdup(yytext);
            yylval.str = pchar;
            free(pchar);
            return(KWWHILE);
          }
if        {
            if ( debug ) printf("if\n");
            char* pchar = strdup(yytext);
            yylval.str = pchar;
            free(pchar);
            return(KWIF);
          }
else      {
            if ( debug ) printf("else\n");
            char* pchar = strdup(yytext);
            yylval.str = pchar;
            free(pchar);
            return(KWELSE);
          }
[0-9]+    {
            if (debug) printf("lex NUMBER\n");
            char *ptr;
            yylval.ival = strtol( &yytext[0], &ptr, 10 );
            return(NUMBER);
          }
[_a-zA-Z][_a-zA-Z0-9]*  {
            if (debug) printf("lex ID: (%s)\n", yytext);
            // creating a copy of the string is important, but
            // in this small program we are leaking this memory,
            // we don't clean it up; needs fixed in bigger program!
            yylval.str = strdup(yytext);
            return(ID);
         }

\"[^\"]*\" {
            if (debug) printf("string: (%s)\n", yytext);
            yylval.str = strdup(yytext);
            return(STRING);
           }


%%
/****** Functions (not used when used with parser) *******/

//
// Code in the ifdef block below is only for compiling the
// scanner all by itself, for testing purposes. The
// Makefile shows how to compile it under the "ltest" rule
// (do "make ltest" to build it)
//
#ifdef LEXONLY

// A main for standalone testing (uses just stdin as input)
int main(int argc, char **argv)
{
   do {
      yylex();
   } while (1);
   // while (!feof(stdin)); doesn't work if redirecting a file
   // in because the file is read in and buffered, and eof is
   // true too early, causing lex to stop; rather, use while(1)
   // and then do a hard exit in yywrap(); ugly, but works!
   return 0;
}

int yywrap()
{
   exit(0); // hard exit!
   //return(1);
}

#endif // LEXONLY
