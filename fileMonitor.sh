#!/bin/bash

# 文件备份
fileMonitor() {
    for DIR in $(echo $MONITOR_DIR | tr -s ' '); do
        if [[ -d ${DIR} ]]; then
            DIR_NAME=${DIR##*/}
            TMP_FILE="/tmp/${DIR_NAME}.txt"
            ORIGIN_FILE="${BACKUP_LOG_DIR}/${DIR_NAME}.origin.txt"
            LOG_FILE="${BACKUP_LOG_DIR}/${DIR_NAME}.${DATE}_change.log"

            getFileInfo ${DIR} ${TMP_FILE}

            local DIFF_FILE=$(diff ${ORIGIN_FILE} ${TMP_FILE})

            if [[ -n $DIFF_FILE ]]; then
                FILE_CHANGE="${FILE_CHANGE} ${DIR} is change:\\n"
                FILE_CHANGE="${FILE_CHANGE} ${DIFF_FILE}"
                # FILE_CHANGE="${FILE_CHANGE} $(echo ${DIFF_FILE} | awk '{print $1$3}' | sort -k2n | uniq -c -s3 | sed '/[<>]/!d;s/1 </删除：/;s/1 >/增加：/;s/2 </编辑：/')"

                echo ${DIFF_FILE} >> ${LOG_FILE}

                backupFile ${DIR}

                if [[ ${WECHAT_NOTICE} = "true" ]]; then
                    WeChatNotice "警告：监控文件被修改！" ${WEBSITE} ${DIR_NAME} "文件修改"
                fi

                cp -f ${TMP_FILE} ${ORIGIN_FILE}  # 将当前状态覆盖为初始监控状态
            fi
        fi
    done
}

initFileMonitor() {
    for DIR in $(echo $MONITOR_DIR | tr -s ' '); do
        if [[ -d ${DIR} ]]; then
            local DIR_NAME=${DIR##*/}
            local ORIGIN_FILE="${BACKUP_LOG_DIR}/${DIR_NAME}.origin.txt"

            # 遍历指定目录下的文件大小及路径并重定向到日志文件
            getFileInfo ${DIR} ${ORIGIN_FILE}
            backupFile ${DIR}
        fi
    done
}

getFileInfo() {
    # 遍历指定目录下的文件大小及路径并重定向到日志文件
    # find: 需要验证目录存在
    if [[ -n ${EXCLUDE_DIR} ]]; then
        # 排除目录
        find ${1} \( -path $(echo ${EXCLUDE_DIR} | sed "s/ / -o -path /") \) -prune -o -type f -print0 | xargs -0 $(echo ${DIFF_EXT}) > ${2}
    else
        find ${1} -type f -print0 | xargs -0 $(echo ${DIFF_EXT}) > ${2}
    fi
}

backupFile() {
    if [[ ${ZIP_BACKUP} = "true" ]]; then
        tar -zcPf ${BACKUP_TAR_DIR}/${DIR_NAME}.${DATE}.tar.gz ${1}  # 备份文件
    fi

    if [[ ${FILE_BACKUP} = "true" ]]; then
        cp -rf ${1} ${BACKUP_FILE_DIR}/${DIR_NAME}_${DATE} # 备份文件
    fi
}
