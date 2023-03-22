/*Jason Miller
CS370
parser.y for compiler3
Oct 6, 2021


/****** Header definitions ******/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"

// function prototypes from lex
int addString( char* input );
void yylex_destroy();
void stringDeclaration ( char* stringArray[1000] );
void symbolDeclaration ( Symbol** table );
int yyerror(char *s);
int yylex(void);
int debug=0; // set to 1 to turn on extra printing

//global variables for stringarray and index and argNum
int ind = 0;
Symbol** table;
int argNum = 0;
char* stringArray[1000];
char* argRegStr[] = {"%edi", "%esi", "%edx", "%ecx", "%r8d", "%r9d"};

%}

/* token value data types */
%union { int ival; char* str; }

/* Starting non-terminal */
%start prog
%type <str> functions function statements statement funcall assignment arguments argument expression declarations vardecl parameters

/* Token types */
%token <ival> NUMBER COMMA SEMICOLON LPAREN RPAREN LBRACE RBRACE PLUS EQUALS
%token <str> ID STRING KWCHARS KWINT

%%


/******* Rules *******/
/*
Prog -> Declarations Functions
Functions -> empty | Function Functions
Function -> ID LPAREN Parameters RPAREN LBRACE Statements RBRACE
Statements -> Statement Statements | empty
Statement -> FunCall SEMICOLON | Assignment SEMICOLON
FunCall -> ID LPAREN Arguments RPAREN
Assignment -> ID EQUALS Expression
Arguments -> empty | Argument | Argument COMMA Arguments
Argument -> STRING | Expression
Expression -> NUMBER | ID | Expression PLUS Expression
Declarations -> empty | VarDecl SEMICOLON Declarations
VarDecl -> KWINT ID | KWCHARS ID
Parameters -> empty | VarDecl | VarDecl COMMA Parameters
*/

prog: declarations functions
     {
         symbolDeclaration( table );
         stringDeclaration( stringArray );
         //will have $1 in future.
         printf( "%s", $2 );
         free($2);
     };
functions: /*empty*/
       { $$ = strdup(""); }
       | function functions
       {
         $$ = (char*) malloc( strlen($1) + strlen($2) + 100 );
         sprintf( $$, "%s\n%s", $1, $2 );
         free($1);
         free($2);
       };
function: ID LPAREN parameters RPAREN LBRACE statements RBRACE
       {
          if (debug) { printf( "Function ID: %s\n", $1 ); }
          $$ = (char*) malloc( strlen($1) * 3 + strlen($6) + 200 );
          char* preamble = (char*) malloc( strlen($1) * 3 + 100 );
          char* middle = (char*) malloc( strlen($6) + 100 );
          char* postamble = (char*) malloc( 100 );
          sprintf( preamble, "\t.text\n\t.globl\t%s\n\t.type\t%s, @function\n%s:\n\tpushq\t%%rbp\n\tmovq\t%%rsp, %%rbp\n", $1, $1, $1 );
          sprintf( middle, "%s", $6 );
          sprintf( postamble, "\tmovl\t$0, %%eax\n\tpopq\t%%rbp\n\tret\n" );
          sprintf( $$, "%s%s%s", preamble, middle, postamble );
          free($6);
          free(preamble);
          free(middle);
          free(postamble);
          free($1);
       };
statements: /*empty*/
       { $$ = strdup(""); }
       | statement statements
       {
         $$ = (char*) malloc( strlen($1) + strlen($2) + 100 );
         sprintf( $$, "%s%s", $1, $2 );
         free($1);
         free($2);
       };
statement: funcall SEMICOLON
        {
          if (debug) { printf( "FUNCALL\n" ); }
          $$ = (char*) malloc( strlen($1) + 100 );
          sprintf( $$, "%s", $1 );
          free($1);
        }
        | assignment SEMICOLON
        {
          if (debug) { printf( "statement assignment SEMICOLON: (%s)\n", $1 ); }
          $$ = (char*) malloc( strlen($1) + 50 );
          sprintf( $$, "%s", $1 );
          free($1);
        };
funcall: ID LPAREN arguments RPAREN
        {
          if (debug) { printf( "FUNCTION CALL: ID(%s), arguments(%s)\n", $1, $3 ); }
          $$ = (char*) malloc( strlen($1) + strlen($3) + 100 );
          sprintf( $$, "%s\tcall\t%s\n", $3, $1 );
          argNum = 0;
          free($1);
          free($3);
        };
