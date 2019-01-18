#ifndef mugas_helper_h
#define mugas_helper_h
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* check if empty or commented line */
static int is_ignored(char *line, size_t len)
{
  if (!line)
    return -1;
  int ignore = 0;
  for (int i = 0; i < len; i++)
  {
    if (ignore)
      break;
    else if (i == len - 1 && line[i] == '\n')
      ignore = 1;
    else if (line[i] == '#')
      ignore = 1;
    else if (line[i] == ' ' || line[i] == '\t')
      continue;
    else
      break;
  }
  return ignore;
}

/* right trim by just moving the string null terminator */
static size_t rtrim(char *str)
{
  size_t len = 0;
  if (!str || !(len = strlen(str)))
    return 0;
  size_t new_len = len;
  for (int i = len - 1; i >= 0; i--)
  {
    if (str[i] == ' ' || str[i] == '\t' || str[i] == '\n')
      new_len--;
    else
      break;
  }
  str[new_len] = '\0';
  return new_len;
}

/* convert a string into uppercase */
static void to_upper_case(char *src, char *dst)
{
  if (!src || !dst)
    return;
  
  int i = 0;
  while(src[i]){
    dst[i] = toupper(src[i]);
    i++;
  }
  dst[i] = 0;
}
#endif