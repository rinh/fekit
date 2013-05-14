Package = require '../../package'
syspath = require 'path'
utils = require '../../util'

### ---------------------------
    模块配置
    该配置是由指定文件的路径向上迭代得到的, 直到遇见fekit.config文件

    {
        //别名的配置
        "alias" : {
            "core" : "./scripts/core"
        }
    }

###
class ModuleConfig
    constructor:(@uri) ->
        @config = utils.config.parse( @uri )

    compileType:() ->
        return @config.root.compiler

    getCompileType: () ->
        return ModuleConfig.MODULE_COMPILE_TYPE.NORMAL if !@config.root.compiler
        return ModuleConfig.MODULE_COMPILE_TYPE.MODULAR if @config.root.compiler is "modular"
        return ModuleConfig.MODULE_COMPILE_TYPE.COMPONENT if @config.root.compiler is "component"
        return ModuleConfig.MODULE_COMPILE_TYPE.UNKNOWN

    isCompileTypeNormal:() ->
        return !@config.root.compiler

    isCompileTypeModular:() ->
        return @config.root.compiler is "modular"

    isCompileTypeComponent:() ->
        return @config.root.compiler is "component"        
        
    isUseAlias:(aliasName) ->
        return !!@config.getAlias(aliasName)

    # 解析别名的真实物理地址
    # aliasName 如果不是一个别名, 则直接返回. 如果是则解析 
    parseAlias:(aliasName) ->
        path = @config.getAlias(aliasName)
        if !path
            return aliasName
        else
            return syspath.join( @config.fekit_root_dirname , path )

    getPackage:(aliasName) ->
        p = new Package( aliasName , null , @config.fekit_root_dirname )
        return p.get_local_entry()


ModuleConfig.MODULE_COMPILE_TYPE = 
    NORMAL : 1
    MODULAR : 2
    COMPONENT : 3 
    UNKNOWN : 4

exports.ModuleConfig = ModuleConfig