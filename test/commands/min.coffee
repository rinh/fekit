util = require('../../lib/commands/min')
should = require('chai').should()
jsp = require("uglify-js").parser;
pro = require("uglify-js").uglify;

describe 'uglify', ->
    describe '#gen_code', ->
        it 'should be right', ->
            source = "var a = 1;"
            ast = jsp.parse(source)
            ast = pro.ast_mangle(ast)
            ast = pro.ast_squeeze(ast)
            final_code = pro.gen_code( ast )
            final_code.should.equals( "var a=1" )