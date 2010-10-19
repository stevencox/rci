#!/bin/bash

mpich_init () {
    renci_ci_require ifort
    export MPICH_VERSION=1.2.7p1
    export MPICH_HOME=${APP_BASE}/mpich-${MPICH_VERSION}
    MPICH_TAR=mpich-${MPICH_VERSION}.tar.gz
}
mpich_get () {
    cd ${APP_SCRATCH} &&
    ${WGET} --timestamping ftp://ftp.mcs.anl.gov/pub/mpi/${MPICH_TAR}  &&
    ${TAR} xvzf ${MPICH_TAR}
}
mpich_configure_env () {
    renci_ci_log_info "configure env..."
    export CC=gcc
    export CXX=g++
    export F77=ifort
    export F90=ifort
    export LDFLAGS=-static
    export NOF77=0
    export NO_F90=0
    renci_ci_show_env "cc|cxx|f77|f90|ldflags|nof77|no_f90"
}
mpich_configure () {
    cd ${APP_SCRATCH}/mpich-${MPICH_VERSION} &&
    renci_ci_log_info "configure fortran. without this, fortran interfaces and tools are not built." &&
    mpich_configure_env &&
    set -x &&
    ./configure \
        -prefix=${APP_BASE}/mpich-${MPICH_VERSION} \
        --with-device=ch_p4 \
	--with-device=ch_shmem &&
    set +x
}
mpich_build () {
    cd ${APP_SCRATCH}/mpich-${MPICH_VERSION} &&
    ${MAKE} clean &&
    ${MAKE} &&
    ${MAKE} install
}
mpich_install () {
    cd ${APP_SCRATCH}/mpich-${MPICH_VERSION} &&
    ${MAKE} install &&
    mpich_verify_static ${MPICH_HOME}/bin/
}   
mpich_all () {
    mpich_get
    mpich_configure
    mpich_build
    mpich_install
}
mpich_verify_static () {
    local binary=$1
    dynamic_symbols=$( ${OBJDUMP} --dynamic-syms ${binary} 2>&1 | ${GREP} -c "${binary}: not a dynamic object" )
    if [ ! "${dynamic_symbols}" = 1 ]; then
	renci_ci_log_error "could not confirm ${binary} was statically linked."
	return 1
    fi
}
mpich_init

if [ "x$1" = "x-all" ]; then
    mpich_all
fi

if [ ! -z "$2" ]; then

    exe=${MPICH_HOME}/bin/mpirun
    target=$2

    ${MKDIR} -p ${target}

    pdir=mpich
    renci_ci_log_info "creating tar file ${pdir}.tar.gz"
    ${RM} -rf ${pdir}
    ${MKDIR} -p ${pdir}
    ${CP} ${exe}* ${pdir}
    ${RM} ${pdir}/*_dbg*

    ${SED} \
	-e "s,prefix=.*,prefix=\$MPI_HOME," \
	-e "s,bindir=.*,bindir=\$MPI_HOME," \
	-e "s,datadir=.*,datadir=\$MPI_HOME/share," ${pdir}/mpirun > ${pdir}/mpirun.new
    ${MV} --force ${pdir}/mpirun.new ${pdir}/mpirun

    ${TAR} czvf ${pdir}.tar.gz ${pdir}
    ${MV} ${pdir}.tar.gz ${target}/..

    renci_ci_log_info "copying ${exe} to ${target}"
    ${CP} ${pdir}/* ${target}
fi

