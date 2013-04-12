Package = require '../../package'
syspath = require 'path'
utils = require '../../util'

### ---------------------------
    模块配置
    该配置是由指定文件的路径向上迭代得到的, 直到遇见fekit.config文件

    {
        //库的配置
        "lib" : {
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
        
    isUseLibrary:(libname) ->
        return !!@config.root.lib[libname]

    # 解析库的真实物理地址
    # libname 如果不是一个库名, 则直接返回. 如果是则解析 
    parseLibrary:(libname) ->
        path = @config.root.lib[libname]
        if !path
            return libname
        else
            return syspath.join( @config.fekit_root_dirname , path )

    getPackage:(libname) ->
        p = new Package( libname , null , @config.fekit_root_dirname )
        return p.get_local_entry()

exports.ModuleConfig = ModuleConfig