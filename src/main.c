#include <stdio.h>
extern int yylex(void);
int main()
{
  int ntoken, vtoken;
  ntoken = yylex();
  while (ntoken)
  {
    printf("%d\n", ntoken);
    ntoken = yylex();
  }
}