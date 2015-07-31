utils = require '../util'


exports.usage = "安装或删除插件"

exports.set_options = ( optimist ) ->

    optimist.alias 'i' , 'install'
    optimist.describe 'i' , '安装插件'

    optimist.alias 'u' , 'uninstall'
    optimist.describe 'u' , '删除插件'


exports.run = ( options ) ->

    dirpath = utils.path.join( utils.path.get_user_home() , ".fekit" , ".extensions" )

    utils.file.mkdirp( dirpath )
    if process.platform is "win32" then npm = "npm.cmd"
    else npm = "npm"

    if options.install
        utils.proc.spawn npm , [ 'install', 'fekit-extension-' + options.install , '-g' ] , () ->
            utils.logger.log '安装完成.'
            utils.exit

    if options.uninstall
        utils.proc.spawn npm , [ 'uninstall', 'fekit-extension-' + options.uninstall , '-g' ] , () ->
            utils.logger.log '删除完成.'
            utils.exit

