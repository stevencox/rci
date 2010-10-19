
#######################################################################################
## 
## This installs a RENCI Open Science Grid (OSG) Compute Element (CE) 
## 
## It assembles this configuration of the Virtual Data Toolkit (VDT) stack:
## 
##     - Installation tools
##        - pacman
## 
##     - Grid ftp and job submission
##        - Globus GridFTP
##        - Globus GRAMS
## 
##     - Batch scheduler
##        - Condor
## 
##  Based on CE QuickStart: https://twiki.grid.iu.edu/bin/view/ReleaseDocumentation/QuickInstallGuide
##  And Preparation Guide: https://twiki.grid.iu.edu/bin/view/ReleaseDocumentation/PreparingComputeElement
## - get certificate
##    - (1) DOE Grids user cert
##    - (2) host cert
##    - (3) http cert
## - verify ntp is running
## - verify hostname is fully qualified domain name (FQDN)
## - think about the firewall
##
##
##    
##    install_ce () {
##        source ~/app/rencici-0.1alpha/bin/environment.sh
##        renci_ci_grid_tools
##        osg_environment_init               \
##    	      --admin-name="Admin Name"      \
##            --admin-email="admin@xxx.org"  \
##            --admin-phone="(999) 999-9999" \
##    	      --osg-base="/opt"              \
##    	      --osg-version=1.2.13           \
##    	      --osg-key-repo=~/.globus
##        osg_install_all --purge > ~/osg-install-log.txt 2>&1
##    }
##    
##
##
#######################################################################################

