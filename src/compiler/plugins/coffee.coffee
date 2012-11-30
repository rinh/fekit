coffee = require 'coffee-script'

exports.process = ( txt , path ) -> 
    return coffee.compile( txt )