#include <stdio.h>
#include <mugas.h>
#include <mugas_log.h>
int main()
{
  mugas_parse();
  mugas_log();
  mugas_cleanup();
}
