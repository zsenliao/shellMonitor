#!/bin/bash

CUR_DIR=$(cd $(dirname $BASH_SOURCE); pwd)

. ${CUR_DIR}/config.sh
. ${CUR_DIR}/fileMonitor.sh
. ${CUR_DIR}/dbMonitor.sh
. ${CUR_DIR}/notice.sh

# 当前剩余容量小于设定容量，预警并退出备份
CUR_SIZE=$(df -m /home | awk 'END{print $4}')
if [[ ${CUR_SIZE} -lt ${MIN_SIZE} ]]; then
    # email
    echo ${CUR_SIZE}
    WeChatNotice "警告：网站剩余空间不足！" "网站空间" "剩余 ${CUR_SIZE}M" "备份失败"
    exit 0
fi


# 日期变量
DATE=`date +%F_%H%M`
DEL_DATE=`date -d -${BACKUP_DAY}day +%F`

# 检查备份路径是否存在，不存在则建立
# 备份目录
BACKUP_TAR_DIR="/home/backup/tar"  # 压缩文件目录
BACKUP_LOG_DIR="/home/backup/log"  # 日志文件目录
BACKUP_FILE_DIR="/home/backup/www"  # 文件备份目录
BACKUP_DB_DIR="/home/backup/db"  # 数据库备份目录

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
if [[ "${CREATE_DATABASE}" = "yes" ]]; then
    OPT="${OPT} --databases"
else
    OPT="${OPT} --no-create-db"
fi

# 检查是否是备份所有数据库
if [[ "${DB_Name}" = "all" ]]; then
    DB_Name="--all-databases"
else
    DB_Name="--databases ${DB_Name}"
fi

if [[ "${DIFF_TYPE}" = "du" ]]; then
    DIFF_EXT="du -b"
elif [[ "${DIFF_TYPE}" = "md5" ]]; then
    DIFF_EXT="md5sum"
else
    echo "文件对比方式选择错误，退出系统！"
    exit 0
fi


if [[ ${1} = "init" ]]; then
    if [[ ${Mail_Type} == "mutt" ]]; then
        mutt -v > /dev/null 2>&1
        [ $? -ne 0 ] && yum install -y mutt || echo "mutt is installed!" > /dev/null
    fi

    ln -sf /home/shellMonitor/sysMonitor.sh /etc/profile.d/sysMonitor.sh
    sed -i "s/^PrintMotd [a-z]*/#&/g; 1,/#PrintMotd[a-z]*/{s/^#PrintMotd [a-z]*/PrintMotd no/g}" /etc/ssh/sshd_config
    service sshd restart

    initFileMonitor
    initDBMonitor

    if [[ ${WECHAT_NOTICE} = "true" ]]; then
        WeChatNotice "监控初始化成功！" ${WEBSITE} "网站文件和数据库" "监控初始化成功"
    fi

    if [[ ${SC_NOTICE} = "true" ]]; then
        ServerNotice "监控初始化成功！" "监控项目：网站文件和数据库"
    fi

    if [[ ${PUSHBEAR_NOTICE} = "true" ]]; then
        PushBearNotice "监控初始化成功！" "监控项目：网站文件和数据库"
    fi

    echo "*/5 * * * * ${CUR_DIR}/main.sh" >> /var/spool/cron/root
else
    fileMonitor
    dbMonitor

    if [[ -n ${FILE_CHANGE} ]]; then
        # 附件作为第三个参数: -a 文件路径
        MailNotice "网站文件监控预警" "修改内容如下：<br>${FILE_CHANGE}"
    fi

    if [[ -n ${DB_CHANGE} ]]; then
        MailNotice "数据库监控预警" "修改内容如下：<br>${DB_CHANGE}"
    fi
fi

FILE_CHANGE=""
DB_CHANGE=""

if [[ ${BACKUP_DAY} != 0 ]]; then
    rm -f ${BACKUP_TAR_DIR}/*.${DEL_DATE}*.tar.gz
    rm -rf ${BACKUP_FILE_DIR}/*.${DEL_DATE}*
    rm -f ${BACKUP_DB_DIR}/db.${DEL_DATE}*.sql.gz
fi
