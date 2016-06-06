coffee = require 'coffee-script'

exports.contentType = "javascript"

exports.process = ( txt , path , module , cb ) ->
    try
        cb( null , coffee.compile( txt ) )
    catch err
        cb( err )