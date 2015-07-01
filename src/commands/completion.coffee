env   = require "../env"
fs    = require "graceful-fs"
path  = require "path"
utils = require '../util'


exports.usage = "TAB 自动补全"


optimist =
    keys: []
    aliases: []
    alias: (k, a) ->
        @keys.push "-#{k}"
        @aliases.push "--#{a}"
    describe: () ->

fullList = fs.readdirSync __dirname
fullList = fullList.concat env.getExtensions()
fullList = fullList.map (f) ->
    return utils.path.fname f if typeof f is "string"
    return f.name
fullList = fullList.filter (f) ->
    return not /^_/.test f

dumpScript = () ->
    p = path.resolve __dirname, "../completion.sh"
    fs.readFile p, "utf8", (er, d) ->
        if er
            utils.logger.error er
            return null

        d = d.replace /^#!.*?\n/, ""
        console.log d


exports.run = (options) ->
    if process.platform is "win32"
        return utils.logger.error "fekit completion 不支持 windows"

    if undefined in [process.env.COMP_CWORD, process.env.COMP_LINE, process.env.COMP_POINT]
        return dumpScript()

    console.error process.env.COMP_CWORD
    console.error process.env.COMP_LINE
    console.error process.env.COMP_POINT

    args         = options._.slice 1
    w            = +process.env.COMP_CWORD
    words        = args
    word         = words[w]
    line         = process.env.COMP_LINE
    point        = +process.env.COMP_POINT
    partialLine  = line.substr 0, point
    partialWords = words.slice 0, w

    partialWord = args[w]
    i = partialWord.length
    i -= 1 while partialWord.substr(0, i) isnt partialLine.substr(-1 * i) and i > 0
    partialWord = partialWord.substr 0, i
    partialWords.push partialWord

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

    if partialWords.length is 2
        result = fullList.filter (c) ->
            return c.indexOf(opts.partialWord) is 0
        return console.log result.join "\n"

    if partialWords.length > 2
        try
            command = opts.partialWords[1]
            command = require "./#{command}"
            command.set_options optimist
            optimist.alias 'h', 'help'

            if /^--/.test opts.partialWord then result = optimist.aliases
            else result = optimist.keys
            result = result.filter (c) ->
                return c.indexOf(opts.partialWord) is 0
            console.log result.join "\n"
        catch e
            console.error e
