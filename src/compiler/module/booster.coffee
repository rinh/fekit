utils = require '../../util'
md5 = require 'MD5'

CHECKSUM_CACHED = {}


cached = (filename) ->
    try
        CHECKSUM_CACHED[filename] = md5( utils.file.io.read( filename ) )
    catch err
        
###
    加速方案
    * 将指定目录 opts.cwd 的文件按路径缓存 checksum , 在 module 初始化的时候使用该缓存
###
exports.init = ( options ) ->
    
    utils.file.watch options.cwd , ( filename ) ->
                cached(filename)

exports.get_checksum_cache = ( filename ) ->
    return CHECKSUM_CACHED[filename]


# 初始化缓存
exports.init_cached = ( filename ) ->
    return if CHECKSUM_CACHED[ filename ]
    cached( filename )