#!/bin/bash

CUR_DIR=/home/shellMonitor  # 需改为脚本所在的绝对路径

. ${CUR_DIR}/config.sh
. ${CUR_DIR}/notice.sh

LOGIN_IP=`echo $SSH_CLIENT | cut -d " " -f 1`
LOGIN_USER=`whoami`

WeChatNotice "${WEBSITE} SSH 登录提醒！" "${WEBSITE}" "[登录用户]${LOGIN_USER}" "[登录IP]${LOGIN_IP}" "如非本人登录，请检查服务器安全！"
ServerNotice "${WEBSITE} SSH 登录提醒！" "[登录用户]${LOGIN_USER} \n[登录IP]${LOGIN_IP} \n如非本人登录，请检查服务器安全！"
MailNotice "${WEBSITE} SSH 登录提醒！" "[登录用户]${LOGIN_USER} \n[登录IP]${LOGIN_IP} \n如非本人登录，请检查服务器安全！"

# cat /var/log/audit/audit.log | grep "failed"

# cat /var/log/secure | grep "Failed password"

lastlog