function osg_environment_init {

    for arg in $*; do
	case $arg in
	    --admin-name\=*)   OSG_ADMIN_NAME=$( renci_ci_getarg $arg );;
	    --admin-email\=*)  OSG_ADMIN_EMAIL=$( renci_ci_getarg $arg );;
	    --admin-phone\=*)  OSG_ADMIN_PHONE=$( renci_ci_getarg $arg );;
	    --osg-base\=*)     OSG_BASE=$( renci_ci_getarg $arg );;
	    --osg-version\=*)  OSG_CE_VERSION=$( renci_ci_getarg $arg );;
	    --osg-key-repo\=*) OSG_KEY_REPO=$( renci_ci_getarg $arg );;
	esac
    done

    osg_require_cert_env

    # local (1)
    #export OSG_BASE=${OSG_BASE:-/opt}
    if [ -z "${OSG_BASE}" ]; then
	renci_ci_log_error "OSG_BASE is not set"
	return 1
    else
	renci_ci_log_info "OSG_BASE is $OSG_BASE"
    fi
    if [ ! -d "${OSG_KEY_REPO}" ]; then
	renci_ci_log_error "OSG_KEY_REPO is not a valid directory"
	return 1
    else
	renci_ci_log_info "OSG_KEY_REPO is $OSG_KEY_REPO"
    fi
    if [ -z "${OSG_CE_VERSION}" ]; then
	export OSG_CE_VERSION=1.2.11
    fi

    OSG_BASE=${OSG_BASE}/${OSG_CE_VERSION}
    renci_ci_log_info "new OSG_BASE is $OSG_BASE"

    export VDT_LOCATION=${OSG_BASE}/osg-${OSG_CE_VERSION}

    # required by the (documented) install procedure
    export PER_JOB_HISTORY_DIR=${VDT_LOCATION}/gratia/var/data
    export VDTSETUP_CONDOR_LOCATION=${CONDOR_HOME}
    export VDTSETUP_CONDOR_CONFIG=${CONDOR_CONFIG}
    #export X509_USER_CERT=${X509_USER_CERT:-/etc/grid-security/hostcert.pem}
    export GRID_SECURITY_DIR=/etc/grid-security
    export GLOBUS_LOCATION=${VDT_LOCATION}/globus
    export VDTSETUP_CONDOR_LOCATION=${CONDOR_LOCATION}
    export VDTSETUP_CONDOR_CONFIG=${CONDOR_LOCATION}/etc/condor_config
    export WORKER_NODE_CLIENT=${OSG_BASE}/wn-${OSG_CE_VERSION}
    export PATH=${GLOBUS_LOCATION}/bin:${PATH}
    export PATH=${VDT_LOCATION}/vdt/bin:${PATH}
    export PATH=${VDT_LOCATION}/glite/bin:${PATH}
    export OSG_CE_APP_DIR=${OSG_BASE}/osg-app
    export OSG_CE_DATA_DIR=${OSG_BASE}/osg-data

    export CERT_REQUEST_DIR=${OSG_BASE}/../osg-cert-requests

    ${TEST} -e ${VDT_LOCATION}/setup.sh && source ${VDT_LOCATION}/setup.sh

    # local (2)
    PACMAN_VERSION=3.28
    PACMAN_TAR_URL=http://atlas.bu.edu/~youssef/pacman/sample_cache/tarballs/pacman-${PACMAN_VERSION}.tar.gz
    PACMAN_HOME=${OSG_BASE}/pacman-${PACMAN_VERSION}
    export OSG_CE_CONFIG_DIR=${OSG_BASE}/osg-${OSG_CE_VERSION}/monitoring
    OSG_CONFIG_INI_TEMPLATE=${OSG_RESOURCES}/osg/config.ini.template
    LOC_CONDOR_CONF=${VDT_LOCATION}/condor/local.`hostname`/condor_config.local
    VDT_CA_MANAGE=vdt-ca-manage
    VDT_CONTROL=vdt-control
    CONFIGURE_OSG=configure-osg
    PACMAN=pacman
    PACMAN_GET="${PACMAN} -allow any-platform -trust-all-caches -get"
    if ${TEST} -d ${PACMAN_HOME}; then
	osg_pacman_init
    else
	renci_ci_log_info "pacman not installed. use osg_install_pacman."
    fi
    export OSG_PACKAGE_CE=http://software.grid.iu.edu/osg-1.2:ce
    export OSG_PACKAGE_GLOBUS_CONDOR_JOBMANAGER=http://software.grid.iu.edu/osg-1.2:Globus-Condor-Setup 
    export OSG_PACKAGE_GLOBUS_PBS_JOBMANAGER=http://software.grid.iu.edu/osg-1.2:Globus-PBS-Setup
    export OSG_PACKAGE_MANAGED_FORK=http://software.grid.iu.edu/osg-1.2:ManagedFork
    export OSG_PACKAGE_WN_CLIENT=http://software.grid.iu.edu/osg-1.2:wn-client    
}
function osg_install_pacman {
    renci_ci_log_info "installing pacman..."
    cd ${OSG_BASE}
    ${WGET} --timestamping ${PACMAN_TAR_URL}
    ${TAR} --no-same-owner -xzf pacman-${PACMAN_VERSION}.tar.gz
    osg_pacman_init
    renci_ci_log_info "pacman installation complete..."
}
function osg_pacman_init {
    renci_ci_log_info "initializing pacman vdt package installation manager..."
    cd ${PACMAN_HOME}
    source setup.sh
    cd ..
    ${PACMAN} -version | ${SED} -e "s,^,   --(pacman): ,g" -e "s,satisfies.*$,,"
}
function osg_install_ce {
    ${TEST} ! -d "${GRID_SECURITY_DIR}/http" && {
	${MKDIR} -p ${GRID_SECURITY_DIR}/http
    }

    ${TEST} ! -d "${OSG_CE_APP_DIR}/etc" && {
	${MKDIR} -p ${OSG_CE_APP_DIR}/etc
	${CHMOD} 1777 ${OSG_CE_APP_DIR}/etc
    }
    ${TEST} ! -d "${OSG_CE_DATA_DIR}" && {
	${MKDIR} -p ${OSG_CE_DATA_DIR}
	${CHMOD} 1777 ${OSG_CE_DATA_DIR}
    }
    renci_ci_log_info "installing osg compute element software..."
    if ${TEST} ! -d ${VDT_LOCATION}; then
	${MKDIR} ${VDT_LOCATION}
    fi
    cd ${VDT_LOCATION}
    ${PACMAN_GET} ${OSG_PACKAGE_CE}
}
function osg_install_worker_node_client {
    if [ ! -d "${WORKER_NODE_CLIENT}" ]; then
	${MKDIR} ${WORKER_NODE_CLIENT}
    fi
    cd ${WORKER_NODE_CLIENT}
    ${PACMAN_GET} ${OSG_PACKAGE_WN_CLIENT}
}
# https://twiki.grid.iu.edu/bin/view/ReleaseDocumentation/ComputeElementInstall#Configure_the_CA_Certificate_Han
# https://twiki.grid.iu.edu/bin/view/ReleaseDocumentation/WorkerNodeClient
function osg_ca_setup {
    cd ${VDT_LOCATION}
    source setup.sh
    renci_ci_log_info "executing VDT CA manager to setup CA..."
    ${VDT_CA_MANAGE} setupca --location local --url osg
    renci_ci_log_info "enableing certificate update service..."
    vdt-control --enable vdt-update-certs
    vdt-control --enable  fetch-crl
}
function osg_require_cert_env {
    if [ -z "${OSG_ADMIN_NAME}" -o -z "${OSG_ADMIN_EMAIL}" -o -z "${OSG_ADMIN_PHONE}" ]; then
	renci_ci_log_error "Define all of the following and try again:"
	renci_ci_log_error '${OSG_ADMIN_NAME} ${OSG_ADMIN_EMAIL} ${OSG_ADMIN_PHONE}'
	return 1
    fi
}
function osg_setup_cert_request {
    osg_require_cert_env
    ${MKDIR} -p ${CERT_REQUEST_DIR}
    cd ${CERT_REQUEST_DIR}
}
function osg_host_cert_request {    
    osg_setup_cert_request &&
    ${VDT_LOCATION}/cert-scripts/bin/cert-request \
	--ou s \
	--dir . \
        --host ${FQDN} \
	--label "host-${FQDN}" \
	--name "${OSG_ADMIN_NAME}" \
        --email "${OSG_ADMIN_EMAIL}" \
	--phone "${OSG_ADMIN_PHONE}" \
	--reason "Installing RENCI Engage CE" \
	--affiliation "osg" \
	--vo "engage" \
	--agree \
	$*
}
function osg_http_cert_request {
    osg_host_cert_request --service http $*
}
function osg_post_install {
    HOST_CERT=${OSG_KEY_REPO}/host/hostcert.pem
    HOST_KEY=${OSG_KEY_REPO}/host/hostkey.pem
    HTTP_CERT=${OSG_KEY_REPO}/http/httpcert.pem
    HTTP_KEY=${OSG_KEY_REPO}/http/httpkey.pem    

    if [ ! -e "${HOST_CERT}" -o ! -e "${HOST_KEY}" ]; then
	renci_ci_log_error "usage: $0 <host-cert> <host-key> <http-cert> <http-key>"
	return 1
    fi
    if [ ! -e "${HTTP_CERT}" -o ! -e "${HTTP_KEY}" ]; then
	renci_ci_log_error "usage: $0 <host-cert> <host-key> <http-cert> <http-key>"
	return 1
    fi
    renci_ci_log_info "Initializing VDT environment..."
    cd ${VDT_LOCATION}
    source setup.sh
    renci_ci_log_info "Installing Globus certificates..."
    ${CP} ${HOST_KEY} ${GRID_SECURITY_DIR}/hostkey.pem
    ${CP} ${HOST_CERT} ${GRID_SECURITY_DIR}/hostcert.pem
    ${CP} ${HTTP_KEY} ${GRID_SECURITY_DIR}/http/httpkey.pem
    ${CP} ${HTTP_CERT} ${GRID_SECURITY_DIR}/http/httpcert.pem
    ${CHMOD} 400 ${GRID_SECURITY_DIR}/hostkey.pem
    ${CHMOD} 400 ${GRID_SECURITY_DIR}/http/httpkey.pem
    ${CHMOD} 444 ${GRID_SECURITY_DIR}/hostcert.pem
    ${CHMOD} 444 ${GRID_SECURITY_DIR}/http/httpcert.pem
    ${CP} ${GRID_SECURITY_DIR}/hostkey.pem ${GRID_SECURITY_DIR}/containerkey.pem
    ${CP} ${GRID_SECURITY_DIR}/hostcert.pem ${GRID_SECURITY_DIR}/containercert.pem
    
    # startup fails w/o this .... why?
    ${CHMOD} 400 ${GRID_SECURITY_DIR}/containerkey.pem

    renci_ci_log_info "listing ${GRID_SECURITY_DIR}..."
    ${FIND} ${GRID_SECURITY_DIR} -name "*.pem" -print

    ${CHOWN} globus:globus container*.pem
    if [ "x${USER}" = "xroot" ]; then
	${CHOWN} root:root ${GRID_SECURITY_DIR}/host*.pem
	${CHOWN} root:root ${GRID_SECURITY_DIR}/http/http*.pem
    else
	${CHOWN} ${USER}: ${GRID_SECURITY_DIR}/host*.pem
	${CHOWN} ${USER}: ${GRID_SECURITY_DIR}/http/http*.pem
    fi
    renci_ci_log_info "Executing VDT post install script..."
    vdt-post-install
}
function osg_install_jobmanager_pbs {
    ${PACMAN_GET} ${OSG_PACKAGE_GLOBUS_PBS_JOBMANAGER}
}
function osg_install_jobmanager_condor {
    ${PACMAN_GET} ${OSG_PACKAGE_GLOBUS_CONDOR_JOBMANAGER}
# Globus-Condor-Setup only - The $VDT_LOCATION/globus/lib/perl/Globus/GRAM/JobManager/condor.pm will by default insert a requirement that all jobs run on nodes of the same architecture as the gatekeeper. ... You have to comment out the line in condor.pm that looks like this to override this feature:
#    $requirements .= " && Arch == \"" . $description->condor_arch() . "\" "; 
}
function osg_configure_ce {
    CONFIG_VALUES=${OSG_RESOURCES}/osg/${FQDN}-ce.conf
    if [ ! -f ${CONFIG_VALUES} ]; then
	renci_ci_log_error "unable to find file: ${CONFIG_VALUES}"
	return 1
    fi
    CONFIG_SCRIPT=./osg-ce-configure.sh
    renci_ci_log_info "   backing up ${OSG_CE_CONFIG_DIR}/config.ini"
    TIMESTAMP=`${DATE} +'%Y%m%d_%H%M'`
    ${CP} ${OSG_CE_CONFIG_DIR}/config.ini ${OSG_CE_CONFIG_DIR}/config.ini.${TIMESTAMP}
    renci_ci_log_info "   applying values in ${CONFIG_VALUES} via template ${OSG_CONFIG_INI_TEMPLATE}..."
    ${ECHO} ${SED} \\ > ${CONFIG_SCRIPT}
    ${SED} \
	-e "s/=/,/g" \
	-e "s/^/s,/" \
	-e 's,^,\",' \
	-e 's/$/,\"\\/' \
	-e "s, ,\\\ ,g" \
	-e "s,^, -e ," \
	${CONFIG_VALUES} >> ${CONFIG_SCRIPT}
    ${CHMOD} +x ${CONFIG_SCRIPT}
    ${CAT} ${OSG_CONFIG_INI_TEMPLATE} | \
	${CONFIG_SCRIPT} | \
	${SED} \
	-e "s,OSG_CE_CONDOR_LOCATION,${VDTSETUP_CONDOR_LOCATION}," \
	-e "s,OSG_CE_WORKER_NODE_CLIENT,${WORKER_NODE_CLIENT}," \
	-e "s,OSG_CE_APP_DIR,${OSG_CE_APP_DIR}," \
	-e "s,OSG_CE_DATA_DIR,${OSG_CE_DATA_DIR}," > ${OSG_CE_CONFIG_DIR}/config.ini
    ${RM} ${CONFIG_SCRIPT}
    renci_ci_log_info "   executing configure-osg..."
    ${CONFIGURE_OSG} -c
    renci_ci_log_info "   verifying created configurations..."
    ${CONFIGURE_OSG} -v

    renci_ci_log_info "configuring local grid-mapfile ..."
    ${CP} ${OSG_RESOURCES}/osg/grid-mapfile.renci ${GRID_SECURITY_DIR}
    ${SED} "s,^,   --local-gridmap-entry: ," ${GRID_SECURITY_DIR}/grid-mapfile.renci
    if [ "`${GREP} -c grid-mapfile.renci ${VDT_LOCATION}/edg/etc/edg-mkgridmap.conf`" -eq 0 ]; then
	${ECHO} "gmf_local ${GRID_SECURITY_DIR}/grid-mapfile.renci" >> ${VDT_LOCATION}/edg/etc/edg-mkgridmap.conf
    fi
}

