syspath = require 'path'
babel = require 'babel-core'
es2015 = require('babel-preset-es2015')
react = require('babel-preset-react')

exports.contentType = "javascript"

exports.process = (txt, path, module, cb) ->
    try
        name = syspath.basename path, '.jsx'

        txt = (babel.transform txt, {presets: [es2015, react]}).code

        cb null, txt
    catch err
        cb err
