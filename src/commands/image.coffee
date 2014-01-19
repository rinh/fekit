utils = require "../util"
syspath = require "path"
temp = require "temp"
_ = require "underscore"
SVN = require "node.svn" 

exports.usage = "处理项目图片 fekit image [upload]"

exports.set_options = ( optimist ) ->

    optimist.alias 'd' , 'development'
    optimist.describe 'd' , 'upload 时使用，上传图片至开发机，默认上传选项'

    optimist.alias 'p' , 'production'
    optimist.describe 'p' , 'upload 时使用，上传图片至外网'


exports.run = ( options ) ->

    utils.proc.checkEnvironment [ 'rsync' , 'svn' ] , () ->

        err "请在 fekit 项目中运行该功能" unless utils.path.exists( utils.path.join( options.cwd , 'fekit.config' ) )

        err "项目中必须存在 images 目录才能使用该功能" unless utils.path.exists( utils.path.join( options.cwd , 'images' ) )

        command = options['_'][1]

        switch command
            when 'upload'
                upload_to_dev options if options.development || ( !options.development && !options.production )
                upload_to_prd options if options.production
            when 'check'
                # todo 
            else
                utils.logger.log "请使用 fekit image --help 查看帮助"



# =====================================================================

SVN_ROOT = 'http://svn.corp.qunar.com/svn/sources.qunar.com/trunk'
SVN_ROOT_NAME = "sources.qunar.com"
svn = null

# checkout source根目录
checkout_svn_root = ( cb ) ->
    utils.logger.log "正在创建缓存目录，请稍等..." 
    svn.checkout "--depth empty #{SVN_ROOT} ." , ( error , output ) -> 
             if error then err(error) else cb()


# 按目录更新文件
# 输入的 path 是 
# 1, 循环 update 路径 [ 'abc', 'fff', 'eee' ]，进行 update 操作，直到出错
# 2, 无论上面操作是否出错，都使用 mkdir -p 进行目录创建
update_svn = ( path , cb ) ->

    # 将路径数组修改为 [ 'abc', 'fff', 'eee' ] => [ 'abc', 'abc/fff', 'abc/fff/eee' ]
    _path = []
    n = path.length
    for i in [n..1]
        _path.unshift path.slice(0,i).join('/')

    # update直到出错或完成，进行 mkdirp
    utils.async.series _path 
        , ( uri , done ) ->
            svn.up [ "--set-depth" , "empty" , uri ] , done 
        , ( error ) ->
            utils.file.mkdirp( utils.path.join( svn.root , path.join( utils.path.SEPARATOR ) ) )
            cb && cb()



# 抽取某目录中的所有目录，取其交集
# 返回 [ [ 'abc', 'fff', 'eee' ], [ 'ddd' ] ]
grep_images_path = ( root , cb ) ->
    # 得到所有目录结构（不包括空目录）
    r = []
    utils.path.each_directory root , ( fullpath , path ) -> 
            d = utils.path.dirname path 
            r.push d if d != "."
        , true , root 

    # 合并为hash
    o = {}
    for i in r 
        o[i] = i.split( utils.path.SEPARATOR )

    # 删除重复
    _o = {}
    for key , val of o
        find = false
        for _key , _val of o
            if _key != key and _key.indexOf( key ) == 0
                find = true 
        _o[key] = val unless find 

    # 合并为数组返回
    return ( val for key , val of _o )
    


# 将 images 目录提交到 svn 对应目录
# 其中涉及的问题
# 1. 抽取 images 中的所有目录，取其交集
# 2. 根据交集 创建svn本地缓存目录
upload_to_prd = ( options ) ->

    basedir = utils.path.tmpdir
    dir = utils.path.join basedir , SVN_ROOT_NAME
    svn = new SVN( dir )

    prjname = utils.path.basename( options.cwd )
    images_path = utils.path.join( options.cwd , 'images' + utils.path.SEPARATOR )

    paths = grep_images_path images_path 
    paths = _.map paths , (i) -> return [prjname].concat i 

    checkout_svn_root () ->
        utils.async.series paths 
            , ( path , done ) ->
                update_svn path , () ->
                    done()
            , ( error ) ->
                # 创建 md5 目标文件夹
                create_temp_images_dir options , ( dirpath ) ->

                    # update 并创建完所有目录后，将 images 目录所有文件 cp 过去
                    utils.path.each_directory( dirpath , ( fullpath , partpath ) ->
                            utils.file.copy fullpath ,  utils.path.join( dir , prjname , partpath )
                        , true , dirpath )
 
                        # add && commit 
                        # todo 不敢写...


# =====================================================================


# 将 images 目录 rsync 到开发机
# 1. 创建临时目录
# 2. 输出md5后的所有文件
# 3. rsync到开发机
upload_to_dev = ( options ) ->
    
    prjname = utils.path.basename( options.cwd )
    images_path = utils.path.join( options.cwd , 'images' + utils.path.SEPARATOR )

    create_temp_images_dir options , ( dirpath ) ->

        utils.logger.log "临时文件生成完毕, 准备上传..."

        utils.rsync {
            local : dirpath + utils.path.SEPARATOR
            host : 'source.corp.qunar.com' 
            path : '/home/q/www/source.qunar.com/' + prjname + '/'
        } , ( err ) ->
            if err 
                utils.logger.error err 
            else 
                utils.logger.log "DONE."


# =====================================================================

create_temp_images_dir = ( options , cb ) ->

    prjname = utils.path.basename( options.cwd )
    images_path = utils.path.join( options.cwd , 'images' + utils.path.SEPARATOR )

    temp.mkdir prjname , ( err , dirpath ) ->

        utils.logger.log "处理图片目录 #{images_path}"
        utils.logger.log "生成临时文件在 #{dirpath}"

        utils.path.each_directory images_path , ( filefullpath ) -> 
                newpath = utils.path.join dirpath , convertMD5path( filefullpath ).replace( images_path , '' )
                utils.logger.log "正在复制 #{filefullpath} 至 #{newpath}"
                utils.file.mkdirp utils.path.dirname( newpath )
                utils.shell.cp filefullpath , newpath
            , true

        cb && cb( dirpath )



err = ( msg ) ->
    utils.logger.error msg 
    utils.exit(1)


exports.convertMD5path = convertMD5path = ( path ) ->
    dir = utils.path.dirname( path )
    ext = utils.path.extname( path )
    part = utils.path.basename( path , ext ) 
    md5 = utils.file.md5( path )
    md5 = md5.slice(8,24)   # 取16位md5
    return utils.path.join( dir , part + '_' + md5 + ext )

