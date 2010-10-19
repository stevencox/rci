renci_ci_environment () {
    export RENCI_HOME=`dirname ${BASH_SOURCE[0]}`
    export RENCI_CI_REPO=http://152.54.9.153:8081/nexus/content/repositories/renci-build-server

    export FQDN=`/bin/hostname -f`
    export APT_GET=/usr/bin/apt-get
    export APT_CACHE=/usr/bin/apt-cache
    export AWK=/usr/bin/awk
    export BASENAME=/usr/bin/basename
    export BASH=/bin/bash
    export BZIP2=/bin/bzip2
    export CAT=/bin/cat
    export CHMOD=/bin/chmod
    export CHOWN=/bin/chown
    export DIRNAME=/usr/bin/dirname
    export CP=/bin/cp
    export CUT=/usr/bin/cut
    export DATE=/bin/date
    export ECHO=/bin/echo
    export ENV=/usr/bin/env    
    export FIND=/usr/bin/find
    export GREP=/bin/egrep
    export ID=/usr/bin/id
    export KILL=/bin/kill
    export MAKE=/usr/bin/make
    export LN=/bin/ln
    export LS=/bin/ls
    export MKDIR=/bin/mkdir
    export MKTEMP=/bin/mktemp
    export MV=/bin/ls
    export MV=/bin/mv
    export NETSTAT=/bin/netstat
    export NSLOOKUP=/usr/bin/nslookup
    export OPENSSL=/usr/bin/openssl
    export OBJDUMP=/usr/bin/objdump
    export PATCH=/usr/bin/patch
    export PERL=/usr/bin/perl
    export PS=/bin/ps
    export EPWD=/bin/pwd
    export RM=/bin/rm
    export RSYNC=/usr/bin/rsync
    export SED=/bin/sed
    export SORT=/usr/bin/sort
    export SUDO=/usr/bin/sudo
    export TAIL=/usr/bin/tail
    export TAR=/bin/tar
    export TEE=/usr/bin/tee
    export TEST=/usr/bin/test
    export TOUCH=/usr/bin/touch
    export TREE=/usr/bin/tree
    export WC=/usr/bin/wc
    export WGET=/usr/bin/wget
    export UNAME=/bin/uname
    export UNZIP=/usr/bin/unzip
    export XINETD=/etc/init.d/xinetd
    export XARGS=/usr/bin/xargs
    if [ -z "${CONDOR_LOCATION}" ]; then
	CONDOR_LOCATION=""
    fi
    export GLOBUS_URL_COPY=${GLOBUS_LOCATION}/bin/globus-url-copy
    export GLOBUS_JOB_RUN=${GLOBUS_LOCATION}/bin/globus-job-run
    export CONDOR_SUBMIT=${CONDOR_LOCATION}/bin/condor_submit
    ${TEST} ! -x ${SORT} && SORT=/bin/sort #CentOS
}
rci_update_src () {
    local old=
    local dir=
    local outdir=
    local usage="usage: rci_update_src --old=<p> --new=<p> --dir=<d> --outdir=<d>"
    for arg in $*; do
	    echo "  --- $arg"
	case $arg in
	    --old\=*) old=$( renci_ci_getarg $arg );;
	    --new\=*) new=$( renci_ci_getarg $arg );;
	    --dir\=*)     dir=$( renci_ci_getarg $arg );;
	    --outdir\=*)  outdir=$( renci_ci_getarg $arg );;
	    *)            renci_ci_log_error ${usage}; return 1;;
	esac
    done
    renci_ci_log_info "   dir: $dir"
    renci_ci_log_info "   old: $old"
    renci_ci_log_info "   new: $new"
    renci_ci_log_info "outdir: $outdir"
    if [ -z "${old}" ]; then echo a; ${ECHO} ${usage}; return 1; fi
    if [ -z "${outdir}" ]; then echo b; ${ECHO} ${usage}; return 1; fi

    if [ ! -d ${outdir} ]; then
	${MKDIR} -p ${outdir}
    fi
    ${CP} -rf ${dir}/* ${outdir}

    cd ${outdir}
    renci_ci_log_info "Now in ${PWD}..."
    TIMESTAMP=$( ${DATE} +'%y%m%d%H%M' )
    for file in $( ${FIND} | ${GREP} -v ".svn" ); do
	file=$( ${ECHO} ${file} | ${SED} s,^./,, )
	if [ -f "${file}" ]; then
	    ${SED} s,${old},${new},g ${file} > ${file}.${TIMESTAMP}
	    renci_ci_log_info ${outdir}/${file}
	    ${MV} ${file}.${TIMESTAMP} ${file}
	fi
    done
}

onemig () {
    local old_dir=/home/scox/dev/rencici
    local new_dir=/home/scox/dev/rci
    rci_update_src --old=renci_ci_ --new=rci_ --dir=${old_dir} --outdir=${new_dir}
    for log_level in info error warn debug; do
	rci_update_src --old=rci_log_${log_level} --new=rci_l${log_level} --dir=${old_dir} --outdir=${new_dir}
    done
}

renci_ci_initialize () {
    EXIT_CODE=1
    
    LOG_LEVEL=2 # error=0, warn=1, info=2, debug=3
    LOG_ERROR=0
    LOG_WARN=1
    LOG_INFO=2
    LOG_DEBUG=3

    if [ -z "${APP_BASE}" ]; then
	export APP_BASE=~/.renci/app
    fi
    export APP_SCRATCH=${APP_BASE}/scratch
    ${MKDIR} -p ${APP_SCRATCH}

    TOP_DIR=`${EPWD}`
    export BASE_URL="gsiftp://${FQDN}${TOP_DIR}"
    RESOURCES=${TOP_DIR}/app/resources
    APP_BIN=${TOP_DIR}/app/bin
    APP_IN=${TOP_DIR}/app/in

    if [ -z "${OSG_BASE}" ]; then
	export OSG_BASE=~/.osg
	${MKDIR} -p ${OSG_BASE}
	#renci_ci_log_warn "OSG_BASE is not set. Setting to ${OSG_BASE}. "
    fi
    OSG_RESOURCES=${RENCI_HOME}/../resources
    OSG_WEB_SOFTWARE_REPO=http://www.renci.org/~scox/bin

    job_init

    MAX_WALL_TIME=60
    MEMORY_REQUIREMENT=400
    SUCCESS_SIGNAL="=== RUN SUCCESSFUL ==="

    renci_ci_log_debug "top_dir  : ${TOP_DIR}"
    renci_ci_log_debug "base_url : ${BASE_URL}"
    renci_ci_log_debug "run_dir  : ${RUN_DIR}"
}
renci_ci_appbase () {
    cd ${APP_BASE}
}
renci_ci_home () {
    cd ${RENCI_HOME}
}
renci_ci_reload () {
    source ${RENCI_HOME}/environment.sh
}
renci_ci_require () {
    local module=$1;
    if [ -d "${RENCI_HOME}/../app/${module}" ]; then
	source ${RENCI_HOME}/../app/${module}/${module}.sh
	if [ "$?" = 0 ]; then
	    ${ECHO} | ${AWK} -v module=${module} '{printf("%s%50s\n", module, "[Ok]")}' | ${SED} -e "s, ,\.,g"
	else
	    ${ECHO} | ${AWK} -v module=${module} '{printf("%s%50s\n", module, "[Fail]")}' | ${SED} -e "s, ,\.,g"
	    renci_ci_log_error "Module ${module} exists but an error occurred loading it."
	fi
    else
	renci_ci_log_error "no such module: ${RENCI_HOME}/../app/${module}"
	return 1
    fi
}
renci_ci_amber_tools () {
    source ${RENCI_HOME}/amber.sh
}
renci_ci_grid_tools () {
    source ${RENCI_HOME}/gtk.sh
    source ${RENCI_HOME}/condor.sh
    source ${RENCI_HOME}/osg.sh
    source ${RENCI_HOME}/torque.sh
}
renci_ci_set_log_level () {
    S=false
    ${TEST} $1 = ${LOG_ERROR} ||
    ${TEST} $1 = ${LOG_WARN} ||
    ${TEST} $1 = ${LOG_INFO} ||
    ${TEST} $1 = ${LOG_DEBUG} && {
	LOG_LEVEL=$1
	S=true
    }
    ${TEST} $S = false && renci_ci_log_error "$1 is not a valid log level"
}
renci_ci_log_error () {
    ${TEST} ${LOG_LEVEL} -ge ${LOG_ERROR} && ${ECHO} "--(err): $*"
    return 0
}
renci_ci_log_warn () {
    ${TEST} ${LOG_LEVEL} -ge ${LOG_WARN} && ${ECHO} "--(warn): $*"
    return 0
}
renci_ci_log_info () {
    ${TEST} ${LOG_LEVEL} -ge ${LOG_INFO} && ${ECHO} "--(inf): $*"
    return 0
}
renci_ci_log_debug () {
    ${TEST} ${LOG_LEVEL} -ge ${LOG_DEBUG} && ${ECHO} "--(dbg): $*"
    return 0
}
renci_ci_wget () {
    renci_ci_log_info "getting ${OSG_WEB_SOFTWARE_REPO}/$1"
    ${WGET} --timestamping ${OSG_WEB_SOFTWARE_REPO}/$1
}
renci_ci_show_env () {
    if ${TEST} -z "$1"; then
	ENV_MAP="condor_home|java_home|condor_config|pacman_home|vdt_location"
    else
	ENV_MAP=$1
    fi
    ${ENV} | ${GREP} -i "${ENV_MAP}" | ${SORT} | ${SED} -e "s,=, \t: ,g" -e "s,^,--(env): ,g"
}
renci_ci_confirm () {
    echo -n "$@ "
    read -e answer
    for response in y Y yes YES Yes; do
        if [ "_$answer" == "_$response" ]; then
            return 0
        fi
    done
    return 1
}
renci_ci_path () {
    local purge=`${DATE}`
    local commit=false
    local prepend=
    local append=
    local list=
    renci_ci_log_debug "renci_ci_path..."
    for arg in $*; do
	case $arg in
	    --purge\=*)   purge=`${ECHO} $arg | ${SED} s,--purge=,,`;
		renci_ci_log_debug "purge=$purge";;
	    --list)       list=true;
		          renci_ci_log_debug "list=true";;
	    --commit)     commit=true;
		          renci_ci_log_debug "commit=$commit";;
	    --prepend\=*) prepend=`${ECHO} $arg | ${SED} s,--prepend=,,`;
		          renci_ci_log_debug "preped=$prepend";;
	    --append\=*)  append=`${ECHO} $arg | ${SED} s,--append=,,`;
		          renci_ci_log_debug "append=$append";;
	    *)            renci_ci_log_error "usage: path [--commit] [--purge=pattern] [--prepend=path] [--append=path]";
                          return 1;;
	esac
    done
    THE_PATH="`${ECHO} $PATH | ${SED} "s,:, ,g"`"
    TEMP_PATH=$prepend
    for item in ${THE_PATH}; do
	seen=`${ECHO} ${TEMP_PATH} | ${GREP} -c :${item}:`
	if [ "$seen" -eq 0 ]; then
	    contains=`${ECHO} $item | grep -c "$purge"`
	    if [ "$contains" -eq 0 ]; then
		if [ "x${list}" = "xtrue" ]; then
		    renci_ci_log_info "   --: $item"
		else
		    renci_ci_log_debug "   --: $item"
		fi
		TEMP_PATH=$TEMP_PATH:$item:
	    fi
	fi
    done
    TEMP_PATH=$TEMP_PATH:$append
    if [ "x$commit" = "xtrue" ]; then
	export PATH=$TEMP_PATH
	renci_ci_log_debug "path: $PATH"
    fi    
}
function renci_ci_grok_platform {
    OSG_PLATFORM=undefined
    RED_HAT_5=rhel5
    DEBIAN_5=debian50
    IS_DEBIAN5=`${UNAME} -a | ${GREP} -ci "debian|ubuntu"`
    if [ "${IS_DEBIAN5}" == "1" ]; then 
	renci_ci_log_debug "detected debian(or ubuntu) platform"
	export OSG_PLATFORM=${DEBIAN_5}
	return 0
    fi
    IS_REDHAT5=`${UNAME} -a | ${GREP} -ci el5`
    if [ "${IS_REDHAT5}" == "1" ]; then 
	renci_ci_log_debug "detected redhat platform"
	export OSG_PLATFORM=${RED_HAT_5}
	return 0
    fi

    if [ "x${IS_DEBIAN5}" == "x1" ]; then
	export OSG_PLATFORM=${DEBIAN_5}
    fi
    if [ "x${IS_DEBIAN5}" == "x1" ]; then
	export OSG_PLATFORM=${DEBIAN_5}
    fi
    if [ -z "${OSG_PLATFORM}" ]; then
	renci_ci_log_info "Unable to determine platform"
	return 1;
    fi    
}
#####################################################################
# If called with no arguments a new timer is returned.
# If called with arguments the first is used as a timer
# value and the elapsed time is returned in the form HH:MM:SS.
#
renci_ci_timer () {
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local  stime=$1
        etime=$(date '+%s')

        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%d:%02d:%02d' $dh $dm $ds
    fi
}

# =========== local utilities
job_gridftp_who () {
    for p in `${NETSTAT} -tnap | ${GREP} 2811 | ${GREP} -vi listen | ${CUT} -c45-57`; do
	${NSLOOKUP} $p | ${GREP} "name ="
    done
}
job_proxy_info () {
    voms-proxy-info -all
    grid-proxy-info 
}
job_proxy_init () {
    voms-proxy-init -voms Engage -valid 72:00
    grid-proxy-init
}
job_proxy_is_valid () {
    TIMELEFT=`voms-proxy-info 2>&1 | ${GREP} timeleft | ${SED} -e 's,[0 \:],,g'`
    
    if [ "x${TIMELEFT}" = "x" ]; then
	echo "false"
    else
	if [ "x${TIMELEFT}" = "xtimeleft" ]; then
	    echo "false"
	else 
	    echo "true"
	fi
    fi
}
job_require_valid_proxy () {
    if [ "x`job_proxy_is_valid`" = "xfalse" ]; then
	renci_ci_log_error "the grid proxy does not exist or has expired..."
	job_proxy_init
    else
	renci_ci_log_info "verified valid grid proxy..."
    fi
}
job_submit () {
    EXECUTABLE_PATH=$1
    if [ -z "${EXECUTABLE_PATH}" ]; then
	EXECUTABLE_PATH=job.sh
    fi
    job_require_valid_proxy &&
    renci_ci_log_info "set up run environment..." &&
    RUN_ID=`${DATE} +'%Y%m%d_%H%M'` &&
    RUN_DIR=${TOP_DIR}/runs/${RUN_ID} &&
    renci_ci_log_info "run directory: ${RUN_DIR}" &&
    ${CHMOD} +x ${APP_BIN}/* &&
    ${MKDIR} -p ${RUN_DIR}/outputs &&
    ${TOUCH} ${RUN_DIR}/alljobs.log &&
    ${CHMOD} 644 ${RUN_DIR}/alljobs.log &&
    unset CUSTOM_GLOBUSRSL &&
    unset CUSTOM_GRID_GLUE &&
    if [ -f "${RESOURCES}/globusrsl.txt" ]; then
	CUSTOM_GLOBUSRSL=$(${CAT} ${RESOURCES}/globusrsl.txt) &&
	renci_ci_log_info "user defined Globus RSL: ${CUSTOM_GLOBUSRSL}"
    fi &&
    if [ -f "${RESOURCES}/grid-glue.txt" ]; then
	CUSTOM_GRID_GLUE=$(${CAT} ${RESOURCES}/grid-glue.txt) &&
	renci_ci_log_info "user defined grid glue: ${CUSTOM_GRID_GLUE}"
    fi &&
    renci_ci_log_info "generating job submit files..." &&
    JOB_ID=0 &&
    for input in `${LS} app/in | ${SORT}`; do 
	JOB_ID=$((${JOB_ID} + 1)) &&
	renci_ci_log_info "   generate job ${JOB_ID} processing ${APP_IN}/${input}" &&
	${MKDIR} -p ${RUN_DIR}/logs/${JOB_ID} &&
	${SED} \
	    -e "s,RUN_DIR,${RUN_DIR},g" \
	    -e "s,BASE_URL,${BASE_URL},g" \
	    -e "s,RUN_ID,${RUN_ID},g" \
	    -e "s,JOB_ID,${JOB_ID},g" \
	    -e "s,MAX_WALL_TIME,${MAX_WALL_TIME},g" \
	    -e "s,MEMORY_REQUIREMENT,${MEMORY_REQUIREMENT},g" \
	    -e "s,CUSTOM_GLOBUSRSL,${CUSTOM_GLOBUSRSL},g" \
	    -e "s,CUSTOM_GRID_GLUE,${CUSTOM_GRID_GLUE},g" \
	    -e "s,TOP_DIR,${TOP_DIR},g" \
	    -e "s,INPUT_FILE,${input},g" \
	    -e "s,USER,${USER},g" \
	    -e "s,EXECUTABLE_PATH,${EXECUTABLE_PATH},g" \
	    ${OSG_RESOURCES}/job/submit.txt > ${RUN_DIR}/${JOB_ID}.submit.txt &&

	${SED} \
	    -e "s,RUN_DIR,${RUN_DIR},g" \
	    -e "s,RUN_ID,${RUN_ID},g" \
	    -e "s,APP_BIN,${APP_BIN},g" \
	    -e "s,JOB_ID,${JOB_ID},g" ${OSG_RESOURCES}/job/dag_fragment.txt >> ${RUN_DIR}/master.dag 
    done &&

    renci_ci_log_info "submitting master DAG:" &&
    ${CAT} ${RUN_DIR}/master.dag &&
    condor_submit_dag -notification NEVER ${RUN_DIR}/master.dag &&
    ${TOUCH} ${RUN_DIR}/alljobs.log &&
    ${CHMOD} 644 ${RUN_DIR}/alljobs.log
}
job_submit_files () {
    ${CAT} -f ${RUN_DIR}/*submit.txt
}
job_dag () {
    ${TAIL} -f ${RUN_DIR}/master.dag.dagman.out
}
job_log () {
    for output in $*; do
	${TAIL} -f ${RUN_DIR}/logs/*/*.${output}
    done
}
job_out_ls () {
    ${LS} -lisa ${RUN_DIR}/outputs/*
}
job_out_tail () {
    ${TAIL} -f ${RUN_DIR}/outputs/*
}
job_init () {
    ${TEST} -d ${TOP_DIR}/runs && RUN_ID=`${LS} -1 ${TOP_DIR}/runs | ${TAIL} -1`
    RUN_DIR=${TOP_DIR}/runs/${RUN_ID}
    renci_ci_log_debug "pointing to latest run: ${RUN_DIR}"
}
job_initialize () {
    echo pre job
    job_init
    ${TOUCH} ${RUN_DIR}/alljobs.log
    ${CHMOD} 644 ${RUN_DIR}/alljobs.log
}
job_shutdown () {
    TIMESTAMP=$( ${DATE} +'%y%m%d_%H:%M' )
    JOB_CHECK_LOG=${RUN_DIR}/logs/${JOB_ID}/job.check
    echo ${RUN_DIR}/logs/${JOB_ID}/job.out >> ${JOB_CHECK_LOG}
    if [ "x`${GREP} -c '=== RUN SUCCESSFUL ===' ${RUN_DIR}/logs/${JOB_ID}/job.out`" == "x1" ]; then
	renci_ci_log_info "${TIMESTAMP}: Found job success marker for ${JOB_ID} in run ${RUN_ID}" >> ${JOB_CHECK_LOG}
	renci_ci_log_info "${TIMESTAMP}:   -- exiting with status 0" >> ${JOB_CHECK_LOG}
	exit 0
    else
	renci_ci_log_error "${TIMESTAMP}: Job ${JOB_ID} does not have a success marker." >> ${JOB_CHECK_LOG}
	renci_ci_log_error "${TIMESTAMP}:  -- saving its output to checked.$TIMESTAMP files..." >> ${JOB_CHECK_LOG}
	renci_ci_log_info "${TIMESTAMP}:   -- exiting with status 1" >> ${JOB_CHECK_LOG}
        # keep copies of the output for failed jobs
	cd $RUN_DIR/logs/$JOB_ID
	${CP} job.out job.out.checked.$TIMESTAMP
	${CP} job.err job.err.checked.$TIMESTAMP
	exit 1
    fi
}

# execute an application using globus tools.
# job_run <host> <app_name>
job_run () {
    job_require_valid_proxy
    local host=
    local renci_dir=~/.renci
    local renci_env=${renci_dir}/environment.sh
    local app_path=
    local app_dir=
    local clean=0
    local exe_arg=
    local usage="usage: job_run <host> <app>"

    renci_ci_log_debug "renci_ci_path..."
    for arg in $*; do
	case $arg in
	    --host\=*) host=$( ${ECHO} $arg | ${SED} s,--host=,, );;
	    --app\=*) app_path=$( ${ECHO} $arg | ${SED} s,--app=,, );;
	    --exe\=*) exe_arg="-- --exec=$( ${ECHO} $arg | ${SED} s,--exe=,, )";;
	    --clean) clean=1;;
	    *) ${ECHO} ${usage}; return 1;;
	esac
    done
    ${TEST} -z "${host}" && (${ECHO} $usage && return 1)

    # cd to app
    if [ -z "${app_path}" ]; then
	renci_ci_log_info "setting app to ${PWD}"
	app_path=${PWD}
    fi
    cd ${app_path} || ( renci_ci_log_error "unable to cd to ${app_path}" && return 1)
    TOP_DIR=${PWD}
    app_path=${PWD}
    app_dir=$( ${BASENAME} ${PWD} )
    if [ ! -d app/bin ]; then
	renci_ci_log_error "${PWD} does not have the structure of a renci application."
	return 1
    fi

    # create run dir
    export RUN_ID=`${DATE} +'%Y%m%d_%H%M'`
    export RUN_DIR=${TOP_DIR}/runs/${RUN_ID}
    if [ "${clean}" = 1 ]; then
	renci_ci_log_info "cleaning: removing previous run dirs..."
	${RM} -rf ${RUN_DIR}/*
    fi
    ${MKDIR} -p ${RUN_DIR}
    renci_ci_initialize 
    renci_ci_line
    renci_ci_log_info "running ${app_path} @ ${host}. Run id: ${RUN_ID}"
    renci_ci_log_info "   --removing old app launcher script at ${host}..."
    renci_env=${renci_dir}/bin/environment.sh
    ${GLOBUS_JOB_RUN} ${host} \
	${RM} -rf ${renci_env}
    renci_ci_log_info "   --staging app launcher script to ${host}..."
    ${GLOBUS_URL_COPY} \
	-create-dest \
        file://${RENCI_HOME}/environment.sh \
	gsiftp://${host}/${renci_env} \
        || return 1
    renci_ci_log_info "   --making launcher script at ${host} executable..."
    ${GLOBUS_JOB_RUN} ${host} \
	${CHMOD} +x ${renci_env}

    renci_ci_log_info "   --copying renci environment into application..."
    # put the renci env in the app before the app calls stage_in from the remote host.
    ${RM} -rf ${app_path}/app/bin/rencici
    ${MKDIR} -p ${app_path}/app/bin/rencici/bin
    ${CP} -r ${RENCI_HOME}/* ${app_path}/app/bin/rencici/bin

    renci_ci_log_info "   --executing remote application at ${host} with run id ${RUN_ID}..."
    ${GLOBUS_JOB_RUN} ${host} \
	${renci_env} ${exe_arg} -- --runapp=gsiftp://${HOSTNAME}/${PWD} -- --runid=${RUN_ID}

    renci_ci_log_info "   --removing renci env from application..."
    # get rid of the renci env.
    ${RM} -rf ${app_path}/app/bin/rencici
    ${GLOBUS_JOB_RUN} ${host} \
	${RM} -rf ${renci_env}

}

# =========== remote utilities
job_setup_grid_environment () {
    export START_DIR=`${EPWD}`
    job_create_work_dir
    export STDOUT=${WORK_OUT_DIR}/app.stdouterr
    export STDIN=${WORK_DIR}/${INPUT_FILE}
    touch ${STDOUT}
    job_write_host_info > ${WORK_OUT_DIR}/app.env
    ${TEST} -z "$PATH" && export PATH="/usr/bin:/bin"
    . $OSG_GRID/setup.sh || {
	echo "Unable to source \$OSG_GRID/setup.sh"
	exit 1
    }
    set -o nounset
    set -e
    set -o pipefail
}
job_write_host_info () {
    renci_ci_log_info "Running on" `hostname -f` "($OSG_SITE_NAME)"
    renci_ci_log_info "`uname -a`"
    ${TEST} -e /etc/redhat-release && (renci_ci_log_info "OS: RedHat" && ${CAT} /etc/redhat-release)
    ${TEST} -e /etc/debian_version && (renci_ci_log_info "OS: Debian" && ${CAT} /etc/debian_version)
    ${ENV}
    ${CAT} /proc/cpuinfo
    ${CAT} /proc/meminfo
}
job_create_work_dir () {
    unset TMPDIR
    STATUS=1
    TARGETS="$OSG_WN_TMP $OSG_DATA/engage/tmp"
    for directory in $TARGETS; do
	WORK_DIR=`${MKTEMP} -d -p ${directory} job.XXXXXXXXXX`
        if [ $? = 0 ]; then
            renci_ci_log_info "Created workdir in ${directory}"
            export WORK_DIR
	    export WORK_OUT_DIR=${WORK_DIR}/out
	    ${MKDIR} -p ${WORK_OUT_DIR}
            STATUS=0
	    break
	else
            renci_ci_log_error "Failed to create workdir in ${directory}"
        fi
    done
    return ${STATUS}
}
stage_in () {
    renci_ci_log_info "stage data into work dir: ${WORK_DIR}"
    cd $WORK_DIR
    export APP_BIN=${WORK_DIR}/app/bin
    ${MKDIR} -p ${APP_BIN}

    # get the application
    renci_ci_log_info "getting ${BASE_URL}/app/"
    ${GLOBUS_URL_COPY} -notpt -nodcau -recurse \
        ${BASE_URL}/app/ \
        file://${WORK_DIR}/app/ \
        || return 1
    ${CHMOD} -R 755 ${APP_BIN}/*
    return 0
}
stage_out () {
    cd $WORK_DIR
    renci_ci_log_info "staging out ${WORK_DIR}/app.stdouterr"
    if [ -d ${WORK_OUT_DIR} ]; then
	if [ "x${JOB_ID}" = "xnone" ]; then
	    ${GLOBUS_URL_COPY} -create-dest -notpt -nodcau -recurse \
		file://${WORK_OUT_DIR}/ \
		${BASE_URL}/runs/${RUN_ID}/out/ \
		|| return 1
	else
	    ${GLOBUS_URL_COPY} -create-dest -notpt -nodcau -recurse \
		file://${WORK_OUT_DIR}/ \
		${BASE_URL}/runs/${RUN_ID}/${JOB_ID}/out/ \
		|| return 1
	fi
    fi
    return 0                                                              
}
job_wait_for_file () {
    local files=
    local maxcycles=$2
    local pausetime=$3
    local cycles=0
    for arg in $*; do
	case $arg in
	    --file\=*) files="$files $( renci_ci_getarg $arg )";;
	    --max-cycles\=*) maxcycles="$( renci_ci_getarg $arg )";;
	    --pause-time\=*) pausetime="$( renci_ci_getarg $arg )";;
	esac
    done
    renci_ci_log_info "waiting for [files=($files), cycles=$cycles, maxcycles=$maxcycles, pausetime=$pausetime]..."
    while true; do
	for file in $files; do
	    if [ -f ${file}* ]; then
		renci_ci_log_info "      --(wait): file pattern ${file} matched."
		return 0
	    fi
	done
	renci_ci_log_info "      --(wait): $(( $cycles * ${pausetime} )) of $(( ${maxcycles} * ${pausetime} )) seconds elapsed..."
	sleep $pausetime
	cycles=$(( $cycles + 1 ))
	if [ $cycles -ge ${maxcycles} ]; then
	    renci_ci_log_error "exiting after waiting $(( $maxcycles * $pausetime )) seconds."
	    return 1
	fi
    done
}
job_cleanup () {
    renci_ci_log_info "executing job cleanup..."
    cd $START_DIR
    ${RM} -rf $WORK_DIR || /bin/true    
    if [ "x${EXIT_CODE}" = "x0" ]; then
	${ECHO} ${SUCCESS_SIGNAL}
    else
	${ECHO} "Job ${JOB_ID} in run ${RUN_ID} failed with status: ${EXIT_CODE}"
    fi
    exit ${EXIT_CODE}
}

# General control and support
renci_ci_line () {
    renci_ci_log_info "==========================================================================================================="
}
usage () {
    renci_ci_log_info "usage ..."
    exit 1
}
renci_ci_test () {
    renci_ci_set_log_level $LOG_INFO
    renci_ci_grid_tools
    renci_ci_amber_tools
    ${ECHO} "end renci ci test"
}
renci_ci_getarg () {
     ${ECHO} $1 | ${SED} s,.*=,,
}
job_main () {
    local OPTIND
    local OPTARG
    local test_rencici=false

    BASE_URL=
    EXECUTABLE=
    RUN_DIR=
    FUNCTION=
    INPUT_FILE=
    JOB_ID=
    RUN_ID=

    for arg in $*; do
	renci_ci_log_info "   --processing argument: [$arg]"
	case $arg in
	    --appurl\=*) export BASE_URL=$( renci_ci_getarg $arg ); renci_ci_log_debug base url: $BASE_URL;;
	    --rundir\=*) export RUN_DIR=$( renci_ci_getarg $arg ); renci_ci_log_debug rundir: $RUN_DIR;;
	    --exec\=*)   export EXECUTABLE=$( renci_ci_getarg $arg ); renci_ci_log_debug executable: $EXECUTABLE;;
	    --func\=*)   export FUNCTION=$( renci_ci_getarg $arg ); renci_ci_log_debug func: $FUNCTION;;
	    --infile\=*) export INPUT_FILE=$( renci_ci_getarg $arg ); renci_ci_log_debug infile: $INPUT_FILE;;
	    --jobid\=*)  export JOB_ID=$( renci_ci_getarg $arg ); renci_ci_log_debug jobid: $JOB_ID;;
	    --runid\=*)  export RUN_ID=$( renci_ci_getarg $arg ); renci_ci_log_debug runid: $RUN_ID;;
	    --test)      test_rencici=true;;
	    --runapp\=*)
		export BASE_URL=$( renci_ci_getarg $arg );
		renci_ci_log_debug base url: $BASE_URL;
		export JOB_ID=none;;
	    *) usage;;
	esac
    done

    ${TEST} ! -z "${RUN_DIR}" &&
    ${TEST} ! -z "${RUN_ID}" &&
    ${TEST} ! -z "${JOB_ID}" &&
    ${TEST} ! -z "${FUNCTION}" && {
	renci_ci_log_info "executing function ${FUNCTION}..."
	${FUNCTION} ${RUN_DIR} ${RUN_ID} ${JOB_ID}
	return $?
    }

    ${TEST} ! -z "${EXECUTABLE}" &&
    ${TEST} ! -z "${RUN_ID}" &&
    ${TEST} ! -z "${JOB_ID}" &&
    ${TEST} ! -z "${BASE_URL}" && {
	job_setup_grid_environment
	trap job_cleanup 1 2 3 6
	renci_ci_line
	renci_ci_log_info "executable: ${EXECUTABLE}"
	renci_ci_log_info "run id    : ${RUN_ID}"
	renci_ci_log_info "job id    : ${JOB_ID}"
	renci_ci_log_info "base url  : ${BASE_URL}"
	renci_ci_log_info "input file: ${INPUT_FILE}"
	renci_ci_log_info "work dir  : ${WORK_DIR}"
	renci_ci_log_info "start dir : ${START_DIR}"
	renci_ci_line
	if [ -r ${WORK_DIR}/app/bin/.settings ]; then
	    renci_ci_log_info "--reading settings:"
	    source ${WORK_DIR}/app/bin/.settings
	    ${CAT} ${WORK_DIR}/app/bin/.settings
	fi
	(cd ${WORK_DIR} && \
	    stage_in && \
	    renci_ci_log_info "sourcing	${WORK_DIR}/app/bin/${EXECUTABLE}" && \
	    source ${WORK_DIR}/app/bin/${EXECUTABLE} && \
	    job_run_model $RUN_ID $JOB_ID && \
	    stage_out)
	EXIT_CODE=$?
	job_cleanup
    }

    if [ "x${test_rencici}" = "xtrue" ]; then
	TEST_LOG=test.log
	renci_ci_test > ${TEST_LOG}
    fi

    return ${EXIT_CODE}
}

renci_ci_environment
renci_ci_initialize $*
${TEST} "$#" != "0" && job_main $*
rencici () {
    renci_ci_grid_tools
}
#export PS1="[\u@\h:\w]$ "