//Jason Miller
//program2.c
//recursive descent parser
//program 2 CS370
//Sep 20, 2021
/*
* S -> A B '\n'
* A -> a A | empty
* B -> b B | empty
* alphabet {'a', 'b', and '\n'}
*/

//include necessary libraries
#include <stdio.h>
#include <stdlib.h>

//function prototypes
void match ( int terminal );
void nontermS();
int nontermA();
int nontermB();

//global variable lookahead
int lookahead;

//function for nonterminal S
// S -> A B '\n'
void nontermS() {

  int countofa = 0, countofb = 0;

  if ( lookahead == 'a' ) {

    countofa = nontermA();

  }//ends if for char 'a'

  if ( lookahead == 'b' ) {

    countofb = nontermB();

  }//ends if for char 'b'

  if ( lookahead == '\n' ) {

    printf( "The total count for character (a) is: %d.\nThe total count for character (b) is %d.\n", countofa, countofb );

  }//ends if for char '\n'

  else {

    printf( "The character (%c) failed to match. It's count from the beginning of the line: %d\n", lookahead, countofa + countofb + 1 );
    match( '\n' );

  }//ends else

}//ends function nontermS

//function for nonterminal A which returns count of character 'a'
//A -> a A | empty
int nontermA() {

  switch ( lookahead ) {

    case 'a': match( 'a' ); return 1 + nontermA(); break;
    default: return 0;

  }//ends switch statement

}//ends function nontermA

// B -> b B | empty
//function for nontermB which returns count of character 'b'
int nontermB() {

  switch ( lookahead ) {

    case 'b': match( 'b' ); return 1 + nontermB(); break;
    default: return 0;

  }//ends switch statement

}//ends nontermB

//function to match lookahead to terminal
void match ( int terminal ) {

  if ( lookahead == terminal ) {

    lookahead = getchar();

  }//ends if

  else {

    exit(0);

  }//ends else

}//ends match function

//begin main
int main ( int argc, char **argv ) {

  lookahead = getchar();

  do {

    nontermS();
    lookahead = getchar();

  } while ( lookahead != EOF );

}//ends main
