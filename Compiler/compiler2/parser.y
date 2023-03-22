/*Jason Miller
CS370
parser.y for compiler2
Sep 20, 2021
/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// function prototypes from lex
int addString( char* input );
void stringDeclaration ( char* stringArray[1000] );
int yyerror(char *s);
int yylex(void);
int debug=0; // set to 1 to turn on extra printing

//global variables for stringarray and index and argNum
int ind = 0;
int argNum = 0;
char* stringArray[1000];
char* argRegStr[] = {"%edi", "%esi", "%edx", "%ecx", "%r8d", "%r9d"};

%}

/* token value data types */
%union { int ival; char* str; }

/* Starting non-terminal */
%start prog
%type <str> functions function statements statement funcall arguments argument expression

/* Token types */
%token <ival> NUMBER COMMA SEMICOLON LPAREN RPAREN LBRACE RBRACE PLUS
%token <str> ID STRING

%%


/******* Rules *******/
/*
Prog -> Functions
Functions -> empty | Function Functions
Function -> ID LPAREN RPAREN LBRACE Statements RBRACE
Statements -> Statement Statements | empty
Statement -> FunCall SEMICOLON
FunCall -> ID LPAREN Arguments RPAREN
Arguments -> empty | Argument | Argument COMMA Arguments
Argument -> STRING | Expression
Expression -> NUMBER | Expression PLUS Expression
*/

prog: functions
     {
         stringDeclaration( stringArray );
         printf( "%s\n", $1 );
     };
functions: /*empty*/
       { $$ = ""; }
       | function functions
       {
         $$ = (char*) malloc( strlen($1) + strlen($2) + 100 );
         sprintf( $$, "%s\n%s", $1, $2 );
       };
function: ID LPAREN RPAREN LBRACE statements RBRACE
       {
          if (debug) { printf( "Function ID: %s\n", $1 ); }
          $$ = (char*) malloc( strlen($1) + strlen($5) + 200 );
          char* preamble = (char*) malloc( strlen($1) + 100 );
          char* middle = (char*) malloc( strlen($5) + 100 );
          char* postamble = (char*) malloc( 100 );
          sprintf( preamble, "\t.text\n\t.globl\t%s\n\t.type\t%s, @function\n%s:\n\tpushq\t%%rbp\n\tmovq\t%%rsp, %%rbp\n", $1, $1, $1 );
          sprintf( middle, "%s", $5 );
          sprintf( postamble, "\tmovl\t$0, %%eax\n\tpopq\t%%rbp\n\tret\n" );
          sprintf( $$, "%s%s%s", preamble, middle, postamble );
       };
statements: /*empty*/
       { $$ = ""; }
       | statement statements
       {
         $$ = (char*) malloc( strlen($1) + strlen($2) + 100 );
         sprintf( $$, "%s%s", $1, $2 );
       };
statement: funcall SEMICOLON
        {
          if (debug) { printf( "FUNCALL\n" ); }
          $$ = (char*) malloc( strlen($1) + 100 );
          sprintf( $$, "%s", $1 );
        };
funcall: ID LPAREN arguments RPAREN
        {
          if (debug) { printf( "FUNCTION CALL: %s\n", $1 ); }
          $$ = (char*) malloc( strlen($1) + strlen($3) + 100 );
          sprintf( $$, "%s\tcall\t%s\n", $3, $1 );
          argNum = 0;
        };
arguments: /* empty */
       { $$ = ""; }
       | argument
       {
         $$ = (char*) malloc( strlen($1) + 100 );
         sprintf( $$, "%s\n", $1 );
       }
       | argument COMMA arguments
       {
         $$ = (char*) malloc( strlen($1) + strlen($3) + 100 );
         sprintf( $$, "%s\n%s", $1, $3 );
       };
argument: STRING
       {
         $$ = (char*) malloc( strlen($1) + 100 );
         int stringind = addString ( $1 );
         sprintf( $$, "\tmovl\t$.LC%d, %s\n", stringind, argRegStr[ argNum ] );
         argNum++;
       }
       | expression
       {
         $$ = (char*) malloc( strlen($1) + 100 );
         sprintf( $$, "%s\n\tmovl\t%%eax, %s\n", $1, argRegStr[ argNum ] );
         argNum++;
       };
expression: NUMBER
       {
         $$ = (char*) malloc( sizeof($1) * 5 + 100 );
         sprintf( $$, "\n\tmovl\t$%d, %%eax", $1 );
       }
       | expression PLUS expression
       {
         $$ = (char*) malloc( strlen( $1 ) + strlen( $3 ) + 100 );
         sprintf( $$, "%s\n\tpushq\t%%rax%s\n\tpopq\t%%r11\n\taddl\t%%r11d, %%eax\n", $1, $3 );
       };
%%
/******* Functions *******/
extern FILE *yyin; // from lex
int addString( char* input );
void stringDeclaration ( char* stringArray[1000] );

//string table function to keep track of the strings and their index.
int addString( char* input ) {

  stringArray[ ind ] = input;
  return ind++;

}//ends addString

//stringDeclaration function which generates the declaration code for all strings.
void stringDeclaration ( char* stringArray[1000] ) {

  printf( "\t.text\n\t.section\t.rodata\n" );
  int i = 0;
  while ( i < ind ){

    printf( ".LC%d:\n\t.string\t%s\n", i, stringArray[ i ] );
    i++;

  }//ends while loop

}//ends stringDeclaration function

int main ( int argc, char **argv )
{
   if ( argc==2 ) {
      yyin = fopen(argv[1],"r");
      if (!yyin) {
         printf("Error: unable to open file (%s)\n",argv[1]);
         return(1);
      }
   }
   return(yyparse());
}

extern int yylineno; // from lex

int yyerror(char *s)
{
   fprintf(stderr, "Error: line %d: %s\n",yylineno,s);
   return 0;
}

int yywrap()
{
   return(1);
}
