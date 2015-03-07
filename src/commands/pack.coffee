compiler = require "../compiler/compiler"
utils = require "../util"
syspath = require "path"

exports.usage = "合并项目文件"

exports.set_options = ( optimist ) ->
    optimist

exports.run = ( options ) ->

    script_global =
        EXPORT_LIST : []
        EXPORT_MAP : {}

    conf = utils.config.parse( options.cwd )

    iter = (srcpath, parents, opts, doneCallback) ->
            utils.logger.log( "正在处理 #{srcpath}" )
            urlconvert = new utils.UrlConvert( srcpath , options.cwd )
            urlconvert.set_no_version() if opts.no_version 
            urlconvert.set_extname_type( compiler.getContentType( srcpath ) )
            dest = urlconvert.to_dev()
            _done = ( err , source ) -> 
                    if err 
                        utils.logger.error( err.toString() )
                        utils.exit(1)
                        return

                    writer = new utils.file.writer()
                    writer.write( dest , source )
                    writer.write( urlconvert.to_ver() , "dev" ) unless opts.no_version 
                    utils.logger.log( "已经处理 #{srcpath}  ==> #{dest}" )
                    doneCallback()

            compiler.compile srcpath , { dependencies_filepath_list : parents , environment : 'dev' } , _done
                
    done = () -> 
            conf.doRefs()
            conf.doScript "postpack" , script_global 
            utils.logger.log("DONE.")

    conf.each_export_files ( srcpath , parents , opts ) ->
        item = 
            url : srcpath 
            path : syspath.join( "src" , opts.partial_path )
            
        script_global.EXPORT_MAP[ opts.partial_path ] = item
        script_global.EXPORT_LIST.push item

    conf.doScript "prepack" , script_global 

    conf.each_export_files_async iter , done
