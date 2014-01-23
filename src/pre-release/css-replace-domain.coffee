utils = require "../util"

trace = ( msg , cb ) ->
    utils.logger.trace msg 
    cb()

exports.exec = ( type , options , done ) ->
    conf = utils.config.parse options.cwd
    path = utils.path.join options.cwd , type
    host = conf.root?.export_global_config?.resource_domain
    prefix = conf.root?.export_global_config?.resource_pid
    return trace "fekit.config 中没有找到`export_global_config.resource_domain`配置节" , done unless host 
    return trace "fekit.config 中没有找到图片前缀`export_global_config.resource_pid`配置节" , done unless prefix
    return trace "没有找到`#{type}`目录" , done unless utils.path.exists path

    # 生成的图片不写协议
    host = host.replace('http://','').replace('https://','').replace('/','')

    console.info( path )
    utils.path.find.file /\.css$/ , path , ( files ) -> 
        console.info files
        
        