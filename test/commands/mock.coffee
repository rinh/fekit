mock_module = require('../../lib/middleware/mock')
should = require('chai').should() 

describe 'mock', ->
    describe '#exjson', ->
        it 'should be right', ->
            a = '{\n\t/test\\d\\d/ : "./mock.js" ,\n\t/test1/ : "./mock.json" , \n\t/test2/ : "./mock.mockjson",\n\t/\\// : "http://ctrip.com" , \n\t/\\/abc\\/def\\/g/ : \'mock.json\'\n}'

            b = '{\n\t\'test\\\\d\\\\d^^^\' : "./mock.js" ,\n\t\'test1^^^\' : "./mock.json" , \n\t\'test2^^^\' : "./mock.mockjson",\n\t\'\\\\/^^^\' : "http://ctrip.com" , \n\t\'\\\\/abc\\\\/def\\\\/g^^^\' : \'mock.json\'\n}'

            mock_module.exjson( a ).should.equals b
