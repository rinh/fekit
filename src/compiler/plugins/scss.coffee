css = require './css'
syspath = require 'path'
sass = require 'node-sass'

exports.contentType = "css"

exports.process = ( txt , path ,module , cb ) ->
	dir = syspath.dirname( path )

	succ = (code) ->
		cb( null , css.ddns( code , module ) )

	fail = (err) ->
		return cb( err )
 

	sass.render({
		data:txt, 
		includePaths:[dir],
		success: succ,
		error: fail
	})
