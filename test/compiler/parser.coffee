parser = require('../../lib/compiler/parser')
assert = require('chai').assert

get_ast = ( code , level = 0 ) ->
    ast = parser.parseAST(code)
    return ast

css_source = """
.filters { position: relative; margin-top:15px; }
.filters .action { position:absolute; right:0; top:5px; }
.filters .action a { cursor:pointer; color:#991e23; width: 65px; height:26px; }
.filters .action a i { vertical-align: middle; display:inline-block; height:15px; width:15px; margin-left:2px; }
.filters .action .more i { background:url("/images/list_bg.png") no-repeat scroll 0 0 transparent; }
.filters .action .less i { background:url("/images/list_bg.png") no-repeat scroll 0 -15px transparent; }

.expand .action .more { display:block; }
.expand .action .less { display:none; }

.collapse .action .more { display:none; }
.collapse .action .less { display:block; }

.filters .filter { display:inline-block; width:970px; padding:9px 0 10px; border-bottom:1px dotted #000;  }
.filters .filter .name { display: inline; float:left; font-weight: bold; width:60px; }
.filters .filter .chklist { display: inline; float:left; margin-top:-2px; }
.filters .filter .chklist li { display:inline; float:left; width:86px; height:18px; line-height:18px; overflow:hidden; padding:1px 4px 1px 0; word-break:break-all; word-wrap:break-word; vertical-align: baseline; }
.filters .filter .chklist li input { height:15px; line-height:15px; margin:3px 3px 0 0; vertical-align:top; width:15px; }
.filters .filter .chklist li label { cursor:pointer; display:inline-block; height:18px; line-height:18px; width:65px; padding: 1px 1px 3px 2px; word-break:break-all; word-wrap:break-word; }

.filters .filter .mutilist { display: inline; float:left; }
.filters .filter .mutilist .handler { display: inline; float:left; position:relative; }
.filters .filter .mutilist .handler .pop_btn { cursor:pointer; width: 65px; } 
.filters .filter .mutilist .handler .pop_btn i { display:inline-block; height:15px; width:15px; margin-left:2px; }
.filters .filter .mutilist .handler .pop_layer {  z-index:10; position: absolute; width:465px; border:1px solid #abadb3; background-color: #fff; padding:5px; }
.filters .filter .mutilist .handler .pop_layer .title { margin:4px 4px 6px; padding:0 4px 6px; border-bottom: 1px solid #ccc; }
.filters .filter .mutilist .handler .pop_layer .title .close { float:right; cursor:pointer; display:block; width:12px; height:12px; background: url("/images/list_bg.png") no-repeat scroll 0 -45px transparent; }
.filters .filter .mutilist .handler .pop_layer ul { width:auto; }
.filters .filter .mutilist .handler .pop_layer ul li { margin: 4px auto; }
.filters .filter .mutilist .handler .pop_layer input { vertical-align: top; }

.filters .filter .mutilist .separate { display: inline; float:left; margin:auto 15px auto 25px; }
.filters .filter .mutilist ul { display: inline; float:left; width:800px; }
.filters .filter .mutilist li { display: inline; float:left; width:90px;}
.filters .filter .mutilist li .cancel { margin:auto 2px; display:inline-block; vertical-align: middle; width:13px; height:13px; line-height: 13px; background:url("/images/list_bg.png") no-repeat scroll 0 -30px transparent;   }

.filters .filter .mutilist .collapse_pop .pop_layer { display:none; }
.filters .filter .mutilist .collapse_pop .pop_btn i { vertical-align: middle; background:url("/images/list_bg.png") no-repeat scroll -15px 0 transparent; }
.filters .filter .mutilist .expand_pop .pop_layer { display:block; }
.filters .filter .mutilist .expand_pop .pop_btn i { vertical-align: middle; background:url("/images/list_bg.png") no-repeat scroll -15px -15px transparent; }


.summary { margin: 30px auto 12px; font-size:14px; }

.result th { color:#fff; vertical-align:middle; height:35px; line-height:35px; text-align:center; background-color:#991e23; border-top:1px solid #5f0c10; }
.result th i { width:7px; vertical-align:middle; margin:auto 3px; height:10px; line-height:10px; display:inline-block; background:url("/images/list_bg.png") no-repeat scroll 0 -72px transparent; }
.result th.asc i { background-position: -7px -72px; }
.result th.desc i { background-position: -14px -72px;  }
.result td { color:#666; height:75px; border-bottom:1px solid #ccc; text-align:center; }
.result tr .t1 { width:75px; }
.result tr .t2 { width:106px; }
.result tr .t3 { width:96px; position:relative; }
.result tr .t4 { width:87px; }
.result tr .t5 { width:72px; }
.result tr .t6 { width:81px; }
.result tr .t7 { width:385px; }
.result tr .t8 { width:68px; }

.result tr td.t2 { color:#000; font-weight:bold; }

.result tr td.t3 i { display:none; vertical-align: top; margin: 0 2px; width:9px; height:9px; background:url("/images/list_bg.png") no-repeat scroll -9px -60px transparent;  }
.result tr td.t3 .tip { display:none; position:absolute; color:#fff; padding:2px 4px; margin-left: 83px; margin-top: -7px; } 
.result tr td.t3 .from { color:#007cd2; }
.result tr td.t3 .from i { display:inline-block; background-position: -9px -60px; }
.result tr td.t3 .from .tip { background-color:#ca0008; }
.result tr td.t3 .to { color:#ca0008; }
.result tr td.t3 .to i { display:inline-block; background-position: 0 -60px; }
.result tr td.t3 .from .tip { background-color:#007cd2; }
.result tr td.t3 .hover .tip { display:block; }

.result tr td.t7 { color:#333; }
"""

