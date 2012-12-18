compiler = require '../../lib/compiler/compiler'
path = require 'path'

compiler.compile path.join( path.dirname( __filename ) , 'src/styles/a.css' ) , (result) ->
    console.info( result ) 

compiler.compile path.join( path.dirname( __filename ) , 'src/scripts/page-a.js' ) , (result) ->
    console.info( result ) 