assignment: ID EQUALS expression
        {
           $$ = (char*) malloc( strlen($1) + strlen( $3 ) + 50 );
           if (debug) { printf( "assignment ID: (%s) expression: (%s)\n", $1, $3 ); }
           Symbol* check = findSymbol( table, $1 );
           if ( check == NULL ) {
             printf( "ERROR: Variable: %s has not been defined.", $1 );
             exit(0);
           }
           sprintf( $$, "%s\tmovl\t%%eax, %s(%%rip)\n", $3, $1 );
           free($1);
           free($3);
        };
arguments: /* empty */
       { $$ = strdup(""); }
       | argument
       {
         if (debug) { printf( "argument(%s)\n", $1 ); }
         $$ = (char*) malloc( strlen($1) + 100 );
         sprintf( $$, "%s\n", $1 );
         free($1);
       }
       | argument COMMA arguments
       {
         if (debug) { printf( "argument (%s) \narguments: (%s) \n", $1 , $3 ); }
         $$ = (char*) malloc( strlen($1) + strlen($3) + 100 );
         sprintf( $$, "%s\n%s", $1, $3 );
         free($1);
         free($3);
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
         if (debug) { printf( "argument expression (%s)\n", $1 ); }
         sprintf( $$, "%s\n\tmovl\t%%eax, %s\n", $1, argRegStr[ argNum ] );
         argNum++;
         free($1);
       };
expression: NUMBER
       {
         $$ = (char*) malloc( sizeof($1) * 5 + 100 );
         sprintf( $$, "\n\tmovl\t$%d, %%eax\n", $1 );
       }
       | ID
       {
         if (debug) { printf( "expression ID (%s)\n", $1 ); }
         $$ = (char*) malloc( strlen($1) + 100 );
         Symbol* check = findSymbol( table, $1 );
         if ( check == NULL ) {
           printf( "ERROR: Variable: %s has not been defined.", $1 );
           exit(0);
         }
         sprintf( $$, "\tmovl\t%s(%%rip), %%eax\n", $1 );
         free($1);
       }
       | expression PLUS expression
       {
         $$ = (char*) malloc( strlen( $1 ) + strlen( $3 ) + 100 );
         sprintf( $$, "%s\n\tpushq\t%%rax\n%s\n\tpopq\t%%r11\n\taddl\t%%r11d, %%eax\n", $1, $3 );
         free($1);
         free($3);
       };
declarations: { $$ = ""; }
       | vardecl SEMICOLON declarations
       {
         //$$ = (char*) malloc( strlen( $1 ) + strlen( $3 ) + 50 );
         //sprintf( $$, "\t.text\n%s\n%s", $1, $3 );
       };
vardecl: KWINT ID
       {
         //$$ = (char*) malloc( strlen( $2 ) + 100 );
         addSymbol( table, $2, 0, T_STRING, 0, 0 );
         free($2);
       }
       | KWCHARS ID
       {
         //$$ = (char*) malloc( strlen( $2 ) + 100 );
         addSymbol( table, $2, 0, T_INT, 0, 0 );
         free($2);
       };
parameters:
       { $$ = strdup(""); }
       | vardecl
       {
         //$$ = (char*) malloc( strlen( $1 ) + 50 );
         //sprintf( $$, "%s", $1 );
       }
       | vardecl COMMA parameters
       {
         //$$ = (char*) malloc( strlen( $1 ) + strlen( $3 ) + 50 );
         //sprintf( $$, "%s\n%s", $1, $3 );
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

//symbolDeclaration generates the code for all symbols.
void symbolDeclaration ( Symbol** table ) {

  if ( table != NULL )
    printf( "\t.text\n" );
  SymbolTableIter iter;
  iter.index = -1;
  while( iterSymbolTable( table, 0, &iter ) != NULL ) {

    if ( table[ iter.index ]-> type == T_INT ) {
      printf( "\t.comm\t%s,4,4\n", table[ iter.index ]->name );
    }
    else if ( table[ iter.index ]-> type == T_STRING ) {
      printf( "\t.comm\t%s,8,8\n", table[ iter.index ]->name );
    }
  }//ends while loop

}//ends symbolDeclaration function

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
   table = newSymbolTable();
   int stat = yyparse();
   freeAllSymbols(table);
   free(table);
   yylex_destroy();
   return stat;

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
