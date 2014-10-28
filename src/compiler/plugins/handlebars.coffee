syspath = require 'path'
handlebars = require 'handlebars'

exports.contentType = "javascript"

exports.process = (txt, path, module, cb) ->
    try
        name = syspath.basename path, '.handlebars'
        txt = handlebars.precompile txt
        builded = """
            if (typeof window.QTMPL === "undefined") window.QTMPL = {};
            window.QTMPL["#{name}"] = new window.Handlebars.template(#{txt});
            if (typeof module !== "undefined") module.exports = window.QTMPL["#{name}"];
        """
        cb null, builded
    catch err
        cb err
