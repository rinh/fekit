utils = require '../util'


exports.usage = "TAB 自动补全"


dumpScript = () ->
    fs = require "graceful-fs"
    path = require "path"
    p = path.resolve __dirname, "../completion.sh"

    fs.readFile p, "utf8", (er, d) ->
        if er
            utils.logger.error er
            return null

        d = d.replace /^#!.*?\n/, ""
        console.log d

exports.run = (options) ->
    if process.platform is "win32"
        utils.logger.error "fekit completion 不支持 windows"
        return null

    # if the COMP_* isn't in the env, then just dump the script.
    if undefined in [process.env.COMP_CWORD, process.env.COMP_LINE, process.env.COMP_POINT]
        return dumpScript()

    console.error(process.env.COMP_CWORD)
    console.error(process.env.COMP_LINE)
    console.error(process.env.COMP_POINT)
