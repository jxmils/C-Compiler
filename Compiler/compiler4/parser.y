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
#include "astree.h"

// function prototypes from lex
int addString( char* input );
void yylex_destroy();
void stringDeclaration ( char* stringArray[1000] );
void symbolDeclaration ( Symbol** table );
int yyerror(char *s);
int yylex(void);
int debug=0; // set to 1 to turn on extra printing

//global variables
ASTNode* root;
int ind = 0;
Symbol** table;
int argNum = 0;
char* stringArray[1000];
char* argRegStr[] = {"%edi", "%esi", "%edx", "%ecx", "%r8d", "%r9d"};

%}

/* token value data types */
%union {
   int ival;  // for most scanner tokens
   char* str; // tokens that need a string, like ID and STRING
   struct astnode_s * astnode; // for all grammar nonterminals
}

/* Starting non-terminal */
%start prog
/* All nonterminals "return" an ASTNode pointer */
%type <astnode> functions function statements statement funcall arguments
%type <astnode> argument expression parameters declarations assignment
%type <astnode> vardecl prog

/* Token types -- tokens either have an int value or a string value */
%token <ival> NUMBER COMMA SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token <ival> PLUS EQUALS KWINT KWCHARS
%token <str>  ID STRING

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

         $$ = newASTNode(AST_PROGRAM);
         $$ -> valType = T_STRING;
         //$$->child[0] = $1
         $$->child[1] = $2;
         root = $$;
         stringDeclaration( stringArray );
     };
functions: /* empty */ {$$ = 0; }
      | function functions
      {
          if (debug) fprintf(stderr,"functions def!\n");

          $$->next = $2;
          $$ = $1;
      };

function: ID LPAREN parameters RPAREN LBRACE statements RBRACE
      {
          if (debug) fprintf(stderr,"function def!\n");
          $$ = newASTNode(AST_FUNCTION);
          $$->valType = T_STRING;
          $$->strval = $1;
          $$->child[0] = $3;
          $$->child[1] = $6;
      };
statements: /*empty*/
       { $$ = 0; }
       | statement statements
       {
         if (debug) fprintf(stderr,"statements->statement statemnts!\n");
         $1->next = $2;
         $$ = $1;
       };
statement: funcall SEMICOLON
        {
          if (debug) fprintf(stderr,"statement->funcall!\n");
          $$ = $1;
        }
        | assignment SEMICOLON
        {
          if (debug) fprintf(stderr,"statement->assignment;!\n");
          $$ = $1;
        };
funcall: ID LPAREN arguments RPAREN
        {
          if (debug) fprintf(stderr,"funcall ID(arg)!\n");
          $$ = newASTNode(AST_FUNCALL);
          $$->valType = T_STRING;
          $$->strval = $1;
          $$->child[0] = $3;
        };
assignment: ID EQUALS expression
        {
          if (debug) fprintf(stderr,"assignment->ID=expr!\n");
          Symbol* check = findSymbol( table, $1 );
          if ( check == NULL ) {
            printf( "ERROR: Variable: %s has not been defined.", $1 );
            exit(0);
          }
          $$ = newASTNode(AST_ASSIGNMENT);
          $$->valType = T_STRING;
          $$->strval = $1;
          $$->child[0] = $3;
        };
arguments: /* empty */
       { $$ = 0; }
       | argument
       {
         if (debug) fprintf(stderr,"arguments->argument!\n");
         $$ = $1;
       }
       | argument COMMA arguments
       {
         if (debug) fprintf(stderr,"arguments->argument,arguments!\n");
         $1->next = $3;
         $$ = $1;

       };
argument: expression
       {
         if (debug) fprintf(stderr,"argument->expr!\n");
         $$ = newASTNode(AST_ARGUMENT);
         $$->child[0] = $1;
         argNum++;
       };
expression: NUMBER
       {
         if (debug) fprintf(stderr,"expr->NUMBER!\n");
         $$ = newASTNode(AST_CONSTANT);
         $$->ival = $1; //may have to switch from string to int
       }
       | ID
       {
         if (debug) fprintf(stderr,"expr->ID!\n");
         $$ = newASTNode(AST_VARREF);
         Symbol* check = findSymbol( table, $1 );
         if ( check == NULL ) {
           printf( "ERROR: Variable: %s has not been defined.", $1 );
           exit(0);
         }
         $$->strval = $1;
       }
       | STRING
       {
         if (debug) fprintf(stderr,"expr->STRING!\n");
         $$ = newASTNode(AST_CONSTANT);
         $$->valType = T_STRING;
         $$->strval = $1;
         ind = addString ( $1 );
         $$->ival = ind;
         ind++;
       }
       | expression PLUS expression
       {
         if (debug) fprintf(stderr,"expr->expr + expr!\n");
         $$ = newASTNode(AST_EXPRESSION);
         $$->child[0] = $1;
         $$->child[1] = $3;
       };
declarations: { $$ = 0; }
       | vardecl SEMICOLON declarations
       {
         //$$ = (char*) malloc( strlen( $1 ) + strlen( $3 ) + 50 );
         //sprintf( $$, "\t.text\n%s\n%s", $1, $3 );
         $1->next = $3;
         $$ = $1;
       };
vardecl: KWINT ID
       {
         //$$ = (char*) malloc( strlen( $2 ) + 100 );
         $$ = newASTNode(AST_VARDECL);
         $$ -> valType = T_STRING;
         $$ -> strval = $2;
         $$ -> ival = addSymbol(table, $2, 0, T_INT,0,0);
       }
       | KWCHARS ID
       {
         //$$ = (char*) malloc( strlen( $2 ) + 100 );
         $$ = newASTNode(AST_VARDECL);
         $$ -> valType = T_STRING;
         $$ -> strval = $2;
         $$ -> ival = addSymbol(table, $2, 0, T_STRING,0,0);
       };
parameters:
       { $$ = 0; }
       | vardecl
       {
         //$$ = (char*) malloc( strlen( $1 ) + 50 );
         //sprintf( $$, "%s", $1 );
         $$ = $1;
       }
       | vardecl COMMA parameters
       {
         //$$ = (char*) malloc( strlen( $1 ) + strlen( $3 ) + 50 );
         //sprintf( $$, "%s\n%s", $1, $3 );
         $1->next = $3;
         $$ = $1;
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
   int doAssembly = 1;
   yyparse();

   if (!doAssembly) {
      printASTree(root,0,stdout);
      return 0;
   }
   genCodeFromASTree(root,0,stdout);
   freeAllSymbols(table);
   free(table);
   yylex_destroy();
   return 0;

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
