---
<div align="center">

 ![](https://i.imgur.com/PSns8lu.png)

</div>
 
# <div align="center">VERBA - (Very Easy Relative Backdoor Application)</div>
---

> Тhey’re always willing to trade away a little of their freedom in exchange for the feeling, the illusion of security.
>
> -- <cite>George Carlin</cite>

---
## Rules:

For education purpose only and bla blya bla...

## Tested on x86 and x86_64
 - Centos 6.10: 2.6.32-754.27.1.el6
 - Centos 7: 3.10.0-862.3.2.el7
 - Centos 8: 4.18.0-193.el8
 - Debian 10: 4.19.0-9
 - Ubuntu 20.04 LTS: 5.4.0-40-generic

## Features
Simple rootkit with mass access:

- Few persist methods
- LD_PRELOAD
- SSH Backdoor
- PAM Backdoor
- RCE MySQL/PG

## Install
```
cd ./PRE
./pre.sh
cd -
```

Copy CLIENT to ./src/CLIENT/

Copy to target
```
./start
```
Have fun.

## References
- "[LKM HACKING](http://www.ouah.org/LKM_HACKING.html)", The Hackers Choice (THC), 1999;
- [http://phrack.org/issues/68/11.html](http://phrack.org/issues/68/11.html)
- [https://github.com/naworkcaj/bdvl](https://github.com/naworkcaj/bdvl) 'Was... Awesome.'
- [https://github.com/r00tkillah/HORSEPILL](https://github.com/r00tkillah/HORSEPIL)
- [https://github.com/milabs/kmatryoshka](https://github.com/milabs/kmatryoshka)

## To Do
- Modernize loader to modify version
- Add ITIME from NSA
- Continue test OpenSUSE
- Add Oracle backdoor

---

2019-2021 tg:@Not_C_Developer

---
