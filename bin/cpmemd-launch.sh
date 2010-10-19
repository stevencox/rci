
# module loaded by grid launcher
job_run_model () {
    CPMEMD_HOME=${WORK_DIR}
    ${RENCI_HOME}/cpmemd.sh --grid --nodes=8 --procs=8 >> ${STDOUT} 2>&1
    ${CAT} ${STDOUT}
    EXIT_CODE=$?
    job_wait_for_output "--(end)" ${CPMEMD_HOME}/run/test.out 10 20
    ${MV} ${CPMEMD_HOME}/run ${WORK_DIR}/out
    return ${EXIT_CODE}
}


