#!/bin/bash

### 配制开始，根据需要修改以下值 ###

# 基础设置
WEBSITE="myServer"  # 服务器
BACKUP_DIR="/data/backup"  # 备份文件保存目录
BACKUP_DAY="30"  # 保留备份文件的天数
DB_BACK_PER="D"  # 数据库备份周期 D/每天 H/每小时
MIN_SIZE="100"  # 保留最少容量 M。存储空间低于该容量不再备份，并发送预警通知
DIFF_TYPE="du"  # 文件比较方式。du: 文件大小对比；md5: 相对更安全

# 文件监控设置
MONITOR_DIR="/data/wwwroot /data/wwwconf"  # 监控目录，多个目录用空格隔开
EXCLUDE_DIR="/data/wwwlogs"  # 排除目录，暂不支持多个目录 #TODO

# 备份相关，如不启用，请改为 false
ZIP_BACKUP="true"  # 启用 ZIP 压缩备份
FILE_BACKUP="true"  # 启用文件备份

# 通知相关，如不启用，请改为 false
MAIL_NOTICE="true"  # 邮件通知
WECHAT_NOTICE="true"  # 微信通知
SC_NOTICE="false"  # Server酱通知
PUSHBEAR_NOTICE="false"  # PushBear通知

# 发邮件参数，如果 MAIL_NOTICE 值为 true，以下内容必填
MAIL_TO=""  # 接受报警通知邮箱，多个邮箱请用空格隔开
MAIL_TYPE="mail"  # 发送邮件方式，可选 mail 或 mutt

# 微信推送参数，如果 WECHAT_NOTICE 值为 true，以下内容必填
TOUSER=""  # 接收推送用户 openid，多个用户用空格隔开
TEMPLATE_ID=""  # 模版ID
APPID=""
SECRET=""

SCKEY=""  # Server酱的 KEY
SENDKEY=""  # PushBear 的 SendKey

# 数据库配置
#   备份数据库设置：按周期、全量备份，不做对比及报警
DB_HOST="localhost"
DB_USER="root"
DB_PASS="root"
DB_NAME="all"  # 需要备份的数据库名 All 或 输入类似 db1 db2 的列表清单
CREATE_DATABASE="yes"  # 备份MYSQL时生成CREATE数据库语句
#   数据库监控设置：定时执行，如数据有改动，会发送报警通知
DB_MONITOR_NAME="db1 db2"  # 需要监控的数据库名，多个数据库以空格隔开
DB_MONITOR_TABLE=("db1_tb1 db1_tb2 db1_tb3" "db2_tb1 db2_tb2")  # 数据库中需要监控的表，多个表以空格隔开。表位置需（引号间的空格）对应上面的数据库位置
DB_MONITOR_FIELD=("\* db1_tb2_fd1,db1_tb2_fd2,db1_tb2_fd3 \*" "db2_tb1_fd1,db2_tb1_fd2 \*")  # 监控数据表中，指定监控的字段。字段之间不能有空格，如不指定请输入 \* (注意：需要反斜杠)

### 配制结束 ###
