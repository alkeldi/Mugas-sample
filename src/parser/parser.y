%{
  #include <stdio.h>
  #include <stdlib.h>
  extern int yylex (void);
  void yyerror(char const *);
  
%}

%union {
  int intval;
  char *strval;
}

%token <strval> NUMBER STRING NAME OPERATOR;
%token <intval> OPEN_BRACKET CLOSE_BRACKET COLON COMMA NEWLINE;


%start all

%%

all: anything
anything:  NUMBER {
}
%%

void yyerror (char const *s) {
  //TODO add all malloced pointers into a list for cleanup
   fprintf (stderr, "[%s]\n", s);
}
