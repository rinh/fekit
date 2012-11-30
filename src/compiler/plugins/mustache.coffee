syspath = require 'path'
hogan = require 'hogan.js'

exports.process = ( txt , path ) ->
    name = syspath.basename( path , '.mustache');
    builded = 'if(typeof QTMPL === "undefined"){var QTMPL={};}\n';
    builded += 'QTMPL.' + name + ' = new Hogan.Template(' + hogan.compile(txt, { asString: 1 }) + ');';
    return builded