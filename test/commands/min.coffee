util = require('../../lib/commands/min')
should = require('chai').should()
ujs = require("uglify-js")

describe 'uglify', ->
    describe '#gen_code', ->
        it 'should be right', ->
            source = "var a = 1;"
            toplevel = ujs.parse( source )
            toplevel.figure_out_scope()
            compressor = ujs.Compressor({})
            compressed_ast = toplevel.transform(compressor)
            compressed_ast.figure_out_scope()
            compressed_ast.compute_char_frequency()
           	compressed_ast.mangle_names()
            stream = ujs.OutputStream({})
            compressed_ast.print(stream);
           	final_code = stream.toString()
            final_code.should.equals( "var a=1;" )