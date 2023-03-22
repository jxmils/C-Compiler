/*Jason Miller
//CS370
//parser.y
/*Sep 1, 2021

/*
* Grammar required:
* Prog -> Function
* Function -> ID '(' ')' '{' Statements '}'
* Statements -> Statement Statements | empty (empty will need its own)
* Statement -> FunCall ';'
* FunCall -> ID '(' STRING ')';
* TOKENS: ID, STRING, ;, (, ), {, }
* Nontokens: Prog(Start), Function, Statements, FunCall
* sprintf( preamble, "\t.text\n\t.globl\tmain\n\t.type\tmain,@function\nmain:\n\tpushq\t%%rbp\n\tmovq\t%%rsp, %%rbp\n", $1, $1, $1) //replace function name with %s
* sprintf( ending, "movl\t$0, %%eax\npopq\t%%rbp\nret\n");
* For the string generate a label and then .string directive with the actual string.
* $ infront of a label means treat label as a function %edi holds the first argument to any function
* sprintf( $$, "\tmovl\t$.LC%d, %%edi\n\tcall\t%s\n", addToStringTable($3), $1 )%s is name of the function probably ($1), %d is the value representing our string probably($3)
* Helper function to store that string into the table that corresponds to %d
* $$ = $1 for statements->FunCall
* for FunCall generate string with movl $.LC[index],
* for statement statement concatenate statement statements and put a new line between statement and statements
/*


/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// function prototypes from lex
int addString( char* input );
void stringDeclaration ( char* stringArray[400] );
int yyerror(char *s);
int yylex(void);
int debug=0; // set to 1 to turn on extra printing

//global variables for stringarray and index
int ind = 0;
char* stringArray[400];

%}

/* token value data types */
%union { int ival; char* str; }

/* Starting non-terminal */
%start prog
%type <str> function statements statement funcall

/* Token types */
%token <ival> NUMBER COMMA SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token <str> ID STRING

%%


/******* Rules *******/

prog: function
     {
         stringDeclaration( stringArray );
         printf( "%s\n", $1 );
     };

function: ID LPAREN RPAREN LBRACE statements RBRACE
       {
          if (debug) { printf( "Function: %s", $1 ); }
          $$ = (char*) malloc( strlen($1) + strlen($5) + 500 );
          char* preamble = (char*) malloc( strlen($1) + strlen($5) + 500 );
          char* middle = (char*) malloc( strlen($1) + 500 );
          char* postamble = (char*) malloc( strlen($1) + strlen($5) + 500 );
          sprintf( preamble, "\t.text\n\t.globl\t%s\n\t.type\t%s, @function\n%s:\n\t.cfi_startproc\n\tpushq\t%%rbp\n\t.cfi_def_cfa_offset 16\n\t.cfi_offset 6, -16   \n\tmovq\t%%rsp, %%rbp\n\t.cfi_def_cfa_register 6 \n", $1, $1, $1);
          sprintf( middle, "%s", $5 );
          sprintf( postamble, "\tmovl\t$0, %%eax\n\tpopq\t%%rbp\n\t.cfi_def_cfa 7, 8\n\tret\n\t.cfi_endproc\n\t.size\tmain, .-main\n");
          sprintf( $$, "%s%s%s", preamble, middle, postamble );

       };
statements: /*empty*/
       { $$ = ""; }

       | statement statements
          {
            $$ = (char*) malloc( strlen($1) + strlen($2) + 500 );
            sprintf( $$, "%s\n%s", $1, $2 );
          };
statement: funcall SEMICOLON
        {
          if (debug) { printf( "FUNCALL %s\n", $1 ); }
          $$ = (char*) malloc( strlen($1) + 500 );
          sprintf( $$, "%s", $1 );
        };
funcall: ID LPAREN STRING RPAREN
        {
          if (debug) { printf( "FUNCTION CALL:\n"); }
          $$ = (char*) malloc( strlen($1) + strlen($3) + 500 );
          int stringind = addString( $3 );
          char *code = (char*) malloc( strlen($1) + strlen($3) + 500 );
          sprintf( code, "\tmovl\t$.LC%d, %%edi\n\tcall\t%s\n", stringind, $1 );
          $$ = code;
        };

%%
/******* Functions *******/
extern FILE *yyin; // from lex
int addString( char* input );
void stringDeclaration ( char* stringArray[400] );

//string table function to keep track of the strings and their index.
int addString( char* input ) {

  stringArray[ ind ] = input;
  return ind++;

}//ends addString

//stringDeclaration function which generates the declaration code for all strings.
void stringDeclaration ( char* stringArray[400] ) {

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
