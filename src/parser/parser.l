%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "parser.y.h"
  #include <parser.h>
  #include <mugas_helper.h>
  #include <mugas.h>
  size_t line = 1;
  size_t column = 1;

  void store_token(token_t * token, char * text, size_t len){
    token->line = line;
    token->column = column - len;
    token->len = len;
    token->text = malloc(len+1);
    strcpy(token->text, text);
    token->text[len] = 0;
  }
  void ERROR_LEX(char * text, char * msg, size_t line, size_t column){
    ERROR(text, msg, line, column);
  }
  void DEBUG_LEX(char * fun_name, char * str){
    DEBUG(fun_name, str);
  }
%}

HEX (0X[0-9A-F]+)|(0x[0-9a-f]+)
DEC 0+|([1-9][0-9]*)
OCT 0[0-7]+
BIN 0[bB][01]+

NEWLINE \n
COLON \:
COMMA \,
OPEN_BRACKET \[
CLOSE_BRACKET \]
OPEN_PARENTHESES \(
CLOSE_PARENTHESES \)

PLUS \+
MINUS \-
MULTIPLY \*
DIVIDE \/
REMINDER \%


STRING \"(\\.|[^"])*\" 
COMMENT (\;|\#).+
SPACE [ \t]+
NAME [._@$0-9a-zA-Z]+

%%

{HEX} {
  column += yyleng;
  DEBUG_LEX(NULL, "[HEX]");
  
  size_t len = yyleng;
  
  long long int dec = strtoll(yytext, NULL, 0);
  
  if(!verify_number_size(dec)){
    ERROR_LEX(yytext, "integer overflow/underflow", line, column);
  }

  yylval.integer = malloc(sizeof(integer_token_t));
  yylval.integer->num = dec;
  store_token(&yylval.integer->token, yytext, yyleng);
  return INTEGER;
}

{DEC} {
  column += yyleng;
  DEBUG_LEX(NULL, "[DEC]");
  long long int dec = strtoll(yytext, NULL, 0);

  if(!verify_number_size(dec)){
    ERROR_LEX(yytext, "integer overflow/underflow", line, column);
  }

  yylval.integer = malloc(sizeof(integer_token_t));
  yylval.integer->num = dec;
  store_token(&yylval.integer->token, yytext, yyleng);
  
  return INTEGER;
}

{PLUS} {
  column += yyleng;
  DEBUG_LEX(NULL, "[PLUS]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return PLUS;
}
{MINUS} {
  column += yyleng;
  DEBUG_LEX(NULL, "[MINUS]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return MINUS;
}
{MULTIPLY} {
  column += yyleng;
  DEBUG_LEX(NULL, "[MULTIPLY]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return MULTIPLY;
}
{DIVIDE} {
  column += yyleng;
  DEBUG_LEX(NULL, "[DIVIDE]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return DIVIDE;
}
{REMINDER} {
  column += yyleng;
  DEBUG_LEX(NULL, "[REMINDER]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return REMINDER;
}
{OPEN_BRACKET} {
  column += yyleng;
  DEBUG_LEX(NULL, "[OPEN_BRACKET]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return OPEN_BRACKET;
}
{CLOSE_BRACKET} {
  column += yyleng;
  DEBUG_LEX(NULL, "[CLOSE_BRACKET]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return CLOSE_BRACKET;
}
{OPEN_PARENTHESES} {
  column += yyleng;
  DEBUG_LEX(NULL, "[OPEN_PARENTHESES]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return OPEN_PARENTHESES;
}
{CLOSE_PARENTHESES} {
  column += yyleng;
  DEBUG_LEX(NULL, "[CLOSE_PARENTHESES]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return CLOSE_PARENTHESES;
}
{COLON} {
  column += yyleng;
  DEBUG_LEX(NULL, "[COLON]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return COLON;
}
{COMMA} {
  column += yyleng;
  DEBUG_LEX(NULL, "[COMMA]");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return COMMA;
}
{NEWLINE} {
  line++;
  column = 1;
  DEBUG_LEX(NULL, "[NEWLINE]\n");
  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return NEWLINE;
}
{NAME} {
  column += yyleng;

  /* make a capitalized copy */
  char yytext_capital[yyleng+1];
  to_upper_case(yytext, yytext_capital);

  /* register -> capitalized */
  reg_t * reg = search_registers_table(yytext_capital);
  if(reg){
    DEBUG_LEX(NULL, "[REG]");
    yylval.reg = malloc(sizeof(reg_token_t));
    memcpy(&yylval.reg->reg, reg, sizeof(reg_t));
    store_token(&yylval.reg->token, yytext, yyleng);
    return REG;
  }

  /* instruction -> capitalized */
  else if(is_instruction_name(yytext_capital)){
    DEBUG_LEX(NULL, "[INST_NAME]");
    yylval.token = malloc(sizeof(token_t));
    store_token(yylval.token, yytext, yyleng);
    return OPCODE;
  }

  /* directive -> case sensitive */
  else if(is_directive_name(yytext)){
    DEBUG_LEX(NULL, "[DCV_NAME]");
    yylval.token = malloc(sizeof(token_t));
    store_token(yylval.token, yytext, yyleng);
    return DIRECTIVE;
  }

  /* label -> case sensitive */
  else {
    DEBUG_LEX(NULL, "[LABEL]");
    yylval.token = malloc(sizeof(token_t));
    store_token(yylval.token, yytext, yyleng);
    return LABEL;
  }
}
{STRING} {
  column += yyleng;
  DEBUG_LEX(NULL, "[STRING]");

  /* TODO handle escape chars */

  yylval.token = malloc(sizeof(token_t));
  store_token(yylval.token, yytext, yyleng);
  return STRING;
}
{SPACE} {
  column += yyleng;
}
{COMMENT} {
  column += yyleng;
}
. {
  column += yyleng;
  ERROR_LEX(yytext, "unknown symbol", line, column - yyleng);
}
%%

int yywrap(){
  return 1;
}
