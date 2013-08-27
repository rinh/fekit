syspath = require 'path'
utils = require '../util'
child_process = require('child_process')

exports.usage = "同步/上传当前目录至远程服务器(依赖rsync)"

exports.set_options = ( optimist ) ->

    optimist.alias 'f' , 'file'
    optimist.describe 'f' , '更换其它的配置文件, 默认使用当前目录下的 .dev'

    optimist.alias 'n' , 'name'
    optimist.describe 'n' , '更换其它的配置名, 默认使用 dev'

    optimist.alias 'i' , 'include'
    optimist.describe 'i' , '同 rsync 的 include 选项'

    optimist.alias 'e' , 'exclude'
    optimist.describe 'e' , '同 rsync 的 exclude 选项'
    
    optimist.alias 'x' , 'nonexec' 
    optimist.describe 'x' , '上传后禁止执行 shell'


rsync = ( opts ) ->

    _args = [ "-rzcv" , "--chmod=a='rX,u+w'" , "--rsync-path='sudo rsync'" , "#{opts.local}" , "#{opts.user}#{opts.host}:#{opts.path}" , "#{opts.include||''}" , "#{opts.exclude||''}" , "--temp-dir=/tmp" ]
    args = _args.join(' ')

    utils.logger.log "[调用] rsync #{args}"

    child_process.exec "rsync #{args}" , ( err , stdout , stderr ) ->
        if err then throw err 
        if stdout then utils.logger.log( stdout )
        if stderr then utils.logger.error( stderr )              

        if opts.shell and !opts.nonexec then shell( opts ) 

shell = ( opts ) ->
    
    cmd = opts.shell.replace /'/g , "\\'"
    args = "#{opts.user}#{opts.host} '#{cmd}'"

    utils.logger.log "[执行] ssh #{args}"

    child_process.exec "ssh #{args}" , ( err , stdout , stderr ) ->
        if err then throw err 
        if stdout then utils.logger.log( stdout )
        if stderr then utils.logger.error( stderr )        


exports.run = ( options ) ->

    path = utils.path.existsFiles( options.cwd , [ options.file || ".dev" , "fekit.config" ] )
    yaml = new utils.file.reader().readJSON( path )

    # 默认使用 dev 节点下的配置
    conf = yaml['dev']
    if options.name and yaml[options.name]
        conf = yaml[options.name]

    if !conf
        utils.logger.error "没有匹配的 #{options.name||'dev'} 节点"
        return

    opts = 
        host : conf.host
        path : conf.path
        local : ( conf.local || './' )
        user : ( if conf.user then conf.user + "@" else "" )
        shell : conf.shell

    #------
     
    default_include = []
    if conf['include'] && conf['include'].length > 0
        default_include = default_include.concat( conf['include'] )

    if options.include && options.include.length
        default_include = default_include.concat( options.include )
    
    if default_include.length > 0 
        opts.include = ( "--include=#{item}" for item in default_include ).join(' ') 

    #------
     
    default_exclude = ['.svn']
    if conf['exclude'] && conf['exclude'].length > 0
        default_exclude = default_exclude.concat( conf['exclude'] )

    if options.exclude && options.exclude.length
        default_exclude = default_exclude.concat( options.exclude )
    
    if default_exclude.length > 0 
        opts.exclude = ( "--exclude=#{item}" for item in default_exclude ).join(' ') 
    
    rsync( opts )
