#!/bin/bash

CUR_DIR=/home/shellMonitor  # 需改为脚本所在的绝对路径

. ${CUR_DIR}/config.sh
. ${CUR_DIR}/notice.sh

LOGIN_IP=`echo $SSH_CLIENT | cut -d " " -f 1`
LOGIN_USER=`whoami`

if [[ ${WECHAT_NOTICE} = "true" ]]; then
    WeChatNotice "系统SSH登录提醒！" ${WEBSITE} "[登录用户]${LOGIN_USER}" "[登录IP]${LOGIN_IP}"
fi

if [[ ${SC_NOTICE} = "true" ]]; then
    ServerNotice "网站${WEBSITE}SSH登录提醒！" "[登录用户]${LOGIN_USER} \n[登录IP]${LOGIN_IP}"
fi

if [[ ${PUSHBEAR_NOTICE} = "true" ]]; then
    PushBearNotice "网站${WEBSITE}SSH登录提醒！" "[登录用户]${LOGIN_USER} \n[登录IP]${LOGIN_IP}"
fi

MailNotice "网站${WEBSITE}SSH登录提醒！" "[登录用户]${LOGIN_USER} [登录IP]${LOGIN_IP}"

# cat /var/log/audit/audit.log | grep "failed"

# cat /var/log/secure | grep "Failed password"

lastlog
