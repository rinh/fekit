compiler = require "../compiler/compiler"
utils = require "../util"

exports.usage = "合并项目文件"


exports.run = ( options ) ->

    conf = utils.config.parse( options.cwd )

    conf.each_export_files (srcpath, parents) =>
        utils.logger.log( "正在处理 #{srcpath}" )
        urlconvert = new utils.UrlConvert( srcpath )
        source = compiler.compile( srcpath, parents )
        dest = urlconvert.to_dev()
        new utils.file.writer().write( dest , source )
        utils.logger.log( "已经处理 #{srcpath}  ==> #{dest}" )

    utils.logger.log("DONE.")
