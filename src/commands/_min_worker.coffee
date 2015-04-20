compiler = require "../compiler/compiler"
utils = require "../util"
syspath = require "path"
md5 = require "MD5"
minCode = require("./_min_mincode").minCode
get_dist_filename = require("./_min_mincode").get_dist_filename

pid = process.pid

process.on 'message', (m) ->
        
        options = m.options
        conf = utils.config.parse( options.cwd )
        o = conf.get_export_info m.file
        srcpath = o.path 
        parents = o.parents 
        opts = o.opts
        vertype = m.vertype


        start = new Date()
        utils.logger.log( "<#{pid}> 正在处理 #{srcpath}" )
        urlconvert = new utils.UrlConvert( srcpath , options.cwd )
        urlconvert.set_no_version() if opts.no_version 
        urlconvert.set_extname_type( compiler.getContentType( srcpath ) )
        writer = new utils.file.writer()

        _done = (  err , source ) ->
            if err 
                utils.logger.error( err.toString() )
                return utils.exit(1)
                
            final_code = minCode( urlconvert.replaced_extname , source , options , conf.root )

            if final_code isnt null

                md5code = md5(final_code)
                dest = urlconvert.to_prd( md5code )

                # 生成真正的压缩后的文件
                writer.write( dest , final_code )
                # 生成对应的 ver 文件
                if vertype is 0 or vertype is 1
                    writer.write( urlconvert.to_ver() , if opts.no_version then "" else md5code ) 

                utils.logger.log( "<#{pid}> 已经处理 [#{new Date().getTime()-start.getTime()}ms] #{srcpath}  ==> #{dest}" )

                process.send( [ md5code , dest ] )

            else 

                utils.logger.error( "编译出现错误 #{srcpath}" )
                return utils.exit(1)

        compiler.compile( srcpath , {
            dependencies_filepath_list : parents 
            environment : utils.getCurrentEnvironment(options) or 'prd'
        }, _done )

