#!/bin/bash

necho(){
        printf ' \e[97;1;2m[...]\t%b\e[0m\n' "$1"
}

secho(){
        printf ' \e[92m[+]\t%b\e[0m\n' "$1"
}

eecho(){
	printf ' \e[91;1;1m[!]\t%b\e[0m\n' "$1"
	exit 255
}

unpack(){
	cd ${1%%${1##*\/}} 1>/dev/null
		case ${1##*\.} in
			xz)
				tar -Jxf ${i}.tar.xz &>/dev/null
			;;
			zip)
				unzip ${i}.zip &>/dev/null
			;;
			gz)
				tar -zxf ${i}.tar.gz &>/dev/null
			;;
			bz2)
				tar -jxf ${i}.tar.bz2 &>/dev/null
			;;
		esac
		shred -u ${i}.*
		mv *${i} ${i} &>/dev/null
		mv ./Linux-PAM ${i} &>/dev/null
	cd - 1>/dev/null
}

patching(){
	read -a jj <<< ${!1}
	for j in ${jj[@]};do
		[[ -d ${3}/${j} ]] && {
			[[ ! -f ${3}/${j}/${1}.patch ]] && cp ${2}/${1} ${3}/${j}/${1}.patch || return 0
			cd ${3}/${j} 1>/dev/null
				[[ "${j}" =~ "7."[45678]"p1" ]] && patch -p1 -i ./${1}.patch 1>/dev/null || patch -i ./${1}.patch 1>/dev/null
				(( $? != 0 )) && {
					patch -p1 -i ./${1}.patch 1>/dev/null
					(( $? != 0 )) && eecho "ERROR when patching [ ${3}/${j} ($?) ]."
				}
				shred -u ./*.orig ./*.rej ./modules/pam_unix/*.orig ./modules/pam_unix/*.rej &>/dev/null
			cd - 1>/dev/null
		} || eecho "ERROR no directory ${2}/${j}"
	done
}

o_ssh_411=("4.0p1 4.1p1")
o_ssh_461=("4.2p1 4.3p1 4.3p2 4.4p1 4.5p1 4.6p1")
o_ssh_531=("4.7p1 4.9p1 5.0p1 5.1p1 5.2p1 5.3p1")
o_ssh_582=("5.4p1 5.5p1 5.6p1 5.7p1 5.8p1 5.8p2")
o_ssh_611=("5.9p1 6.0p1 6.1p1")
o_ssh_622=("6.2p1 6.2p2")
o_ssh_691=("6.3p1 6.4p1 6.5p1 6.6p1 6.7p1 6.8p1 6.9p1")
o_ssh_722=("7.0p1 7.1p1 7.1p2 7.2p1 7.2p2")
o_ssh_731=("7.3p1")
o_ssh_751=("7.4p1 7.5p1")
o_ssh_761=("7.6p1")
o_ssh_771=("7.7p1")
o_ssh_781=("7.8p1")
o_ssh_811=("7.9p1 8.0p1 8.1p1")
o_ssh_861=("8.2p1 8.3p1 8.4p1 8.5p1 8.6p1")

s_ssh_531=("4.0p1 4.1p1 4.2p1 4.3p1 4.3p2 4.4p1 4.5p1 4.6p1 4.7p1 4.9p1 5.0p1 5.1p1 5.2p1 5.3p1")
s_ssh_582=("5.4p1 5.5p1 5.6p1 5.7p1 5.8p1 5.8p2")
s_ssh_771=("5.9p1 6.0p1 6.1p1 6.2p1 6.2p2 6.3p1 6.4p1 6.5p1 6.6p1 6.7p1 6.8p1 6.9p1 7.0p1 7.1p1 7.1p2 7.2p1 7.2p2 7.3p1 7.4p1 7.5p1 7.6p1 7.7p1")
s_ssh_861=("7.8p1 7.9p1 8.0p1 8.1p1 8.2p1 8.3p1 8.4p1 8.5p1 8.6p1")

o_pam_066=("0.59 0.61 0.62 0.63 0.64 0.65 0.66")
o_pam_067=("0.67")
o_pam_075=("0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75")
o_pam_151=("0.76 0.77 0.78 0.79 0.80 0.81 0.99.1.0 0.99.10.0 0.99.2.0 0.99.2.1 0.99.3.0 0.99.4.0 0.99.5.0 0.99.6.0 0.99.6.1 0.99.6.2 0.99.6.3 0.99.7.0 0.99.7.1 0.99.8.0 0.99.8.1 0.99.9.0 1.0.0 1.0.1 1.0.2 1.0.3 1.0.4 1.1.0 1.1.1 1.1.2 1.1.3 1.1.4 1.1.5 1.1.6 1.1.7 1.1.8 1.2.0 1.2.1 1.3.0 1.3.1 1.4.0 1.5.0 1.5.1")

SSHUPATH="./ssh_patches"
PAMUPATH="./pam_patches"
patch_ssh_ver=($(ls -1 ${SSHUPATH}/*|cut -f3 -d'/'))
patch_pam_ver=($(ls -1 ${PAMUPATH}/*|cut -f3 -d'/'))
SSHNPATH="../src/SSHD"
PAMNPATH=".,/src/PAM"

mkdir -p ${SSHNPATH} ${PAMNPATH}

###
necho "Downloading and unpacking SSHs..."
for i in {4..8}.{0..9}p{1..2};do
	[[ ! -d ${SSHNPATH}/${i} ]] && {
		wget -nc -q http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${i}.tar.gz		-O ${SSHNPATH}/${i}.tar.gz
		unpack ${SSHNPATH}/${i}.tar.gz
	}
done

necho "Downloading and unpacking PAMs..."
for i in {0.{56..81},0.99.{1..10}.{0..3}};do
	[[ ! -d ${PAMNPATH}/${i} ]] && {
		wget -nc -q http://ftp.be.debian.org/pub/linux/libs/pam/pre/library/Linux-PAM-${i}.tar.bz2	-O ${PAMNPATH}/${i}.tar.bz2
		unpack ${PAMNPATH}/${i}.tar.bz2
	}
done
for i in 1.{0..3}.{0..9};do
	[[ ! -d ${PAMNPATH}/${i} ]] && {
		wget -nc -q http://www.linux-pam.org/library/Linux-PAM-${i}.tar.bz2				-O ${PAMNPATH}/${i}.tar.bz2
		unpack ${PAMNPATH}/${i}.tar.bz2
	}
done
for i in 1.{3..6}.{0..9};do
	[[ ! -d ${PAMNPATH}/${i} ]] && {
		wget -nc -q https://github.com/linux-pam/linux-pam/archive/refs/tags/v${i}.zip			-O ${PAMNPATH}/${i}.zip
		wget -nc -q https://github.com/linux-pam/linux-pam/archive/refs/tags/Linux-PAM-${i}.zip		-O ${PAMNPATH}/${i}.zip
		wget -nc -q https://github.com/linux-pam/linux-pam/archive/refs/tags/Linux-PAM-${i//./_}.zip	-O ${PAMNPATH}/${i}.zip
		unpack ${PAMNPATH}/${i}.zip
	}
done
secho "Successful."

###
necho "Patching SSHs..."
for i in ${patch_ssh_ver[@]};do
	patching ${i} ${SSHUPATH} ${SSHNPATH}
done

necho "Patching PAMs..."
for i in ${patch_pam_ver[@]};do
	patching ${i} ${PAMUPATH} ${PAMNPATH}
done
secho "Successful."

###
necho "Cleaning..."
shred -u ../src/{SSHD,PAM}/*/*.patch
secho "Successful."
