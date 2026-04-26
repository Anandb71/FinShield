#include <iostream>
#include <cstring>
void process(char* input) {
    // Buffer Overflow
    char buffer[10];
    strcpy(buffer, input);
}\n