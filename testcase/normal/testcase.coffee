compiler = require '../../lib/compiler/compiler'
path = require 'path'

console.info( compiler.compile( path.join( path.dirname( __filename ) , 'src/scripts/page-a.js' ) ) )

