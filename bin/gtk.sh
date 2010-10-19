
# create globus user
# configure all globus pre-reqs
#   sudo apt-get install libssl-dev

function gtk_chown_globus {
    ${SUDO} ${CHOWN} ${GLOBUS_USER} ${GLOBUS_LOCATION}
}
function gtk_environment {
    # Hinges:
    GTK_APP_ROOT=${OSG_BASE}
    GLOBUS_USER=scox

    renci_ci_log_debug "initializing Globus Toolkit 5 environment..."
    export GLOBUS_VERSION=5.0.2
    export GLOBUS_LOCATION=${GTK_APP_ROOT}/globus-${GLOBUS_VERSION}
    export GLOBUS_SRC=${GTK_APP_ROOT}/gt${GLOBUS_VERSION}-all-source-installer
    export GRID_SECURITY_DIR=${GLOBUS_LOCATION}/etc/grid-security
    #export X509_USER_PROXY=
    #export X509_USER_CERT=${GLOBUS_USER}/.globus/usercert.pem
    #export X509_USER_KEY=${GLOBUS_USER}/.globus/userkey.pem
    export GRIDMAP_FILE=${GRID_SECURITY_DIR}/grid-mapfile

    PATH=${PATH}:${GLOBUS_LOCATION}/bin
    ${TEST} -f ${GLOBUS_LOCATION}/etc/globus-user-env.sh && \
	source $GLOBUS_LOCATION/etc/globus-user-env.sh
    GTK_BUILD_LOG=gtk-build-log.txt
    GTK_INSTALL_LOG=gtk-install-log.txt
    if [ "x$1" == "x--verbose" ]; then
	GTK_V=${ECHO}
    fi
}
function gtk_clean {
    ${GTK_V} cd ${APP_ROOT}
    ${GTK_V} ${SUDO} ${RM} -rf ${GLOBUS_SRC}
    ${GTK_V} ${TAR} --use-compress-program ${BZIP2} -xvf $1
    ${GTK_V} ${SUDO} ${RM} -rf ${GLOBUS_LOCATION}
    ${GTK_V} ${SUDO} ${MKDIR} ${GLOBUS_LOCATION}
}
function openssl_cert_and_key {
    certificate_name=usercert.pem #`echo $1 | sed -e "s,\.p12$,_cert.pem,"`
    key_name=userkey.pem #`echo $1 | sed -e "s,\.p12$,_key.pem,"`
    ${GTK_V} ${TEST} ! -d ${HOME}/.globus && ${MKDIR} ${HOME}/.globus
    ${GTK_V} renci_ci_log_info " -- creating cert ${certificate_name}"
    ${GTK_V} ${OPENSSL} pkcs12 -in $1 -clcerts -nokeys -out ${HOME}/.globus/${certificate_name}
    ${GTK_V} renci_ci_log_info " -- creating private key ${key_name}"
    ${GTK_V} ${OPENSSL} pkcs12 -in $1 -nocerts -out ${HOME}/.globus/${key_name}
    ${GTK_V} ${CHMOD} 600 ${HOME}/.globus/*.pem
}
function gtk_build {
    ${GTK_V} cd ${GLOBUS_SRC}
    ${GTK_V} ./configure --prefix=${GLOBUS_LOCATION}
    ${GTK_V} ${MAKE} 2>&1 | ${TEE} ${GTK_BUILD_LOG}
}
function gtk_install {
    ${GTK_V} cd ${GLOBUS_SRC}
    ${GTK_V} ${SUDO} ${MAKE} install 2>&1 | ${TEE} ${GTK_INSTALL_LOG}
}
function gtk_install_simpleca {
    ${GTK_V} cd ${GLOBUS_SRC}/quickstart
    ${GTK_V} renci_ci_log_info "removing existing simpleCA..."
    ${GTK_V} ${RM} -rf ~/.globus/simpleCA
    ${GTK_V} ${SUDO} ${PERL} gt-server-ca.pl -y
    ${GTK_V} ${SUDO} ${RM} -rf ${GRID_SECURITY_DIR}
    ${GTK_V} ${SUDO} ${MKDIR} ${GRID_SECURITY_DIR}
    ${GTK_V} ${SUDO} ${CP} ${GLOBUS_LOCATION}/etc/host*.pem ${GRID_SECURITY_DIR}
    ${GTK_V} ${SUDO} ${CP} -r ${GLOBUS_LOCATION}/share/certificates/ ${GRID_SECURITY_DIR}
}
function gtk_install_myproxy {
    ${GTK_V} MYPROXY_TEMPLATE=${RENCI_HOME}/resources/globus/myproxy
    ${GTK_V} MYPROXY_USER=${GLOBUS_USER}
    ${GTK_V} ${SUDO} ${CP} ${MYPROXY_TEMPLATE}/myproxy-server.config /etc
    ${GTK_V} ${TEST} ! -z `${GREP} -c myproxy /etc/services` && \
	${SUDO} ${CAT} $GLOBUS_LOCATION/share/myproxy/etc.services.modifications >> /etc/services
    ${GTK_V} ${GREP} -i myproxy /etc/services
    ${GTK_V} ${SUDO} ${SED} -e "s,GLOBUS_HOME,${GLOBUS_LOCATION},g" ${MYPROXY_TEMPLATE}/myproxy > /etc/xinetd.d/myproxy
    ${GTK_V} ${SUDO} ${XINETD} reload
    ${GTK_V} ${SUDO} ${XINETD} status
    ${GTK_V} ${NETSTAT} -an | ${GREP} 7512
    ${GTK_V} myproxy-admin-adduser -c "Globus User" -l ${MYPROXY_USER}
    ${GTK_V} ${ECHO} create ${GRIDMAP_FILE} by pasting the subject name from output above.
}
function gtk_all {
    ${GTK_V} gtk_clean
    ${GTK_V} gtk_build
    ${GTK_V} gtk_install
    ${GTK_V} gtk_install_simpleca
    ${GTK_V} gtk_install_myproxy
}

gtk_environment