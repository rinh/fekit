compiler = require '../lib/compiler/compiler'
path = require 'path'

m = new compiler.Module( path.join( path.dirname( __filename ) , 'src/scripts/page-a.js' ) )
console.info( m.toString() )

