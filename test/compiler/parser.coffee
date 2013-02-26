parser = require('../../lib/compiler/parser')
assert = require('chai').assert

get_ast = ( code , level = 0 ) ->
    ast = parser.parse(code)
    return ast


# ast
describe 'Parser', ->
    it 'should be right', ->
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




