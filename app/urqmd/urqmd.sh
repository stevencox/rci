
urqmd_init () {
    URQMD_VERSION=3.3p1
    URQMD_TAR_GZ=urqmd-${URQMD_VERSION}.tar.gz
    URQMD_SRC=http://urqmd.org/download/src/${URQMD_TAR_GZ}
}
urqmd_get () {
    cd ${APP_SCRATCH}
    ${WGET} --timestamping ${URQMD_SRC}
    ${TAR} xvzf ${URQMD_TAR_GZ}
}
urqmd_make () {
    cd ${APP_SCRATCH}/urqmd-${URQMD_VERSION}
    ${MAKE}
    ${BASH} runqmd.bash
}
urqmd_all () {
    urqmd_get
    urqmd_make
}

urqmd_init

if [ "$1" = "-all" ]; then
    urqmd_all
fi

if [ ! -z "$2" ]; then
    exe="urqmd.$(uname -m)"
    target=$2
    renci_ci_log_info "copying ${exe} to ${target}"
    ${MKDIR} -p ${target}
    ${CP} ${APP_SCRATCH}/urqmd-${URQMD_VERSION}/${exe} ${target}/${exe}
fi
