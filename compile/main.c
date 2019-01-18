#include <stdio.h>
#include <stdlib.h>
#include <string.h>
struct mine_st {
    int i8;
    char *ha;
};

char list[64];
char haha[] = "Haha = lol";
int main(){
    struct mine_st  myst;
    myst.i8 = 5;
    printf("Hello World!\n");
    char *alc = malloc(50);
    memset(alc, 0, 50);
    float a = 3.5;
    float b = 5.55555;
    float c = a+b;
    size_t d = sizeof(haha);
    return 10;

}
