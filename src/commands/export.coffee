syspath = require 'path'
sysutil = require 'util'
utils = require '../util'

exports.usage = """文件首行添加 '/* [export] */' 或 '/* [export no_version] */'
\t\t\t将被自动添加 fekit.config 'export' 列表中"""
config_object = {}

do_clean = (dir) ->
    nu = []
    exists = (path) ->
        path = path.path if path.path?
        return utils.path.exists (utils.path.join dir, path)

    if sysutil.isArray config_object.export
        nu.push i for i in config_object.export when exists i
    config_object.export = nu

start_export = (dir) ->
    utils.path.each_directory dir, (file) ->
        if utils.path.is_directory file
            start_export file, dir
            return null

        ext = syspath.extname file
        if ext in ['.js', '.css', '.scss'] then do_export file, dir
    ,true

do_export = (file, dir) ->
    reader = new utils.file.reader()
    content = reader.read file
    file = syspath.relative dir, file
    lines = content.split "\n"

    line = lines[0] or ""
    line = line.trim()
    re = /^\/\*\s*\[export(?: (no_version))?\]\s*\*\/$/
    result = line.match re

    file = file.replace /\\/g, '/' if syspath.sep is '\\'
    if result?
        index = config_object.export.indexOf file
        if index < 0
            index = null
            index = i for i, j of config_object.export when j.path is file

        item =
            path: file
            no_version: result[1] is 'no_version'

        if index?
            if config_object.export[index]['path']?
                config_object.export[index]['no_version'] = item.no_version
            else
                config_object.export[index] = item
        else
            config_object.export.push item


exports.run = (options) ->
    base = options.cwd
    dir = options._[1] or 'src'
    dir = utils.path.join base, dir

    config_file = utils.path.join base, 'fekit.config'
    reader = new utils.file.reader()

    try
        config_object = reader.readJSON config_file
    catch err
        return utils.logger.error err

    do_clean dir
    start_export dir

    str = JSON.stringify config_object, null, 4
    writer = new utils.file.writer()
    writer.write config_file, str
    utils.logger.log "'fekit.config' 写入完成"
