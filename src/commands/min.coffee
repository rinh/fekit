syspath = require 'path'
compiler = require "../compiler/compiler"
utils = require "../util"
md5 = require "MD5"
uglifycss = require("uglifycss")
jsp = require("uglify-js").parser;
pro = require("uglify-js").uglify;

exports.usage = "压缩/混淆项目文件"


exports.set_options = ( optimist ) ->

    optimist.alias 'f' , 'filename'
    optimist.describe 'f' , '指定编译某个文件, 而不是当前目录. 处理后默认将文件放在同名目录下并加后缀 min'
    

process_directory = ( options ) ->
    
    script_global =
        EXPORT_LIST : []
        EXPORT_MAP : {}

    conf = utils.config.parse( options.cwd )

    conf.each_export_files ( srcpath , parents , opts ) ->
        iter = 
            url : srcpath 
            path : syspath.join( "src" , opts.partial_path )
        script_global.EXPORT_LIST.push( iter )
        script_global.EXPORT_MAP[ opts.partial_path ] = iter

    conf.doScript "premin" , script_global 

    conf.each_export_files_async(
        (srcpath, parents, opts, seriesCallback) ->
            utils.logger.log( "正在处理 #{srcpath}" )
            urlconvert = new utils.UrlConvert( srcpath , options.cwd )
            urlconvert.set_no_version() if opts.no_version 
            writer = new utils.file.writer()

            _done = (  err , source ) ->
                if err 
                    utils.logger.error( err.toString() )
                    utils.exit(1)
                    return

                switch urlconvert.extname
                    when ".css"
                        final_code = uglifycss.processString(source).replace( /}/g , "}\n" )
                    when ".js"
                        ast = jsp.parse(source)
                        ast = pro.ast_mangle(ast)
                        #ast = pro.ast_squeeze(ast)
                        final_code = pro.gen_code( ast )

                md5code = md5(final_code)
                dest = urlconvert.to_prd( md5code )

                # 生成真正的压缩后的文件
                writer.write( dest , final_code )
                # 生成对应的 ver 文件
                writer.write( urlconvert.to_ver() , md5code ) 

                script_global.EXPORT_MAP[ opts.partial_path ]?.ver = md5code
                script_global.EXPORT_MAP[ opts.partial_path ]?.minpath = dest.replace( options.cwd , "" )

                utils.logger.log( "已经处理 #{srcpath}  ==> #{dest}" )
                seriesCallback()

            compiler.compile( srcpath , {
                dependencies_filepath_list : parents 
            }, _done )
 

        () ->
            conf.doScript "postmin" , script_global 
            utils.logger.log("DONE.")
    )


process_single_file = ( options ) ->

    if utils.path.is_absolute_path( options.filename ) 
        srcpath = options.filename
    else
        srcpath = syspath.join( options.cwd , options.filename )

    compiler.compile srcpath , ( source ) ->

        extname = syspath.extname( srcpath )

        switch extname
            when ".css"
                final_code = uglifycss.processString(source)
            when ".js"
                ast = jsp.parse(source)
                ast = pro.ast_mangle(ast)
                #ast = pro.ast_squeeze(ast)
                final_code = pro.gen_code( ast )

        dest = srcpath.replace( extname , ".min" + extname )

        new utils.file.writer().write( dest , final_code )

        utils.logger.log( "已经处理 #{srcpath}  ==> #{dest}" )

        utils.logger.log("DONE.")


exports.run = ( options ) ->
    
    if options.filename 
        process_single_file( options )
    else
        process_directory( options )
