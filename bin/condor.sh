
# create condor user
function cndr_environment {
    CONDOR_VERSION=7.4.2
    export CONDOR_LOCATION=${OSG_BASE}/condor
    export PATH=${CONDOR_LOCATION}/bin:${CONDOR_LOCATION}/sbin:${PATH}
    export CONDOR_CONFIG=${CONDOR_LOCATION}/etc/condor_config
#    renci_ci_path --prepend=${CONDOR_LOCATION}bin:${CONDOR_LOCATION}/sbin --commit
    CONDOR_LOCAL_CONFIG=${CONDOR_SCRATCH}/condor_config.local

    renci_ci_grok_platform
    if [ "x$?" == "x1" ]; then
	renci_ci_log_info "will not continue"
	return 1
    fi

    renci_ci_log_debug "osg platform: ${OSG_PLATFORM}"
    if [ "${OSG_PLATFORM}" == "debian50" ]; then
	if [ -d "/lib64" ]; then
	    CONDOR_BINARY_FILE=condor-7.4.2-linux-x86_64-debian50-dynamic.tar.gz
	else
	    CONDOR_BINARY_FILE=condor-7.4.2-linux-x86-debian50-dynamic.tar.gz
	fi
    else
	CONDOR_BINARY_FILE=condor-7.4.2-linux-x86-${OSG_PLATFORM}-dynamic.tar.gz
    fi

    renci_ci_log_debug "condor binary: ${CONDOR_BINARY_FILE}"
    CONDOR_BINARY_URL=${OSG_WEB_SOFTWARE_REPO}/${CONDOR_BINARY_FILE}

    CONDOR_PKG=${OSG_BASE}/condor-${CONDOR_VERSION}
    CONDOR_SCRATCH=${OSG_BASE}/condor_scratch
    ${TEST} -x ${CONDOR_LOCATION}/condor.sh && \
	source ${CONDOR_LOCATION}/condor.sh
}
function cndr_get {
    renci_ci_log_info "  getting condor binaries"
    ${WGET} --timestamping ${CONDOR_BINARY_URL}
}
function cndr_unpack {
    renci_ci_log_info "  unpacking condor binaries"
    if [ -d "${CONDOR_PKG}" ]; then
	renci_ci_log_info "    skipping untar of binary - output directory exists"
    else
	renci_ci_log_info "    untar binary ${CONDOR_BINARY_FILE} to ${OSG_BASE}..."
	${TAR} xzf ${CONDOR_BINARY_FILE} -C ${OSG_BASE}
    fi
}
function cndr_install {
    renci_ci_log_info "  installing condor..." 
    ${RM} -rf ${CONDOR_SCRATCH}
    renci_ci_log_info "creating condor scratch: ${CONDOR_SCRATCH}"
    ${MKDIR} -p ${CONDOR_SCRATCH}
    TYPE=$1
    ${TEST} -z "${TYPE}" && \
	TYPE=submit,execute,manager
    ${ECHO} --installing ${TYPE}
    ${CONDOR_PKG}/condor_install \
	--install=${CONDOR_PKG} \
	--prefix=${CONDOR_LOCATION} \
	--local-dir=${CONDOR_SCRATCH} \
	--type=${TYPE}
}
function cndr_configure {
    renci_ci_log_info "  configuring condor..." 
    TIMESTAMP=`${DATE} +'%Y%m%d_%H%M'`
    renci_ci_log_info "backing up existing condor config to ${CONDOR_CONFIG}.${TIMESTAMP}"
    ${CP} ${CONDOR_CONFIG} ${CONDOR_CONFIG}.${TIMESTAMP}
    ${CP} ${CONDOR_LOCAL_CONFIG} ${CONDOR_LOCAL_CONFIG}.${TIMESTAMP}
    renci_ci_log_info "creating config file"

    # move out
    DOMAIN_NAME=`${ECHO} ${FQDN} | ${SED} s,[a-zA-Z0-9_\-]*\.,,`
    OSG_INET_ADDR=`ifconfig | grep -i "inet addr" | grep -v 127.0.0.1 | sed -e "s,^.*addr:,," -e "s, .*$,,"`

    CONDOR_USER=condor
    CONDOR_UID=`${ID} -u ${CONDOR_USER}`
    CONDOR_GID=`${ID} -g ${CONDOR_USER}`

    ${SED} \
	-e "s,OSG_INET_ADDR,${OSG_INET_ADDR}," \
	-e "s,OSG_CONDOR_SCRATCH,${CONDOR_SCRATCH}," \
	-e "s,OSG_CONDOR_RELEASE_DIR,${CONDOR_LOCATION}," \
	-e "s,OSG_ADMIN_EMAIL,${OSG_ADMIN_EMAIL}," \
	-e "s,OSG_CONDOR_LOCAL_CONFIG,${CONDOR_LOCAL_CONFIG}," \
	-e "s,OSG_CONDOR_IDS,${CONDOR_UID}.${CONDOR_GID}," \
	-e "s,OSG_UID_DOMAIN,${DOMAIN_NAME}," \
	${OSG_RESOURCES}/condor/condor_config > ${CONDOR_CONFIG}
    
    ${SED} \
	-e "s,^CONDOR_IDS =.*$,CONDOR_IDS =${CONDOR_UID}.${CONDOR_GID}," \
	-e "s,OSG_UID_DOMAIN,${DOMAIN_NAME}," \
	${OSG_RESOURCES}/condor/condor_config.local > ${CONDOR_LOCAL_CONFIG}

    for var in NETWORK_INTERFACE FULL_HOSTNAME HOSTNAME CONDOR_IDS RELEASE_DIR LOCAL_DIR UID_DOMAIN MASTER_LOG; do
	condor_config_val -v ${var}
    done
}
function cndr_cleanup {
    renci_ci_log_info "  cleaning up condor install..."
    ${RM} -rf ${CONDOR_BINARY_FILE}
}
function cndr_install_all {
    t=$(renci_ci_timer)
    renci_ci_log_info "Installing condor-${CONDOR_VERSION} to ${CONDOR_LOCATION}" &&
    (cndr_get &&
	cndr_unpack &&
	cndr_install &&
	cndr_configure &&
	cndr_cleanup)
    renci_ci_log_info "starting condor master..."
    condor_master
    renci_ci_log_info "elapsed time: $(renci_ci_timer $t)"
}
function cndr_clean {
    renci_ci_log_info "removing ${CONDOR_PKG}..."
    ${RM} -rf "${CONDOR_PKG}" 
    renci_ci_log_info "removing ${CONDOR_LOCATION}..."
    ${RM} -rf "${CONDOR_LOCATION}"
    renci_ci_log_info "removing ${CONDOR_SCRATCH}..."
    ${RM} -rf "${CONDOR_SCRATCH}"
    renci_ci_log_info "removing ${CONDOR_BINARY_FILE}..."
    ${RM} -rf "${CONDOR_BINARY_FILE}"
}
function cndr_tail {
    ${TAIL} -f ${CONDOR_SCRATCH}/log/MasterLog
}
cndr_procs () {
    ps -ef | grep condor 
}
function cndr_kill {
    for p in `ps -ef | grep " condor_" | cut -c10-15`; do echo $p; kill -9 $p; done
}
cndr_environment
