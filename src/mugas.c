#include <stdio.h>
#include <stdlib.h>
#include <DLList.h>
#include <mugas.h>

struct DLLNode *mugas_list;
struct DLLNode *mugas_allocated_lists;
struct DLLNode *mugas_allocated_values;
extern int yyparse(void);
void myfree(void * ptr){
  if(!ptr)
    return;
  free(ptr);
}

void mugas_parse()
{
  mugas_allocated_lists = (struct DLLNode*)DLList_init(NULL);
  mugas_allocated_values = (struct DLLNode*)DLList_init(NULL);
  yyparse();
}

void mugas_cleanup()
{
  /* values */
  struct DLLNode* iter = mugas_allocated_values->next;
  while(iter != mugas_allocated_values){
    myfree(iter->data);
    iter->data = NULL;
    iter = iter->next;
  }
  DLList_free(mugas_allocated_values);

  /* lists */
  iter = mugas_allocated_lists->next;
  while(iter != mugas_allocated_lists){
    DLList_free(iter->data);
    iter = iter->next;
  }
  DLList_free(mugas_allocated_lists);

}