#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
        
    /*  main does not wait child and dies, 
    *   new child will be changed to a init's child and thus a daemon. */
    if (argc < 2) {
        fprintf(stderr,"Syntax: %s path-to-daemon..", argv[0]);
        return 1;
    }
    int pid = fork();
    if (pid == 0) {
        system(argv[1]);
        printf("Stopped daemon `%s'",argv[1]);
    } else {
        printf("Starting daemon `%s' .. (pid=%d)" ,argv[1], pid);
        return 0;
    }
    return 0;
}
