//Jason Miller
//hw1
//CS370

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//function to process each individual line given line and delimitor.
int processLine ( char *line, char *del );

//argc is the number of arguments passed
//argv is the argument values
int main ( int argc, char **argv ) {

   //maximum character count for line
   char line[ 1024 ];

   //delimitors specified by Dr. Cook
   char *del = " \t\r\n";

   //input file name
   FILE *inFile;

   //counters for number of lines and the number of words
   int numWords = 0, numLines = 0;

   //no arguments were given meaning argc is equal to 1
   if ( argc == 1 ) {

     fgets( line, sizeof( line ), stdin );
     numWords += processLine( line, del );
     numLines += processLine( line, "\n" );

   }//ends if statement

   //if 1 argument was given argc will be equal to 2
   else if ( argc == 2 ) {

     inFile = fopen ( argv[ 1 ], "r" );

     //if the argument cannot be opened, print an error message and exit.
     if ( inFile == NULL ) {

       printf( "ERROR: The file could not be opened." );
       return -1;
       exit(0);

     }//ends inner if

     //this part reads in the file.
     while ( fgets( line, sizeof( line ), inFile ) != NULL ) {

       //we have to check if it is a blank line
       int i = 0;
       while ( line[ i ] == '\n' ) {

         numLines++;
         i++;

       }//ends while

       numWords += processLine( line, del );
       numLines += processLine( line, "\n" );

     }//ends while loop

     //closing the file.
     fclose( inFile );

   }//ends outer if

   //if more than 1 argument was given provide an error and usage message then exit.
   else if ( argc > 2 ) {

     printf( "ERROR: More than one argument was provided.\n" );
     printf( "usage: ./myprogram argument" );
     return -1;
     exit(0);

   }//ends last if

   //output two numbers separated by one tab character, and followed by one newline character
   printf( "%d\t%d\n", numWords, numLines );

   //return 0 if processed correctly
   return 0;

}//ends the main

//function to process each individual line given line and delimitor.
int processLine ( char *line, char *del ) {

   //this will count the number of tokens.
   int count = 0;

   //pointer to move across the line
   char *t;

   t = strtok( line, del );
   //will stop at NULL
   while ( t != NULL ) {

      count++;
      t = strtok( NULL, del );

   }//ends while
   return count;

}//ends processLine
