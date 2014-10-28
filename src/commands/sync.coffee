_ = require 'underscore'
child_process = require 'child_process'
utils = require '../util'

exports.usage = "同步/上传当前目录至远程服务器(依赖rsync)"

exports.set_options = ( optimist ) ->
    optimist.alias 'f', 'file'
    optimist.describe 'f', '更换其它的配置文件, 默认使用当前目录下的 .dev'

    optimist.alias 'n', 'name'
    optimist.describe 'n', '更换其它的配置名, 默认使用 dev'

    optimist.alias 'i', 'include'
    optimist.describe 'i', '同 rsync 的 include 选项'

    optimist.alias 'e', 'exclude'
    optimist.describe 'e', '同 rsync 的 exclude 选项'

    optimist.alias 'x', 'nonexec'
    optimist.describe 'x', '上传后禁止执行 shell'

    optimist.alias 'd', 'delete'
    optimist.describe 'd', '删除服务器上本地不存在的文件'


rsync = (opts) ->
    _args = [
        "-rzcv",
        "--chmod=a='rX,u+w'",
        "--rsync-path='sudo rsync'",
        "#{opts.local}",
        "#{opts.user}#{opts.host}:#{opts.path}",
        "#{opts.include || ''}",
        "#{opts.exclude || ''}",
        "--temp-dir=/tmp"
    ]

    if opts.delete then _args.push '--delete'
    args = _args.join(' ')

    if utils.sys.isWindows then process.env['HOME'] = process.env.USERPROFILE
    utils.logger.log "[调用] rsync #{args}"
    child_process.exec "rsync #{args}", (err, stdout, stderr) ->
        if err
            if utils.sys.isWindows
                utils.logger.error "出错了！"
                utils.logger.error "[提示] 1. 请确认 'rsync' 指令是否存在"
                utils.logger.error "[提示]    如不存在，下载 http://wiki.corp.qunar.com/download/attachments/42273573/rsync.rar?version=1&modificationDate=1402624229000"
                utils.logger.error "          解压将存放路径添加到环境变量 'PATH' 中，如 set PATH=C:\\rsync;%PATH%"
                utils.logger.error "[提示] 2. 请确认是否可以免密登录相应开发机，且拥有 sudo 权限"
                utils.logger.error "[提示]    如不可以，登录 http://ops.corp.qunar.com/ops/account/ 申请相关权限，并配置免密登录开发机"
                return null
            else
                throw err

        if stdout then utils.logger.log stdout
        if stderr then utils.logger.error stderr

        if opts.shell and (not opts.nonexec) then shell opts

shell = (opts) ->
    cmd = opts.shell.replace /'/g, "\\'"
    args = "#{opts.user}#{opts.host} '#{cmd}'"

    utils.logger.log "[执行] ssh #{args}"

    child_process.exec "ssh #{args}", (err, stdout, stderr) ->
        if err then throw err
        if stdout then utils.logger.log stdout
        if stderr then utils.logger.error stderr


exports.run = (options) ->
    files = [
        options.file || '.dev',
        'fekit.config'
    ]
    path = utils.path.existsFiles options.cwd, files
    reader = new utils.file.reader()
    yaml = reader.readJSON path

    # 默认使用 dev 节点下的配置
    conf = yaml['dev']
    if options.name and yaml[options.name]
        conf = yaml[options.name]

    if not conf
        utils.logger.error "没有匹配的 #{options.name || 'dev'} 节点"
        return

    opts =
        host  : conf.host
        path  : conf.path
        local : (conf.local || './')
        user  : (if conf.user then conf.user + "@" else "")
        shell : conf.shell

    opts.delete = true if options.delete
    opts.nonexec = true if options.nonexec

    # ----------

    default_include = []
    if conf['include'] and conf['include']['length'] > 0
        default_include = default_include.concat conf['include']

    if options.include and options.include.length
        default_include = default_include.concat options.include

    if default_include.length > 0
        default_include = _.uniq default_include
        opts.include = ("--include=#{item}" for item in default_include).join ' '


    # ----------

    default_exclude = ['.svn', '.git']
    if conf['exclude'] and conf['exclude'].length > 0
        default_exclude = default_exclude.concat conf['exclude']

    if options.exclude and options.exclude.length
        default_exclude = default_exclude.concat options.exclude

    if default_exclude.length > 0
        default_exclude = _.uniq default_exclude
        opts.exclude = ("--exclude=#{item}" for item in default_exclude).join ' '


    rsync opts
