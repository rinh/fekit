syspath = require 'path'
less = require 'less'

exports.contentType = "css"

exports.process = ( txt , path , cb ) ->
    dir = syspath.dirname( path )
    parser = new(less.Parser)({
        paths: [ dir ] 
    });

    parser.parse txt , (err, tree) ->
        return cb( err.message ) if err 
        cb( null , tree.toCSS({ compress: false }) )
