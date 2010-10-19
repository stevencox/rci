#!/bin/bash

mpich2_init () {
    renci_ci_require ifort
    export MPICH2_VERSION=1.1.1p1
    export MPICH2_HOME=${APP_BASE}/mpich2-${MPICH2_VERSION}
    MPICH2_TAR=mpich2-${MPICH2_VERSION}.tar.gz
}
mpich2_configure_env () {
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
mpich2_get () {
    cd ${APP_SCRATCH}
    ${WGET} --timestamping http://www.mcs.anl.gov/research/projects/mpich2/downloads/tarballs/${MPICH2_VERSION}/${MPICH2_TAR}
    ${TAR} xzvf mpich2-${MPICH2_VERSION}.tar.gz
}
mpich2_clean () {
    ${RM} -rf ${APP_SCRATCH}/mpich2-${MPICH2_VERSION}
}
mpich2_configure () {
    cd ${APP_SCRATCH}/mpich2-${MPICH2_VERSION}
    mpich2_configure_env
    ./configure -prefix=${MPICH2_HOME}
}
mpich2_build () {
    cd ${APP_SCRATCH}/mpich2-${MPICH2_VERSION}
    ${MAKE}
}
mpich2_install () {
    cd ${APP_SCRATCH}/mpich2-${MPICH2_VERSION}
    ${MAKE} install
#    ${SUDO} ${MAKE} install
}
mpich2_all () {
    mpich2_get
    mpich2_configure
    mpich2_build
    mpich2_install
}

# yay - crashes on blueridge: https://trac.mcs.anl.gov/projects/mpich2/ticket/694
# mpich2 bug? http://dev-archive.ambermd.org/201004/0108.html
mpich2_exec () {
    renci_ci_log_info " -- exiting mpd processes on all hosts (mpdallexit)..."
    mpdallexit > /dev/null
    mpdcheck
    if [ "$?" = "0" ]; then
	mpd &
	renci_ci_log_info " -- starting mpd process (mpdboot)..."
	mpdboot
	t=$(renci_ci_timer)
	${MPICH2_EXEC}
	renci_ci_log_info " -- elapsed time: $(renci_ci_timer $t)"
	renci_ci_log_info " -- exiting mpd processes on all hosts (mpdallexit)..."
	mpdallexit
    fi
}
mpich2_init



if [ "x$1" = "x-all" ]; then
    mpich2_all
fi

if [ ! -z "$2" ]; then
    exe=${MPICH2_HOME}/bin/
    target=$2
    ${MKDIR} -p ${target}
    pdir=mpich2
    renci_ci_log_info "creating tar file ${pdir}.tar.gz"
    ${RM} -rf ${pdir}
    ${MKDIR} -p ${pdir} 
    ${CP} ${exe}* ${pdir}
    cd ${pdir}
    for f in $( ${GREP} python2.6 ${MPICH2_HOME}/bin/* | ${SED} -e "s,.*/mp,mp," -e "s,:.*,," -e "s,\\n,,g" ); do
	renci_ci_log_info " --python2.6->python in ${PWD}/$f..."
	${SED} -e "s,python2.6,python," $f > $f.new
	${MV} --force $f.new $f
    done
    cd ..
    ${TAR} czvf ${pdir}.tar.gz ${pdir}
    ${MV} ${pdir}.tar.gz ${target}/..
    renci_ci_log_info "copying ${exe} to ${target}"
    ${CP} ${exe}* ${target}
fi

