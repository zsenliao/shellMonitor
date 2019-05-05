#!/bin/bash

### 配制开始，根据需要修改以下值 ###

# 监控网址
WEBSITE=""

# 监控目录
MONITOR_DIR=""  # 监控目录，多个目录用空格隔开
EXCLUDE_DIR=""  # 排除目录，暂不支持多个目录 #TODO
BACKUP_DIR=""  # 备份文件目录

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
MAIL_FROM="backup@${WEBSITE}"  # 发送预警通知邮件地址

# 微信推送参数，如果 WECHAT_NOTICE 值为 true，以下内容必填
TOUSER=""  # 接收推送用户 openid，多个用户用空格隔开
TEMPLATE_ID=""  # 模版ID
APPID=""
SECRET=""

SCKEY=""  # Server酱的 KEY
SENDKEY=""  # PushBear 的 SendKey

# 保留备份文件的天数
BACKUP_DAY="30"

# 保留最少容量 M
MIN_SIZE="100"  # 存储空间低于该容量不再备份，并发送预警通知

# 数据库配置
# 备份数据库与监控数据表的区别：
#     备份数据库：每天备份一次，全量备份，不做对比及报警
#     监控数据表：定时执行，如数据有改动，会发送报警通知
DB_HOST="localhost"
DB_USER="root"
DB_PASS="root"
DB_NAME="all"  # 需要备份的数据库名 All 或 输入类似 db1 db2 的列表清单
CREATE_DATABASE="yes"  # 备份MYSQL时生成CREATE数据库语句
DB_MONITOR_NAME=""  # 需要监控的数据库名，只能为单一数据库。以下监控的数据表必须是此数据库中的表
DB_MONITOR_TABLE=""  # 数据库中需要监控的表，监控全部字段变化，可以为多个表，以空格隔开
DB_ADMIN_MONITOR_TABLE=""  # 需指定监控某些字段的表，比如管理员表，避免登录时间、IP变化带来的频繁报警；如果要监控登录事件，则可以不填写此项
DB_ADMIN_MONITOR_FIELD=""  # 需指定监控的字段

# 文件比较方式
# du: 文件大小对比，效率更快
# md5: 相对更安全，但效率更慢
DIFF_TYPE="du"

### 配制结束 ###
