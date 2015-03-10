utils = require '../util'
{spawn} = require 'child_process'

exports.usage = "进行单元测试"

exports.set_options = ( optimist ) ->
    optimist

exports.run = ( options ) ->

    errmsg = ''

    c = spawn utils.proc.npmbin("mocha") , [ '--colors', '--recursive', '--compilers', 'coffee:coffee-script' ] ,
        cwd : options.cwd , 
        env : process.env

    c.stderr.on 'data' , ( data ) ->
        errmsg += data

    c.stderr.on 'close' , ( err ) ->
        utils.logger.error "请建立`test`目录，并放置测试用例" if errmsg
        utils.logger.error errmsg if options.debug

    #c.stderr.pipe process.stderr, end: false 
    c.stdout.pipe process.stdout, end: false 