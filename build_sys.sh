#!/bin/bash -e
###  InterGenOS_build_002 build_sys.sh - Builds InterGen packages
###  Written by Christopher 'InterGen' Cork <chris@intergenstudios.com>
###  4/5/2015

## Begin initialize logs

touch /var/log/{btmp,lastlog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

## End initialize logs

## Begin package builds

cd /sources

## Updated kernel to 3.19 ###
#############################
## Linux-3.19 API Headers  ##
## ======================= ##
#############################


tar xf linux-3.19.tar.xz &&
cd linux-3.19/

make mrproper &&

make INSTALL_HDR_PATH=dest headers_install &&

find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include

cd .. && rm -rf linux-3.19

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


####################
## man-pages-3.79 ##
## ============== ##
####################


tar xf man-pages-3.79.tar.xz &&
cd man-pages-3.79

make install &&

cd .. && rm -rf man-pages-3.79 &&

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


################
## glibc-2.21 ##
## ========== ##
################


tar xf glibc-2.21.tar.xz &&
cd glibc-2.21

patch -Np1 -i ../glibc-2.21-fhs-1.patch &&

sed -e '/ia32/s/^/1:/' \
    -e '/SSE2/s/^1://' \
    -i  sysdeps/i386/i686/multiarch/mempcpy_chk.S &&

mkdir -v ../glibc-build
cd ../glibc-build

../glibc-2.21/configure    \
    --prefix=/usr          \
    --disable-profile      \
    --enable-kernel=2.6.32 \
    --enable-obsolete-rpc  \
    --with-pkgversion='InterGenOS GNU/Linux glibc build002'

make &&

make check 2>&1 | tee /glibc-mkck-log_$(date +"%m-%d-%Y_%T") &&

COUNT=15 # Add some blank lines so glibc make check results
#          are easier to see in build output

while [ "$COUNT" -gt "0" ]; do
	echo " "
	let COUNT=COUNT-1
done
unset COUNT

echo " ---------------------------------- "
echo " "
echo " GLIBC MAKE CHECK RESULTS ARE ABOVE "
echo " "
echo " ---------------------------------- "

COUNT=15 # Add some blank lines so glibc make check results
#          are easier to see in build output

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

touch /etc/ld.so.conf # the install stage of Glibc will complain about 
#                       the absence of /etc/ld.so.conf. Touching the 
#                       file prevents it

make install &&

cp -v ../glibc-2.21/nscd/nscd.conf /etc/nscd.conf

mkdir -pv /var/cache/nscd

install -v -Dm644 ../glibc-2.21/nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../glibc-2.21/nscd/nscd.service /lib/systemd/system/nscd.service

mkdir -pv /usr/lib/locale

localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns myhostname
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../tzdata2015a.tar.gz

ZONEINFO=/usr/share/zoneinfo

mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO

zic -d $ZONEINFO -p America/New_York

unset ZONEINFO

ln -sfv /usr/share/zoneinfo/America/Chicago /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

mkdir -pv /etc/ld.so.conf.d

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE TOOLCHAIN TESTING      |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


#############################
## Adjusting the Toolchain ##
## ======================= ##
#############################


mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log

ExpectedA="Requestingprograminterpreter/lib64/ld-linux-x86-64.so.2"
ActualA="$(readelf -l a.out | grep ': /lib' | sed s/://g | cut -d '[' -f 2 | cut -d ']' -f 1 | awk '{print $1$2$3$4}')"

if [ "$ExpectedA" != "$ActualA" ]; then
    echo "!!!!!TOOLCHAIN ADJUSTMENT TEST 1 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
    
    echo "TOOLCHAIN ADJUSTMENT TEST 1 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

cat > tlchn_test2.txt << "EOF"
/usr/lib/../lib64/crt1.o succeeded
/usr/lib/../lib64/crti.o succeeded
/usr/lib/../lib64/crtn.o succeeded
EOF

ExpectedB="$(cat tlchn_test2.txt)"
ActualB="$(grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log)"

        if [ "$ActualB" != "$ExpectedB" ]; then

                echo "!!!!!TOOLCHAIN ADJUSTMENT TEST 2 FAILED!!!!! Halting build, check your work."
                exit 0

        else

		COUNT=15 # Add some blank lines so build output
		#   	   is easier to review

    		while [ "$COUNT" -gt "0" ]; do
    		echo " "
    		let COUNT=COUNT-1
    		done
    		unset COUNT
    		
		echo "TOOLCHAIN ADJUSTMENT TEST 2 PASSED, CONTINUING TESTS"
	
		COUNT=15 # Add some blank lines so build output
		#   	   is easier to review

    		while [ "$COUNT" -gt "0" ]; do
    		echo " "
    		let COUNT=COUNT-1
    		done
    		unset COUNT
	fi

rm tlchn_test2.txt

ExpectedC="/usr/include"
ActualC="$(grep -B1 '^ /usr/include' dummy.log | grep usr | awk '{print $1}')"

if [ "$ExpectedC" != "$ActualC" ]; then
    echo "!!!!!TOOLCHAIN ADJUSTMENT TEST 3 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN ADJUSTMENT TEST 3 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

cat > tlchn_test4.txt << "EOF"
SEARCH_DIR("=/tools/x86_64-unknown-linux-gnu/lib64")
SEARCH_DIR("/usr/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("=/tools/x86_64-unknown-linux-gnu/lib");
EOF

ExpectedD="$(cat tlchn_test4.txt)"
ActualD="$(grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g')"

if [ "$ExpectedD" != "$ActualD" ]; then
    echo "!!!!!TOOLCHAIN ADJUSTMENT TEST 4 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN ADJUSTMENT TEST 4 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

rm tlchn_test4.txt

ExpectedE="succeeded"
ActualE="$(grep "/lib.*/libc.so.6 " dummy.log | awk '{print $5}')"

if [ "$ExpectedE" != "$ActualE" ]; then
    echo "!!!!!TOOLCHAIN ADJUSTMENT TEST 5 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN ADJUSTMENT TEST 5 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

ExpectedF="found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2"
ActualF="$(grep found dummy.log)"

if [ "$ExpectedF" != "$ActualF" ]; then
    echo "!!!!!TOOLCHAIN ADJUSTMENT TEST 6 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN ADJUSTMENT TEST 6 PASSED, CONTINUING BUILD"

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

rm -v dummy.c a.out dummy.log

cd .. && rm -rf glibc-2.21 glibc-build/


################
## Zlib-1.2.8 ##
## ========== ##
################


tar xf zlib-1.2.8.tar.xz &&
cd zlib-1.2.8

./configure --prefix=/usr &&

make &&

make check 2>&1 | tee /zlib-mkck-log_$(date +"%m-%d-%Y_%T") &&

make install &&

mv -v /usr/lib/libz.so.* /lib

ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

cd .. && rm -rf zlib-1.2.8

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


###############
## File-5.22 ##
## ========= ##
###############


tar xf file-5.22.tar.gz &&
cd file-5.22

./configure --prefix=/usr &&

make &&

make check 2>&1 | tee /file-mkck-log_$(date +"%m-%d-%Y_%T") &&

make install &&

cd .. && rm -rf file-5.22

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


###################
## Binutils-2.25 ##
## ============= ##
###################


tar xf binutils-2.25.tar.bz2 &&
cd binutils-2.25


###############
## PTY check ##
## ========= ##
###############

cat > pty_test.txt << "EOF"
spawn ls
EOF

ExpectedG="$(cat pty_test.txt)"
ActualG="$(expect -c "spawn ls")"

if [ "$ExpectedG" != "$ActualG" ]; then
    echo "!!!!!PTY Check FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "PTY Check PASSED, CONTINUING BUILD"

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

mkdir -v ../binutils-build
cd ../binutils-build

../binutils-2.25/configure --prefix=/usr   \
                           --enable-shared \
                           --disable-werror &&

make tooldir=/usr &&

make -k check 2>&1 | tee /binutils-mkck-log_$(date +"%m-%d-%Y_%T") &&

make tooldir=/usr install &&

cd .. && rm -rf binutils-2.25 binutils-build/

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


################
## GMP-6.0.0a ##
## ========== ##
################


tar xf gmp-6.0.0a.tar.xz &&
cd gmp-6.0.0

./configure --prefix=/usr \
            --enable-cxx  \
            --docdir=/usr/share/doc/gmp-6.0.0a &&

make &&

make html &&

make check 2>&1 | tee /gmp-check-logA &&

awk '/tests passed/{total+=$2} ; END{print total}' /gmp-check-logA >> /gmp-mkck-log_$(date +"%m-%d-%Y_%T") &&

make install &&

make install-html &&

cd .. && rm -rf gmp-6.0.0

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


################
## MPFR-3.1.2 ##
## ========== ##
################


tar xf mpfr-3.1.2.tar.xz &&
cd mpfr-3.1.2

patch -Np1 -i ../mpfr-3.1.2-upstream_fixes-3.patch &&

./configure --prefix=/usr        \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-3.1.2 &&

make &&

make html &&

make check 2>&1 | tee /mpfr-mkck-log_$(date +"%m-%d-%Y_%T") &&

make install &&

make install-html &&

cd .. && rm -rf mpfr-3.1.2

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


###############
## MPC-1.0.2 ##
## ========= ##
###############


tar xf mpc-1.0.2.tar.gz &&
cd mpc-1.0.2

./configure --prefix=/usr --docdir=/usr/share/doc/mpc-1.0.2 &&

make &&

make html &&

make check 2>&1 | tee /mpc-mkck-log_$(date +"%m-%d-%Y_%T")

make install &&

make install-html &&

cd .. && rm -rf mpc-1.0.2

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT

echo "------------------------------------------"
echo "|                                        |"
echo "|  SPACING BEFORE STARTING NEXT PACKAGE  |"
echo "|  ALLOWS FOR EASIER REVIEW OF BUILD     |"
echo "|  OUTPUT                                |"
echo "|                                        |"
echo "------------------------------------------"

COUNT=15 # Add some blank lines so build output
#          is easier to review

while [ "$COUNT" -gt "0" ]; do
        echo " "
        let COUNT=COUNT-1
done
unset COUNT


###############
## GCC-4.9.2 ##
## ========= ##
###############


tar xf gcc-4.9.2.tar.bz2 &&
cd gcc-4.9.2/

mkdir -v ../gcc-build
cd ../gcc-build

SED=sed                       \
../gcc-4.9.2/configure        \
     --prefix=/usr            \
     --enable-languages=c,c++ \
     --disable-multilib       \
     --disable-bootstrap      \
     --with-system-zlib &&

make &&

ulimit -s 32768

make -k check 2>&1 | tee /gcc-mkck-logA_$(date +"%m-%d-%Y_%T") &&

../gcc-4.9.2/contrib/test_summary | grep -A7 Summ >> /gcc-mkck-logB_$(date +"%m-%d-%Y_%T") &&

make install &&

ln -sv ../usr/bin/cpp /lib

ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins &&

ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/4.9.2/liblto_plugin.so /usr/lib/bfd-plugins/


###########################
## Testing the Toolchain ##
## ===================== ##
###########################


echo 'main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log

ExpectedH="Requestingprograminterpreter/lib64/ld-linux-x86-64.so.2"
ActualH="$(readelf -l a.out | grep ': /lib' | sed s/://g | cut -d '[' -f 2 | cut -d ']' -f 1 | awk '{print $1$2$3$4}')"

if [ "$ExpectedH" != "$ActualH" ]; then
    echo "!!!!!TOOLCHAIN TEST 1 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN TEST 1 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

cat > tlchn_test2.txt << "EOF"
/usr/lib/gcc/x86_64-unknown-linux-gnu/4.9.2/../../../../lib64/crt1.o succeeded
/usr/lib/gcc/x86_64-unknown-linux-gnu/4.9.2/../../../../lib64/crti.o succeeded
/usr/lib/gcc/x86_64-unknown-linux-gnu/4.9.2/../../../../lib64/crtn.o succeeded
EOF

ExpectedI="$(cat tlchn_test2.txt)"
ActualI="$(grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log)"

if [ "$ExpectedI" != "$ActualI" ]; then

    echo "!!!!!TOOLCHAIN TEST 2 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN TEST 2 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

rm -rf tlchn_test2.txt

cat > tlchn_test3.txt << "EOF"
#include <...> search starts here:
 /usr/lib/gcc/x86_64-unknown-linux-gnu/4.9.2/include
 /usr/local/include
 /usr/lib/gcc/x86_64-unknown-linux-gnu/4.9.2/include-fixed
 /usr/include
EOF

ExpectedJ="$(cat tlchn_test3.txt)"
ActualJ="$(grep -B4 '^ /usr/include' dummy.log)"

if [ "$ExpectedJ" != "$ActualJ" ]; then
    echo "!!!!!TOOLCHAIN TEST 3 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN TEST 3 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

rm -rf tlchn_test3.txt

cat > tlchn_test4.txt << "EOF"
SEARCH_DIR("/usr/x86_64-unknown-linux-gnu/lib64")
SEARCH_DIR("/usr/local/lib64")
SEARCH_DIR("/lib64")
SEARCH_DIR("/usr/lib64")
SEARCH_DIR("/usr/x86_64-unknown-linux-gnu/lib")
SEARCH_DIR("/usr/local/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("/usr/lib");
EOF

ExpectedK="$(cat tlchn_test4.txt)"
ActualK="$(grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g')"

if [ "$ExpectedK" != "$ActualK" ]; then
    echo "!!!!!TOOLCHAIN TEST 4 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN TEST 4 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#   	       is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

rm tlchn_test4.txt

cat > tlchn_test5.txt << "EOF"
attempt to open /lib64/libc.so.6 succeeded
EOF

ExpectedL="$(cat tlchn_test5.txt)"
ActualL="$(grep "/lib.*/libc.so.6 " dummy.log)"

if [ "$ExpectedL" != "$ActualL" ]; then
    echo "!!!!!TOOLCHAIN TEST 5 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN TEST 5 PASSED, CONTINUING TESTS"

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

rm -rf tlchn_test5.txt

cat > tlchn_test6.txt << "EOF"
found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2
EOF

ExpectedM="$(cat tlchn_test6.txt)"
ActualM="$(grep found dummy.log)"

if [ "$ExpectedM" != "$ActualM" ]; then
    echo "!!!!!TOOLCHAIN TEST 6 FAILED!!!!! Halting build, check your work."
    exit 0

else

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT

    echo "TOOLCHAIN TEST 6 PASSED, CONTINUING BUILD"

    COUNT=15 # Add some blank lines so build output
#              is easier to review

    while [ "$COUNT" -gt "0" ]; do
    echo " "
    let COUNT=COUNT-1
    done
    unset COUNT
fi

rm -v dummy.c a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd .. && rm -rf gcc-build/ gcc-4.9.2


#################
## Bzip2-1.0.6 ##
## =========== ##
#################


tar xf bzip2-1.0.6.tar.gz &&
cd bzip2-1.0.6

patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so &&
make clean &&
make &&

make PREFIX=/usr install

cp -v bzip2-shared /bin/bzip2 &&
cp -av libbz2.so* /lib &&
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2} &&
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat

cd .. && rm -rf bzip2-1.0.6


#####################
## Pkg-config-0.28 ##
## =============== ##
#####################


tar xf pkg-config-0.28.tar.gz &&
cd pkg-config-0.28

./configure --prefix=/usr        \
            --with-internal-glib \
            --disable-host-tool  \
            --docdir=/usr/share/doc/pkg-config-0.28 &&

make &&
make -k check 2>&1 | tee /pkg-config-mkck-log_$(date +"%m-%d-%Y_%T") &&

make install &&

cd .. && rm -rf pkg-config-0.28


#################
## Ncurses-5.9 ##
## =========== ##
#################


tar xf ncurses-5.9.tar.gz &&
cd ncurses-5.9

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --enable-pc-files       \
            --enable-widec &&

make &&
make install &&

mv -v /usr/lib/libncursesw.so.5* /lib

ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv lib${lib}w.a      /usr/lib/lib${lib}.a
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncurses++w.a /usr/lib/libncurses++.a

rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
ln -sfv libncursesw.a      /usr/lib/libcursesw.a
ln -sfv libncurses.a       /usr/lib/libcurses.a

make distclean &&

./configure --prefix=/usr    \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding &&

make sources libs &&

cp -av lib/lib*.so.5* /usr/lib

cd .. && rm -rf ncurses-5.9


#################
## Attr 2.4.47 ##
## =========== ##
#################


tar xf attr-2.4.47.src.tar.gz &&
cd attr-2.4.47

sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in

sed -i -e "/SUBDIRS/s|man2||" man/Makefile

./configure --prefix=/usr &&

make

make -j1 test root-tests 2>&1 | tee /attr-mkck-log_$(date +"%m-%d-%Y_%T") &&

make install install-dev install-lib &&

chmod -v 755 /usr/lib/libattr.so

mv -v /usr/lib/libattr.so.* /lib

ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

cd .. && rm -rf attr-2.4.47


################
## Acl-2.2.52 ##
## ========== ##
################


tar xf acl-2.2.52.src.tar.gz &&
cd acl-2.2.52

sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in

sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test

sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" \
    libacl/__acl_to_any_text.c

./configure --prefix=/usr --libexecdir=/usr/lib &&

make &&

make install install-dev install-lib &&
chmod -v 755 /usr/lib/libacl.so

mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so

cd .. && rm -rf acl-2.2.52


#################
## Libcap-2.24 ##
## =========== ##
#################


tar xf libcap-2.24.tar.xz &&
cd libcap-2.24

make &&
make RAISE_SETFCAP=no prefix=/usr install &&

chmod -v 755 /usr/lib/libcap.so

mv -v /usr/lib/libcap.so.* /lib

ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so

cd .. && rm -rf libcap-2.24


###############
## Sed-4.2.2 ##
## ========= ##
###############


tar xf sed-4.2.2.tar.bz2 &&
cd sed-4.2.2

./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2

make &&
make html &&

make -k check 2>&1 | tee /sed-mkck-log_$(date +"%m-%d-%Y_%T") &&

make install &&
make -C doc install-html &&

cd .. && rm -rf sed-4.2.2


####################
## cracklib-2.9.1 ##
## ============== ##
####################


tar xf cracklib-2.9.1.tar.gz &&
cd cracklib-2.9.1

./configure --prefix=/usr \
            --with-default-dict=/lib/cracklib/pw_dict \
            --disable-static &&
make &&

make install &&
mv -v /usr/lib/libcrack.so.* /lib &&
ln -sfv ../../lib/$(readlink /usr/lib/libcrack.so) /usr/lib/libcrack.so

install -v -m644 -D    ../cracklib-words-20080507.gz           \
                         /usr/share/dict/cracklib-words.gz     &&
gunzip -v                /usr/share/dict/cracklib-words.gz     &&
ln -v -sf cracklib-words /usr/share/dict/words                 &&
echo $(hostname) >>      /usr/share/dict/cracklib-extra-words  &&
install -v -m755 -d      /lib/cracklib                         &&
create-cracklib-dict     /usr/share/dict/cracklib-words        \
                         /usr/share/dict/cracklib-extra-words &&

cd .. && rm -rf cracklib-2.9.1


##################
## Shadow-4.2.1 ##
## ============ ##
##################


tar xf shadow-4.2.1.tar.xz &&
cd shadow-4.2.1

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \; &&

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

sed -i 's@DICTPATH.*@DICTPATH\t/lib/cracklib/pw_dict@' etc/login.defs

sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32 --with-libcrack &&

make &&

make install &&

mv -v /usr/bin/passwd /bin

pwconv &&

grpconv &&

sed -i 's/yes/no/' /etc/default/useradd

echo "root:intergenos" | chpasswd &&

cd .. && rm -rf shadow-4.2.1


##################
## Psmisc-22.21 ##
## ============ ##
##################


tar xf psmisc-22.21.tar.gz
cd psmisc-22.21

./configure --prefix=/usr &&

make &&
make install &&

mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin

cd .. && rm -rf psmisc-22.21








echo ok all designated builds completed

### remaining packages to be added as testing finishes
###
### packages in testing as of 4/6/2015:
###
### Procps-ng-3.3.10
### E2fsprogs-1.42.12
### Coreutils-8.23
### Iana-Etc-2.30
### M4-1.4.17
### Flex-2.5.39
### Bison-3.0.4
### Grep-2.21
### Readline-6.3
### Bash-4.3.30
### Bc-1.06.95
### Libtool-2.4.6
### GDBM-1.11
### Expat-2.1.0
### Inetutils-1.9.2
### Perl-5.20.2
### XML::Parser-2.44
### Autoconf-2.69
### Automake-1.15
### Diffutils-3.3
### Gawk-4.1.1
### Findutils-4.4.2
### Gettext-0.19.4
### Intltool-0.50.2
### Gperf-3.0.4
### Groff-1.22.3
### Xz-5.2.0
### GRUB-2.02~beta2
### Less-458
### Gzip-1.6
### IPRoute2-3.19.0
### Kbd-2.0.2
### Kmod-19
### Libpipeline-1.4.0
### Make-4.1
### Patch-2.7.4
### Systemd-219
### D-Bus-1.8.16
### Util-linux-2.26
### Man-DB-2.7.1
### Tar-1.28
### Texinfo-5.2
### Vim-7.4
### Nano-2.26
###
### 
