#!/bin/bash

INITDB="false"

# 数据库备份及指定数据表监控
# 数据库备份按设定周期执行，如果有则跳过，没有则执行备份
# 数据表监控与文件监控同频次
dbMonitor() {
    BACKUP_DB_FILE="${BACKUP_DB_DIR}/db.${DB_DATE}.sql.gz"
    if [[ ! -f ${BACKUP_DB_FILE} ]]; then
        # 备份数据库
        `which mysqldump` -u${DB_USER} -p${DB_PASS} --host=${DB_HOST} ${OPT} ${DB_NAME} | gzip > "${BACKUP_DB_FILE}"
        # `which mysqldump` --host=${DB_HOST} ${OPT} ${DB_NAME} | gzip > ${BACKUP_DB_FILE}
    fi

    # 监控指定的数据表
    idx=0
    for DB in $(echo "${DB_MONITOR_NAME}" | tr -s ' '); do
        FIELD=(`echo ${DB_MONITOR_FIELD[idx]}`)
        tdx=0
        for TABLE in $(echo "${DB_MONITOR_TABLE[idx]}" | tr -s ' '); do
            TMP_DB="/tmp/${DB}.${TABLE}.txt"
            ORIGIN_DB="${BACKUP_LOG_DIR}/db.${DB}-${TABLE}.origin.txt"
            LOG_DB="${BACKUP_LOG_DIR}/db.${DB}-${TABLE}.${DATE}_change.log"

            if [[ ${FIELD[tdx]} != '\*' ]]; then
                SQLSTR="select ${FIELD[tdx]} from ${TABLE}"
            else
                SQLSTR="select * from ${TABLE}"
            fi

            `which mysql` -u${DB_USER} -p${DB_PASS} -D ${DB} -Bse "${SQLSTR}" > "${TMP_DB}"

            local DIFF_DB
            DIFF_DB=$(diff "${ORIGIN_DB}" "${TMP_DB}" | awk '{print $1$2}' | sort -k2n | uniq -c -s3 | sed '/[<>]/!d;s/1 </【删除】/;s/1 >/【增加】/;s/2 </【编辑】/')

            if [[ ${INITDB} == "true" ]]; then
                cp -f "${TMP_DB}" "${ORIGIN_DB}"
            fi
            if [[ -n ${DIFF_DB} ]]; then
                echo "${DB_CHANGE} ${DB} ${TABLE} is change: " >> /tmp/db.change.txt
                diff "${ORIGIN_DB}" "${TMP_DB}" >> "${LOG_DB}"
                cat "${LOG_DB}" >> /tmp/db.change.txt
                echo "" >> /tmp/db.change.txt
                cp -f "${TMP_DB}" "${ORIGIN_DB}"  # 将当前状态覆盖为初始监控状态

                if [[ ${INITDB} != "true" ]]; then
                    WeChatNotice "警告：数据库被修改！" "${WEBSITE}" "${DB}" "${TABLE}" "$(echo ${DIFF_DB} | sed -r "s/\s*//g")"
                    ServerNotice "${WEBSITE} 数据库修改通知！" "数据库：${DB}表：\n${TABLE} \n修改内容：$(echo ${DIFF_DB} | sed -r "s/\s*//g")"
                fi
            fi

            let tdx=tdx+1
        done
        let idx=idx+1
    done
}

initDBMonitor() {
    INITDB="true"
    dbMonitor
}
