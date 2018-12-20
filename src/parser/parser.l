%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "parser.y.h"
  char * make_strval(char*, unsigned);
%}


%%

\"(\\.|[^"])*\" {
  yylval.strval = make_strval(yytext, yyleng); 
  return STRING;
}
"global"|"extern" {
  yylval.strval = make_strval(yytext, yyleng); 
  return MODIFIER;
}
"section" {
  yylval.strval = make_strval(yytext, yyleng); 
  return SECTION_WORD;
}
[.][_a-zA-Z0-9]+ {
  yylval.strval = make_strval(yytext, yyleng); 
  return SECTION_NAME;
}
"db"|"dw"|"dd"|"dq"|"dt" {
  yylval.strval = make_strval(yytext, yyleng);
  return DATA_TYPE;
}
"mov"|"add"|"sub"|"push" {
  yylval.strval = make_strval(yytext, yyleng);
  return OPCODE;
}
"eax"|"ebx"|"ecx"|"edx" {
  yylval.strval = make_strval(yytext, yyleng);
  return REGISTER;
}
[0-9]+|(0[xX][0-9a-fA-F]+) {
  yylval.strval = make_strval(yytext, yyleng);
  return NUMBER;
}
\[[_a-zA-Z]+[_a-zA-Z0-9]*\] {
  yylval.strval = make_strval(yytext, yyleng);
  return MEMORY_CONTENT;
}
[_a-zA-Z]+[_a-zA-Z0-9]* {
  yylval.strval = make_strval(yytext, yyleng); 
  return LEGAL_NAME; 
}
":" {
  yylval.strval = make_strval(yytext, yyleng); 
  return COLON;
}                                
"," {
  yylval.strval = make_strval(yytext, yyleng); 
  return COMMA;
}                                 

[ \t]+ {

}

";".*\n|\n {
  yylval.strval = make_strval(yytext, yyleng); 
  return NEWLINE;
}

[.]+ {
  printf("parser error: unexpected [%s]\n", yytext);
}

%%

char * make_strval(char *yytext, unsigned yyleng){
  if(yytext == NULL)
    return 0;
  char *str = (char *)malloc(yyleng + 1);
  str[yyleng] = 0;
  strcpy(str, yytext);
  return str;
}

int yywrap(){
  return 1;
}