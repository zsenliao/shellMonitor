#!/bin/bash

MailNotice() {
    # 将备份文件保存至指定邮箱
    if [[ ${MAIL_NOTICE} == "true" ]]; then
        if [[ "${MAIL_TYPE}" == "mail" ]]; then
            echo "${2}" | mail -s "${1}" "${MAIL_TO}"
        fi

        if [[ "${MAIL_TYPE}" == "mutt" ]]; then
            for MAILTO in $(echo "${MAIL_TO}" | tr -s ' '); do
                echo "${2}" | mutt -s "${1}" "${MAILTO}"
            done
        fi
    fi
}

WeChatNotice() {
    if [[ ${WECHAT_NOTICE} == "true" ]]; then
        GetAccessToken

        # 发送模版消息，多个用户以空格分隔
        for OPENID in $(echo "${TO_USER}" | tr -s ' '); do
            wxTemplate "${OPENID}" "${1}" "${2}" "${3}" "${4}" "${5}"
        done
    fi
}

wxTemplate() {
    # 发送模版消息
    # {{first.DATA}}
    # 网站名称：{{keyword1.DATA}}
    # 监控项目：{{keyword2.DATA}}
    # 预警状态：{{keyword3.DATA}}
    # {{remark.DATA}}
    curl -s -o /dev/null --request POST \
         --url "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=${ACCESS_TOKEN}" \
         --header "cache-control: no-cache" \
         --header "content-type: application/json" \
         --data '{
                "touser":"'"${1}"'",
                "template_id":"'"${TEMPLATE_ID}"'",
                "url":"",
                "data":{
                    "first": {
                        "value":"'"${2}"'\n",
                        "color":"#565656"
                    },
                    "keyword1": {
                        "value":"'"${3}"'",
                        "color":"#173177"
                    },
                    "keyword2": {
                        "value":"'"${4}"'",
                        "color":"#ff7700"
                    },
                    "keyword3": {
                        "value":"'"${5}"'",
                        "color":"#173177"
                    },
                    "remark": {
                        "value":"\n\n'"${6}"'",
                        "color":"#ff7700"
                    }
                }
            }'
}

GetAccessToken() {
    if [ ! -f "/tmp/access_token" ]; then
        touch "/tmp/access_token"
        GetAccessToken4Curl
    else
        local MTIME
        MTIME=$(cat /tmp/access_token | grep expires_time | cut -d "|" -f 1)
        let EXPTIME=$(date +%s)-${MTIME}
        if [ ${EXPTIME} -lt 6000 ]; then
            ACCESS_TOKEN=$(cat /tmp/access_token | grep access_token | cut -d "|" -f 1)
        else
            GetAccessToken4Curl
        fi
    fi
}

GetAccessToken4Curl() {
    # 获取微信 access token
    # return: {"access_token":"ACCESS_TOKEN","expires_in":7200}
    local JSON_STR
    JSON_STR=$(curl -s --request GET --url "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${APP_ID}&secret=${APP_SECRET}" --header 'cache-control: no-cache')
    ACCESS_TOKEN=$(echo "${JSON_STR}" | sed "s/{\"access_token\":\"//" | sed "s/\",\"expires_in\":7200}//")
    # ACCESS_TOKEN=${JSON_STR#\{\"access_token\":\"}
    # ACCESS_TOKEN=${ACCESS_TOKEN%\",\"expires_in\":7200\}}

    echo "${ACCESS_TOKEN}|access_token" > /tmp/access_token
    echo "$(date +%s)|expires_time" >> /tmp/access_token
}

ServerNotice() {
    if [[ ${FTQQ_SC_NOTICE} == "true" ]]; then
        curl -s -o /dev/null --request GET \
            --url "https://sc.ftqq.com/${FTQQ_SCKEY}.send?text=${1}&desp=${2}" \
            --header 'cache-control: no-cache'
    fi

    if [[ ${FTQQ_PB_NOTICE} == "true" ]]; then
        curl -s -o /dev/null --request GET \
            --url "https://pushbear.ftqq.com/sub?sendkey=${FTQQ_SENDKEY}&text=${1}&desp=${2}" \
            --header 'cache-control: no-cache'
    fi
}