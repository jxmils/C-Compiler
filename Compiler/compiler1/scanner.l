

/* Jason Miller CS370 Compiler1
* Scanner produces following token types: ID, STRING, LPAREN, RPAREN, LBRACE, RBRACE, SEMICOLON
* The ID token type is for valid C identifiers and must have a string value associated with them (the actual identifier string).
* Valid C identifiers begin with a letter or underscore, and contain letters, numbers and underscores
* The STRING token type matches a quoted string in the program source,
* and it must also have a string value associated with it (the actual string, including its beginning and ending quote characters).
* Your scanner must also skip unnecessary white space, including spaces, tabs, and newlines that are in between the tokens.
*/

/****** Header definitions ******/
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
int debug=0;
#endif
%}

/* This option is useful for printing out a syntax error
*  message and printing out the line # it occurred on
*/
%option yylineno

/****** Token Patterns ******/
%%
[ \t\n\r]+ { /* skipping white space */ }
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
[0-9a-z_A-Z]+  {
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