function osg_set_nonroot_option {
    if [ "${USER}" == "root" ]; then
	export OSG_NON_ROOT_OPTION=
    else
	export OSG_NON_ROOT_OPTION=--non-root
    fi
}
function osg_on {
    osg_set_nonroot_option
    kill_osg_processes
    ${VDT_CONTROL} --list
    ${VDT_CONTROL} --on ${NON_ROOT_OPTION} --force
}
function osg_off {
    osg_set_nonroot_option
    ${VDT_CONTROL} --off ${NON_ROOT_OPTION}
}
function osg_verify {
    job_require_valid_proxy
    if [ "`${GREP} -c ${USER} ${GRID_SECURITY_DIR}/grid-mapfile`" -eq "0" ]; then
	renci_ci_log_error "user ${USER} is not in the grid-mapfile: ${GRID_SECURITY_DIR}/grid-mapfile"
	SUBJECT=`grid-cert-info -subject`
	renci_ci_log_info "use: grid-mapfile-add-entry -dn '${SUBJECT} -ln ${USER}"
    else
	${GREP} ${USER} ${GRID_SECURITY_DIR}/grid-mapfile | ${SED} "s,^,   ,"
	renci_ci_log_info "verified user ${USER} is in the grid-mapfile"
	${VDT_LOCATION}/verify/site_verify.pl
    fi
}
function osg_clean {
    renci_ci_log_info "clean: --removing and re-creating ${OSG_BASE}"
    ${RM} -rf ${OSG_BASE}
    ${MKDIR} -p ${OSG_BASE}
}
function osg_install_all {
    local purge=false
    local condor=false
    for arg in $*; do
	case $arg in
	    --condor)  condor=true;
	               renci_ci_log_debug "condor option selected.";;
	    --purge)   purge=true;
		       renci_ci_log_debug "purge option selected.";;
	    *)         renci_ci_log_error "usage: path [--purge] [--condor]";
                       return 1;;
	esac
    done
    if [ "x$purge" = "xtrue" ]; then
	osg_clean
    fi
    if [ "x$condor" = "xtrue" ]; then
	if [ "x$purge" = "xtrue" ]; then
	    cndr_clean
	fi
	cndr_install_all
    fi

    if [ ! -d "${OSG_BASE}" ]; then
	renci_ci_log_info "   --creating ${OSG_BASE}"
	${MKDIR} -p ${OSG_BASE}
    fi

    t=$(renci_ci_timer)
    renci_ci_log_info "starting install at `${DATE}`"
    (renci_ci_log_info "osg_install_pacman..." &&
	osg_install_pacman &&
	renci_ci_log_info "osg_pacman_init..." &&
	osg_pacman_init &&
	renci_ci_log_info "osg_install_worker_node_client..." &&
	osg_install_worker_node_client &&
	renci_ci_path --purge=$WORKER_NODE_CLIENT --commit &&
	renci_ci_log_info "osg_install_ce..." &&
	osg_install_ce &&
	renci_ci_log_info "osg_install_jobmanager_pbs..." &&
	osg_install_jobmanager_pbs &&
	renci_ci_log_info "osg_ca_setup..." &&
	osg_ca_setup &&
	renci_ci_log_info "osg_post_install..." &&
	osg_post_install &&
	renci_ci_log_info "osg_configure_ce..." &&
	osg_configure_ce &&
	renci_ci_log_info "osg_on..." &&
	osg_on &&
	edg-mkgridmap)

    ${RM} -rf ${OSG_BASE}/current
    ${LN} -s ${OSG_BASE}/osg-${OSG_CE_VERSION} ${OSG_BASE}/current
    renci_ci_log_info "end at `${DATE}`. duration: $(renci_ci_timer $t)"
    
}
function osg_less_vdt_control_log {
    ${LESS} ${VDT_LOCATION}/logs/vdt-control.log
}
kill_osg_processes () {
    local patterns="httpd globus"
    renci_ci_log_info "killing all processes matching patterns: $patterns"
    for pattern in $patterns; do
	${KILL} -9 `${PS} -ef | ${GREP} $pattern | ${AWK} -F' ' '{ print $2 }'` > /dev/null 2>&1
    done
    renci_ci_log_info "remaining processes:"
    for pattern in $patterns; do
	${PS} -ef | ${GREP} $pattern | ${GREP} -v ${GREP}
    done
}
osg_environment_init $*
return 0


