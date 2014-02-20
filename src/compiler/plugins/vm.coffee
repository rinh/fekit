Velocity = require 'velocityjs'
path = require 'path'
fs = require 'fs'
_ = require 'underscore'
utils = require '../../util'
cjson = require 'cjson'
EscapeTool = require '../tools/EscapeTool'
MathTool = require '../tools/MathTool'
DateTool = require '../tools/DateTool'
NumberTool = require '../tools/NumberTool'
exports.contentType = "html"

exports.process = ( txt , p ,module , cb) ->
	filePaths = p.replace(/(\\|\/)vm\1/g,'$1data$1').replace('.vm', '.json')
	ps = p.split path.sep
	baseVmPath = ps.slice(0 , _.indexOf( ps , 'vm' ) + 1).join( path.sep )
	fs.exists filePaths , ( exists ) ->
		if not exists
			cb( "#{filePaths} file not exists!" )
			return
		_render = ( data , ctx , macros) ->
			return (new Velocity.Compile(Velocity.Parser.parse( data ))).render( ctx , macros)
		context = cjson.load( filePaths )
		context.esc = EscapeTool
		context.date = DateTool
		context.math = MathTool
		context.number = NumberTool
		macros = {
			load: ( path ) ->
				return @jsmacros.parse.call @ , path
			,
			parse: ( path ) ->
				content = utils.file.io.read( baseVmPath + path )
				return _render content , @context , @macros
			,
			ver: ( path ) ->
				return ''
		}
		cb( null , _render( txt , context , macros) )