#include <stdio.h>
#include <mugas.h>
#include <mugas_log.h>
extern int yyparse (void);
int main()
{
  yyparse(); 
  print_all_lines(mugas_list);
}
