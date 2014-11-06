optimist = require "optimist"
sysfs = require "fs"
syspath = require "path"
utils = require "./util"
env = require "./env"

CURR = syspath.dirname( __filename )

each_commands = ( cb ) ->
    cmddir = syspath.join( CURR , "commands" )
    list = sysfs.readdirSync( cmddir )
    list = list.concat env.getExtensions()

    for f in list 
        if typeof f is 'string'
            if f isnt "." or f isnt ".."
                if f.charAt(0) isnt "_"
                    fullpath = syspath.resolve( cmddir , f )
                    continue if utils.path.is_directory( fullpath )
                    command = utils.path.fname( fullpath )
                    cb( command , require(fullpath) )
        else if f.name && f.path
            cb( "#{f.name}(#{f.version})" , require(f.path) )

fixempty = ( str , limit ) ->
    n = limit - str.length
    if n < 0 then n = 0
    return str + ( " " for i in [0..n]).join('')

help_title = () ->

    console.info("")
    console.info("===================== FEKIT #{utils.version} ====================")
    console.info("")

init_options = ( command ) ->

    if command.set_options 
        opt = command.set_options( optimist )
    else 
        opt = optimist

    opt.alias 'h', 'help'
    opt.describe 'h', '查看帮助'

    options = opt.argv

    utils.logger.setup( options )
    cwd = process.cwd()
    options.cwd = cwd

    return options



command_run = ( cmdname , cmd , options ) ->

    cmd.run( options )


command_help = ( cmdname , cmd , options ) ->

    help_title()

    console.info("命令: #{cmdname} ")
    console.info("功能: #{cmd.usage} ")
    console.info("")

    optimist.showHelp()


exports.help = () ->
    
    help_title()
    
    each_commands ( name , cmd ) =>
        console.info(" #{fixempty(name,15)} # #{cmd.usage||''}")
    
    console.info("")
    console.info(" 如果需要帮助, 请使用 fekit {命令名} --help ")
    console.info("")

find_cmd = ( cmd ) ->
    
    lib = syspath.dirname( __filename )
    path = syspath.join( lib , "./commands/#{cmd}.js" )

    return path if utils.path.exists( path )

    list = env.getExtensions()
    for i in list 
        return i.path if i.name == cmd 

    return null


exports.run = ( cmd ) ->

    path = find_cmd( cmd )

    if !path
        utils.logger.error("请确认是否有 #{cmd} 这个命令")
        return 1

    utils.logger.trace( "加载命令 #{path}" )
    
    try
        command = require( path )

        options = init_options( command )

        if options.help
            command_help( cmd , command , options )
        else
            command_run( cmd , command , options )

    catch err
        
        if ~process.argv.indexOf('--debug')
            throw err
        else
        
            if typeof err is 'object'
                err = JSON.stringify( err ) + "\n" + err.toString()
            
            utils.logger.error( err )
            return 1



    



    



