
ifort_init () {
    unset INTEL_COMPILER_HOME
    INTEL_ROOTS="/opt ${INTEL_ROOT} ${APP_BASE} ${HOME}"
    for root in ${INTEL_ROOTS}; do
	if [ -d "${root}/intel/Compiler/11.1/current/bin" ]; then
	    INTEL_ROOT=${root}
	    INTEL_COMPILER_HOME=${INTEL_ROOT}/intel/Compiler/11.1/current
	    break
	fi
    done
    if [ -z "${INTEL_COMPILER_HOME}" ]; then
	renci_ci_log_error "unable to locate intel compiler"
	return 1
    fi
    if [ -d "/lib64" ]; then
	export INTEL_ARCHITECTURE=intel64
    else
	export INTEL_ARCHITECTURE=ia32
    fi
    source ${INTEL_COMPILER_HOME}/bin/ifortvars.sh ${INTEL_ARCHITECTURE} &&
    renci_ci_path --prepend=${INTEL_COMPILER_HOME}/bin/${INTEL_ARCHITECTURE} --commit &&
    renci_ci_path
}


ifort_init0 () {
    x=1
#    INTEL_ROOT=${INTEL_ROOT:=${APP_BASE}}
}
ifort_configure0 () {
    renci_ci_log_info "configuring ifort..."
    if [ -d "/opt/intel/Compiler/11.1/current/bin" ]; then
	. ${INTEL_COMPILER_HOME}/bin/iccvars.sh intel64 &&
	. ${INTEL_COMPILER_HOME}/bin/ifortvars.sh intel64
    elif [ -d "${INTEL_ROOT}/intel/Compiler/11.1/current/bin" ]; then
	ifort_configure_local &&
	renci_ci_path
    else
	renci_ci_log_error "failed to find intel fortran compiler."
	return 1
    fi
}
ifort_configure_local0 () {
    renci_ci_log_info "configurig intel fortran..."
    IFORT_COMPILER_PATH=intel/Compiler/11.1/current
    renci_ci_path --prepend=${INTEL_ROOT}/${IFORT_COMPILER_PATH}/bin/intel64 --commit
    . ${INTEL_ROOT}/${IFORT_COMPILER_PATH}/bin/intel64/ifortvars_intel64.sh
    export LD_LIBRARY_PATH=${INTEL_ROOT}/${IFORT_COMPILER_PATH}/lib/intel64:$LD_LIBRARY_PATH
}
ifort_init