%option noyywrap
%{ 
    //C libraries
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include <malloc.h> 

    #include "myParser.tab.h"  

    //Declare functions and variables that Flex and Bison that is going to be used later
    void yyerror(const char* msg); //this function take as input a string and return an error message at the point in which the error accures
    void placing_tabs(int num); //this function puts the appropriate number of tabs 
    void print_string(char* str); //this function prints string values

    extern int yylex();
    extern int yyparse();

    //yyin and yyout are variables responible to read and write to the appropriate files
    extern FILE *yyin;   
	  extern FILE *yyout;
    
    //C doesn't support bool variables, so we make them with enum
    typedef int bool;
    enum { false, true };

    bool retweet = false;
    bool range = false;

    extern int profile_info;
	  extern bool retweet;
	  extern bool range;

    int retweet_st = 0;
    int lineNumber = 1;
    int number_of_objects = -1;
%}


ACCEPTABLE_CHARS [^"\\] 
ESCAPE_CHAR \\["\\\/bfnrtu]
CHAR {ESCAPE_CHAR}|{ACCEPTABLE_CHARS}
CHARS {CHAR}+
DOUBLE_QUOTE \"
COLON \:

%%
{DOUBLE_QUOTE}created_at{DOUBLE_QUOTE}{COLON} { //Recognizes "created_at": and returns a token to Bison
  placing_tabs(number_of_objects);
  ECHO; //ECHO print the string that recognized, in that case prints 
        //"created_at": .The same is applied for the rest of the code 
  return CREATED_AT;
}

{DOUBLE_QUOTE}id_str{DOUBLE_QUOTE}{COLON} { //Recognizes "id_str": and returns a token to Bison
  //yylval.sval = strdup(yytext); //Return a copy of the string to Bison in order to check if the id_str is unique
  placing_tabs(number_of_objects);
  ECHO;
  return ID_STR;
}

{DOUBLE_QUOTE}text{DOUBLE_QUOTE}{COLON} { //Recognizes "text": tag and returns a token to Bison
  //yylval.sval = strdup(yytext);
  placing_tabs(number_of_objects);
  ECHO;
  return TEXT;
}

{DOUBLE_QUOTE}user{DOUBLE_QUOTE}{COLON} { //Recognizes "user": and returns a token to Bison 
  placing_tabs(number_of_objects); 
  ECHO;
  return USER_OBJECT;
}

{DOUBLE_QUOTE}id{DOUBLE_QUOTE}{COLON} { //Recognizes "id": and returns a token to Bison
  placing_tabs(number_of_objects);
  ECHO;
  return USER_ID;
}

{DOUBLE_QUOTE}name{DOUBLE_QUOTE}{COLON} { //Recognizes "name": and returns a token to Bison
  //yylval.sval = strdup(yytext);
  placing_tabs(number_of_objects);
  ECHO;
  return USER;
}

{DOUBLE_QUOTE}screen_name{DOUBLE_QUOTE}{COLON} { //Recognizes "screen_name": and returns a token to Bison
  //yylval.sval = strdup(yytext);
  placing_tabs(number_of_objects);
  ECHO;
  return SCREEN_NAME;
}

{DOUBLE_QUOTE}location{DOUBLE_QUOTE}{COLON} { //Recognizes "location": and returns a token to Bison
  //yylval.sval = strdup(yytext);
  placing_tabs(number_of_objects);
  ECHO;
  return LOCATION;
}

{DOUBLE_QUOTE}retweeted_status{DOUBLE_QUOTE}{COLON} { //Recognizes "retweeted_status": and returns a token to Bison
  placing_tabs(number_of_objects);
  retweet = true; //we want to make clear to the parser that there is a retweet object
  ECHO;
  return RETWEET_OBJECT;
}

{DOUBLE_QUOTE}tweet{DOUBLE_QUOTE}{COLON} { //Recognizes "tweet": and returns a token to Bison
  placing_tabs(number_of_objects);
  retweet = true; //we want to make clear to the parser that there is a retweet object
  ECHO;
  return TWEET_OBJECT;
}

{DOUBLE_QUOTE}(RT)[ ](@){CHARS}{DOUBLE_QUOTE} { //Recognizes RT + @author + text and returns a token to Bison
  yylval.sval = strdup(yytext);
  ECHO;
  return TWEET_TEXT;
}

{DOUBLE_QUOTE}display_text_range{DOUBLE_QUOTE}{COLON} { //Recognizes "display_text_range" and returns a token to bison
  placing_tabs(number_of_objects);
  ECHO;
  return TEXT_RANGE;
}

{DOUBLE_QUOTE}extended_tweet{DOUBLE_QUOTE}{COLON} { //Recognizes "extended_tweet" and returns a token to bison
  retweet = true;
  placing_tabs(number_of_objects);
  ECHO;
  return EXTENDED_TWEET_OBJECT;
}

{DOUBLE_QUOTE}full_text{DOUBLE_QUOTE}{COLON} { //Recognizes "full_text": and returns a token to Bison
  placing_tabs(number_of_objects);
  ECHO;
  return FULL_TEXT;
}

{DOUBLE_QUOTE}entities{DOUBLE_QUOTE}{COLON} { //Recognizes "entities": and returns a token to Bison
  placing_tabs(number_of_objects);
  ECHO;
  return ENTITIES;
}

{DOUBLE_QUOTE}hashtags{DOUBLE_QUOTE}{COLON} { //Recognizes "hashtags": and returns a token to Bison
  placing_tabs(number_of_objects);
  ECHO;
  return HASHTAGS;
}

{DOUBLE_QUOTE}indices{DOUBLE_QUOTE}{COLON} { //Recognize "indices": and returns a token to Bison
  placing_tabs(number_of_objects);
  ECHO;
  return INDICES;
}

[-+]?[0-9]+ { /*Rule that recognize integers and reterns them to the bison parser*/
  yylval.ival = atoll(yytext);
  ECHO;
  return LINTEGER; 
}

[-+]?[0-9]*\.?[0-9]*([eE][-+]?[0-9]+)? { /*Rule that recognize floating point numbers and reterns them to the bison parser*/
  yylval.fval = atof(yytext); //converts stings to integes and returns them to parser
  ECHO;
  return FLOAT; 
}


{DOUBLE_QUOTE}(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[ ](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ](0[1-9]|[12][0-9]|3[01])[ ](0[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])[ ](\+)([0-9][0-9][0-9][0-9])[ ]([12][0-9][0-9][0-9]){DOUBLE_QUOTE} {
  //Recognizes the date in the appropriate form and returns a token to Bison
  yylval.sval = strdup(yytext);
  ECHO;
  return DATE;
}

{DOUBLE_QUOTE}{DOUBLE_QUOTE}|{DOUBLE_QUOTE}{CHARS}{DOUBLE_QUOTE} {  //Recognizes the empty string or a string based on the grammar that we have made at the start of the program
  yylval.sval = strdup(yytext);
  ECHO;
  return STRING_VALUE;
}

{DOUBLE_QUOTE}{CHARS}{DOUBLE_QUOTE}{COLON} {  //Recognize strings that are tags we do not know their names initialy (and we dont have to)
  placing_tabs(number_of_objects);   
  yylval.sval = strdup(yytext);
  ECHO;
  return STRING_TAG;
}

{DOUBLE_QUOTE} { //recognize quote symbol
  return QUOTE;
}

{COLON} { //recognize colon symbol
  ECHO;
  return COLON;
}

"{" {
  ++number_of_objects; //whenever the open bracket is recognized the variable number_of_objects must be increased by one
  placing_tabs(number_of_objects);
  ECHO;
  return OBJECT_BEGIN;
}

"}" {
placing_tabs(number_of_objects);
number_of_objects--; //whenever the closed bracket is recognized the variable number_of_objects must be reduced by one
ECHO;
return OBJECT_END;
}

"[" {
  ECHO;
  return ARRAY_BEGIN;
}

"]" {
  ECHO;
  return ARRAY_END;
}

true {
  ECHO;
  return TRUE_V;
}

false {
  ECHO;
  return FALSE_V;
}

null {
  ECHO;
  return NULL_V;
}

"," {
  ECHO;
  return COMMA;
}

[ \t] {}

\n {
  ECHO;
  lineNumber++; //we count the number of lines in order to tell in which line an error occurs
}

. return yytext[0];
%%

//a function that places tabs before tags accordin to the number of object that exist 
void placing_tabs(int num){
  int i;
  for(i = 0;i < number_of_objects; i++){
    fprintf(yyout,"\t");
  }
}
