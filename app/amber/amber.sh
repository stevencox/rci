#!/bin/bash 

amber_init () {
    renci_ci_require mpich
    renci_ci_require mpich2
    DIST_BASE=~/Downloads # licensed software.
    AMBER_DIST=${DIST_BASE}/amber9
    export AMBERHOME=${APP_BASE}/amber9
    export PATH=${PATH}:${AMBERHOME}/exe
    export AMBER_FORTRAN=gfortran
    # MPI
    export MVAPICH_HOME=/opt/mpi/intel/mvapich-1.1    # blueridge specific ... but that's mpi for you.
    export MVAPICH2_HOME=/opt/mpi/intel/mvapich2-1.4    # blueridge specific ... but that's mpi for you.
}
amber_fortran () {
    local gfortran=false
    local ifort=false
    if [ "$#" = 0 ]; then
	renci_ci_log_info "AMBER_FORTRAN=${AMBER_FORTRAN}"
    else
	for arg in $*; do
	    case $arg in
		--ifort) export AMBER_FORTRAN=ifort;
		    renci_ci_log_debug "fortran compiler: ifort";;
		--gfortran) export AMBER_FORTRAN=gfortran;
		    renci_ci_log_debug "fortran compiler: gfortran";;
	    esac
	done
    fi
}
amber_clean () {
    ${V} renci_ci_log_info "removing amber: ${AMBERHOME}..."
    ${V} ${RM} -rf ${AMBERHOME}
}
amber_install () {
    ${V} renci_ci_log_info "amber - install..."
    ${V} renci_ci_log_info "  --creating ${AMBERHOME}..."
    ${V} cd ${APP_BASE}
    ${V} renci_ci_log_info "  --un-tarring amber source..."
    ${V} ${TAR} xzf ${AMBER_DIST}/amber9.tgz
    #${V} renci_ci_log_info "  --un-tarring tutorial..."
    #${V} ${TAR} xzf ${AMBER_DIST}/tutorial.tgz
    cd ${AMBERHOME}
    ${V} renci_ci_log_info "  --patching source with ${AMBERDIST}/bugfix.all..."
    ${V} ${PATCH} --quiet -p0 -N -r patch-rejects < ${AMBER_DIST}/bugfix.all
}
amber_configure_flags () {
    local parallel=false
    local num_processes=2
    for arg in $*; do
	case $arg in
	    --np\=*) num_processes=$( ${ECHO} $arg | ${SED} s,--np=,,);;
	    --parallel) parallel=true; renci_ci_log_debug "parallel build...";;
	esac
    done
    ${V} unset DO_PARALLEL
    if [ "x${parallel}" = "xtrue" ]; then
	${V} renci_ci_log_info "configuring parallel build..."
	${V} export DO_PARALLEL="mpirun -np ${num_processes}"
	renci_ci_log_info "DO_PARALLEL=${DO_PARALLEL}"
    fi
    ${V} renci_ci_show_env "mpi_home|do_parallel"
}
amber_compile_serial () {
    ${V} renci_ci_log_info "amber - compile serial..."
    ${V} cd ${AMBERHOME}/src
    amber_configure_flags
    ${V} ./configure -verbose ${AMBER_FORTRAN}
    ${V} make serial
}
amber_compile_parallel () {
    ${V} renci_ci_log_info "amber - compile parallel..."
    ${V} cd $AMBERHOME/src
    ${V} make clean
     
    amber_configure_flags --parallel
    ${V} ./configure -verbose -openmpi ${AMBER_FORTRAN}
   
    #http://structbio.vanderbilt.edu/archives/amber-archive/2006/2646.php
    ${SED} -e "s,FC=.*$,FC=$MPI_HOME/bin/mpif90," config.h > config.h.fixed
    ${MV} config.h.fixed config.h
    ${GREP} FC= config.h

    ${V} make parallel
}
amber_test () {
    ${V} renci_ci_log_info "amber - test $1..."
    ${V} cd $AMBERHOME/test
    ${V} make test.$1
}

#########################################################################
#########################################################################
####                                                                #####
####          P M E M D                                             #####
####                                                                #####
####                                                                #####
#### - notes:                                                       #####
####      * sudo apt-get install uuid-dev                           #####
####      * adding the -xT optimization flag did not help           #####
####         ${SED} -e "s,F90_OPT_HI =,F90_OPT_HI = -xT," \         #####
####                config.h > config.h.new &&                      #####
####         ${MV} config.h.new config.h                            #####
####                                                                #####
####                                                                #####
#########################################################################
#########################################################################

