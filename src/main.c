#include <stdio.h>
#include <mugas.h>
#include <mugas_log.h>
int main()
{
  mugas_init();
  mugas_parse();
  mugas_cleanup();
}
