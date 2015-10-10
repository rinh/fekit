compiler = require "../compiler/compiler"
utils = require "../util"
syspath = require "path"

pid = process.pid

process.on 'message', (m) ->

        conf = utils.config.parse( m.cwd )
        o = conf.get_export_info m.file
        srcpath = o.path
        parents = o.parents
        opts = o.opts
        dispath = syspath.relative process.cwd(), srcpath

        utils.logger.log( "<#{pid}> 正在处理 #{dispath}" )
        urlconvert = new utils.UrlConvert( srcpath , m.cwd )
        urlconvert.set_no_version() if opts.no_version
        urlconvert.set_extname_type( compiler.getContentType( srcpath ) )
        dest = urlconvert.to_dev()
        disdest = syspath.relative process.cwd(), dest
        _done = ( err , source ) ->
                if err
                    utils.logger.error( err.toString() )
                    utils.exit(1)
                    return

                writer = new utils.file.writer()
                writer.write( dest , source )
                writer.write( urlconvert.to_ver() , "dev" ) unless opts.no_version
                utils.logger.log( "<#{pid}> 已经处理 #{dispath} ==> #{disdest}" )

                process.send('ok')

        compiler.compile srcpath , { dependencies_filepath_list : parents , environment : 'dev' } , _done

