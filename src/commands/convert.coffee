syspath = require 'path'
sysfs = require 'fs'
utils = require '../util'
findit = require 'findit'
spawn = require('child_process').spawn

exports.usage = "转换 [qzz项目] 为 [fekit项目] "

exports.set_options = ( optimist ) ->

CURR = null
CONFIG = 
        "lib" : {} 
        "export" : []
FILE = ( name ) ->
    return syspath.join( CURR , name )

# 检查当前目录是否可以转换
check = () ->
    if !sysfs.existsSync( FILE(".ver") ) then return false
    if sysfs.existsSync( FILE("fekit.config") ) then return false
    return true
    

###
1. 处理 srclist
            a. 文件名变为普通
            b. 修改引用方式 document.write 变为 import , js/css的
###
process_srclist = () ->
    files = findit.sync( CURR )
    add_list = []
    remove_list = []
    for file in files
        if ~file.indexOf('-srclist.') and !~file.indexOf(".svn")
            utils.logger.info("正在处理 #{file}")
            add_list.push( _replaceSrclist( file ) )
            remove_list.push( file )

    add = spawn 'svn' , [ 'add' ].concat( add_list )
    add.on 'exit' , (code) =>
        spawn 'svn' , [ 'rm' ].concat( remove_list )
    

JS_REG = /!!document\.write.*src=['"]([^'"]*)['"].*/g
CSS_REG = /@import\s+url\s*\(\s*['"]?([^'"\)]*)['"]?\s*\)/g

_replaceSrclist = ( filepath ) ->
    url = new utils.UrlConvert( filepath )
    dest = url.to_src().replace('-srclist','')

    # 修改引用 
    content = new utils.file.reader().read( filepath )
    content = content.replace JS_REG , ($0,$1) =>
                    return "@import('#{$1}');"
    content = content.replace CSS_REG , ($0,$1) =>
                    return "@import('#{$1}');"
    new utils.file.writer().write( dest , content )

    # 添加config
    if ~dest.indexOf('/src/')
        part = dest.split('/src/')[1]
    else if ~dest.indexOf('\\src\\')
        part = dest.split('\\src\\')[1]
    CONFIG.export.push( part )

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


###
    恢复原状
    svn revert . -R && svn st | awk '{print $2}' | xargs rm
###
exports.run = ( options ) ->
    
    CURR = options.cwd

    if !check() 
        utils.logger.error("当前目录不符合转换规则, 禁止转换")
        return

    process_srclist()
    process_ver()
    process_build()
    process_config()

    utils.logger.info( "转换完成.  转换日志在当前目录下的 convert.log " )

