syspath = require 'path'
utils = require "../util"
computecluster = require('compute-cluster');

max = Math.ceil(require('os').cpus().length * 1.25)
max = 5 if max > 5
cc = new computecluster({
  module: utils.path.join( __dirname , '_min_worker.js' )
  max_backlog: -1,
  max_processes: max
})


exports.usage = "压缩/混淆项目文件"


exports.set_options = ( optimist ) ->

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

    optimist.alias 'e' , 'environment'
    optimist.describe 'e' , '设置环境为`local`,`dev`,`beta`或`prd`'


save_versions_mapping = ( mapping_file_path , mapping ) ->

    str = []

    for k , v of mapping
        k = k.replace /\.[^.\/\\]+$/, syspath.extname(v.minpath)
        str.push( k.replace(/\\/g,"/") + '#' + v.ver )

    utils.file.io.write( mapping_file_path , str.join('\n') )



exports.run = ( options ) ->

    utils.logger.log "fekit(#{utils.version}) min"

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

    conf = utils.config.parse( options.cwd )

    conf.each_export_files ( srcpath , parents , opts ) ->
        iter =
            url : srcpath
            path : syspath.join( "src" , opts.partial_path )
        script_global.EXPORT_LIST.push( iter )
        script_global.EXPORT_MAP[ opts.partial_path ] = iter

    conf.doScript "premin" , script_global

    # ------------------

    done = () ->
        if vertype is 0 or vertype is 2
            save_versions_mapping( syspath.join( options.cwd , './ver/versions.mapping' ) , script_global.EXPORT_MAP )
        conf.doRefs( options )
        conf.doScript "postmin" , script_global
        utils.logger.log("DONE.")


    list = conf.get_export_list()
    toRun = list.length
    for i in list
        cl = (i) ->
            cc.enqueue {
                options : options
                file : i
                vertype : vertype
            } , (err, result ) ->
                if err
                    utils.logger.error err
                    cc.exit()
                    utils.exit(1)

                md5code = result[0]
                dest = result[1]

                conf = utils.config.parse( options.cwd )
                o = conf.get_export_info i
                n = o.opts.partial_path
                script_global.EXPORT_MAP[ n ]?.ver = if o.opts.no_version then "" else md5code
                script_global.EXPORT_MAP[ n ]?.minpath = dest.replace( options.cwd , "" )

                if --toRun is 0
                    done()
                    utils.exit(0)

        cl(i)
