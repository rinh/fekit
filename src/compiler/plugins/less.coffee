css = require './css'
syspath = require 'path'
less = require 'qless'

exports.contentType = "css"

exports.process = ( txt , path ,module , cb ) ->
    dir = syspath.dirname( path )
    parser = new(less.Parser)({
        paths: [ dir ] 
    });

    parser.parse txt , (err, tree) ->
        return cb( err.message ) if err 
        code = tree.toCSS({ compress: false })
        cb( null , css.ddns( code , module ) )
