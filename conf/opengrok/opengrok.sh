opengrok_install () {
    OPENGROK_VERSION=0.9
    OPENGROK_HOME=${APP}/opengrok-${OPENGROK_VERSION}
    OPENGROK_VAR=${OPENGROK_HOME}/var
    cd ${APP}
    CTAGS_VERSION=5.8
    CTAGS_HOME=${APP}/ctags
    if [ ! -d "${CTAGS_HOME}" ]; then
	${WGET} --timestamping http://prdownloads.sourceforge.net/ctags/ctags-${CTAGS_VERSION}.tar.gz
	${TAR} xvzf ctags-${CTAGS_VERSION}
	cd ctags-${CTAGS_VERSION}
	./configure --prefix=${APP}/ctags
	${MAKE} install
    fi
    cd ${APP}
    ${WGET} --timestamping http://hub.opensolaris.org/bin/download/Project+opengrok/files/opengrok-${OPENGROK_VERSION}.tar.gz
    ${TAR} -xvzf opengrok-${OPENGROK_VERSION}.tar.gz
    ${MKDIR} -p ${OPENGROK_VAR}/lib/opengrok/bin
    ${MKDIR} -p ${OPENGROK_VAR}/lib/opengrok/data
    ${MKDIR} -p ${OPENGROK_VAR}/lib/opengrok/src
    ${MKDIR} -p ${OPENGROK_VAR}/log/opengrok
    java -jar \
	${OPENGROK_HOME}/lib/opengrok.jar -W \
	${OPENGROK_VAR}/lib/opengrok/configuration.xml \
	-c ${CTAGS_HOME}/bin/ctags \
	-P -s ${DEV}/renci/ \
	-d ${OPENGROK_VAR}/lib/opengrok/data -w opengrok -L polished
    ${MKDIR} ${OPENGROK_HOME}/src
    ${CP} ${OPENGROK_HOME}/lib/source.war ${OPENGROK_HOME}/src
    cd ${OPENGROK_HOME}/src
    ${RM} -rf source
    ${MKDIR} -p source
    ${UNZIP} source.war -d source
    cd source
    ${CAT} WEB-INF/web.xml | sed s,/var/opengrok/etc/configuration.xml,${OPENGROK_VAR}/lib/opengrok/configuration.xml, > web.xml.new
    ${MV} web.xml.new WEB-INF/web.xml
    ${ZIP} -u ../source.war WEB-INF/web.xml
    ${CP} ../source.war ${CATALINA_HOME}/webapps/opengrok.war
}
opengrok_indexer () {
    PROGDIR=$(dirname $0)
    OPENGROK_HOME=$(dirname ${PROGDIR})
    SRC_ROOT=/home/scox/dev/renci
    VAR=${OPENGROK_HOME}/var/
    DATA_ROOT=${VAR}/lib/opengrok/data/
    EXUB_CTAGS=${OPENGROK_HOME}/../ctags/bin/ctags
    TIMESTAMP=$(date +'%Y%m%d_%H%M')
    set -x
    java ${JAVA_OPTS} \
	${PROPERTIES} \
	${LOGGER} \
	-jar ${PROGDIR}/../lib/opengrok.jar \
	-c ${EXUB_CTAGS} \
	-s ${SRC_ROOT} \
	-d ${DATA_ROOT} \
	-R ${VAR}/lib/opengrok/configuration.xml > ${OPENGROK_HOME}/var/log/opengrok-indexer-${TIMESTAMP}
    set +x
}
# run as root to create indexer script and register w/cron.
opengrok_write_indexer () {
    INDEXER=${OPENGROK_HOME}/bin/indexer.sh
    ${ECHO} '#!/bin/bash' > ${INDEXER}
    declare -f opengrok_indexer >> ${INDEXER}
    ${ECHO} opengrok_indexer >> ${INDEXER}
    ${CHMOD} +x ${INDEXER}
    CRON_HOURLY=/etc/cron.hourly/opengrok-indexer.sh
    ${ECHO} '#!/bin/bash' > ${CRON_HOURLY}
    ${ECHO} ${OPENGROK_HOME}/bin/run.sh >> ${CRON_HOURLY}
}
