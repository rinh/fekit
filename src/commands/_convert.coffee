##### 该功能已废弃

syspath = require 'path'
sysfs = require 'fs'
utils = require '../util'
spawn = require('child_process').spawn

exports.usage = "转换 [qzz项目] 为 [fekit项目] "

exports.set_options = ( optimist ) ->
    optimist.alias 'q' , 'qzz'
    optimist.describe 'q' , '转换qzz项目'

    optimist.alias 'a' , 'app'
    optimist.describe 'a' , '转换app项目'
    

CURR = null
CONFIG =
        "compiler" : false 
        "alias" : {} 
        "export" : []

FILE = ( name ) ->
    return syspath.join( CURR , name )

# 检查当前目录是否可以转换
check = () ->
    if !utils.path.exists( FILE(".ver") ) then return false
    if utils.path.exists( FILE("fekit.config") ) then return false
    return true
    

###
1. 处理 srclist
            a. 文件名变为普通
            b. 修改引用方式 document.write 变为 require , js/css的
###
process_srclist = () ->
    add_list = []
    remove_list = []
    utils.path.each_directory CURR , ( file ) ->
            if ~file.indexOf('-srclist.') and !~file.indexOf(".svn")
                utils.logger.log("正在处理 #{file}")
                add_list.push( _replaceSrclist( file ) )
                remove_list.push( file )
        , true

    add = spawn 'svn' , [ 'add' ].concat( add_list )
    add.on 'exit' , (code) =>
        spawn 'svn' , [ 'rm' ].concat( remove_list )
    

JS_REG = /!!document\.write.*src=['"]([^'"]*)['"].*/g
CSS_REG = /@import\s+url\s*\(\s*['"]?([^'"\)]*)['"]?\s*\)/g

_replaceSrclist = ( filepath ) ->
    url = new utils.UrlConvert( filepath , CURR )
    dest = url.to_src().replace('-srclist','')

    # 修改引用 
    content = new utils.file.reader().read( filepath )
    content = content.replace JS_REG , ($0,$1) =>
                    return "require('./#{$1}');"
    content = content.replace CSS_REG , ($0,$1) =>
                    return "require('./#{$1}');"
    new utils.file.writer().write( dest , content )

    # 添加config
    if ~dest.indexOf('/src/')
        part = dest.split('/src/')[1]
    else if ~dest.indexOf('\\src\\')
        part = dest.split('\\src\\')[1]
    CONFIG.export.push( part.replace( /\\/g , '/' ) )

    return dest


###
    2. 处理 .ver 删除
###
process_ver = () ->
    spawn 'svn' , [ 'remove' , "#{FILE('.ver')}" ]


###
    3. 处理 build.sh 修改
###
process_build = () ->


###
    4. 生成 fekit.config
###
process_config = () ->
    str = JSON.stringify( CONFIG , null , 4 )
    new utils.file.writer().write( FILE("fekit.config") , str )


#---------------------

###
    转换app
###
LINK_CSS_REG = /http:\/\/qunarzz.com\/(.*?)\/prd\/(.*?)-(.*?)\.css/ig
LINK_JS_REG = /http:\/\/qunarzz.com\/(.*?)\/prd\/(.*?)-(.*?)\.js/ig

get_config = () ->
    return new utils.file.reader().readJSON( FILE("_convert.json") )

_each_files = ( cb ) ->
    config = get_config()
    utils.path.each_directory CURR , ( file ) ->
            if ~file.indexOf(".svn") then return
            if utils.path.is_directory(file) then return
            ext = syspath.extname( file )
            if  !config.filter.length or ( config.filter.length and ~config.filter.indexOf(ext) )  
                if cb( file , config )
                    utils.logger.log("已处理 #{file}")
        , true

_get_verpath = ( config , path , type , filepath ) ->
    ext = syspath.extname( filepath )
    ver = syspath.join( config.ver_path , path + ".#{type}.ver" )
    if config.include_version_type[ext]
        return config.include_version_type[ext].replace("#ver#",ver)
    else
        throw "没有正确的 include_version_type 配置节点 , 当前处理文件是 #{filepath}"

_replaceCSS = ( filepath , config ) ->
    # 修改引用 
    content = new utils.file.reader().read( filepath )
    m = content.match( LINK_CSS_REG )
    if !m or !m.length then return false
    content = content.replace LINK_CSS_REG , (match, project_name, path, ver ) =>
                    

                    return "http://qunarzz.com/#{project_name}/prd/#{path}@#{_get_verpath(config,path,"css",filepath)}.css"
    new utils.file.writer().write( filepath , content )
    return true


_replaceJS = ( filepath , config ) ->
    # 修改引用 
    content = new utils.file.reader().read( filepath )
    m = content.match( LINK_JS_REG )
    if !m or !m.length then return false
    content = content.replace LINK_JS_REG , (match, project_name, path, ver ) =>
                    return "http://qunarzz.com/#{project_name}/prd/#{path}@#{_get_verpath(config,path,"js",filepath)}.js"
    new utils.file.writer().write( filepath , content )
    return true

check_config = () ->
    utils.path.exists( FILE("_convert.json") )

show_config = () ->
    str = """
    请按以下格式在项目根目录下建立 _convert.json 文件 , 此配置只符合一般项目使用 , 如果项目中的引用方式不一致 , 需要自行修改

    {
        // ver目录的路径, 这个路径会影响include version文件
        "ver_path" : "/ver/" ,   
        // 搜索文件类型, 如果不指定则默认搜索所有文件
        "filter" : [ ".jsp" , ".htm" ] ,
        // 引用版本号文件的方式. 使用#ver#代替路径描述
        "include_version_type" : {  
            ".jsp" : "<jsp:include page=\\"#ver#\\" flush=\\"true\\"/>" , 
            ".htm" : "<!--#include file=\\"#ver#\\" -->" 
        }
    }

    """
    utils.logger.error("没有转换应用的配置文件.")
    utils.logger.error( str )

process_app_css = () ->
    _each_files _replaceCSS


process_app_javascript = () ->
    _each_files _replaceJS

###
    恢复原状
    svn revert . -R && svn st | awk '{print $2}' | xargs rm
###
exports.run = ( options ) ->
    
    CURR = options.cwd

    if options.qzz
        if !check() 
            utils.logger.error("当前目录不符合转换规则, 禁止转换")
            return
        process_srclist()
        process_ver()
        process_build()
        process_config()
        utils.logger.log( "转换完成." )

    else if options.app
        if !check_config() 
            show_config()
        else
            process_app_css()
            process_app_javascript()
            utils.logger.log( "转换完成." )
    else
        utils.logger.error( "必须使用 --qzz 或 --app 来确定转换的目录类型, 使用 fekit convert --help 来查看帮助. " )


