compiler = require('../../lib/compiler/compiler')
should = require('chai').should()
except = require('chai').except


describe 'ModuleChecker', ->
    describe '#reg', ->
        it 'should be right', ->
            c = new compiler.ModuleChecker()
            lines = [
                {  str : "  @import('a.js'); " , except : "a.js"  }
                {  str : '  @import("b.js"); ' , except : "b.js"  }
                {  str : "  @require('a.js'); " , except : "a.js"  }
                {  str : '  @require("b.js"); ' , except : "b.js"  }
                {  str : "  @import  (  'a.js' )   ; " , except : "a.js"  }
                {  str : '  @import("b.js"); ' , except : "b.js"  }
            ]

            for line in lines 
                line.str.match( c.reg )[1].should.equal( line.except )

###

describe 'Array', ->
    describe '#indexOf()', ->
        it 'should return -1 when the value is not present', ->
            [1,2,3].indexOf(5).should.equal(-1)


describe 'FileModule', ->
    describe '#regex', ->
        it 'shoule be right', ->
            s = """
                @require ("7") ;
                // @require ("8") ;
                @import ("1");

                @import '2';
                //@import"3";
                @import ( 4 )
                @import "5"
                /// @require "9" ;
                @require "10"
                @require '11' ; 
                @import"6"
                @ import "12"
                @require '13";
                @require '14":
            """
            m = new FileModule();
            rs = []
            while( r = m.reg.exec(s) )
                rs.push( r[1] )

            rs.join().should.equal("7,8,1");


describe 'FileModule', ->
    describe '#disable regex', ->
        it 'shoule be right', ->
            s = [
                '@import("1");'
                "@import ('2');"
                '//@import("3");'
                '//    @import("3");'
                '@import ("4")'
                '@import "4-1"'
                '@import"4-2"'
                '@require ("5") ;'
                '@require("6");'
                '/// @require ("7") ;'
                '@require ("8")'
                "@require ('9') ;"
            ]
            m = new FileModule();
            rs = []

            for n in s
                if( m.disable_reg.test(n) )
                    rs.push(n)

            rs.length.should.equal(3);


###