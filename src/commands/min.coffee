syspath = require 'path'
compiler = require "../compiler/compiler"
utils = require "../util"
md5 = require "MD5"
uglifycss = require("uglifycss")
ujs = require("uglify-js")

exports.usage = "压缩/混淆项目文件"


exports.set_options = ( optimist ) ->

    optimist.alias 'f' , 'filename'
    optimist.describe 'f' , '指定编译某个文件, 而不是当前目录. 处理后默认将文件放在同名目录下并加后缀 min'

    optimist.alias 'o' , 'output'
    optimist.describe 'o' , '指定单个文件编译的输出位置'

    optimist.alias 'n' , 'nopack'
    optimist.describe 'n' , '不进行压缩处理'

    optimist.alias 'c' , 'noSplitCSS'
    optimist.describe 'c' , '不分割 css 为多行形式，默认分割'

    optimist.alias 'v' , 'onlyVersionFile'
    optimist.describe 'v' , '在 /ver 目录中只生成 version 文件'

    optimist.alias 'm' , 'onlyMappingFile'
    optimist.describe 'm' , '在 /ver 目录中只生成 mapping 文件'


process_directory = ( options ) ->

    utils.file.rmrf syspath.join( options.cwd , './ver/' )
    utils.file.rmrf syspath.join( options.cwd , './prd/' )

    # 0 - 都生成 ， 1 - 只生成 ver ， 2 - 只生成 mapping
    vertype = 0
    if options.onlyMappingFile and options.onlyVersionFile
        vertype = 0
    else if !options.onlyMappingFile and options.onlyVersionFile
        vertype = 1
    else if options.onlyMappingFile and !options.onlyVersionFile
        vertype = 2

    script_global =
        EXPORT_LIST : []
        EXPORT_MAP : {}

    _get_dist_filename = ( srcpath ) ->
        t = compiler.getContentType( srcpath )
        switch t.toLowerCase()
            when "javascript"
                ext = ".js"
            when "css"
                ext = ".css"
        _extname = utils.path.extname( srcpath )
        # _basename = utils.path.basename( srcpath , _extname )
        return srcpath.replace _extname, ext

    conf = utils.config.parse( options.cwd )

    conf.each_export_files ( srcpath , parents , opts ) ->
        iter =
            url : srcpath
            path : syspath.join( "src" , opts.partial_path )
        script_global.EXPORT_LIST.push( iter )
        script_global.EXPORT_MAP[ _get_dist_filename( opts.partial_path ) ] = iter

    conf.doScript "premin" , script_global

    conf.each_export_files_async(
        (srcpath, parents, opts, seriesCallback) ->
            start = new Date()
            utils.logger.log( "正在处理 #{srcpath}" )
            urlconvert = new utils.UrlConvert( srcpath , options.cwd )
            urlconvert.set_no_version() if opts.no_version
            urlconvert.set_extname_type( compiler.getContentType( srcpath ) )
            writer = new utils.file.writer()

            _done = (  err , source ) ->
                if err
                    utils.logger.error( err.toString() )
                    utils.exit(1)
                    return

                final_code = minCode( urlconvert.replaced_extname , source , options , conf.root )

                if final_code isnt null

                    md5code = md5(final_code)
                    dest = urlconvert.to_prd( md5code )

                    # 生成真正的压缩后的文件
                    writer.write( dest , final_code )
                    # 生成对应的 ver 文件
                    if vertype is 0 or vertype is 1
                        writer.write( urlconvert.to_ver() , if opts.no_version then "" else md5code )

                    n = _get_dist_filename( opts.partial_path )
                    script_global.EXPORT_MAP[ n ]?.ver = if opts.no_version then "" else md5code
                    script_global.EXPORT_MAP[ n ]?.minpath = dest.replace( options.cwd , "" )

                    utils.logger.log( "已经处理 [#{new Date().getTime()-start.getTime()}ms] #{srcpath}  ==> #{dest}" )

                else

                    utils.logger.error( "编译出现错误 #{srcpath}" )

                seriesCallback()

            compiler.compile( srcpath , {
                dependencies_filepath_list : parents
                environment : 'prd'
            }, _done )


        () ->
            if vertype is 0 or vertype is 2
                save_versions_mapping( syspath.join( options.cwd , './ver/versions.mapping' ) , script_global.EXPORT_MAP )
            conf.doRefs()
            conf.doScript "postmin" , script_global
            utils.logger.log("DONE.")
    )

save_versions_mapping = ( mapping_file_path , mapping ) ->

    str = []

    for k , v of mapping
        str.push( k.replace(/\\/g,"/") + '#' + v.ver )

    utils.file.io.write( mapping_file_path , str.join('\n') )


process_single_file = ( options ) ->

    if utils.path.is_absolute_path( options.filename )
        srcpath = options.filename
    else
        srcpath = syspath.join( options.cwd , options.filename )

    # 指定位置保存
    extname = syspath.extname( srcpath )
    switch compiler.getContentType( srcpath )
        when "javascript"
            replaced_extname = ".js"
        when "css"
            replaced_extname = ".css"

    fname = syspath.basename( srcpath )

    if options.output
        if utils.path.exists( options.output ) and utils.path.is_directory( options.output )
            dest = utils.path.join( options.output , fname.replace( extname , ".min" + replaced_extname ) )
        else
            dest = options.output
    else
        dest = srcpath.replace( extname , ".min" + replaced_extname )


    compiler.compile srcpath , { environment : 'prd' } , ( err , source ) ->

        return utils.logger.error(err) if err

        final_code = minCode( replaced_extname , source , options )

        if final_code isnt null

            new utils.file.writer().write( dest , final_code )

            utils.logger.log( "已经处理  #{srcpath}  ==> #{dest}" )

        else

            utils.logger.error( "编译出现错误 #{srcpath}" )

        utils.logger.log("DONE.")


exports.minCode = minCode = ( extname , source , options = {} , fekitconfig = {} ) ->

    if options.nopack then return source

    switch extname
        when ".css"
            if options.noSplitCSS
                final_code = uglifycss.processString( source , fekitconfig?.min?.config?.uglifycss )
            else
                final_code = uglifycss.processString( source , fekitconfig?.min?.config?.uglifycss ).replace( /}/g , "}\n" )
        when ".js"
            #try
                toplevel = ujs.parse( source )
                toplevel.figure_out_scope()

                CompressorOptions = fekitconfig?.min?.config?.uglifyjs?.compressor or {
                    drop_console : true
                    drop_debugger : true
                    warnings : false
                }
                compressor = ujs.Compressor( CompressorOptions )
                compressed_ast = toplevel.transform(compressor)
                compressed_ast.figure_out_scope()
                compressed_ast.compute_char_frequency()
                compressed_ast.mangle_names()

                BeautifierOptions = fekitconfig?.min?.config?.uglifyjs?.beautifier or {}

                stream = ujs.OutputStream(BeautifierOptions)
                compressed_ast.print(stream);

                final_code = stream.toString()
            #catch err
            #    console.info( err )
            #    return null

    return final_code


exports.run = ( options ) ->

    utils.logger.log "fekit(#{utils.version}) min"

    if options.filename
        process_single_file( options )
    else
        process_directory( options )
