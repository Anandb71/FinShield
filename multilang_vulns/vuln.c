#include <stdio.h>
void vuln(char *str) {
    // Format String Vulnerability
    printf(str);
}\n