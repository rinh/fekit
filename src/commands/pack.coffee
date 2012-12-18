compiler = require "../compiler/compiler"
utils = require "../util"

exports.usage = "合并项目文件"


exports.run = ( options ) ->

    conf = utils.config.parse( options.cwd )

    iter = (srcpath, parents, doneCallback) ->
            utils.logger.log( "正在处理 #{srcpath}" )
            urlconvert = new utils.UrlConvert( srcpath )
            dest = urlconvert.to_dev()
            _done = ( err , source ) -> 
                    if err 
                        utils.logger.error( err.toString() )
                        utils.exit(1)
                        return

                    new utils.file.writer().write( dest , source )
                    utils.logger.log( "已经处理 #{srcpath}  ==> #{dest}" )
                    doneCallback()

            compiler.compile srcpath , { dependencies_filepath_list : parents } , _done
                
    done = () -> 
            utils.logger.log("DONE.")

    conf.each_export_files_async iter , done
