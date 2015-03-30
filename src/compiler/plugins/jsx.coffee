##parse jsx file to js file
react = require "react-tools"

exports.contentType = "javascript"

exports.process = ( txt , path , module , cb ) ->
	try
		code = react.transform( txt );
		cb null, code
	catch err
		cb err