compiler = require('../../lib/compiler/module/module')
assert = require('chai').assert

describe 'Module', ->
    describe '#reg', ->
        it 'should be right', ->
            lines = [
                {  str : "//  @import url('a.js'); " , except : null  }
                {  str : '  @import url("b.js"); ' , except : "b.js"  }
                {  str : "  require('a.js'); " , except : "a.js"  }
                {  str : '  require("b.js"); ' , except : "b.js"  }
                {  str : "  @import  url(  'a.js' )   ;; " , except : "a.js"  }
                {  str : '  @import url("b.js"); ' , except : "b.js"  }
            ]

            for line in lines 
                m = line.str.match( compiler.MODULE_LINE_REGEXP )
                if !m 
                    assert.equal( m , line.except )
                else 
                    assert.equal( m[3] , line.except )
