
torque_init () {
    TORQUE_VERSION=2.5.1
    TORQUE_TAR=torque-${TORQUE_VERSION}.tar.gz 
    TORQUE_URL=http://www.clusterresources.com/downloads/torque/torque-${TORQUE_VERSION}.tar.gz
    TORQUE_HOME=${APP_BASE}/torque-${TORQUE_VERSION}
}
torque_get () {
    cd ${APP_SCRATCH}
    ${PWD}
    ${WGET} --timestamping ${TORQUE_URL}
    ${RM} -rf ${APP_SCRATCH}/torque-${TORQUE_VERSION}
    ${TAR} xzf ${TORQUE_TAR}
}
torque_configure () {
    cd ${APP_SCRATCH}/torque-${TORQUE_VERSION}
    ${PWD}
    ./configure --prefix=${TORQUE_HOME} #...mpiexec wont use them from here.
}
torque_build () {
    cd ${APP_SCRATCH}/torque-${TORQUE_VERSION}
    ${PWD}
    ${MAKE}
    cd src/lib # just the libraries please.
    ${MAKE} install 
}
torque_all () {
    torque_get
    torque_configure
    torque_build
}

torque_init

if [ "$1" = "-all" ]; then
    torque_all
fi