syspath = require 'path'
hogan = require '../../../vendors/hogan.js/lib/hogan'

exports.contentType = "javascript"
exports.process = (txt, path, module, cb) ->
    try
        name = syspath.basename path, '.mustache'
        txt = hogan.compile txt, asString: 1
        builded = """
            if (typeof window.QTMPL === "undefined") window.QTMPL = {};
            window.QTMPL["#{name}"] = new window.Hogan.Template(#{txt});
            if (typeof module !== "undefined") module.exports = window.QTMPL["#{name}"];
        """
        cb null, builded
    catch err
        cb err
