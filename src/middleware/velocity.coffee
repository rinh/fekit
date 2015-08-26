fs        = require "fs"
obsolete  = require "./velocity.obsolete"
spawn     = require("child_process").spawn
path      = require "path"
sysurl    = require "url"
urlrouter = require "urlrouter"
utils     = require '../util'
velocity  = require "velocity.java"


contentType =
    'Content-Type': "text/html;charset=UTF-8"


module.exports = (options) ->
    ROOT = options.cwd

    if options["without-java"]
        existsJava = false
    else
        existsJava = true
        projects = fs.readdirSync ROOT
        projects = projects.filter (el) ->
            fs.existsSync(path.join el, "fekit.config")
        roots = projects.map (el) ->
            _get_loader_path(utils.config.parse(path.join(ROOT, el)))
        roots = roots.filter (el) ->
            el isnt null
        roots.push "."

        velocity.startServer {
            root: roots,
            callback: (n) ->
                existsJava = not n
        }

    return urlrouter (app) ->
        app.get /\.(vm|vmhtml)\b/ , (req, res, next) ->
            utils.logger.log "existsJava is", existsJava
            if existsJava is false
                obsolete req, res, next, options
                return res.end()

            url         = sysurl.parse req.url
            p           = path.join ROOT, url.pathname
            vmjs_path   = p.replace '.vm', '.vmjs'
            vmjson_path = p.replace '.vm', '.json'
            conf        = utils.config.parse p

            if utils.path.exists vmjs_path
                delete require.cache[vmjs_path]
                ctx = utils.proc.requireScript vmjs_path, {
                    request  : req ,
                    response : res ,
                    utils    : utils
                }
            else if utils.path.exists vmjson_path
                ctx = utils.file.io.readJSON vmjson_path
            else
                ctx = {}

            root = _get_loader_path conf
            if root
                filename = path.relative root, p
            else
                filename = path.relative ".", p

            velocity.render filename, ctx, (err, data) ->
                if err
                    res.writeHead 500, contentType
                    res.write "<pre>" + err + "</pre>"
                else
                    res.writeHead 200, contentType
                    res.write data

                res.end()


_get_loader_path = (conf) ->
    root = conf?.root?.development?.velocity_root
    if root
        root = utils.path.join conf.fekit_root_dirname, root

        root = utils.path.join root, "../refs/vm" if not fs.existsSync root
        if not fs.existsSync root then return null
        else return root
    else
        return null
