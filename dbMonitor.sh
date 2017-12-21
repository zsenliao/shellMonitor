#!/bin/bash

# 数据库备份及指定数据表监控
# 数据库备份每天一次，检查是否有当天的备份，如果有则跳过，没有则执行备份
# 数据表监控与文件监控同频次
dbMonitor() {
    local BACKUP_DB_FILE=${BACKUP_DB_DIR}/db.`date +%F`.sql.gz

    if [[ ! -f ${BACKUP_DB_FILE} ]]; then
        # 备份数据库
        `which mysqldump` -u${DB_User} -p${DB_Pass} --host=${DB_HOST} ${OPT} ${DB_Name} | gzip > ${BACKUP_DB_FILE}
        # `which mysqldump` --host=${DB_HOST} ${OPT} ${DB_Name} | gzip > ${BACKUP_DB_FILE}
    fi

    if [[ -n ${DB_ADMIN_MONITOR_TABLE} ]]; then
        TMP_DB=/tmp/${DB_ADMIN_MONITOR_TABLE}.txt
        ORIGIN_DB=${BACKUP_LOG_DIR}/db.${DB_ADMIN_MONITOR_TABLE}.origin.txt
        TODAY_DB=${BACKUP_LOG_DIR}/db.${DB_ADMIN_MONITOR_TABLE}.${DATE}_change.log

        `which mysql` -u${DB_User} -p${DB_Pass} -D ${DB_MONITOR_NAME} -Bse "SELECT ${DB_ADMIN_MONITOR_FIELD} FROM ${DB_ADMIN_MONITOR_TABLE}" > ${TMP_DB}

        DIFF_DB=$(diff ${ORIGIN_DB} ${TMP_DB} | awk '{print $1$2}' | sort -k2n | uniq -c -s3 | sed '/[<>]/!d;s/1 </【删除】/;s/1 >/【增加】/;s/2 </【编辑】/')
        if [[ -n ${DIFF_DB} ]]; then
            echo ${DB_CHANGE}

            if [[ ${WECHAT_NOTICE} = "true" ]]; then
                WeChatNotice "警告：管理员账号数据库被修改！" ${WEBSITE} "${DB_CHANGE}" "管理员账号修改"
            fi

            if [[ ${SC_NOTICE} = "true" ]]; then
                ServerNotice "网站${WEBSITE}预警通知！" "监控项目：管理员账号修改"
            fi

            if [[ ${PUSHBEAR_NOTICE} = "true" ]]; then
                PushBearNotice "网站${WEBSITE}预警通知！" "监控项目：管理员账号修改"
            fi

            DB_CHANGE=$(diff ${ORIGIN_DB} ${TMP_DB})"\\n===*=*=*===\\n"

            echo ${DIFF_DB} > ${TODAY_DB}
            cp -f ${TMP_DB} ${ORIGIN_DB}  # 将当前状态覆盖为初始监控状态
        fi
    fi

    # 监控指定的数据表
    for TABLE in $(echo ${DB_MONITOR_TABLE} | tr -s ' '); do
        TMP_DB=/tmp/${TABLE}.txt
        ORIGIN_DB=${BACKUP_LOG_DIR}/db.${TABLE}.origin.txt
        TODAY_DB=${BACKUP_LOG_DIR}/db.${TABLE}.${DATE}_change.log

        # `which mysqldump` -u${DB_User} -p${DB_Pass} --host=${DB_HOST} --databases ${DB_MONITOR_NAME} --tables ${TABLE} > ${TMP_DB}
        `which mysql` -u${DB_User} -p${DB_Pass} -D ${DB_MONITOR_NAME} -Bse "select * from ${TABLE}" > ${TMP_DB}

        DIFF_DB=$(diff ${ORIGIN_DB} ${TMP_DB} | awk '{print $1$5}' | sort -k2n | uniq -c -s3 |  sed '/[<>]/!d;s/1 </【删除】/;s/1 >/【增加】/;s/2 </【编辑】/')
        if [[ -n ${DIFF_DB} ]]; then
            DB_CHANGE="${DB_CHANGE} $(diff ${ORIGIN_DB} ${TMP_DB})"

            if [[ ${WECHAT_NOTICE} = "true" ]]; then
                WeChatNotice "警告：系统设置数据库被修改！" ${WEBSITE} ${DIFF_DB} "系统设置修改"
            fi

            if [[ ${SC_NOTICE} = "true" ]]; then
                ServerNotice "网站${WEBSITE}预警通知！" "监控项目：系统设置数据库被修改"
            fi

            if [[ ${PUSHBEAR_NOTICE} = "true" ]]; then
                PushBearNotice "网站${WEBSITE}预警通知！" "监控项目：系统设置数据库被修改"
            fi

            echo ${DIFF_DB} > ${TODAY_DB}
            cp -f ${TMP_DB} ${ORIGIN_DB}  # 将当前状态覆盖为初始监控状态
        fi
    done

    TMP_DB=""
    ORIGIN_DB=""
    TODAY_DB=""
    DIFF_DB=""
}

initDBMonitor() {
    local BACKUP_DB_FILE=${BACKUP_DB_DIR}/db.`date +%F`.sql.gz

    # 备份数据库
    `which mysqldump` -u${DB_User} -p${DB_Pass} --host=${DB_HOST} ${OPT} ${DB_Name} | gzip > ${BACKUP_DB_FILE}
    # `which mysqldump` --host=${DB_HOST} ${OPT} ${DB_Name} | gzip > ${BACKUP_DB_FILE}

    if [[ -n ${DB_ADMIN_MONITOR_TABLE} ]]; then
        ORIGIN_DB=${BACKUP_LOG_DIR}/db.${DB_ADMIN_MONITOR_TABLE}.origin.txt
        `which mysql` -u${DB_User} -p${DB_Pass} -D ${DB_MONITOR_NAME} -Bse "SELECT ${DB_ADMIN_MONITOR_FIELD} FROM ${DB_ADMIN_MONITOR_TABLE}" > ${ORIGIN_DB}
    fi

    # 监控指定的数据表
    for TABLE in $(echo ${DB_MONITOR_TABLE} | tr -s ' '); do
        ORIGIN_DB=${BACKUP_LOG_DIR}/db.${TABLE}.origin.txt
        # `which mysqldump` -u${DB_User} -p${DB_Pass} --host=${DB_HOST} --databases ${DB_MONITOR_NAME} --tables ${TABLE} > ${TMP_DB}
        `which mysql` -u${DB_User} -p${DB_Pass} -D ${DB_MONITOR_NAME} -Bse "select * from ${TABLE}" > ${ORIGIN_DB}
    done

    ORIGIN_DB=""
}
