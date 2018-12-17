%{

%}

SPECIFIRR ("global")|("extern")|("section")
NAME = "."?[_a-zA-Z][_a-zA-Z0-9]
NUMBER (("+"|"-")[1-9]+) | [0]

OPENING_BRACKET "["
CLOSING_BRACKET "["

DOUBLE_QUOTED_STRING \"(\\.|[^"])*\"
SINGLE_QUOTED_STRING \'(\\.|[^'])*\'

COLON ":"
SEMI_COLON ";"
COMMA ","
SPACE [ \t]*

%%


{SINGLE_QUOTED_STRING} {
  printf("single: %s\n", yytext);
}

{DOUBLE_QUOTED_STRING} {
  printf("double: %s\n", yytext);
}


\n {  }
. {  }

%%

int main(int argc, char **argv)
{
  yylex();
}
