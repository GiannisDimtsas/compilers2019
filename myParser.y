%{ 
    //C libraries
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include <malloc.h> 

    //Declare functions and variables that Flex and Bison need to know
    void yyerror(const char* msg); //this function takes as input a string and prints an error message
    extern int yylex();
    extern int yyparse();
    //yyin and yyout are variables responible to read and write to the appropriate file  
    extern FILE *yyin;   
	extern FILE *yyout;
    
	extern bool retweet;
	extern bool range;
%}


//Here we declare variables that are global to the parser
%code top {
    typedef int bool; //C doesn't support bool variables, so we make them with enum
    enum { false, true };

    //Arrays responsible for "id", "id_str" and "name"
    long long *ids;
	int text_range[2];
	int text_counter = 0;
    char **id_str;
    char **username;

    int numbOfstr = 0;
    int id_counter = 0;
    int name_counter = 0;

    bool id = false;
    bool name = false;
    bool screen_name = false;
    bool location = false;
}


//Specifies the entire collection of possible data types for semantic values
%union {
    long long ival;
    double fval;
    char *sval;
}

//Define the tokens that are going to be used:
%token OBJECT_BEGIN 
%token OBJECT_END
%token ARRAY_BEGIN 
%token ARRAY_END
%token USER_OBJECT 
%token RETWEET_OBJECT 
%token TWEET_OBJECT 
%token EXTENDED_TWEET_OBJECT
%token SCREEN_NAME
%token USER 
%token USER_ID 
%token ID_STR 
%token LOCATION 
%token CREATED_AT 
%token TRUNCATED 
%token TEXT_RANGE
%token TRUE_V 
%token FALSE_V
%token NULL_V
%token COMMA 
%token COLON
%token QUOTE;
%token LINTEGER 
%token FLOAT
%token STRING_VALUE 
%token STRING_TAG 
%token DATE 
%token TEXT 
%token TWEET_TEXT
%token FULL_TEXT
%token ENTITIES
%token INDICES
%token HASHTAGS


//Define the type of the above tokens
%type <ival> LINTEGER
%type <fval> FLOAT
%type <sval> STRING_VALUE
%type <sval> STRING_TAG
%type <sval> DATE
%type <sval> TEXT
%type <sval> TWEET_TEXT

//Indicate the initial rule:
%start json

%%

//At first we can have an object or an array:
json: object | array 
;

//Objects are either filled with content or not:
object: OBJECT_BEGIN OBJECT_END
|OBJECT_BEGIN content OBJECT_END
;

//Arrays are either filled with items or not 
array: ARRAY_BEGIN ARRAY_END 
|ARRAY_BEGIN items ARRAY_END 
;

//It is possible to have one pair of values or more seperated by comma:
content: pair //generic pair
| pair COMMA content
| user //pair specified for the user object
| user COMMA content
| retweet //pari specified for the retweet object
| retweet COMMA content
| extended  //pair specifiedfor the extended tweet object
| extended COMMA content
;


//The pair format is defined below:
pair: STRING_TAG value 
|TEXT STRING_VALUE //Checks if the lenght of the text is smaller than 140 characters
{ 
	if(strlen($2) >= 141) { 
		yyerror("The text field can't be bigger than 140 characters."); 
		free($2);
    }
	free($1);
	free($2);
}
|ID_STR STRING_VALUE  //Checks if the "id_str" is unique
{ 
	int i;
	id_str = (char **)realloc(id_str, (numbOfstr + 1)); //allocate space for the id_str
	if(id_str == NULL) { //check if the realloc failed to allocate space for the new id_str
    perror("Realloc failed\n");
    exit(1);
	}
	*(id_str + numbOfstr) = (char *)malloc(strlen($2)*sizeof(char)+3); 
	strcpy(*(id_str + numbOfstr),$2);
	for(i = 0; i <= numbOfstr; i++){ //check all the previous id_str's in case the current id_str is identical with a previous one
		if(strcmp(*(id_str + i), *(id_str + numbOfstr)) == 0 && i != numbOfstr){
			yyerror("Tweets can't have the same ID.\n"); //if there is throw an error.
		}
	}
	++numbOfstr; 
	free($2);
}
|CREATED_AT  DATE //This rule matches the tag "created_at" with the date if and only if the date haw the apropriate format
{
    free($2);
}
|ENTITIES OBJECT_BEGIN content OBJECT_END;
|HASHTAGS ARRAY_BEGIN hashtags_content ARRAY_END
|HASHTAGS ARRAY_BEGIN ARRAY_END
;

//It is possible an array to have one value or more seperated by comma:
items: value 
| value COMMA items
;

//Rule to match user object and checks all the limitations
user: USER_OBJECT OBJECT_BEGIN user_content OBJECT_END{
	int i;
	//user object needs to contain the variables id, name, location, screen_name unless the user profile appears inside a retweet object 
	if(id == true && name == true && location == true && screen_name == true){
		for(i = 0; i <= id_counter; i++){ //check if the user id doesnt belong to another user 
			if(ids[i] == ids[id_counter-1] && i != id_counter-1 && strcmp(*(username + i), *(username + id_counter -1)) != 0)
			{
				yyerror("Users can't have the same id."); //if it is throw an error
			}
		}
	}else if(id == false && name == false && location == false && retweet == true) { 
		break;
	}	
	else { 
		yyerror("User information is incomplete!\n");
	}
	//we set again the variables to false in order to use them for the next user inside the json file
	name = false; id = false; location = false; screen_name = false;
}

