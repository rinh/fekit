utils = require '../../util'
md5 = require 'MD5'
watchr = require 'watchr'

directories = []

CHECKSUM_CACHED = exports.CHECKSUM_CACHED = {}
COMPILED_CACHED = exports.COMPILED_CACHED = {}

cached = (filename) ->
    try
        CHECKSUM_CACHED[filename] = md5( utils.file.io.read( filename ) )
    catch err
        
###
    加速方案
    * 将指定目录 opts.directories 的文件按路径缓存 checksum , 在 module 初始化的时候使用该缓存
    * 
###
exports.init = ( options ) ->
    
    for dir in options.directories 
        _dir = utils.path.resolve( options.cwd , dir )
        directories.push( _dir )
        if utils.path.exists(_dir) and utils.path.is_directory(_dir)
            utils.logger.log "已对 #{_dir} 进行加速"
            watchr.watch
                paths: [ _dir ] , 
                listeners:
                    change: ( evt , filepath , fstat , fprevstat ) ->
                        # 当修改文件内容时，对 checksum 缓存
                        cached(filepath)
                        # 当修改文件内容时，清除编译缓存
                        delete COMPILED_CACHED[filepath]
                        # 为了 server 里使用的缓存数据
                        delete COMPILED_CACHED[filepath+"_deps"]

exports.get_checksum_cache = ( filename ) ->
    return CHECKSUM_CACHED[filename]


exports.get_compiled_cache = ( filename ) ->
    return COMPILED_CACHED[filename]

exports.set_compiled_cache = ( filename , source ) ->
    for dir in directories 
        if ~dir.indexOf( dir )
            COMPILED_CACHED[filename] = source

# 初始化缓存
exports.init_cached = ( filename ) ->
    return if CHECKSUM_CACHED[ filename ]
    cached( filename )