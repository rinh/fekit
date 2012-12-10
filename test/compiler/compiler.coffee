compiler = require('../../lib/compiler/compiler')
should = require('chai').should()
except = require('chai').except


describe 'ModuleChecker', ->
    describe '#reg', ->
        it 'should be right', ->
            c = new compiler.ModuleChecker()
            lines = [
                {  str : "  import('a.js'); " , except : "a.js"  }
                {  str : '  import("b.js"); ' , except : "b.js"  }
                {  str : "  require('a.js'); " , except : "a.js"  }
                {  str : '  require("b.js"); ' , except : "b.js"  }
                {  str : "  import  (  'a.js' )   ; " , except : "a.js"  }
                {  str : '  import("b.js"); ' , except : "b.js"  }
            ]

            for line in lines 
                line.str.match( c.reg )[2].should.equal( line.except )
