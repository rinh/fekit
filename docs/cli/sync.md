sync
========

###usage

    fekit sync
               -f, --file     更换成其它目录下的配置文件, 默认使用当前目录下的 .dev,见实例
               -n, --name     更换其它的配置名, 默认使用 dev ,见实例
               -i, --include  同 rsync 的 include 选项
               -e, --exclude  同 rsync 的 exclude 选项
               -x, --nonexec  上传后禁止执行 shell ,可配置
               -d, --delete   删除服务器上本地不存在的文件
               -h, --help     查看帮助


###description

想要与服务器同步，需要配置`.dev`文件，

`.dev`文件配置实例

    {
        "dev": {
            "host": "l-qzz1.fe.dev.cn6.qunar.com",
            "path": "/home/q/www/qunarzz.com/ordercenter/",
            "local": "./",
            "user": "cc.zhuang",
            "shell": "nginx -s reload",
            "delete": true,
            "nonexec": true,
            "include": [],
            "exclude": ".git"
        },
        "qa": {
            "host": "l-qzz1.fe.dev.cn6.qunar.com",
            "path": "/home/q/www/qunarzz.com/ordercenter/",
            "local": "./",
            "user": "cc.zhuang",
            "shell": "nginx -s reload",
            "delete": true,
            "nonexec": true,
            "include": [],
            "exclude": ".git"
        }

    }
