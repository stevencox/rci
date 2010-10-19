#!/bin/bash

#PBS -N pmemd
#   PBS -l nodes=16:ppn=8
#   PBS -l walltime=60:00:00

set -e

##############################################################
## load required modules.
## initialize the environment. 
## clean up from previous runs.
##############################################################
cpmemd_init () {
    source ${RENCI_HOME}/environment.sh
#    source /home/scox/dev/rencici/bin/environment.sh
    renci_ci_amber_tools
    if [ -z $CPMEMD_HOME ]; then
	CPMEMD_HOME=`${DIRNAME} $0` 
    fi
    TIMESTAMP=$( ${DATE} +'%Y%m%d_%H%M' )
    export CPMEMD_RUN_DIR=${CPMEMD_HOME}/run-${TIMESTAMP}
    export CPMEMD_INPUT_DIR=${CPMEMD_HOME}/in
    export CPMEMD_LOG=${CPMEMD_RUN_DIR}/test.out
    export CPMEMD_OUT_DIR=${CPMEMD_RUN_DIR}/out
    export CPMEMD_EXE=/home/scox/pmemd/pmemd.mvapich2

    renci_ci_show_env "cpmemd_home|cpmemd_run_dir|cpmemd_input_dir|cpmemd_log|cpmemd_out_dir|renci_home|cpmemd_exe"
    ${MKDIR} -p ${CPMEMD_OUT_DIR}    
    fname=i14vnphdhf+_hip
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
cpmemd_mpi_exec () {
    MVAPICH_CMD="/usr/bin/time /opt/mpi/mpiexec/intel/bin/mpiexec $OPTS -comm=mpich-ib $TRANSFORM"
    MVAPICH2_CMD="/usr/bin/time /opt/mpi/intel/mpiexec-0.84/bin/mpiexec $OPTS -comm=pmi $TRANSFORM"
    MPI_CMD=MVAPICH_CMD
    for arg in $*; do
	case $arg in
	    --mvapich)
		MPI_CMD=${MVAPICH_CMD}
		shift;;
	    --mvapich2)
		MPI_CMD=${MVAPICH2_CMD}
		shift;;
	esac
    done
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
    cpmemd_mpi_exec --${MPI_KIND} ${CPMEMD_EXE} \
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
    cd $PBS_O_WORKDIR
    MPI_KIND=$1

    cpmemd_pmemd_exec input.template.txt $fname 

    fnamei=$fname'W1'
    ${CP} ${CPMEMD_RUN_DIR}/out/$fname.rst ${CPMEMD_INPUT_DIR}/$fnamei.crd
    ${CP} ${CPMEMD_INPUT_DIR}/$fname.top ${CPMEMD_INPUT_DIR}/$fname'W1'.top

    cpmemd_pmemd_exec fnamei.template.txt $fnamei    

    ${ECHO} 0 > ${CPMEMD_OUT_DIR}/pj_var
    ${ECHO} 0 > ${CPMEMD_OUT_DIR}/j_var
    ${ECHO} 0 > ${CPMEMD_OUT_DIR}/ns_var
    ${ECHO} 1 > ${CPMEMD_OUT_DIR}/p_var
    ${ECHO} 2 > ${CPMEMD_OUT_DIR}/limit_var

    ${MV} \
	${CPMEMD_HOME}/logfile \
	${CPMEMD_HOME}/mdinfo \
	${CPMEMD_OUT_DIR}
    cpmemd_line
    renci_ci_log_info "--(end): $0-@-`hostname`-@-$(${DATE})"
}
##############################################################
## main program.
##    accept grid arguments and submit to pbs
##       or
##    without parameters, execute pmemd test.
##############################################################
cpmemd_main () {
    cd ${CPMEMD_HOME}
    unset num_processes
    unset num_nodes
    unset grid
    unset GRID_ARGS
    for arg in $*; do
	case $arg in
	    --procs\=*)
		num_processes=$( ${ECHO} $arg | ${SED} s,--procs=,,)
		GRID_ARGS=${GRID_ARGS}:ppn=${num_processes};;
	    --nodes\=*)
		num_nodes=$( ${ECHO} $arg | ${SED} s,--nodes=,,);
		GRID_ARGS="-l nodes=${num_nodes}";;
	    --grid) grid=true; renci_ci_log_debug "pmemd: grid run...";;
	esac
    done
    for x in $*; do 
	shift;
    done
    if [ "x${grid}" = "xtrue" ]; then
	if [ -r ${CPMEMD_HOME}/run/test.out ]; then
	    LAST_RUN_DATE=`${LS} -lisaF ${CPMEMD_HOME} | ${GREP} run/ | ${AWK} '{ print $8 "-" $9 "-" $10 }'`
	    renci_ci_log_info "archiving last run as ${CPMEMD}/run-${LAST_RUN_DATE}"
#	    ${MV} ${CPMEMD_HOME}/run ${CPMEMD_HOME}/run-${LAST_RUN_DATE}
	fi
	${MKDIR} -p ${CPMEMD_RUN_DIR}
	cpmemd_line > ${CPMEMD_LOG}
	renci_ci_log_info "== CPMEMD" >> ${CPMEMD_LOG}
	cpmemd_line >> ${CPMEMD_LOG}
	renci_ci_log_info "     start: $0-@-`hostname`-@-$(${DATE})" >> ${CPMEMD_LOG}
	renci_ci_log_info "      qsub: qsub -V ${GRID_ARGS} $0 " >> ${CPMEMD_LOG}
	renci_ci_log_info "     nodes: ${num_nodes}" >> ${CPMEMD_LOG}
	renci_ci_log_info "      cpus: ${num_processes}" >> ${CPMEMD_LOG}
	renci_ci_log_info "   pbs pid: $( qsub -V ${GRID_ARGS} $0 )" >> ${CPMEMD_LOG}
    else
	renci_ci_log_info "   compute: `hostname`" >> ${CPMEMD_LOG}
	t=$( renci_ci_timer )
	cpmemd_execute_test mvapich2 >> ${CPMEMD_LOG}
	renci_ci_log_info "total test execution time: $( renci_ci_timer $t )" >> ${CPMEMD_LOG}
	cpmemd_line >> ${CPMEMD_LOG}
	${MV} ${CPMEMD_HOME}/pmemd* ${CPMEMD_RUN_DIR}
	${ECHO} complete > ${CPMEMD_HOME}/complete
    fi
}

cpmemd_init && cpmemd_main $* 
