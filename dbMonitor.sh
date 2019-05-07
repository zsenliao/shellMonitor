#!/bin/bash

# 数据库备份及指定数据表监控
# 数据库备份按设定周期执行，如果有则跳过，没有则执行备份
# 数据表监控与文件监控同频次
dbMonitor() {
    if ! cat /etc/my.cnf | grep ^user 1>/dev/null && ! cat /root/.my.cnf | grep ^user 1>/dev/null; then
        DB_USER="-u${DB_USER}"
    else
        DB_USER=""
    fi
    if ! cat /etc/my.cnf | grep ^password 1>/dev/null && ! cat /root/.my.cnf | grep ^password 1>/dev/null; then
        DB_PASS="-p${DB_PASS}"
    else
        DB_PASS=""
    fi

    if [[ ${DB_BACK_PER} == "H" ]]; then
        BACKUP_DB_FILE="${BACKUP_DB_DIR}/db.$(date +%F_%H).sql.gz"
    else
        BACKUP_DB_FILE="${BACKUP_DB_DIR}/db.$(date +%F).sql.gz"
    fi
    if [[ ! -f ${BACKUP_DB_FILE} ]]; then
        # 备份数据库
        OPT="--quote-names --opt"
        # 检查是否需要生成CREATE数据库语句
        if [[ "${CREATE_DATABASE}" == "true" ]]; then
            OPT="${OPT} --databases"
        else
            OPT="${OPT} --no-create-db"
        fi

        # 检查是否是备份所有数据库
        if [[ "${DB_NAME}" == "all" ]]; then
            DB_NAME="--all-databases"
        else
            DB_NAME="--databases ${DB_NAME}"
        fi

        if ! `which mysqldump` ${DB_USER} ${DB_PASS} --host=${DB_HOST} ${OPT} ${DB_NAME} | gzip > "${BACKUP_DB_FILE}" 2>/tmp/shellMonitor.sql.error; then
            error_msg=$(cat /tmp/shellMonitor.sql.error)
            WeChatNotice "数据库备份失败！" "${HOST_NAME}" "数据库备份" "备份失败" "错误信息：${error_msg}"
            ServerNotice "${HOST_NAME} 数据库备份失败！" "错误信息：${error_msg}"
            MailNotice "${HOST_NAME} 数据库备份失败！" "错误信息：${error_msg}"
        fi
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

            if [[ ${FIELD[tdx]} != '*' ]]; then
                SQLSTR="select ${FIELD[tdx]} from ${TABLE}"
            else
                SQLSTR="select * from ${TABLE}"
            fi

            if ! `which mysql` ${DB_USER} ${DB_PASS} -D ${DB} -Bse "${SQLSTR}" > "${TMP_DB}" 2>/tmp/shellMonitor.sql.error; then
                error_msg=$(cat /tmp/shellMonitor.sql.error)
                WeChatNotice "数据库监控失败！" "${HOST_NAME}" "数据库监控" "监控失败" "错误信息：${error_msg}"
                ServerNotice "${HOST_NAME} 数据库监控失败！" "错误信息：${error_msg}"
                MailNotice "${HOST_NAME} 数据库监控失败！" "错误信息：${error_msg}"
                exit 1
            fi

            if [[ ${1} == "init" ]]; then
                cp -f "${TMP_DB}" "${ORIGIN_DB}"
            else
                local DIFF_DB
                DIFF_DB=$(diff "${ORIGIN_DB}" "${TMP_DB}" | awk '{print $1$2}' | sort -k2n | uniq -c -s3 | sed '/[<>]/!d;s/1 </【删除】/;s/1 >/【增加】/;s/2 </【编辑】/')
            fi

            if [[ -n ${DIFF_DB} ]]; then
                echo "${DB_CHANGE} ${DB} ${TABLE} is change: " >> /tmp/db.change.txt
                diff "${ORIGIN_DB}" "${TMP_DB}" >> "${LOG_DB}"
                cat "${LOG_DB}" >> /tmp/db.change.txt
                echo "" >> /tmp/db.change.txt
                cp -f "${TMP_DB}" "${ORIGIN_DB}"  # 将当前状态覆盖为初始监控状态

                WeChatNotice "警告：数据库被修改！" "${HOST_NAME}" "${DB}" "${TABLE}" "$(echo ${DIFF_DB} | sed -r "s/\s*//g")"
                ServerNotice "${HOST_NAME} 数据库修改通知！" "数据库：${DB}表：\n${TABLE} \n修改内容：$(echo ${DIFF_DB} | sed -r "s/\s*//g")"
            fi

            let tdx=tdx+1
        done
        let idx=idx+1
    done

    if [[ ${1} == "init" ]]; then
        WeChatNotice "监控初始化成功！" "${HOST_NAME}" "数据库监控初始化" "操作成功" "监控数据库：${DB_MONITOR_NAME}\n监控数据表：${DB_MONITOR_TABLE}"
        ServerNotice "${HOST_NAME} 监控初始化成功！" "监控数据库：${DB_MONITOR_NAME}\n监控数据表：${DB_MONITOR_TABLE}"
        MailNotice "${HOST_NAME} 监控初始化成功！" "监控数据库：${DB_MONITOR_NAME}\n监控数据表：${DB_MONITOR_TABLE}"
    fi
}
