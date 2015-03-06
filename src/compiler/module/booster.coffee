utils = require '../../util'
md5 = require 'MD5'
fs = require 'fs'

MODULES = {}
COMPILED_CACHED = {}
COMPILED_CACHED_DEPEND = {}


# 监控模块所对应的文件 
# 如果文件发生变化则触发 change
watch = exports.watch = ( module ) ->

    filepath = module.path.uri

    key = module.path.uri + "__" + module.root_module.path.uri 

    return if MODULES[key]
    MODULES[ key ] = module

    module.cleanCache = () ->
        utils.logger.trace "缓存失效 #{@.path.uri}"
        delete COMPILED_CACHED[@.path.uri]
        delete COMPILED_CACHED_DEPEND[@.path.uri]
        if @parent then @parent.cleanCache()

    fs.watchFile filepath , () ->
        module.emit 'change'

    module.on 'change' , () ->
        @cleanCache()

    for m in module.depends
        watch( m )


exports.get_compiled_cache = ( filename , is_deps ) ->
    utils.logger.trace "获取缓存 #{filename}"
    if is_deps
        return COMPILED_CACHED_DEPEND[filename]
    else
        return COMPILED_CACHED[filename]


exports.set_compiled_cache = ( filename , source , is_deps ) ->
    utils.logger.trace "增加缓存 #{filename}"
    if is_deps
        COMPILED_CACHED_DEPEND[filename] = source
    else 
        COMPILED_CACHED[filename] = source
