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

    optimist.alias 'i' , 'init'
    optimist.describe 'i', '初始化 .dev 文件'

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
    child_process.exec "rsync #{args}", {
        maxBuffer: 200 * 1024 * 1024
    }, (err, stdout, stderr) ->
        if err
            utils.logger.log "[提示] 如遇问题参见 http://wiki.corp.qunar.com/display/fe/8+Trouble+shooting"
            throw err

        if stdout then utils.logger.log stdout
        if stderr then utils.logger.error stderr

        unless opts.nonexec
            common_shell = 
                user : opts.user
                host : opts.host
                shell : "sudo /home/q/tools/bin/fekit_common_shell.sh \"#{opts.path}\""
            shell common_shell , () ->
                if opts.shell then shell opts

shell = (opts,cb) ->
    cmd = opts.shell.replace /'/g, "\\'"
    args = "#{opts.user}#{opts.host} '#{cmd}'"

    utils.logger.log "[执行] ssh #{args}"

    child_process.exec "ssh #{args}", (err, stdout, stderr) ->
        if err then throw err
        if stdout then utils.logger.log stdout
        if stderr then utils.logger.error stderr
        cb()

init = (options) ->
    code = 
        dev : 
            host : ""
            path : ""
    code_path = utils.path.join options.cwd , ".dev"
    utils.logger.log "[sync] 已创建 .dev 配置"
    utils.file.io.write code_path , JSON.stringify(code,null,4)


exports.run = (options) ->

    return init(options) if options.init 

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
