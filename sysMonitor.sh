#!/bin/bash

CUR_DIR=/home/shellMonitor  # 需改为脚本所在的绝对路径

. ${CUR_DIR}/config.sh
. ${CUR_DIR}/notice.sh

LOGIN_IP=`echo $SSH_CLIENT | cut -d " " -f 1`
LOGIN_USER=`whoami`

if [[ ${WECHAT_NOTICE} = "true" ]]; then
    WeChatNotice "${WEBSITE} SSH 登录提醒！" "${WEBSITE}" "[登录用户]${LOGIN_USER}" "[登录IP]${LOGIN_IP}" "如非本人登录，请检查服务器安全！"
fi

if [[ ${SC_NOTICE} = "true" ]]; then
    ServerNotice "${WEBSITE} SSH 登录提醒！" "[登录用户]${LOGIN_USER} \n[登录IP]${LOGIN_IP} \n如非本人登录，请检查服务器安全！"
fi

if [[ ${PUSHBEAR_NOTICE} = "true" ]]; then
    PushBearNotice "${WEBSITE} SSH 登录提醒！" "[登录用户]${LOGIN_USER} \n[登录IP]${LOGIN_IP} \n如非本人登录，请检查服务器安全！"
fi

MailNotice "${WEBSITE} SSH 登录提醒！" "[登录用户]${LOGIN_USER}<br>[登录IP]${LOGIN_IP}<br>如非本人登录，请检查服务器安全！"

# cat /var/log/audit/audit.log | grep "failed"

# cat /var/log/secure | grep "Failed password"

lastlog
