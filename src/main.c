#include <stdio.h>
extern int yylex (void);
int main(){
  printf("Hello World!\n");
  
  yylex();
}