//It is possible for the user object to have one value or more seperated by comma:
user_content: user_value
| user_value COMMA user_content
;

//The following is pairs that a user object must have in some cases. Also a user 
//object can have a pair as we have declare above
user_value: pair
|USER_ID LINTEGER //Stores the id value into an array 
{
	ids = realloc(ids, (id_counter + 1) * sizeof(long long)); //allocate space for the user id
	if( $2 <= 0 ){ //checks if the user id is positive 
		yyerror("User can't have negative id.");
	}else{ 
		*(ids+id_counter) = $2;
		 ++id_counter;
	}
	id = true;
	//the  checking for unique id will be done later, for now we just insert the id into the array
}
|USER STRING_VALUE //Stores the name of the user into an array
{
	username = (char **)realloc(username, (name_counter + 1)); //allocate space for the user name
	if(username == NULL) { //if allocation fails throw an error
    	perror("Realloc failed\n");
   		exit(1);
	}
  	*(username + name_counter) = (char *)malloc(strlen($2)*sizeof(char)+3);
	strcpy(*(username + name_counter),$2);
	name_counter++;
	free($2);
	name = true;
}
|SCREEN_NAME STRING_VALUE { //Just matches the rule and change the the variable screen_name to true
	screen_name = true;
}
|LOCATION STRING_VALUE { //Just matches the rule and change the the variable location to true
	location = true;
}
;

//A rule to match tweet or retweeted_status objects
retweet: RETWEET_OBJECT OBJECT_BEGIN retweet_value OBJECT_END { 
    retweet = false; 
}
| TWEET_OBJECT OBJECT_BEGIN tweet_value OBJECT_END { 	
    retweet = false;
}
;

//A retweeted_status object must have text field and the user that posted the tweet
retweet_value: TEXT STRING_VALUE COMMA user_retweet {
	if(strlen($2) >= 140) { 
		yyerror("The text field can't be bigger than 140 characters."); 
		free($2);
	}
    free($2);
}
;

user_retweet: USER_OBJECT OBJECT_BEGIN  SCREEN_NAME STRING_VALUE  OBJECT_END{
	screen_name = true;
}

//A tweet object must have text field and the user that posted the tweet
tweet_value: TEXT TWEET_TEXT COMMA user_retweet {
    if(strlen($2) >= 140) { 
		yyerror("The text field can't be bigger than 140 characters."); 
		free($2);
	}
    free($2);
}

//A rule to match extended tweet objects
extended: EXTENDED_TWEET_OBJECT OBJECT_BEGIN extended_content OBJECT_END {
	retweet = false;
}
;

//It is possible an extended object to have one value or more seperated by comma:
extended_content: extended_values
| extended_values COMMA extended_content
;

//An extended tweet must have full_text field and entities or any other pair
extended_values: TRUNCATED TRUE_V {
	if(range == false){
		yyerror("You must include the text range");
	}
}
| TRUNCATED FALSE_V //If false, will do nothing
| TEXT_RANGE ARRAY_BEGIN integers ARRAY_END //Array consist from integers for the "display_text_range" field
| FULL_TEXT STRING_VALUE //Checks if the lenght of the text is smaller than 140 characters
{	
	if(strlen($2) >= 140) { 
		yyerror("The text field can't be bigger than 140 characters."); 
		free($2);
	}
    free($2);
}
| entities //entities contain the hashtag that appear in full_text field and their position
;

entities: ENTITIES OBJECT_BEGIN hashtags OBJECT_END
;

hashtags: HASHTAGS ARRAY_BEGIN hashtags_content ARRAY_END
;

hashtags_content:  hashtags_info
| hashtags_info COMMA hashtags_content
;

//Rule that matches hashtag info. It says in which places at the text the hashtags appears
hashtags_info: OBJECT_BEGIN TEXT STRING_VALUE COMMA INDICES ARRAY_BEGIN integers ARRAY_END OBJECT_END
;

//The integer values for an array consist only with integers
integers: LINTEGER { text_range[text_counter] = $1; text_counter++; }
| LINTEGER COMMA integers { text_range[text_counter] = $1; text_counter++; }
;

//The type of values that are acceptable and can be handled from the parser:
value: STRING_TAG
| STRING_VALUE
| LINTEGER  
| FLOAT 
| object 
| array 
| TRUE_V 
| FALSE_V 
| NULL_V 
;
%%

int main(int argc, char *argv[]){  

	//Opening a file with the NAME:"log.txt" in order to print the input
	//and also the errors that maybe be occur
    yyout = fopen("log.txt", "w+");

	//The program will exit if it can't open the file 
     if (yyout == NULL) {
        printf("Error opening file!\n");
        exit(1);
	}
    
    //Opening a file with the NAME: "JsonInput.txt" in order to read the Json file
    yyin = fopen(argv[1], "r");

    //The program will exit if it can't open the file 
     if (yyin == NULL) {
        printf("Error opening file!\n");
        exit(1);
	}
    
    // Parse through the input:
    yyparse();
  
    //Closing the files that we open earlier
    fclose(yyin);  
    fclose(yyout);
	
    return 0;
}

//Function that print the error messege whenever it occurs while the program is running
//The program  exit if an error occurs
extern int lineNumber;
void yyerror(const char *msg) {
    fprintf(yyout," [line %d]: %s\n", lineNumber, msg);
	exit(1); 
}

