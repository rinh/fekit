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

    isCompileTypeNormal:() ->
        return !@config.root.compiler

    isCompileTypeModular:() ->
        return @config.root.compiler is "modular"
        
    isUseAlias:(aliasName) ->
        return !!@config.root.alias[aliasName]

    # 解析别名的真实物理地址
    # aliasName 如果不是一个别名, 则直接返回. 如果是则解析 
    parseAlias:(aliasName) ->
        path = @config.root.alias[aliasName]
        if !path
            return aliasName
        else
            return syspath.join( @config.fekit_root_dirname , path )

    getPackage:(aliasName) ->
        p = new Package( aliasName , null , @config.fekit_root_dirname )
        return p.get_local_entry()

exports.ModuleConfig = ModuleConfig