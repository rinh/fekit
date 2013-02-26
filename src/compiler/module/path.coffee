syspath = require 'path'
utils = require '../../util'

### ---------------------------
    模块路径
###
class ModulePath
    
    # @uri 物理真实路径
    constructor:( @uri ) ->

    parseify:( path_without_extname ) ->
        extname = @extname()
        if ~ModulePath.EXTLIST.indexOf( extname )
            return utils.file.findify( path_without_extname , ModulePath.EXTLIST )
        throw "not found extname for compile [#{extname}]"

    extname:() ->
        return syspath.extname(@uri)

    dirname:() ->
        return syspath.dirname(@uri)

    getFullPath:()->
        return @uri

    getContentType:()->
        return ModulePath.getContentType( @extname() )

###
    解析子模块真实路径

    子模块路径表现形式可以是
        省略后缀名方式, 该方式会认为子模块后缀名默认与parentModule相同
            a/b/c
            a.b.c
            
            后缀名默认匹配顺序为, 如果都找不到就会报错
            [javascript]
            .js / .coffee / .mustache 
            [css]
            .css / .less

    子模块的

    子模块路径分2种
    1, 相对路径, 相对于父模块的dirname. 如 a/b/c
    2, 库引用路径, 库是由配置指定的路径. 如 core/a/b/c , core是在配置文件中进行配置的

###
ModulePath.resolvePath = ( path , parentModule ) ->
    parts = utils.path.split_path( path , ModulePath.EXTLIST )
    result = []

    # 解析全路径
    for part , i in parts
        if i == 0
            if parentModule.config.isUseLibrary( part )
                # 库引用路径
                result.push( parentModule.config.parseLibrary( part ) )    
            else
                # 相对路径
                result.push( parentModule.path.dirname() )
                result.push( part )
        else
            result.push( part )

    # 解析文件名( 猜文件名 )
    path_without_extname = syspath.join.apply( syspath , result )
    truelypath = parentModule.path.parseify( path_without_extname )
    utils.logger.info("[COMPILE] 解析子模块真实路径 #{path} >>>> #{truelypath}")
    return truelypath

ModulePath.getContentType = ( extname ) ->
    ModulePath.EXTTABLE[ extname ]?.contentType


ModulePath.addExtensionPlugin = ( extName , plugin ) ->
    ModulePath.EXTLIST.push( extName )
    ModulePath.EXTTABLE[ extName ] = plugin

# 后缀列表 
ModulePath.EXTLIST = []
ModulePath.EXTTABLE = {}


exports.ModulePath = ModulePath
