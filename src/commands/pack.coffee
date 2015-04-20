compiler = require "../compiler/compiler"
utils = require "../util"
syspath = require "path"
computecluster = require('compute-cluster');
cc = new computecluster({
  module: utils.path.join( __dirname , '_pack_worker.js' )
  max_backlog: -1
});

exports.usage = "合并项目文件"

exports.set_options = ( optimist ) ->
    
    optimist
    
exports.run = ( options ) ->

    script_global =
        EXPORT_LIST : []
        EXPORT_MAP : {}

    conf = utils.config.parse( options.cwd )
                
    done = () -> 
            conf.doRefs( options )
            conf.doScript "postpack" , script_global 
            utils.logger.log("DONE.")

    conf.each_export_files ( srcpath , parents , opts ) ->
        item = 
            url : srcpath 
            path : syspath.join( "src" , opts.partial_path )
            
        script_global.EXPORT_MAP[ opts.partial_path ] = item
        script_global.EXPORT_LIST.push item

    conf.doScript "prepack" , script_global 

    list = conf.get_export_list()
    toRun = list.length
    for i in list 
        cc.enqueue {
            cwd : options.cwd
            file : i 
        } , (err,r) ->
            if err
                utils.logger.error err 
                cc.exit()
                utils.exit(1)
                
            if --toRun is 0 
                done() 
                utils.exit(0)
