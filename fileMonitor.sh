#!/bin/bash

# 文件备份
fileMonitor() {
    for DIR in $(echo "${MONITOR_DIR}" | tr -s ' '); do
        if [[ -d ${DIR} ]]; then
            DIR_NAME=${DIR##*/}
            TMP_FILE="/tmp/${DIR_NAME}.txt"
            ORIGIN_FILE="${BACKUP_LOG_DIR}/${DIR_NAME}.origin.txt"
            LOG_FILE="${BACKUP_LOG_DIR}/${DIR_NAME}.${DATE}_change.log"

            getFileInfo "${DIR}" "${TMP_FILE}"

            if [[ ${1} == "init" ]]; then
                backupFile "${DIR}"
            else
                local DIFF_FILE
                DIFF_FILE=$(diff "${ORIGIN_FILE}" "${TMP_FILE}" | awk '{print $1$3}' | sort -k2n | uniq -c -s3 | sed '/[<>]/!d;s/1 </【删除】/;s/1 >/【增加】/;s/2 </【编辑】/')
            fi

            if [[ -n $DIFF_FILE ]]; then
                echo "${DIR} is change: " >> /tmp/file.change.txt
                echo "${DIFF_FILE}" >> "${LOG_FILE}"
                echo "${DIFF_FILE}" >> /tmp/file.change.txt
                echo "" >> /tmp/file.change.txt
                cp -f "${TMP_FILE}" "${ORIGIN_FILE}"  # 将当前状态覆盖为初始监控状态
                backupFile "${DIR}"

                WeChatNotice "警告：监控文件被修改！" "${HOST_NAME}" "${DIR_NAME}" "文件更改" "$(echo ${DIFF_FILE} | sed -r "s/\s*//g")"
                ServerNotice "监控项目：${DIR_NAME}文件修改" "修改内容：$(echo ${DIFF_FILE} | sed -r "s/\s*//g")"
            fi
        fi
    done

    if [[ ${1} == "init" ]]; then
        WeChatNotice "监控初始化成功！" "${HOST_NAME}" "文件监控初始化" "操作成功" "监控目录：${MONITOR_DIR}\n排除目录：${EXCLUDE_DIR}"
        ServerNotice "${HOST_NAME} 监控初始化成功！" "监控目录：${MONITOR_DIR}\n排除目录：${EXCLUDE_DIR}"
        MailNotice "${HOST_NAME} 监控初始化成功！" "监控目录：${MONITOR_DIR}\n排除目录：${EXCLUDE_DIR}"
    fi
}

getFileInfo() {
    # 遍历指定目录下的文件大小及路径并重定向到日志文件
    # find: 需要验证目录存在
    if [[ -n ${EXCLUDE_DIR} ]]; then
        # 排除目录
        find "${1}" \( -path $(echo ${EXCLUDE_DIR} | sed "s/ / -o -path /") \) -prune -o -type f -print0 2>/tmp/shellMonitor.file.error | xargs -0 $(echo ${DIFF_TYPE}) > "${2}"
    else
        find "${1}" -type f -print0 2>/tmp/shellMonitor.file.error | xargs -0 $(echo ${DIFF_TYPE}) > "${2}"
    fi

    error_msg=$(cat /tmp/shellMonitor.file.error)
    if [[ ${error_msg} != "" ]]; then
        WeChatNotice "文件监控失败！" "${HOST_NAME}" "文件监控" "监控失败" "错误信息：${error_msg}"
        ServerNotice "${HOST_NAME} 文件监控失败！" "错误信息：${error_msg}"
        MailNotice "${HOST_NAME} 文件监控失败！" "错误信息：${error_msg}"
        exit 1
    fi
}

backupFile() {
    if [[ ${ZIP_BACKUP} = "true" ]]; then
        tar -zcPf "${BACKUP_TAR_DIR}/${DIR_NAME}.${DATE}.tar.gz" "${1}"  # 备份文件
    fi

    if [[ ${FILE_BACKUP} = "true" ]]; then
        cp -rf "${1}" "${BACKUP_FILE_DIR}/${DIR_NAME}_${DATE}" # 备份文件
    fi
}
