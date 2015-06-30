env   = require "../env"
fs    = require "graceful-fs"
path  = require "path"
utils = require '../util'


exports.usage = "TAB 自动补全"


dumpScript = () ->
    p = path.resolve __dirname, "../completion.sh"
    fs.readFile p, "utf8", (er, d) ->
        if er
            utils.logger.error er
            return null

        d = d.replace /^#!.*?\n/, ""
        console.log d

fullList = () ->
    list = fs.readdirSync __dirname
    list = list.concat env.getExtensions()
    list = list.map (f) ->
        return utils.path.fname f if typeof f is "string"
        return f.name
    list = list.filter (f) ->
        return not /^_/.test f


exports.run = (options) ->
    if process.platform is "win32"
        utils.logger.error "fekit completion 不支持 windows"
        return null

    # if the COMP_* isn't in the env, then just dump the script.
    if undefined in [process.env.COMP_CWORD, process.env.COMP_LINE, process.env.COMP_POINT]
        return dumpScript()

    console.error process.env.COMP_CWORD
    console.error process.env.COMP_LINE
    console.error process.env.COMP_POINT

    args         = options._.slice 1
    w            = +process.env.COMP_CWORD
    words        = args.map unescape
    word         = words[w]
    line         = process.env.COMP_LINE
    point        = +process.env.COMP_POINT
    partialLine  = line.substr 0, point
    partialWords = words.slice 0, w

    partialWord = args[w]
    i = partialWord.length
    i -= 1 while partialWord.substr(0, i) isnt partialLine.substr(-1 * i) and i > 0

    opts =
        words        : words
        w            : w
        word         : word
        line         : line
        lineLength   : line.length
        point        : point
        partialLine  : partialLine
        partialWords : partialWords
        partialWord  : partialWord
        raw          : args

    console.error opts

    console.error fullList()
    console.log "a"
    console.log "b"
