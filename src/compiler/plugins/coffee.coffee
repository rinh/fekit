coffee = require 'coffee-script'

exports.contentType = "javascript"

exports.process = ( txt , path ) -> 
    return coffee.compile( txt )