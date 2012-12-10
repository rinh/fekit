sass = require 'sass'

exports.contentType = "css"

exports.process = ( txt , path ) ->
    return sass.render( txt )