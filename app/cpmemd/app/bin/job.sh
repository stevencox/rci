job_run_model () {
    export MOABHOMEDIR=/var/moab
    export PATH=/opt/torque/bin:/opt/moab/bin:${PATH}
    export BASE=~/.cpmemd
    export CPMEMD_HOME=${BASE}/app
    export RENCI_HOME=${CPMEMD_HOME}/bin/rencici/bin

    ${RM} -rf ${CPMEMD_HOME}
    ${MKDIR} -p ${CPMEMD_HOME}
    ${CP} -r ${WORK_DIR}/app/* ${CPMEMD_HOME}
    ${CHMOD} +x ${CPMEMD_HOME}/bin/cpmemd.sh
    ${CPMEMD_HOME}/bin/cpmemd.sh \
	--grid \
	--nodes=4 \
	--procs=8 >> ${STDOUT} 2>&1
    ${CAT} ${STDOUT}
    sleep 5

    ${ECHO} "user queue [${LOGNAME}]"
    showq | ${GREP} ${LOGNAME}

    runoutput=$( ${LS} -1 ${CPMEMD_HOME} | ${GREP} run )

    max_cycles=20
    pause_time=15
    job_wait_for_file ${CPMEMD_HOME}/${runoutput}/out/mdinfo ${max_cycles} ${pause_time}
    EXIT_CODE=$?

    ${CP} -r ${CPMEMD_HOME} ${WORK_DIR}/out
    ${RM} -rf \
	${WORK_DIR}/out/app/bin \
	${WORK_DIR}/out/app/complete \
	${WORK_DIR}/out/app/in \
	${WORK_DIR}/out/app/resources \

    return ${EXIT_CODE}
}





