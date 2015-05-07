syspath = require 'path'
jade = require 'jade'


exports.contentType = 'javascript'

exports.process = (txt, path, module, cb)->
    try
        # console.log arguments
        name = syspath.basename path, '.jade'
        txt = jade.compileClient txt,
            name: ' ' 
            filename: path
            doctype: 'html'

        builded = """
            if (typeof window.QTMPL === "undefined") window.QTMPL = {};
            window.QTMPL["#{name}"] = #{txt};
            if (typeof module !== "undefined") module.exports = window.QTMPL["#{name}"];
        """

        cb null, builded
    catch e
        cb e
        
                    