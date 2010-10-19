
irods_init () {
    renci_ci_log_info "initializing irods environment"
    export IRODS_HOME=~/dev/iRods/iRODS
    export IRODS_CLIENT_BIN=${IRODS_HOME}/clients/icommands/bin

    export ILS=${IRODS_CLIENT_BIN}/ils
    export IADMIN=${IRODS_CLIENT_BIN}/iadmin
    export IRM=${IRODS_CLIENT_BIN}/irm
    export IPUT=${IRODS_CLIENT_BIN}/iput
    export IGET=${IRODS_CLIENT_BIN}/iget

    REMOTE_ZONE_SUFFIX=_rz
}
irods_federate () {
    local zone_name=
    local zone_host=
    for arg in $*; do
	case $arg in
	    --zone\=*) zone_name=$( renci_ci_getarg $arg );;
	    --host\=*) zone_host=$( renci_ci_getarg $arg );;
	    *) renci_ci_log_error "usage: irods_federate --zone=<z> --host=<host:port>"; return 1;;
	esac
    done
    ${TEST} -z $zone_name || ${TEST} -z $zone_host && \
	( renci_ci_log_error "zone name and host must be specified"; return 1 )
    ${IADMIN} mkzone ${zone_name}${REMOTE_ZONE_SUFFIX} remote ${zone_host}
    ${IADMIN} lz
    ${ILS} /
}
irods_unfederate () {
    local zone_name=
    for arg in $*; do
	case $arg in
	    --zone\=*) zone_name=$( renci_ci_getarg $arg );;
	    *) renci_ci_log_error "usage: irods_unfederate --zone=<z> "; return 1;;
	esac
    done
    ${TEST} -z $zone_name && \
	( renci_ci_log_error "zone name must be specified"; return 1 )
    renci_ci_log_info "removing remote zone ${zone_name}"
    ${IADMIN} rmzone ${zone_name}
}
irods_build () {
    export LDFLAGS=
    echo ==========================================================================================================
    echo ==========================================================================================================
    echo ================================ $0 ==========================================================================
    echo ==========================================================================================================
    echo ==========================================================================================================
    echo ==========================================================================================================
    echo ==========================================================================================================
    pwd
    ls
    ls ./scripts/
    ./scripts/configure
    ${MAKE} clean
    ${MAKE}
}
irods_init


if [ "$1" = "-all" ]; then
    irods_build
fi

