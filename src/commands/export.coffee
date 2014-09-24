syspath = require 'path'
sysfs = require 'fs'
utils = require '../util'

exports.usage = "自动化生成 fekit.config 'export' 列表"
config_object = {}


do_clean = (dir) ->
    nu = []
    exists = (path) ->
        path = path.path if path.path?
        return utils.path.exists (utils.path.join dir, path)

    nu.push i for i in config_object.export when exists i
    config_object.export = nu

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


exports.run = (options) ->
    base = options.cwd
    dir = options._[1] || 'src'
    dir = utils.path.join base, dir

    config_file = utils.path.join base, 'fekit.config'
    reader = new utils.file.reader()

    try
        config_object = reader.readJSON config_file
    catch err
        return utils.logger.error err

    do_clean dir
        # start_export(options.dir)
    str = JSON.stringify config_object, null, 4
    writer = new utils.file.writer()
    writer.write config_file, str