amber_pmemd_configure_env () {
    amber_grok_mpi $* &&
    export MPI_LIBDIR2=/lib64 &&
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib &&
    amber_fortran --ifort 
}
amber_pmemd_configure () {
    amber_pmemd_configure_env $* &&
    cd ${AMBERHOME}/src &&
    amber_configure_flags --parallel &&
    ARCH=$( ${UNAME} -m )
    if [ "x${ARCH}" = "xi686" ]; then
	ARCH=ia32
    fi &&
    ./configure -verbose -${MPI_CONFIGURE_FLAG} ifort_${ARCH} &&
    cd ${AMBERHOME}/src/pmemd &&
    ${ECHO} no | ${BASH} ./configure linux_em64t ifort ${MPI_CONFIGURE_FLAG} &&
    export LDFLAGS=-static &&
    ${SED} \
	-e "s,MPI_LIBS =.*,MPI_LIBS = -L\$(MPI_LIBDIR)," \
	-e "s,F90 =.*,F90 = mpif90," \
	-e "s,CC =.*,CC = mpicc," \
	-e "s,LOAD =.*,LOAD = mpif90," config.h > config.h.new &&
    ${MV} config.h.new config.h
}
amber_pmemd_build () {
    cd ${AMBERHOME}/src/pmemd &&
    amber_pmemd_configure_env $* &&
    ${MAKE} clean &&
    ${MAKE}
}
amber_pmemd_install () {
    cd ${AMBERHOME}/src/pmemd &&
    ${MAKE} install &&
    ${MV} ${AMBERHOME}/exe/pmemd ${AMBERHOME}/exe/pmemd.${MPI_CONFIGURE_FLAG} &&
    ${LS} -lisa ${AMBERHOME}/exe/pmemd*
}
amber_grok_mpi () {
    if [ "$#" = 0 ];then 
	renci_ci_log_error "an mpi library must be specifed"
	amber_pmemd_mpi_usage
	return 1
    fi
    export MPI_HOME=
    export MPI_CONFIGURE_FLAG=
    for arg in $*; do
	case $arg in
	    --mvapich)
		export MPI_HOME=${MVAPICH_HOME}
		export MPI_CONFIGURE_FLAG=mvapich;;
	    --mvapich2)
		export MPI_HOME=${MVAPICH2_HOME}
		export MPI_CONFIGURE_FLAG=mvapich2;;
	    --mpich)
		export MPI_HOME=${MPICH_HOME}
		export MPI_CONFIGURE_FLAG=mpich;;
	    --mpich2)
		export MPI_HOME=${MPICH2_HOME}
		export MPI_CONFIGURE_FLAG=mpich2;;
	    *)  amber_pmemd_mpi_usage;;
	esac
    done
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MPI_HOME}/lib
    renci_ci_path --prepend=$MPI_HOME/bin --commit
    renci_ci_log_info " --(pmemd-configure): mpi-lib: ${MPI_HOME}"
}
amber_pmemd_mpi_usage () {
    renci_ci_log_error "usage: amber_pmemd_configure [--mvapich | --mvapich2 | --mpich ]"
}
amber_pmemd_all () {
    amber_clean &&
    amber_install &&
    amber_pmemd_configure $* &&
    amber_pmemd_build $* &&
    amber_pmemd_install
}
amber_pmemd_both () {
    amber_clean &&
    amber_install &&
    amber_pmemd_configure --mpich &&
    amber_pmemd_build --mpich &&
    amber_pmemd_install &&
    amber_pmemd_configure --mpich2 &&
    amber_pmemd_build --mpich2 &&
    amber_pmemd_install
}



#########################################################################
##   openmpi                                                         ####
#########################################################################
openmpi_install () {
    ${V} renci_ci_log_info "installing openmpi..."
    ${V} cd ${APP_SCRATCH}
    ${V} renci_ci_wget openmpi-${OPENMPI_VERSION}.tar.gz
    ${V} ${TAR} xzvf openmpi-${OPENMPI_VERSION}.tar.gz
    ${V} cd openmpi-${OPENMPI_VERSION}

    export LDFLAGS=-static
    ${V} ./configure --prefix=${APP_BASE}/openmpi-${OPENMPI_VERSION}
    export LDFLAGS=

    unset RM
    ${V} make all install
    export RM=/bin/rm
    ${V} cd ..
    ${V} ${RM} -rf ${APP_SCRATCH}/openmpi-${OPENMPI_VERSION}
}
amber_pmemd_test_openmpi () {
    cd ${AMBERHOME}/src
    ./configure -verbose -openmpi ifort_x86_64
    cd ../test
    amber_configure_flags --parallel $*
    make test.pmemd
}
amber_all () {
    amber_clean
    amber_install
    amber_compile_serial
    amber_test serial
    amber_compile_parallel
    amber_test parallel
}
    
amber_init

find_symbol () {
    local symbol=$1
    local alib=/opt/intel/Compiler/11.1/046/lib/intel64/
    local libs="$( echo $LD_LIBRARY_PATH | sed s,:, , )"
    if [ ! -z $2 ]; then
	alib=$2
	libs="$alib"
    fi
    for lib in $libs; do
	echo --searching lib: $lib
	for file in $( ls $lib ); do 
	    if [ ! "$(nm $lib/$file | grep -c $symbol)" = 0 ]; then
		echo $lib/$file
		nm $lib/$file  2>&1 | grep $symbol | grep -v "format not recognized"
	    fi; 
	done
    done
}


if [ "x$1" = "x-all" ]; then
#    amber_pmemd_all --mpich
#    amber_pmemd_all --mpich2
    amber_pmemd_both
fi

if [ ! -z "$2" ]; then
    exe=${AMBERHOME}/exe/pmemd.
    target=$2
    renci_ci_log_info "creating ${target}" &&
    ${MKDIR} -p ${target} &&
    pdir=pmemd &&
    renci_ci_log_info "creating ${pdir}.tar.gz" &&
    ${RM} -rf ${pdir} &&
    ${MKDIR} -p ${pdir} &&
    ${CP} ${exe}* ${pdir} &&
    ${TAR} czvf ${pdir}.tar.gz ${pdir} &&
    ${MV} ${pdir}.tar.gz ${target}/.. &&
    renci_ci_log_info "copying ${exe} to ${target}" &&
    ${CP} ${exe}* ${target}
fi
