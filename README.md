# shellMonitor
一个 Linux 下基于 bash 的文件和数据库监控及备份工具。

写这个工具的原因，在于一个朋友的一个小电商网站，因为未明原因被黑了，总是会被增加超级管理员，并将收款账号改成别人的。于是有了写一个监控工具的想法。

> 因为不断的重新安装/初始化各项系统服务，为了方（TOU）便（LAN），写了一个[服务器初始化脚本](https://github.com/zsenliao/initServer)，主要功能包括：
> * 可选添加用户及 SSH 傻瓜式配置；
> * git/zsh/oh-my-zsh 等安装、vim 升级（增加`nginx`, `ini`, `php`, `python`等文件类型的高亮显示）；
> * MySQL/PHP/Python3(uwsgi)/Redis/Nodejs/Nginx/ikev2/acme.sh 等服务可选择安装；
> * 提供了一个简单的管理工具，用于管理`nginx`,`mysql`,`php-fpm`,`redis`,`uwsgi`等服务，以及新增站点（自动申请并配置安装域名证书）；

## 主要功能

### 监控功能
* 文件监控：主要监控网站文件，可以监控多个网站目录，也可以在配置中将 `Nginx`、`PHP`、`MySQL` 等的配置文件也添加到监控中；
* 数据库监控：可以监控指定数据库中的指定数据表；也可以对指定的表指定字段做监控；
* 数据库备份：设定的数据库全量傻瓜式备份，无监控功能；

### 报警功能
* Server酱：通过「[Server酱](http://sc.ftqq.com/3.version)」推送预警消息通知（只能推送给**单个**微信账号）；
* PushBear：通过「[PushBear](https://pushbear.ftqq.com/admin/#/)」推送预警消息通知（可以推送给**多个**微信账号）；
* 微信报警：设置好相关的微信公众号参数后，监控到改变会发送微信模板通知（可以推送给**多个**微信账号）；
* 邮件通知：详细的改变内容会通过邮件发送；
> 提示：如果是阿里云或者腾讯云服务器，会禁止 `25` 端口，默认方式邮件发送失败。可以手动配置邮件发送服务器或者 `MUTT` ，设置以 `SMTP` 的方式发送邮件。也可以在云服务商管理后台申请解封 `25` 端口。

#### 关于Server酱通知
微信接收通知其实是相当方便的一种方式，但测试账号发出的通知会被折叠到订阅号中，一不留神可能就错过通知消息。

而认证又是相当麻烦的一件事情：需要企业身份申请服务号认证。所以增加Server酱通知。

> **说明：**
> * 在[微信推送](http://sc.ftqq.com/?c=wechat&a=bind)中绑定微信号后，就可以在微信对话界面看到推送的消息；
> * Server酱只支持推送到一个微信号，如果想要推送到多个微信号，请使用`PushBear`或微信通知功能；

#### 关于 PushBear 通知
与`Server酱`一样，区别在于可以推送到多个微信账号。请点击[这里](https://pushbear.ftqq.com/admin/#/channel)先行设置好通道。

#### 关于微信通知
如果没有微信公众号、或者没有做认证的公众号，发送模版消息有限制。可以申请[微信公众平台接口测试账号](https://mp.weixin.qq.com/debug/cgi-bin/sandbox?t=sandbox/login)，然后新增测试模版，标题随便写，内容如下：

> {{first.DATA}}
> 网站名称：{{keyword1.DATA}}
> 监控项目：{{keyword2.DATA}}
> 预警状态：{{keyword3.DATA}} 
> {{remark.DATA}}

## 使用方式

* 克隆项目
```bash
git clone https://github.com/zsenliao/shellMonitor.git
```

* 设置权限
```bash
chown -R root:root shellMonitor  #  建议在 root 权限下操作
chmod +x shellMonitor/*.sh  # 添加执行权限
```

* 修改配置
```bash
vi shellMonitor/config.sh  # 根据提示修改相关的配置
```

* 初始化
```bash
shellMonitor/main.sh init
```

* 检查系统定时任务是否生效
```bash
crontab -l | grep shellMonitor  # shellMonitor 为程序目录名
```
如返回结果为空，请通过`crontab -e`的方式手动添加。

* `SSH` 登录预警通知的手动添加方式
```bash
ln -sf /home/shellMonitor/sysMonitor.sh /etc/profile.d/sysMonitor.sh

sed -i "s/^PrintMotd [a-z]*/#&/g; 1,/#PrintMotd[a-z]*/{s/^#PrintMotd [a-z]*/PrintMotd no/g}" /etc/ssh/sshd_config

# 重启 SSH 服务
service sshd restart
```
> 注意：需要修改 `sysMonitor.sh` 文件中的 `CUR_DIR` 为脚本所在的实际路径

## TODO
* [x] 将设定系统任务添加到初始化任务中
* [ ] 监控文件或数据库设置错误情况下的异常处理
* [x] 如邮件通知方式选择 `mutt` 但系统中并没有安装改工具下的处理
* [x] 增加 `SSH` 登录的预警通知
* [x] 增加 `SFTP` 登录的预警通知
* [ ] 增加 `SCP` 上传文件的预警通知
* [x] 增加「[PushBear](http://pushbear.ftqq.com/admin/#/api)」预警通知功能
* [x] 增加 「[Server酱](http://sc.ftqq.com/3.version)」预警通知功能
* [x] 优化微信 `ACCESS_TOKEN` 获取方式
* [ ] 文件监控中，增加多个排除的目录
* [ ] 优化数据库/表的监控
* [ ] 检测更改文件内容

## 相关说明及风险提示
* 本工具可作为一些个人网站，或一些小微电商类型网站做**伪**入侵检测工具用，毕竟小微团队在系统运维及安全方面的投入几乎没有；
* 对于具备资源的团队，还是需要从**运维策略**上来考虑安全风险防范的问题；
* 本工具对于系统资源的消耗，并未经测试过；不过我认为目前一般商用的服务器配置，即便是小团队的电商网站的服务器配置，都经得起这点消耗吧；
* 如果您使用了本工具，也请不要完全依赖本工具。如有条件，想办法做系统层面、数据库层面、代码层面的加固；如条件实在不足，也请多关注您系统的异常状况。
