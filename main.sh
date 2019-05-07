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

# 备份目录
BACKUP_TAR_DIR="${BACKUP_DIR}/tar"  # 压缩文件目录
BACKUP_LOG_DIR="${BACKUP_DIR}/log"  # 日志文件目录
BACKUP_FILE_DIR="${BACKUP_DIR}/www"  # 文件备份目录
BACKUP_DB_DIR="${BACKUP_DIR}/db"  # 数据库备份目录


if [[ ${1} = "init" ]]; then
    if crontab -l | grep "${CUR_DIR}/main.sh" 1>/dev/null; then
        echo "似乎已安装过 shellMonitor, 是否重新安装?"
        read -r -p "是(Y)/否(N): " REINSMONITOR
        if [[ ${REINSMONITOR} == "y" || ${REINSMONITOR} == "Y" ]]; then
            sed -i '/shellMonitor/d' /var/spool/cron/root
        else
            echo "退出安装 shellMonitor!"
            exit 0
        fi
    fi

    echo -e "\e[0;33m监控周期(默认: 5分钟)\e[0m"
    read -r -p "请输入数字: " MONITOR_TIME
    MONITOR_TIME=$(echo ${MONITOR_TIME} | sed -r "s/^[ \t]*|[ \t]*$//g")  # 删除前后空格 sed -e "s/[ \t]*$//" -e "s/^[ \t]*//
    if [[ ${MONITOR_TIME} == "" ]]; then
        MONITOR_TIME=5
    fi

    echo -e "\e[0;33m请选择配置文件设置方式(默认按提示操作)\e[0m"
    read -r -p "按提示操作(1)/手动编辑(2): " EDITTYPE
    if [[ ${EDITTYPE} == 2 ]]; then
        echo -e "\e[0;32m已选择手动编辑配置文件。\e[0m"
        echo -e "\e[0;31m脚本不会检查相关配置值，请确保配置文件 config.sh 已经设定好!\e[0m"
        read -r -p "已设置好(Y)/还未设置(N): " GOINSTALL
        if [[ ${GOINSTALL} == "n" || ${GOINSTALL} == "N" ]]; then
            echo -e "\e[0;32m退出安装。\e[0m"
            exit 0
        fi
    else
        if [ -z "${HOST_NAME}" ]; then
            DEFHOSTNAME=$(cat /etc/hostname)
            echo -e "\e[0;33m服务器名称(默认: ${DEFHOSTNAME})\e[0m"
            read -r -p "请输入(可直接回车): " HOST_NAME
            if [ -z "${HOST_NAME}" ]; then
                HOST_NAME=${DEFHOSTNAME}
            fi
        fi
        sed -i "s#HOST_NAME=\".*\"#HOST_NAME=\"${HOST_NAME}\"#g" "${CUR_DIR}/config.sh"

        echo -e "\e[0;33m备份文件保存目录(默认: ${INSHOME}/backups)\e[0m"
        read -r -p "请输入: " BACKUP_DIR
        BACKUP_DIR=$(echo ${BACKUP_DIR} | sed -r "s/^[ \t]*|[ \t]*$//g")
        if [ -z "${BACKUP_DIR}" ]; then
            BACKUP_DIR="${INSHOME}/backups"
        fi
        sed -i "s#BACKUP_DIR=\".*\"#BACKUP_DIR=\"${BACKUP_DIR}\"#g" "${CUR_DIR}/config.sh"

        echo -e "\e[0;33m保留备份文件的天数(默认: 30)\e[0m"
        read -r -p "请输入数字: " BACKUP_DAY
        BACKUP_DAY=$(echo ${BACKUP_DAY} | sed -r "s/^[ \t]*|[ \t]*$//g")
        if [ -z "${BACKUP_DAY}" ]; then
            BACKUP_DAY=30
        fi
        sed -i "s#BACKUP_DAY=\".*\"#BACKUP_DAY=\"${BACKUP_DAY}\"#g" "${CUR_DIR}/config.sh"

        echo -e "\e[0;33m最低存储容量(存储空间低于该值将不再执行备份。默认: 100)\e[0m"
        read -r -p "请输入数字: " MIN_SIZE
        MIN_SIZE=$(echo ${MIN_SIZE} | sed -r "s/^[ \t]*|[ \t]*$//g")
        if [ -z "${MIN_SIZE}" ]; then
            MIN_SIZE=100
        fi
        sed -i "s#MIN_SIZE=\".*\"#MIN_SIZE=\"${MIN_SIZE}\"#g" "${CUR_DIR}/config.sh"

        echo -e "\e[0;33m是否启用邮件通知(默认: 否)?\e[0m"
        read -r -p "是(Y)/否(N): " MAIL_NOTICE
        if [[ ${MAIL_NOTICE} == "y" || ${MAIL_NOTICE} == "Y" ]]; then
            MAIL_NOTICE="true"
            echo -e "\e[0;32m请注意：部分服务器需要设置通过 SMTP 的方式发送邮件！\e[0m"
            echo ""
            echo -e "\e[0;33m请选择邮件发送方式(默认: mail)?\e[0m"
            read -r -p "mail/mutt(请输入小写): " MAIL_TYPE
            if [[ ${MAIL_TYPE} == "mutt" ]]; then
                MAIL_TYPE="mutt"
                yum install -y mutt
            else
                MAIL_TYPE="mail"
            fi

            echo -e "\e[0;33m接收报警通知的邮箱(多个邮箱用空格隔开)\e[0m"
            while :;do
                read -r -p "请输入: " MAIL_TO
                MAIL_TO=$(echo ${MAIL_TO} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${MAIL_TO} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31m接收报警邮箱不能为空!\e[0m"
                fi
            done
        else
            MAIL_NOTICE="false"
        fi
        sed -i "s#MAIL_NOTICE=\".*\"#MAIL_NOTICE=\"${MAIL_NOTICE}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#MAIL_TYPE=\".*\"#MAIL_TYPE=\"${MAIL_TYPE}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#MAIL_TO=\".*\"#MAIL_TO=\"${MAIL_TO}\"#g" "${CUR_DIR}/config.sh"

        echo -e "\e[0;33m是否启用微信通知(默认: 否)?\e[0m"
        read -r -p "是(Y)/否(N): " WECHAT_NOTICE
        if [[ ${WECHAT_NOTICE} == "y" || ${WECHAT_NOTICE} == "Y" ]]; then
            WECHAT_NOTICE="true"

            echo -e "\e[0;33m接收通知的用户 OPENID(多个用户用空格隔开)\e[0m"
            while :;do
                read -r -p "请输入: " TO_USER
                TO_USER=$(echo ${TO_USER} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${TO_USER} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31m用户 OPENID 不能为空!\e[0m"
                fi
            done

            echo -e "\e[0;33m微信模版 ID\e[0m"
            while :;do
                read -r -p "请输入: " TEMPLATE_ID
                TEMPLATE_ID=$(echo ${TEMPLATE_ID} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${TEMPLATE_ID} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31m微信模版 ID 不能为空!\e[0m"
                fi
            done

            echo -e "\e[0;33m微信公众号 APPID\e[0m"
            while :;do
                read -r -p "请输入: " APP_ID
                APP_ID=$(echo ${APP_ID} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${APP_ID} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31m微信公众号 APPID 不能为空!\e[0m"
                fi
            done

            echo -e "\e[0;33m微信公众号 APPSECRET\e[0m"
            while :;do
                read -r -p "请输入: " APP_SECRET
                APP_SECRET=$(echo ${APP_SECRET} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${APP_SECRET} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31m微信公众号 APPSECRET 不能为空!\e[0m"
                fi
            done
        else
            WECHAT_NOTICE="false"
        fi
        sed -i "s#WECHAT_NOTICE=\".*\"#WECHAT_NOTICE=\"${WECHAT_NOTICE}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#TO_USER=\".*\"#TO_USER=\"${TO_USER}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#TEMPLATE_ID=\".*\"#TEMPLATE_ID=\"${TEMPLATE_ID}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#APP_ID=\".*\"#APP_ID=\"${APP_ID}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#APP_SECRET=\".*\"#APP_SECRET=\"${APP_SECRET}\"#g" "${CUR_DIR}/config.sh"

        echo -e "\e[0;33m是否启用 Server 酱通知(默认: 否)?\e[0m"
        read -r -p "是(Y)/否(N): " FTQQ_SC_NOTICE
        if [[ ${FTQQ_SC_NOTICE} == "y" || ${FTQQ_SC_NOTICE} == "Y" ]]; then
            FTQQ_SC_NOTICE="true"

            echo -e "\e[0;33mServer 酱 KEY\e[0m"
            while :;do
                read -r -p "请输入: " FTQQ_SCKEY
                FTQQ_SCKEY=$(echo ${FTQQ_SCKEY} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${FTQQ_SCKEY} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31mServer 酱 KEY 不能为空!\e[0m"
                fi
            done
        else
            FTQQ_SC_NOTICE="false"
        fi
        sed -i "s#FTQQ_SC_NOTICE=\".*\"#FTQQ_SC_NOTICE=\"${FTQQ_SC_NOTICE}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#FTQQ_SCKEY=\".*\"#FTQQ_SCKEY=\"${FTQQ_SCKEY}\"#g" "${CUR_DIR}/config.sh"

        echo -e "\e[0;33m是否启用 PushBear 通知(默认: 否)?\e[0m"
        read -r -p "是(Y)/否(N): " FTQQ_PB_NOTICE
        if [[ ${FTQQ_PB_NOTICE} == "y" || ${FTQQ_PB_NOTICE} == "Y" ]]; then
            FTQQ_PB_NOTICE="true"

            echo -e "\e[0;33mPushBear SendKey\e[0m"
            while :;do
                read -r -p "请输入: " FTQQ_SENDKEY
                FTQQ_SENDKEY=$(echo ${FTQQ_SENDKEY} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${FTQQ_SENDKEY} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31mPushBear SendKey 不能为空!\e[0m"
                fi
            done
        else
            FTQQ_PB_NOTICE="false"
        fi
        sed -i "s#FTQQ_PB_NOTICE=\".*\"#FTQQ_PB_NOTICE=\"${FTQQ_PB_NOTICE}\"#g" "${CUR_DIR}/config.sh"
        sed -i "s#FTQQ_SENDKEY=\".*\"#FTQQ_SENDKEY=\"${FTQQ_SENDKEY}\"#g" "${CUR_DIR}/config.sh"

        if [[ ${MAIL_NOTICE} == "false" && ${WECHAT_NOTICE} == "false" && ${FTQQ_SC_NOTICE} == "false" && ${FTQQ_PB_NOTICE} == "false" ]]; then
            echo "======++++++======"
            echo -e "\e[0;31m所有通知方式都已禁用，将无法接收系统的任何警报信息！如要启用，请编辑 config.sh 中对应值。\e[0m"
            echo "======++++++======"
        fi

        echo -e "\e[0;33m是否启用文件监控(默认: 启用)\e[0m"
        read -r -p "启用(Y)/不启用(N): " ENABLE_FILE_MONITOR
        if [[ ${ENABLE_FILE_MONITOR} == "n" || ${ENABLE_FILE_MONITOR} == "N" ]]; then
            ENABLE_FILE_MONITOR="false"
        else
            ENABLE_FILE_MONITOR="true"

            echo -e "\e[0;33m请选择数文件比较方式(默认: du)\e[0m"
            read -r -p "请输入小写(md5/du): " DIFF_TYPE
            if [[ ${DIFF_TYPE} == "md5" || ${DIFF_TYPE} == "MD5" ]]; then
                DIFF_TYPE="md5sum"
            else
                DIFF_TYPE="du -b"
            fi
            sed -i "s#DIFF_TYPE=\".*\"#DIFF_TYPE=\"${DIFF_TYPE}\"#g" "${CUR_DIR}/config.sh"

            echo -e "\e[0;33m要监控的文件目录(多个目录用空格隔开)\e[0m"
            while :;do
                read -r -p "请输入: " MONITOR_DIR
                MONITOR_DIR=$(echo ${MONITOR_DIR} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${MONITOR_DIR} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31m监控目录不能为空!\e[0m"
                fi
            done
            sed -i "s#MONITOR_DIR=\".*\"#MONITOR_DIR=\"${MONITOR_DIR}\"#g" "${CUR_DIR}/config.sh"

            echo -e "\e[0;33m要排除的目录(该目录下的文件不做监控，多个目录用空格隔开) \e[0m"
            read -r -p "请输入(不添加直接回车): " EXCLUDE_DIR
            EXCLUDE_DIR=$(echo ${EXCLUDE_DIR} | sed -r "s/^[ \t]*|[ \t]*$//g")
            sed -i "s#EXCLUDE_DIR=\".*\"#EXCLUDE_DIR=\"${EXCLUDE_DIR}\"#g" "${CUR_DIR}/config.sh"

            echo -e "\e[0;33m是否启用 ZIP 压缩备份文件(默认: 是)?\e[0m"
            read -r -p "是(Y)/否(N): " ZIP_BACKUP
            if [[ ${ZIP_BACKUP} == "n" || ${ZIP_BACKUP} == "N" ]]; then
                ZIP_BACKUP="false"
            else
                ZIP_BACKUP="true"
            fi
            sed -i "s#ZIP_BACKUP=\".*\"#ZIP_BACKUP=\"${ZIP_BACKUP}\"#g" "${CUR_DIR}/config.sh"

            echo -e "\e[0;33m是否启用文件复制备份文件(默认: 是)?\e[0m"
            read -r -p "是(Y)/否(N): " FILE_BACKUP
            if [[ ${FILE_BACKUP} == "n" || ${FILE_BACKUP} == "N" ]]; then
                FILE_BACKUP="false"
            else
                FILE_BACKUP="true"
            fi
            sed -i "s#FILE_BACKUP=\".*\"#FILE_BACKUP=\"${FILE_BACKUP}\"#g" "${CUR_DIR}/config.sh"
        fi

        echo -e "\e[0;33m是否启用数据库监控(默认: 启用)\e[0m"
        read -r -p "启用(Y)/不启用(N): " ENABLE_DB_MONITOR
        if [[ ${ENABLE_DB_MONITOR} == "n" || ${ENABLE_DB_MONITOR} == "N" ]]; then
            ENABLE_DB_MONITOR="false"
        else
            ENABLE_DB_MONITOR="true"

            if ! cat /etc/my.cnf | grep ^user 1>/dev/null && ! cat /root/.my.cnf | grep ^user 1>/dev/null; then
                echo -e "\e[0;33mMySQL 数据库用户名(默认: root)\e[0m"
                read -r -p "请输入: " DB_USER
                DB_USER=$(echo ${DB_USER} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [ -z "${DB_USER}" ]; then
                    DB_USER="root"
                fi
                sed -i "s#DB_USER=\".*\"#DB_USER=\"${DB_USER}\"#g" "${CUR_DIR}/config.sh"
            fi
            if ! cat /etc/my.cnf | grep ^password 1>/dev/null && ! cat /root/.my.cnf | grep ^password 1>/dev/null; then
                echo -e "\e[0;33mMySQL 数据库密码(请注意前后空格)\e[0m"
                while :;do
                    read -r -p "请输入: " DB_PASS
                    if [[ ${DB_PASS} != "" ]]; then
                        break
                    else
                        echo -e "\e[0;31m数据库密码不能为空!\e[0m"
                    fi
                done
                sed -i "s#DB_PASS=\".*\"#DB_PASS=\"${DB_PASS}\"#g" "${CUR_DIR}/config.sh"
            fi

            echo -e "\e[0;33m需要备份的数据库名(多个数据库用空格隔开。默认: all)\e[0m"
            read -r -p "请输入(全库备份请输入小写 all 或者直接回车): " DB_NAME
            DB_NAME=$(echo ${DB_NAME} | sed -r "s/^[ \t]*|[ \t]*$//g")
            if [ -z "${DB_NAME}" ]; then
                DB_NAME="all"
            fi
            sed -i "s#DB_NAME=\".*\"#DB_NAME=\"${DB_NAME}\"#g" "${CUR_DIR}/config.sh"

            echo -e "\e[0;33m备份 MYSQL 时生成 CREATE 数据库语句(默认: 是)?\e[0m"
            read -r -p "是(Y)/否(N): " CREATE_DATABASE
            if [[ ${CREATE_DATABASE} == "n" || ${CREATE_DATABASE} == "N" ]]; then
                CREATE_DATABASE="false"
            else
                CREATE_DATABASE="true"
            fi
            sed -i "s#CREATE_DATABASE=\".*\"#CREATE_DATABASE=\"${CREATE_DATABASE}\"#g" "${CUR_DIR}/config.sh"

            echo -e "\e[0;33m请选择数据库备份周期(默认: 天)\e[0m"
            read -r -p "每天(D)/每小时(H): " DB_BACK_PER
            if [[ ${DB_BACK_PER} == "h" || ${DB_BACK_PER} == "H" ]]; then
                DB_BACK_PER="H"
            else
                DB_BACK_PER="D"
            fi
            sed -i "s#DB_BACK_PER=\".*\"#DB_BACK_PER=\"${DB_BACK_PER}\"#g" "${CUR_DIR}/config.sh"

            echo -e "\e[0;33m需要监控的数据库名(多个数据库用空格隔开)\e[0m"
            while :;do
                read -r -p "请输入: " DB_MONITOR_NAME
                DB_MONITOR_NAME=$(echo ${DB_MONITOR_NAME} | sed -r "s/^[ \t]*|[ \t]*$//g")
                if [[ ${DB_MONITOR_NAME} != "" ]]; then
                    break
                else
                    echo -e "\e[0;31m需要监控的数据库不能为空!\e[0m"
                fi
            done

            for DB in $(echo "${DB_MONITOR_NAME}" | tr -s ' '); do
                DB_TABLE=""
                DB_FIELD=""
                echo -e "\e[0;33m数据库 ${DB} 中监控的表(多个表用空格隔开)\e[0m"
                while :;do
                    read -r -p "请输入: " TMP_TABLE
                    TMP_TABLE=$(echo ${TMP_TABLE} | sed -r "s/^[ \t]*|[ \t]*$//g")
                    if [[ ${TMP_TABLE} != "" ]]; then
                        break
                    else
                        echo -e "\e[0;31m需要监控的表不能为空!\e[0m"
                    fi
                done

                DB_TABLE="${DB_TABLE} ${TMP_TABLE}"
                for TABLE in $(echo "${TMP_TABLE}" | tr -s ' '); do
                    echo -e "\e[0;33m${DB} -> ${TABLE} 中监控的字段(多个字段用英文逗号,隔开。\e[0;31m如果字段名是系统关键词，需要加上 \`！\e[0;33m) \e[0m"
                    read -r -p "请输入(全部字段可直接回车): " TMP_FIELD
                    TMP_FIELD=$(echo ${TMP_FIELD} | sed -r "s/^[ \t]*|[ \t]*$//g")
                    if [[ ${TMP_FIELD} == "" ]]; then
                        TMP_FIELD="*"
                    else
                        TMP_FIELD=$(echo "${TMP_FIELD}" | sed -r "s/ *//g" | sed -r 's/`/\\\\`/g')
                    fi
                    DB_FIELD="${DB_FIELD} ${TMP_FIELD}"
                done
                DBMONITORTABLE="${DBMONITORTABLE} \"${DB_TABLE}\""
                DBMONITORFIELD="${DBMONITORFIELD} \"${DB_FIELD}\""
            done

            DBMONITORTABLE=$(echo ${DBMONITORTABLE} | sed -r "s/ *\" */\\\"/g" | sed -r 's/""/" "/g')
            DBMONITORFIELD=$(echo ${DBMONITORFIELD} | sed -r "s/ *\" */\\\"/g" | sed -r 's/""/" "/g')
            DB_MONITOR_TABLE=(`echo ${DBMONITORTABLE}`)
            DB_MONITOR_FIELD=(`echo ${DBMONITORFIELD}`)

            sed -i "s#DB_MONITOR_NAME=\".*\"#DB_MONITOR_NAME=\"${DB_MONITOR_NAME}\"#g" "${CUR_DIR}/config.sh"
            sed -i "s#DB_MONITOR_TABLE=(.*)#DB_MONITOR_TABLE=(${DBMONITORTABLE})#g" "${CUR_DIR}/config.sh"
            sed -i "s#DB_MONITOR_FIELD=(.*)#DB_MONITOR_FIELD=(${DBMONITORFIELD})#g" "${CUR_DIR}/config.sh"
        fi
    fi

    mkdir -p ${BACKUP_DIR}/{tar,log,www,db}
    ln -sf ${CUR_DIR}/sysMonitor.sh /etc/profile.d/sysMonitor.sh
    sed -i "s/^PrintMotd [a-z]*/#&/g; 1,/#PrintMotd[a-z]*/{s/^#PrintMotd [a-z]*/PrintMotd no/g}" /etc/ssh/sshd_config
    service sshd restart

    sed -i "s#\`which mysql\`#`which mysql`#g" "${CUR_DIR}/dbMonitor.sh"
    sed -i "s#\`which mysqldump\`#`which mysqldump`#g" "${CUR_DIR}/dbMonitor.sh"
    sed -i "s#CUR_DIR=.*#CUR_DIR=${CUR_DIR}#g" "${CUR_DIR}/sysMonitor.sh"

    echo "*/${MONITOR_TIME} * * * * ${CUR_DIR}/main.sh" >> /var/spool/cron/root
fi


if [[ ${ENABLE_FILE_MONITOR} == "true" ]]; then
    fileMonitor ${1}
fi
if [[ ${ENABLE_DB_MONITOR} == "true" ]]; then
    dbMonitor ${1}
fi

if [[ -f "/tmp/file.change.txt" ]]; then
    # 附件作为第三个参数: -a 文件路径
    MailNotice "${HOST_NAME} 文件监控预警" "$(cat /tmp/file.change.txt | tr -d '\r')"
    rm -f /tmp/file.change.txt
fi
if [[ -f "/tmp/db.change.txt" ]]; then
    MailNotice "${HOST_NAME} 数据库监控预警" "$(cat /tmp/db.change.txt | tr -d '\r')"
    rm -f /tmp/db.change.txt
fi

if [[ ${BACKUP_DAY} != 0 ]]; then
    rm -f "${BACKUP_TAR_DIR}/*.${DEL_DATE}*.tar.gz"
    rm -rf "${BACKUP_FILE_DIR}/*.${DEL_DATE}*"
    rm -f "${BACKUP_DB_DIR}/db.${DEL_DATE}*.sql.gz"
fi
