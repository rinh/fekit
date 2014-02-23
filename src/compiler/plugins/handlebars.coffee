syspath = require 'path'
handlebars = require 'handlebars'

exports.contentType = "javascript"

exports.process = ( txt , path ,module , cb ) ->
    try 
        name = syspath.basename( path , '.handlebars');
        builded = 'if(typeof window.QTMPL === "undefined"){ window.QTMPL={}; }\n';
        builded += 'window.QTMPL.' + name + ' = window.Handlebars.template(' + handlebars.precompile(txt) + ');';
        cb( null , builded )
    catch err 
        cb( err )