compiler = require 'less'

exports.contentType = "css"

exports.process = ( txt , path , cb ) ->
    compiler.render txt , ( err , css ) =>
        cb( err , css )