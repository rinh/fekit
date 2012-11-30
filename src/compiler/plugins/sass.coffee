sass = require 'sass'

exports.process = ( txt , path ) ->
    return sass.render( txt )