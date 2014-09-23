syspath = require 'path'
sysfs = require 'fs'
utils = require '../util'

exports.usage = "自动化生成fekit.config"

CONFIG = null

load_config = () ->
    content = new utils.file.reader().read( "fekit.config" )
    CONFIG = JSON.parse(content);

do_clean = (dir) ->
    new_export = []
    new_export.push(path) for path in CONFIG.export when utils.path.exists("#{dir}/#{path}")
    new_export.push(path) for path in CONFIG.export when utils.path.exists("#{dir}/#{path.path}")
    CONFIG.export = new_export

start_export = (dir) ->
    utils.path.each_directory dir, (file) ->
            if utils.path.is_directory(file) 
                start_export(file, dir)
                return
            if ~file.indexOf(".js") or ~file.indexOf(".css") then do_export(file)
        ,true


do_export = (file, dir) ->
    content = new utils.file.reader().read( file )
    lines = content.split("\n")
    file = file.replace(/\\/g, "/")
    file = file.replace("#{dir}/", "")

    if lines[0] is "/*[export]*/"    
        exist = true for path in CONFIG.export when path is file
        if not exist
            CONFIG.export.push(file)

    if lines[0] is "/*[export noversion]*/"
        exist = true for path in CONFIG.export when path.path is file
        if not exist
            CONFIG.export.push({path: file, no_version: true})


exports.run = ( options ) ->
    if options.dir
        load_config()
        do_clean(options.dir)
        start_export(options.dir)
        str = JSON.stringify( CONFIG , null , 4 )
        new utils.file.writer().write( "fekit.config" , str )
    else
        utils.logger.error( "必须使用 --dir 来指定要扫描的文件目录" )
