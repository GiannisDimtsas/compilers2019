#ifndef YY_YY_MYPARSER_TAB_H_INCLUDED
# define YY_YY_MYPARSER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    OBJECT_BEGIN = 258,
    OBJECT_END = 259,
    ARRAY_BEGIN = 260,
    ARRAY_END = 261,
    USER_OBJECT = 262,
    RETWEET_OBJECT = 263,
    TWEET_OBJECT = 264,
    EXTENDED_TWEET_OBJECT = 265,
    SCREEN_NAME = 266,
    USER = 267,
    USER_ID = 268,
    ID_STR = 269,
    LOCATION = 270,
    CREATED_AT = 271,
    TRUNCATED = 272,
    TEXT_RANGE = 273,
    TRUE_V = 274,
    FALSE_V = 275,
    NULL_V = 276,
    COMMA = 277,
    COLON = 278,
    QUOTE = 279,
    LINTEGER = 280,
    FLOAT = 281,
    STRING_VALUE = 282,
    STRING_TAG = 283,
    DATE = 284,
    TEXT = 285,
    TWEET_TEXT = 286,
    FULL_TEXT = 287,
    ENTITIES = 288,
    INDICES = 289,
    HASHTAGS = 290
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE YYSTYPE;
union YYSTYPE
{
#line 45 "myParser.y" /* yacc.c:1909  */

    long long ival;
    double fval;
    char *sval;

#line 96 "myParser.tab.h" /* yacc.c:1909  */
};
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_MYPARSER_TAB_H_INCLUDED  */
