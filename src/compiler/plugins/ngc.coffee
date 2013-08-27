coffee = require 'coffee-script'
esprima = require 'esprima'
escodegen = require 'escodegen'
astral = require('astral')()
require('astral-angular-annotate')(astral)


exports.contentType = "javascript"

exports.process = ( ori_txt , path ,module , cb ) ->
    
    txt = coffee.compile( ori_txt )

    ast = esprima.parse txt , {
            tolerant: true
        }

    astral.run( ast )

    code = escodegen.generate ast , 
        format : 
            indent: 
                style: '  '

    cb( null , code )