syspath = require 'path'

exports.contentType = "javascript"

exports.process = (ori_txt, path, module, cb) ->
    name = syspath.basename path, '.string'
    txt = JSON.stringify ori_txt
    code = """
        if (typeof window.QTMPL === "undefined") window.QTMPL = {};
        window.QTMPL["#{name}"] = #{txt};
        if (typeof module !== "undefined") module.exports = window.QTMPL["#{name}"];
    """
    cb null, code
