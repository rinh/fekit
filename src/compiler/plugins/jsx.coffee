reactTools = require('react-tools')

exports.contentType = "javascript"

exports.process = ( txt , path , module , cb ) ->
    try
        cb( null , reactTools.transform( txt ) )
    catch err
        cb( err )
