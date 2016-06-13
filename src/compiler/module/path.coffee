syspath = require 'path'
fs = require 'fs'
utils = require '../../util'
cjson = require 'cjson'

### ---------------------------
    模块路径
###
class ModulePath

    # @uri 物理真实路径
    constructor:( @uri ) ->

    parseify:( path_without_extname ) ->
        extname = @extname()
        if ~ModulePath.EXTLIST.indexOf( extname )
            ext_list = ModulePath.getContentTypeList(extname)
            result = utils.file.findify( path_without_extname , ext_list )
            #如果仍然没有，则以 path_without_extname 为目录名进行测试
            if result is null and utils.path.exists( path_without_extname ) and utils.path.is_directory( path_without_extname )
                p = utils.path.join( path_without_extname , "index" )
                result = utils.file.findify( p , ModulePath.EXTLIST )
        if result
            return result
        else
            throw "找不到文件或对应的编译方案 [#{path_without_extname}] 后缀检查列表为[#{ModulePath.EXTLIST}]"

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
    2, 别名引用路径, 别名是由配置指定的路径. 如 core/a/b/c , core是在配置文件中进行配置的

###
ModulePath.resolvePath = ( path , parentModule ) ->
    # 解析文件名( 猜文件名 )
    path_without_extname = ModulePath.parsePath( path , parentModule )
    truelypath = parentModule.path.parseify( path_without_extname )
    utils.logger.trace("[COMPILE] 解析子模块真实路径 #{path} >>>> #{truelypath}")
    return truelypath

ModulePath.parsePath = ( path , parentModule ) ->
    parts = utils.path.split_path( path , ModulePath.EXTLIST )
    result = []

    # 解析全路径
    for part , i in parts
        if i == 0 and parts.length is 1

            ###
                处理组件名或只写一个当前目录文件且没有扩展名的情况
                优先取文件，再取组件
            ###
            package_path = parentModule.config.getPackage( part )
            if package_path
                # 组件
                result.push( package_path )
            else
                # 相对路径
                result.push( parentModule.path.dirname() )
                result.push( part )

        else if i == 0
            ###
                大于1个以上的引用名的情况
            ###
            if parentModule.config.isUseAlias( part )
                # 别名引用路径
                result.push( parentModule.config.parseAlias( part ) )
            else
                # 相对路径
                result.push( parentModule.path.dirname() )
                result.push( part )
        else
            result.push( part )

    return syspath.join.apply( syspath , result )



ModulePath.getContentType = ( extname ) ->
    ModulePath.EXTTABLE[ extname ]?.contentType


ModulePath.addExtensionPlugin = ( extName , plugin ) ->
    ModulePath.EXTLIST.push( extName )
    ModulePath.EXTTABLE[ extName ] = plugin

ModulePath.getPlugin = ( extName, path ) ->
    firstMatch = syspath.join(path, extName)
    return ModulePath.EXTTABLE[ firstMatch ] or ModulePath.EXTTABLE[ extName ]

ModulePath.getContentTypeList = ( extName ) ->
    type = ModulePath.EXTTABLE[ extName ].contentType
    return ( k for k , v of ModulePath.EXTTABLE when v.contentType is type )

ModulePath.findFileWithoutExtname = ( uri ) ->
    return uri if utils.path.exists( uri )
    ext = syspath.extname( uri )
    p = uri.replace( ext , '' )
    list = ModulePath.getContentTypeList( ext )
    for extname in list
        n = p + extname
        return n if utils.path.exists( n )
    return null

ModulePath.getCompile = (cwd, folder) ->
    fekitconfig = syspath.join(cwd, folder, 'fekit.config')
    projectFolder = syspath.join(cwd, folder)
    if fs.existsSync(fekitconfig)
        try
            config = cjson.load(fekitconfig)
        catch err
            utils.logger.error("解析 #{fekitconfig} 时出现错误, 请检查该文件, 该文件必须是标准JSON格式" )
        build = config.build
        if build
            for extName, plugin of build
                buildPath = syspath.join(projectFolder, plugin.path)
                if fs.statSync(buildPath).isDirectory()
                    buildPath = syspath.join(buildPath, 'index')

                buildName = syspath.join(projectFolder, extName)
                ModulePath.addExtensionPlugin(buildName, require(buildPath))

# 后缀列表
ModulePath.EXTLIST = []
ModulePath.EXTTABLE = {}

exports.ModulePath = ModulePath
