optimist = require "optimist"
sysfs = require "fs"
syspath = require "path"
utils = require "./util"

CURR = syspath.dirname( __filename )

each_commands = ( cb ) ->
    cmddir = syspath.join( CURR , "commands" )
    list = sysfs.readdirSync( cmddir )
    for f in list 
        if f isnt "." or f isnt ".."
            cb( f.replace(".js","") , require( syspath.join( cmddir , f ) ) )

fixempty = ( str , limit ) ->
    n = limit - str.length
    if n < 0 then n = 0
    return str + ( " " for i in [0..n]).join('')

help_title = () ->

    version = new utils.file.reader().readJSON( syspath.join( CURR , "../package.json" ) ).version

    console.info("")
    console.info("===================== FEKIT #{version} ====================")
    console.info("")

init_options = ( command ) ->

    command.set_options && command.set_options( optimist )

    optimist.alias 'h', 'help'
    optimist.describe 'h', '查看帮助'

    options = optimist.argv

    utils.logger.setup( options )
    cwd = process.cwd()
    options.cwd = cwd

    return options



command_run = ( cmd , options ) ->

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

exports.run = ( cmd ) ->

    lib = syspath.dirname( __filename )
    path = syspath.join( lib , "./commands/#{cmd}.js" )

    if !utils.path.exists( path ) 
        utils.logger.error("请确认是否有 #{cmd} 这个命令")
        return 1

    utils.logger.info( "加载命令 #{path}" )
    
    try
        command = require( path )

        options = init_options( command )

        if options.help
            command_help( cmd , command , options )
        else
            command_run( command , options )

    catch err
        if utils.logger.debug is true
            throw err 
        else
            utils.logger.error( err )
            return 1



    



    



