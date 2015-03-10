css = require './css'
syspath = require 'path'
stylus = require 'stylus'
nib = require 'nib'

exports.contentType = 'css'

exports.process = (txt, path, module, cb)->
    dir = syspath.dirname path
    succ = (code)->
        cb null, (css.ddns code, module)

    fail = (err)->
        cb err

    stylus.render txt,
        filename: path
        paths: [dir]
        use: nib()
        (err, css)->
            if err
                fail err
            else
                succ css

