syspath = require 'path'
hogan = require '../../../vendors/hogan.js/lib/hogan'

exports.contentType = "javascript"

exports.process = ( txt , path ,module , cb ) ->
    try 
        name = syspath.basename( path , '.mustache');
        builded = 'if(typeof window.QTMPL === "undefined"){ window.QTMPL={}; }\n';
        builded += 'window.QTMPL.' + name + ' = new window.Hogan.Template(' + hogan.compile(txt, { asString: 1 }) + ');';
        cb( null , builded )
    catch err 
        cb( err )