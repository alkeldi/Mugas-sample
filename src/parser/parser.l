%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "parser.y.h"
  #include <mugas_types.h>
  #include <mugas_helper.h>
  #include <mugas.h>

  size_t line = 1;
  size_t column = 1;
%}

HEX ((0X[0-9A-F]+)|(0x[0-9a-f]+))
DEC (0+|([1-9][0-9]*))
OCT (0[0-7]+)
BIN (0[bB][01]+)
NUMBER {HEX}|{DEC}|{OCT}|{BIN}

NEWLINE \n
COLON \:
COMMA \,
OPEN_BRACKET \[
CLOSE_BRACKET \]

OPERATOR \+|\-|\*

STRING \"(\\.|[^"])*\" 
COMMENT (\;|\#).+
SPACE [ \t]+
NAME [._@$0-9a-zA-Z]+

%%

{NUMBER} {
  column += yyleng;
  printf("[NUMBER]");
}
{OPERATOR} {
  column += yyleng;
  printf("[OPERATOR]");
}
{OPEN_BRACKET} {
  column += yyleng;
  printf("[OPEN_BRACKET]");
}
{CLOSE_BRACKET} {
  column += yyleng;
  printf("[CLOSE_BRACKET]");
}
{COLON} {
  column += yyleng;
  printf("[COLON]");
}
{COMMA} {
  column += yyleng;
  printf("[COMMA]");
}
{NEWLINE} {
  line++;
  column = 0;
  printf("[NEWLINE]\n");
}
{NAME} {
  column += yyleng;

  /* make a capitalized copy */
  char yytext_capital[yyleng+1];
  to_upper_case(yytext, yytext_capital);

  /* register -> capitaalized */
  registers_table_entry_t * reg = search_registers_table(yytext_capital);
  if(reg){
    printf("[REG]");
  }

  /* instruction -> capitaalized */
  else if(is_instruction_name(yytext_capital)){
    printf("[INST_NAME]");
  }

  /* directive -> case sensitive*/
  else if(is_directive_name(yytext)){
    printf("[DCV_NAME]");
  }

  /* label -> case sensitive */
  else printf("[LABEL]");
}

{STRING} {
  column += yyleng;
  printf("[STRING]");
}
{SPACE}|{COMMENT} {}


. {
  column += yyleng;
  fprintf(stderr, "\nERROR at %u:%u\n", line, column);
}
%%

int yywrap(){
  return 1;
}