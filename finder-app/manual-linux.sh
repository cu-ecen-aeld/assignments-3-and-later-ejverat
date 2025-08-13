#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE_BASE=aarch64-none-linux-gnu
CROSS_COMPILE=${CROSS_COMPILE_BASE}-
TOOLCHAIN_PATH=$(dirname $(which ${CROSS_COMPILE}gcc))
TOOLCHAIN_PATH=${TOOLCHAIN_PATH%/bin}

echo "CROSS_COMPILE=${CROSS_COMPILE}"

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j8 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make -j8 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make -j8 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

mkdir -p ${OUTDIR}/rootfs/{bin,dev,etc,home,lib,lib64,proc,sbin,sys,tmp,usr,var}
mkdir -p ${OUTDIR}/rootfs/usr/{bin,lib,sbin}
mkdir -p ${OUTDIR}/rootfs/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} distclean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
    cd busybox
fi

make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
cd ${OUTDIR}/rootfs

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

cp $TOOLCHAIN_PATH/${CROSS_COMPILE_BASE}/libc/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp $TOOLCHAIN_PATH/${CROSS_COMPILE_BASE}/libc/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64
cp $TOOLCHAIN_PATH/${CROSS_COMPILE_BASE}/libc/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp $TOOLCHAIN_PATH/${CROSS_COMPILE_BASE}/libc/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64

sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5 1

cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE} writer


cp writer ${OUTDIR}/rootfs/home
cp finder.sh ${OUTDIR}/rootfs/home
cp finder-test.sh ${OUTDIR}/rootfs/home
cp conf/username.txt ${OUTDIR}/rootfs/home
cp conf/assignment.txt ${OUTDIR}/rootfs/home
cp autorun-qemu.sh ${OUTDIR}/rootfs/home

sudo chown root:root ${OUTDIR}/rootfs

cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd $OUTDIR
gzip -f initramfs.cpio
