#!/bin/bash

CUR_DIR=$(cd $(dirname $BASH_SOURCE); pwd)

. ${CUR_DIR}/config.sh
. ${CUR_DIR}/fileMonitor.sh
. ${CUR_DIR}/dbMonitor.sh
. ${CUR_DIR}/notice.sh

# 当前剩余容量小于设定容量，预警并退出备份
CUR_SIZE=$(df -m /home | awk 'END{print $4}')
if [[ ${CUR_SIZE} -lt ${MIN_SIZE} ]]; then
    MailNotice "警告：服务器剩余空间不足！" "剩余 ${CUR_SIZE}M"
    WeChatNotice "警告：服务器剩余空间不足！" "服务器空间" "剩余 ${CUR_SIZE}M" "备份失败"
    exit 0
fi

# 日期变量
DATE=`date +%F_%H%M`
DEL_DATE=`date -d -${BACKUP_DAY}day +%F`
if [[ ${DB_BACK_PER} == "H" ]]; then
    DB_DATE=`date +%F_%H`
else
    DB_DATE=`date +%F`
fi

# 检查备份路径是否存在，不存在则建立
# 备份目录
BACKUP_TAR_DIR="${BACKUP_DIR}/tar"  # 压缩文件目录
BACKUP_LOG_DIR="${BACKUP_DIR}/log"  # 日志文件目录
BACKUP_FILE_DIR="${BACKUP_DIR}/www"  # 文件备份目录
BACKUP_DB_DIR="${BACKUP_DIR}/db"  # 数据库备份目录

if [[ ! -e "${BACKUP_TAR_DIR}" ]]; then
    mkdir -p "${BACKUP_TAR_DIR}"
fi
if [[ ! -e "${BACKUP_LOG_DIR}" ]]; then
    mkdir -p "${BACKUP_LOG_DIR}"
fi
if [[ ! -e "${BACKUP_FILE_DIR}" ]]; then
    mkdir -p "${BACKUP_FILE_DIR}"
fi
if [[ ! -e "${BACKUP_DB_DIR}" ]]; then
    mkdir -p "${BACKUP_DB_DIR}"
fi

OPT="--quote-names --opt"
# 检查是否需要生成CREATE数据库语句
if [[ "${CREATE_DATABASE}" == "yes" ]]; then
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

if [[ ${DIFF_TYPE} == "md5" ]]; then
    DIFF_TYPE="md5sum"
else
    DIFF_TYPE="du -b"
fi


if [[ ${1} = "init" ]]; then
    if [[ ${MAIL_TYPE} == "mutt" ]]; then
        mutt -v > /dev/null 2>&1
        [ $? -ne 0 ] && yum install -y mutt || echo "mutt is installed!" > /dev/null
    fi

    ln -sf ${CUR_DIR}/sysMonitor.sh /etc/profile.d/sysMonitor.sh
    sed -i "s/^PrintMotd [a-z]*/#&/g; 1,/#PrintMotd[a-z]*/{s/^#PrintMotd [a-z]*/PrintMotd no/g}" /etc/ssh/sshd_config
    service sshd restart

    sed -i "s#\`which mysql\`#`which mysql`#g" "${CUR_DIR}/dbMonitor.sh"
    sed -i "s#\`which mysqldump\`#`which mysqldump`#g" "${CUR_DIR}/dbMonitor.sh"

    initFileMonitor
    initDBMonitor

    WeChatNotice "监控初始化成功！" "${WEBSITE}" "服务器文件和数据库" "监控初始化成功" "文件目录：${MONITOR_DIR} \n数据库：${DB_MONITOR_NAME}"
    ServerNotice "${WEBSITE} 监控初始化成功！" "文件目录：${MONITOR_DIR} \n数据库：${DB_MONITOR_NAME}"
    MailNotice "${WEBSITE} 监控初始化成功！" "文件目录：${MONITOR_DIR} \n数据库：${DB_MONITOR_NAME}"

    echo "*/5 * * * * ${CUR_DIR}/main.sh" >> /var/spool/cron/root
else
    fileMonitor
    dbMonitor

    if [[ -f "/tmp/file.change.txt" ]]; then
        # 附件作为第三个参数: -a 文件路径
        MailNotice "服务器文件监控预警" "$(cat /tmp/file.change.txt | tr -d '\r')"
        rm -f /tmp/file.change.txt
    fi

    if [[ -f "/tmp/db.change.txt" ]]; then
        MailNotice "数据库监控预警" "$(cat /tmp/db.change.txt | tr -d '\r')"
        rm -f /tmp/db.change.txt
    fi
fi

if [[ ${BACKUP_DAY} != 0 ]]; then
    rm -f "${BACKUP_TAR_DIR}/*.${DEL_DATE}*.tar.gz"
    rm -rf "${BACKUP_FILE_DIR}/*.${DEL_DATE}*"
    rm -f "${BACKUP_DB_DIR}/db.${DEL_DATE}*.sql.gz"
fi
