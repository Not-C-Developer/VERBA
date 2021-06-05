#ifndef _PAM_PRIVATE_H
#define _PAM_PRIVATE_H

#include <syslog.h>

#define PAM_CONFIG    "/etc/pam.conf"
#define PAM_CONFIG_D  "/etc/pam.d"
#define PAM_CONFIG_DF "/etc/pam.d/%s"
#define PAM_DEFAULT_SERVICE        "other"
#define PAM_DEFAULT_SERVICE_FILE   PAM_CONFIG_D "/" PAM_DEFAULT_SERVICE

#ifdef PAM_LOCKING
#define PAM_LOCK_FILE "/var/lock/subsys/PAM"
#endif

#define _PAM_INVALID_RETVAL  -1

struct handler {
	int handler_type;
	int (*func)(pam_handle_t *pamh, int flags, int argc, char **argv);
	int actions[_PAM_RETURN_VALUES];
	int cached_retval; int *cached_retval_p;
	int argc;
	char **argv;
	struct handler *next;
	char *mod_name;
	int stack_level;
};

#define PAM_HT_MODULE       0
#define PAM_HT_MUST_FAIL    1
#define PAM_HT_SUBSTACK     2
#define PAM_HT_SILENT_MODULE 3

struct loaded_module {
	char *name;
	int type;
	void *dl_handle;
};

#define PAM_MT_DYNAMIC_MOD 0
#define PAM_MT_STATIC_MOD  1
#define PAM_MT_FAULTY_MOD 2

struct handlers {
	struct handler *authenticate;
	struct handler *setcred;
	struct handler *acct_mgmt;
	struct handler *open_session;
	struct handler *close_session;
	struct handler *chauthtok;
};

struct service {
	struct loaded_module *module;
	int modules_allocated;
	int modules_used;
	int handlers_loaded;
	struct handlers conf;
	struct handlers other;
};

#define PAM_ENV_CHUNK         10

struct pam_environ {
	int entries;
	int requested;
	char **list;
};

#include <sys/time.h>

typedef enum { PAM_FALSE, PAM_TRUE } _pam_boolean;

struct _pam_fail_delay {
	_pam_boolean set;
	unsigned int delay;
	time_t begin;
	const void *delay_fn_ptr;
};

struct _pam_substack_state {
	int impression;
	int status;
};

struct _pam_former_state {
	int choice;
	int depth;
	int impression;
	int status;
	struct _pam_substack_state *substates;
	int fail_user;
	int want_user;
	char *prompt;
	_pam_boolean update;
};
#ifndef OLD_DISTRO
struct pam_handle {
	char *authtok;
	unsigned caller_is;
	struct pam_conv *pam_conversation;
	char *oldauthtok;
	char *prompt;
	char *service_name;
	char *user;
	char *rhost;
	char *ruser;
	char *tty;
	char *xdisplay;
	char *authtok_type;
	struct pam_data *data;
	struct pam_environ *env;
	struct _pam_fail_delay fail_delay;
	struct pam_xauth_data xauth;
	struct service handlers;
	struct _pam_former_state former;
	const char *mod_name;
	int mod_argc;
	char **mod_argv;
	int choice;
#ifdef HAVE_LIBAUDIT
	int audit_state;
#endif
};
#else
struct pam_handle {
	char *authtok;
	unsigned caller_is;
	struct pam_conv *pam_conversation;
	char *oldauthtok;
	char *prompt;
	char *service_name;
	char *user;
	char *rhost;
	char *ruser;
	char *tty;
	struct pam_data *data;
	struct pam_environ *env;
	struct _pam_fail_delay fail_delay;
	struct service handlers;
	struct _pam_former_state former;
	const char *mod_name;
	int choice;
#ifdef HAVE_LIBAUDIT
	int audit_state;
#endif
};
#endif

#define PAM_NOT_STACKED   0
#define PAM_AUTHENTICATE  1
#define PAM_SETCRED       2
#define PAM_ACCOUNT       3
#define PAM_OPEN_SESSION  4
#define PAM_CLOSE_SESSION 5
#define PAM_CHAUTHTOK     6
#define _PAM_ACTION_IS_JUMP(x)  ((x) > 0)
#define _PAM_ACTION_IGNORE      0
#define _PAM_ACTION_OK         -1
#define _PAM_ACTION_DONE       -2
#define _PAM_ACTION_BAD        -3
#define _PAM_ACTION_DIE        -4
#define _PAM_ACTION_RESET      -5
#define _PAM_ACTION_UNDEF      -6
#define PAM_SUBSTACK_MAX_LEVEL 16

extern const char * const _pam_token_actions[-_PAM_ACTION_UNDEF];
extern const char * const _pam_token_returns[_PAM_RETURN_VALUES+1];

int _pam_dispatch(pam_handle_t *pamh, int flags, int choice);
int _pam_free_handlers(pam_handle_t *pamh);
int _pam_init_handlers(pam_handle_t *pamh);
void _pam_start_handlers(pam_handle_t *pamh);
int _pam_make_env(pam_handle_t *pamh);
void _pam_drop_env(pam_handle_t *pamh);
void _pam_reset_timer(pam_handle_t *pamh);
void _pam_start_timer(pam_handle_t *pamh);
void _pam_await_timer(pam_handle_t *pamh, int status);

typedef void (*voidfunc(void))(void);
typedef int (*servicefn)(pam_handle_t *, int, int, char **);
#ifdef PAM_STATIC
struct pam_module * _pam_open_static_handler (pam_handle_t *pamh, const char *path);
voidfunc *_pam_get_static_sym(struct pam_module *mod, const char *symname);
#else
void *_pam_dlopen (const char *mod_path);
servicefn _pam_dlsym (void *handle, const char *symbol);
void _pam_dlclose (void *handle);
const char *_pam_dlerror (void);
#endif

struct pam_data {
	char *name;
	void *data;
	void (*cleanup)(pam_handle_t *pamh, void *data, int error_status);
	struct pam_data *next;
};

void _pam_free_data(pam_handle_t *pamh, int status);
char *_pam_StrTok(char *from, const char *format, char **next);
char *_pam_strdup(const char *s);
char *_pam_memdup(const char *s, int len);
int _pam_mkargv(char *s, char ***argv, int *argc);
void _pam_sanitize(pam_handle_t *pamh);
void _pam_set_default_control(int *control_array, int default_action);
void _pam_parse_control(int *control_array, char *tok);
#define _PAM_SYSTEM_LOG_PREFIX "PAM"

#define IF_NO_PAMH(X,pamh,ERR) \
if ((pamh) == NULL) { \
	syslog(LOG_ERR, _PAM_SYSTEM_LOG_PREFIX " " X ": NULL pam handle passed"); \
	return ERR; \
}

#define _PAM_CALLED_FROM_MODULE         1
#define _PAM_CALLED_FROM_APP            2

#define __PAM_FROM_MODULE(pamh)  ((pamh)->caller_is == _PAM_CALLED_FROM_MODULE)
#define __PAM_FROM_APP(pamh)     ((pamh)->caller_is == _PAM_CALLED_FROM_APP)
#define __PAM_TO_MODULE(pamh) \
	do { (pamh)->caller_is = _PAM_CALLED_FROM_MODULE; } while (0)
#define __PAM_TO_APP(pamh)    \
	do { (pamh)->caller_is = _PAM_CALLED_FROM_APP; } while (0)

#ifdef HAVE_LIBAUDIT
extern int _pam_auditlog(pam_handle_t *pamh, int action, int retval, int flags);
extern int _pam_audit_end(pam_handle_t *pamh, int pam_status);
#endif

#endif
