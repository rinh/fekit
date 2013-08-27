Package = require '../package'
utils = require '../util'

exports.usage = "删除指定的包"

exports.set_options = ( optimist ) ->
    optimist

exports.run = ( options ) ->

    CURR = options.cwd

    pkgname = options['_'][1]

    if !pkgname 
        utils.logger.error "请指定要删除的包名称"
        return

    path = utils.path.closest CURR , "fekit_modules"

    if !path 
        utils.logger.error "找不到 fekit_modules 目录, 请确认是否在 fekit 项目目录中执行 uninstall 命令."
        return

    path = utils.path.join path , "fekit_modules" , pkgname

    if !utils.path.exists path 
        utils.logger.error "找不到 #{pkgname} , 删除失败"
        return

    utils.file.rmrf path , ( err ) ->
        if err 
            utils.logger.error "删除失败, 原因为 #{err.toString()}"
        else
            utils.logger.log "done."