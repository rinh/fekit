Velocity = require "velocityjs"
fs = require "fs"
spawn = require("child_process").spawn
syspath = require "path"
sysurl = require "url"
urlrouter = require "urlrouter"
utils = require '../util'
vm = require "vm"


contentType =
    'Content-Type': "text/html;charset=UTF-8"

module.exports = (options) ->

    ROOT = options.cwd

    return urlrouter (app) ->
        app.get /\.(vm|vmhtml)\b/ , ( req , res , next ) ->
            url         = sysurl.parse req.url
            p           = syspath.join ROOT, url.pathname
            vmjs_path   = p.replace '.vm', '.vmjs'
            vmjson_path = p.replace '.vm', '.json'
            jar         = syspath.join __dirname, "../..", "bin/velocity-for-fekit.jar"
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


            ctx["velocity.fekit.loader.path"] = _get_loader_path(conf) || syspath.dirname(p)
            ctx["velocity.fekit.filename"] = syspath.relative ctx["velocity.fekit.loader.path"], p
            console.log ctx["velocity.fekit.loader.path"], ctx["velocity.fekit.filename"]
            ctx = JSON.stringify ctx

            res.writeHead 200, contentType
            java = spawn "java", ["-jar", jar, ctx]
            java.stdout.pipe res
            java.stderr.pipe res


_get_loader_path = (conf) ->
    root = conf?.root?.development?.velocity_root
    if root
        root = utils.path.join conf.fekit_root_dirname, root

        root = utils.path.join root, "../refs/vm" if not fs.existsSync root
        if not fs.existsSync root then return null
        else return root
    else
        return null