describe 'Parser', ->
    it 'find_line_from_str', ->

        assert.equal parser.find_line_from_str( "abcde\n12345" , 3 , true ) , "abcde"
        assert.equal parser.find_line_from_str( "abcde\n12345" , 7 , true ) , "12345"
        assert.equal parser.find_line_from_str( "abcde\n12345" , 3 , false ) , "abc"
        assert.equal parser.find_line_from_str( "abcde\n12345" , 7 , false ) , "1"


# print
describe 'Parser', ->
    describe '#defineType1', ->
        it 'should be right', ->

            def1 = ( code ) ->
                ast = parser.parseAST(code)
                ast.defineType 'require' , ( line ) ->
                    return "[load " + line.value + "]"
                return ast;

            # js
            s = def1('require("./abca/def");').print();
            assert.equal( s , '[load ./abca/def]')

            s = def1('require("./abc/def");').print();
            assert.equal( s , '[load ./abc/def]')

            s = def1('require("./abc/def").abc').print();
            assert.equal( s , '[load ./abc/def].abc')

            s = def1('require("./abc");require("./def");').print();
            assert.equal( s , '[load ./abc][load ./def]')

            s = def1('require("./abc");\nrequire("./def");').print();
            assert.equal( s , '[load ./abc]\n[load ./def]')

            s = def1('require("./abc")\nrequire("./def")').print();
            assert.equal( s , '[load ./abc]\n[load ./def]')

            s = def1('ext.require("./abc")\nrequire("./def")').print();
            assert.equal( s , 'ext.require("./abc")\n[load ./def]')

            s = def1('require("./abc")\next.require("./def")').print();
            assert.equal( s , '[load ./abc]\next.require("./def")')

            s = def1('require("./abc")\n // require("./def")').print();
            assert.equal( s , '[load ./abc]\n // require("./def")')

            s = def1('require("./abc")\n // require("./def") \r\n ext.require("abc");').print();
            assert.equal( s , '[load ./abc]\n // require("./def") \r\n ext.require("abc");')

            # css
            s = def1('@import url("./abc1/def");').print();
            assert.equal( s , '[load ./abc1/def]')

            s = def1("@import url('./abc2/def');").print();
            assert.equal( s , '[load ./abc2/def]')

            s = def1('@import url(./abc3/def);').print();
            assert.equal( s , '[load ./abc3/def]')

            s = def1('@import url("./abc/def").abc').print();
            assert.equal( s , '[load ./abc/def].abc')

            s = def1('@import url("./abc");@import url("./def");').print();
            assert.equal( s , '[load ./abc][load ./def]')

            s = def1('@import url("./abc");\n@import url("./def");').print();
            assert.equal( s , '[load ./abc]\n[load ./def]')

            s = def1('@import url("./abc")\n@import url("./def")').print();
            assert.equal( s , '[load ./abc]\n[load ./def]')



describe 'Parser', ->
    describe '#is_line_end', ->
        it 'should be right', ->

            str = "12345\n12345require   \n"

            assert.ok( parser.is_line_end( "1234   \n" , 4 ) )

            assert.ok( parser.is_line_end( str , 5 ) )
            assert.ok( !parser.is_line_end( str , 4 ) )
            assert.ok( parser.is_line_end( str , 18 ) )


# find
describe 'Parser', ->
    describe '#find', ->
        it 'should be right', ->

            s = get_ast('abc\nabc\nrequire("./abc/def");\nabc');
            r = s.find "REQUIRE" , (node) ->
                assert.equal( node.value , './abc/def' )
            assert.equal( r.length , 1 )

            s = get_ast('abc\nabc\nrequire("./abc");require(\'./def\');\nabc');
            r = s.find "REQUIRE"
            assert.equal( r.length , 2 )
            assert.equal( r[0].value , './abc' )
            assert.equal( r[1].value , './def' )


# find
describe 'Css Parser', ->
    describe '#find', ->
        it 'should be right', ->

            s = get_ast(css_source);
            r = s.find "REQUIRE" , (node) ->
                console.info( node )