# https://twiki.grid.iu.edu/bin/view/ReleaseDocumentation/ManagedFork
#   "We recommend large sites (>1000 cores) consider running managed fork."
function osg_install_managed_fork {
    renci_ci_log_info "installing managed fork..."
    renci_ci_log_info ${PACMAN_GET} ${OSG_PACKAGE_MANAGED_FORK}
    source $VDT_LOCATION/setup.sh

    renci_ci_log_info "   configuring managed fork..."
    ${CP} ${LOC_CONDOR_CONF} ${LOC_CONDOR_CONF}.orig
    ${CAT} ${LOC_CONDOR_CONF} \
	| ${SED} -e "s,TotalLocalJobsRunning < 200,TotalLocalJobsRunning < 20 || GridMonitorJob =?= TRUE,g" \
	> ${LOC_CONDOR_CONF}.new
    ${GREP} TotalLocalJobsRunning ${LOC_CONDOR_CONF}.new 
    ${MV} ${LOC_CONDOR_CONF}.new ${LOC_CONDOR_CONF}.ya
    rm ${LOC_CONDOR_CONF}.ya    # get rid of this once stuff works.

    renci_ci_log_info "   setting managed fork as default job manager..."
    ${VDT_LOCATION}/vdt/setup/configure_globus_gatekeeper --managed-fork y --server y
}



