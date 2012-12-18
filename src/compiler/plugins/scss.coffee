sass = require 'node-sass'

exports.contentType = "css"

exports.process = ( txt , path , cb ) ->
    sass.render txt , ( err , css ) =>
        cb( err , css )