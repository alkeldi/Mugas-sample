#ifndef mugas_helper_h
#define mugas_helper_h
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>
#include <stdio.h>
#include <parser.h>


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

/* get size in bits of an int */
static inline int get_number_size(long long int num){
  if(num <= 0xff && num >= -0xff)
    return 1;
  else if(num <= 0xffff && num >= -0xffff)
    return 2;
  else if(num <= 0xffffffff && num >= -0xffffffff)
    return 4;
  else if(num <= 0xffffffffffffffff && num >= -0xffffffffffffffff)
    return 8;
  else return -1;
}

/* debug */
static void DEBUG(char * fun_name, char * str){
  if(fun_name)
    printf("%s:\t%s", fun_name, str);
  else printf("%s", str);
}

static void ERROR(char * text, char * msg, size_t line, size_t column){
  if(text)
    fprintf(stderr, "[%02u:%02u] -> [%s] %s\n", line, column, text, msg);
  else fprintf(stderr, "[%02u:%02u] -> %s\n", line, column, msg);
  exit(1);
}

static void ERROR_WITH_TOKEN(token_t *token, char * msg){
  if(token)
    ERROR(token->text, msg, token->line, token->column);
  else {
    fprintf(stderr, "unexpected error: %s\n", msg);
    exit(1);
  }
}

static unsigned char hex_to_byte(char *hex)
{
  return (unsigned char)strtol(hex, NULL, 16);
}

static int is_hex_n(char *str, size_t n)
{
  if (!str)
    return 0;
  for (size_t i = 0; i < n; i++)
  {
    if (str[i] >= 48 && str[i] <= 57)
      continue;
    if (str[i] >= 65 && str[i] <= 70)
      continue;
    if (str[i] >= 97 && str[i] <= 102)
      continue;
    return 0;
  }
  return 1;
}
static int is_hex(char *str)
{
  return is_hex_n(str, strlen(str));
}
#endif