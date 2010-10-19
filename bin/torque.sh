function torque_initialize {
    TORQUE_VERSION=2.5.1
    TORQUE_BINARY_FILE=torque-${TORQUE_VERSION}.tar.gz 
    TORQUE_BINARY_URL=${OSG_WEB_SOFTWARE_REPO}/${TORQUE_BINARY_FILE}
    TORQUE_PKG=${OSG_BASE}/torque-${TORQUE_VERSION}
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
    export TORQUE_INSTALL_LOG=./torque-install.log
}
function torque_get {
    ${WGET} --timestamping ${TORQUE_BINARY_URL}
}
function torque_unpack {
    if [ -d "${TORQUE_PKG}" ]; then
	renci_ci_log_info "skipping untar of binary - output directory exists"
    else
	renci_ci_log_info "untar binary ${TORQUE_BINARY_FILE}..."
	${TAR} xzf ${TORQUE_BINARY_FILE} -C ${OSG_BASE}
    fi
}
function torque_build {
    cd ${TORQUE_PKG}
    ./configure > ${TORQUE_INSTALL_LOG} 2>&1
    ${MAKE} >> ${TORQUE_INSTALL_LOG} 2>&1
    ${SUDO} ${MAKE} install >> ${TORQUE_INSTALL_LOG} 2>&1
}
function torque_uninstall {
    ${SUDO} ${MAKE} uninstall >> ${TORQUE_INSTALL_LOG} 2>&1
}
function torque_setup {
    ${SUDO} ${TORQUE_PKG}/torque.setup $1
}
function torque_start {
    echo not yet
}
function torque_stop {
    echo not yet
}
torque_initialize

