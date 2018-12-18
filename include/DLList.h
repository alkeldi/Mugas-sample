#ifndef DLList_h
#define DLList_h

#include <stdlib.h>

/* 
 * Doubly linked list node structure.
 */
typedef struct DLLNode
{
  void *data;
  struct DLLNode *next;
  struct DLLNode *prev;
} DLLNode;

/*
 * Doubly linked list initializer.
 * data: optional data to store in the sentinel.
 * return value: the sentinel node of the doubly linked list.
 */
DLLNode *DLList_init(void *data)
{
  DLLNode *node = (DLLNode *)malloc(sizeof(DLLNode));
  node->next = node;
  node->prev = node;
  node->data = data;
  return node;
}

/*
 * Add an element at the end of the doubly linked list.
 * list: the sentinel of the doubly linked list.
 * data: data to add to the list.
 * return value: the newly created node, which contains the data.
 */
DLLNode *DLList_addEnd(DLLNode *list, void *data)
{
  if (!list)
    return NULL;

  DLLNode *node = (DLLNode *)malloc(sizeof(DLLNode));
  node->data = data;
  node->prev = list->prev;
  node->next = list;
  list->prev->next = node;
  list->prev = node;

  return node;
}

/*
 * Add an element at the beginning of the doubly linked list.
 * list: the sentinel of the doubly linked list.
 * data: data to add to the list.
 * return value: the newly created node, which contains the data.
 */
DLLNode *DLList_addFront(DLLNode *list, void *data)
{
  if (!list)
    return NULL;

  DLLNode *node = (DLLNode *)malloc(sizeof(DLLNode));
  node->data = data;
  node->prev = list;
  node->next = list->next;
  list->next->prev = node;
  list->next = node;

  return node;
}

/*
 * Remove an element from the doubly linked list.
 * list: the sentinel of the doubly linked list.
 * node: a doubly linked list node to be removed from the list.
 *       if the node and the list have the same memory address, no action is taken.
 * return value: 1 on success, 0 on failure.
 */
int DLList_remove(DLLNode *list, DLLNode *node)
{
  if (!node || !list || list == node)
    return 0;

  node->next->prev = node->prev;
  node->prev->next = node->next;
  free(node);
  node = NULL;
  return 1;
}

/*
 * Remove the entire doubly linked list.
 * list: the sentinel of the doubly linked list.
 * return value: 1 on success, 0 on failure.
 */
int DLList_free(DLLNode *list)
{
  if (!list)
    return 0;
    
  DLLNode *iter = list->next;
  while (iter != list)
  {
    /* free all nodes */
    if (!DLList_remove(list, iter))
      return 0;
  }

  /* free the sentinel */
  free(list);
  list = NULL;
}

#endif