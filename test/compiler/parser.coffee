parser = require('../../lib/compiler/parser')
assert = require('chai').assert

reset = () ->
    path = require.resolve('../../lib/compiler/parser')
    delete require.cache[ path ]
    parser = require('../../lib/compiler/parser')


get_ast = ( code , level = 0 ) ->
    ast = parser.parse(code)
    return ast


# ast
describe 'Parser', ->
    it 'should be right', ->

        reset()

        assert.ok( get_ast("aaaaa /* aaaaa */")["$1"]["$1"][1].name == "COMMENT_STATEMENT" )
        assert.ok( get_ast("aaaaa  dsafsadf /* aaaaa */")["$1"]["$1"][1].name == "COMMENT_STATEMENT" )
        
        ast = get_ast("""
            abcde 
            /* 
                abcde 
            adfasd */
            // hohohoh
        """)["$1"]["$1"]

        assert.ok( ast[1].name == "LINE_COMMENT_STATEMENT" )
        assert.ok( ast[0]["$1"][0]["$1"][1].name == "COMMENT_STATEMENT" )

# print
describe 'Parser', ->
    describe '#defineNode', ->
        it 'should be right', ->

            reset()

            parser.defineNode('REQUIRE',{
                print : () ->
                    return "[load " + this.$3.print().replace(/"/g,'') + "]";
            })

            s = parser.parse('require("./abc/def");').print();
            assert.equal( s , '[load ./abc/def];')


            parser.defineNode('LINE_COMMENT_STATEMENT',{
                print : () ->
                    return "#LINE";
            })

            s = parser.parse("/* hoho */\nabc\n// hohohohoohoh").print();
            assert.equal( s , '/* hoho */\nabc\n#LINE' );



# find
describe 'Parser', ->
    describe '#find', ->
        it 'should be right', ->

            reset()

            s = parser.parse('abc\nabc\nrequire("./abc/def");\nabc');
            r = s.find "REQUIRE" , (node) ->
                assert.equal( node.getPath() , './abc/def' )
            assert.equal( r.length , 1 )

            s = parser.parse('abc\nabc\nrequire("./abc");require(\'./def\');\nabc');
            r = s.find "REQUIRE"
            assert.equal( r.length , 2 )
            assert.equal( r[0].getPath() , './abc' )
            assert.equal( r[1].getPath() , './def' )



# emit
describe 'Parser', ->
    describe '#emit', ->
        it 'should be right', ->

            reset()

            hit = 0
            s = parser.parse('abc\nabc\nrequire("./abc/def");\nabc');
            s.find 'REQUIRE' , ( node ) ->
                node.on 'printing' , ( evt ) ->
                    hit = 1
            assert.equal( s.print() , 'abc\nabc\nrequire("./abc/def");\nabc' );
            assert.equal( hit , 1 )




