#!/bin/bash

set -e
#set -x

##############################################################
## load required modules.
## initialize the environment. 
## clean up from previous runs.
##############################################################
cpmemd_init () {
    source ${RENCI_HOME}/environment.sh
    if [ -z "$CPMEMD_HOME" ]; then
	CPMEMD_HOME="$( ${DIRNAME} $( ${DIRNAME} $0 ) )"
    fi
    TIMESTAMP=$( ${DATE} +'%Y%m%d_%H%M' )
    export CPMEMD_RUN_DIR=${CPMEMD_HOME}/run-${TIMESTAMP}
    export CPMEMD_INPUT_DIR=${CPMEMD_HOME}/in
    export CPMEMD_LOG=${CPMEMD_RUN_DIR}/test.out
    export CPMEMD_OUT_DIR=${CPMEMD_RUN_DIR}/out
    export CPMEMD_SBIN=${CPMEMD_HOME}/sbin

    renci_ci_show_env "cpmemd_home|cpmemd_run_dir|cpmemd_input_dir|cpmemd_log|cpmemd_out_dir|renci_home|cpmemd_exe"
    fname=i14vnphdhf+_hip

    MPICH_ARTIFACT=mpich-static-1.2.7p1
    MPICH2_ARTIFACT=mpich2-static-1.1.1p1
    PMEMD_ARTIFACT=amber-pmemd-static-9

    ${MKDIR} -p ${CPMEMD_OUT_DIR} &&
    ${RM} -rf ${CPMEMD_SBIN} &&
    ${MKDIR} -p ${CPMEMD_SBIN} &&
    cd ${CPMEMD_SBIN} &&
    renci_ci_log_info "in dir: ${PWD}" &&
    ${WGET} --timestamping ${RENCI_CI_REPO}/org/renci/mpich-static/1.2.7p1/${MPICH_ARTIFACT}.tar.gz &&
    ${WGET} --timestamping ${RENCI_CI_REPO}/org/renci/mpich2-static/1.1.1p1/${MPICH2_ARTIFACT}.tar.gz &&
    ${WGET} --timestamping ${RENCI_CI_REPO}/org/renci/amber-pmemd-static/9/${PMEMD_ARTIFACT}.tar.gz &&
    renci_ci_log_info "extracting ${MPICH_ARTIFACT}.tar.gz ..." &&
    ${TAR} xvzf ${MPICH_ARTIFACT}.tar.gz &&
    renci_ci_log_info "extracting ${MPICH2_ARTIFACT}.tar.gz ..." &&
    ${TAR} xvzf ${MPICH2_ARTIFACT}.tar.gz &&
    renci_ci_log_info "extracting ${PMEMD_ARTIFACT}.tar.gz ..." &&
    ${TAR} xvzf ${PMEMD_ARTIFACT}.tar.gz &&

    cd ${CPMEMD_HOME}
}
##############################################################
## standard line
##############################################################
cpmemd_line () {
    renci_ci_log_info "======================================================================================="
}
##############################################################
## establish mpi library specific commands.
##############################################################
cpmemd_grok_mpi () {
    MVAPICH_CMD="/usr/bin/time /opt/mpi/mpiexec/intel/bin/mpiexec $OPTS -comm=mpich-ib $TRANSFORM"
    MVAPICH2_CMD="/usr/bin/time /opt/mpi/intel/mpiexec-0.84/bin/mpiexec $OPTS -comm=pmi $TRANSFORM"
    MPICH_CMD="/usr/bin/time ${CPMEMD_SBIN}/mpich/mpirun -np 8 "
    MPICH2_CMD="/usr/bin/time ${CPMEMD_SBIN}/mpich2/mpiexec -np 8 "
    MPI_CMD=MVAPICH_CMD
    for arg in $*; do
	case $arg in
	    --mvapich)
		MPI_CMD=${MVAPICH_CMD}
		export CPMEMD_EXE=/home/scox/pmemd/pmemd.mvapich
		shift;;
	    --mvapich2)
		MPI_CMD=${MVAPICH2_CMD}
		export CPMEMD_EXE=/home/scox/pmemd/pmemd.mvapich2
		shift;;
	    --mpich)
		MPI_CMD=${MPICH_CMD}
		export CPMEMD_EXE=${CPMEMD_SBIN}/pmemd/pmemd.mpich
		shift;;
	    --mpich2)
		MPI_CMD=${MPICH2_CMD}
		export CPMEMD_EXE=${CPMEMD_SBIN}/pmemd/pmemd.mpich2
		shift;;
	esac
    done
}
cpmemd_mpi_exec () {
    ${ECHO} ${MPI_CMD} $* | ${SED} -e "s, -,\n                 -,g" -e "s,^,               ," 
    ${MPI_CMD} $*
}
##############################################################
## translate parameters into a pmemd config file.
## invoke pmemd with a cluster specific mpi command.
##############################################################
cpmemd_pmemd_exec () {
    local template=$1
    local target=$2
    ${SED} -e "s/EXTRA_TEMPLATE/cut=12,/" ${CPMEMD_HOME}/resources/${template} > ${CPMEMD_RUN_DIR}/${target}.in
    cpmemd_line
    renci_ci_log_info "== input: [${target}]"
    cpmemd_line
    renci_ci_log_info `${SED} -e "s,^,         ," ${CPMEMD_RUN_DIR}/${target}.in`
    cpmemd_line
    pe_t=$(renci_ci_timer)
    cpmemd_mpi_exec ${CPMEMD_EXE} \
	-O \
	-i ${CPMEMD_RUN_DIR}/$target.in \
	-c ${CPMEMD_INPUT_DIR}/$target.crd \
	-p ${CPMEMD_INPUT_DIR}/$target.top \
	-x ${CPMEMD_OUT_DIR}/$target.tra \
	-r ${CPMEMD_OUT_DIR}/$target.rst \
	-e ${CPMEMD_OUT_DIR}/$target.ene \
	-o ${CPMEMD_OUT_DIR}/$target.out
    renci_ci_log_info "--(pmemd-exec): execution time: $(renci_ci_timer $pe_t)"
}
##############################################################
## configure and execute the overall pmemd test
##    log pbs nodes
##    coorindate test phases
##    write outputs
##############################################################
cpmemd_execute_test () {
    cpmemd_pmemd_exec input.template.txt $fname &&
    fnamei=$fname'W1' &&
    ${CP} ${CPMEMD_RUN_DIR}/out/$fname.rst ${CPMEMD_INPUT_DIR}/$fnamei.crd &&
    ${CP} ${CPMEMD_INPUT_DIR}/$fname.top ${CPMEMD_INPUT_DIR}/$fname'W1'.top &&
    cpmemd_pmemd_exec fnamei.template.txt $fnamei &&
    ${ECHO} 0 > ${CPMEMD_OUT_DIR}/pj_var &&
    ${ECHO} 0 > ${CPMEMD_OUT_DIR}/j_var &&
    ${ECHO} 0 > ${CPMEMD_OUT_DIR}/ns_var &&
    ${ECHO} 1 > ${CPMEMD_OUT_DIR}/p_var &&
    ${ECHO} 2 > ${CPMEMD_OUT_DIR}/limit_var &&
    ${MV} \
	${CPMEMD_HOME}/logfile \
	${CPMEMD_HOME}/mdinfo \
	${CPMEMD_OUT_DIR} &&
    cpmemd_line &&
    renci_ci_log_info "--(end): $0-@-`hostname`-@-$(${DATE})"
}
##############################################################
## main program.
##    accept grid arguments and submit to pbs
##       or
##    without parameters, execute pmemd test.
##############################################################
cpmemd_main () {
    cpmemd_grok_mpi $*
    cd ${CPMEMD_HOME}
    unset num_cpus
    for arg in $*; do
	case $arg in
	    --procs\=*)	num_cpus=$( ${ECHO} $arg | ${SED} s,--procs=,,);;
	esac
    done
    for x in $*; do
	shift;
    done
    ${MKDIR} -p ${CPMEMD_RUN_DIR}
    cpmemd_line 
    renci_ci_log_info "== CPMEMD" 
    cpmemd_line 
    renci_ci_log_info "     start: $0-@-`hostname`-@-$(${DATE})" 
    renci_ci_log_info "      cpus: ${num_cpus}" 
    t=$( renci_ci_timer )
    cpmemd_execute_test
    renci_ci_log_info "total test execution time: $( renci_ci_timer $t )" 
    cpmemd_line 
}

cpmemd_init && \
    cpmemd_main $* 
