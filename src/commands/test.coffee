utils = require '../util'
{spawn} = require 'child_process'

exports.usage = "进行单元测试"

exports.set_options = ( optimist ) ->
    optimist

exports.run = ( options ) ->
    
    p = utils.path.join( __dirname , '../../node_modules/.bin/mocha' )

    c = spawn 'node' , [ p , '--colors', '--recursive', '--compilers', 'coffee:coffee-script' ] , {
        cwd : options.cwd , 
        env : process.env
    }

    c.stderr.pipe process.stderr, end: false 
    c.stdout.pipe process.stdout, end: false 