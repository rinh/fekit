path = require 'path'
utils = require('../lib/util')
Package = require('../lib/package')
assert = require('chai').assert

reset = () ->
    path = require.resolve('../lib/package')
    delete require.cache[ path ]
    Package = require('../lib/package')

describe 'package #_preinstall fetch non-existent package', ->
    
    before ->
        reset()
        Package.prototype._get = ( url , cb ) ->
            cb null , null , JSON.stringify({
                ret : false
                errmsg : 'missing'
            })

    it 'shoule be right' , ( done ) ->

        new Package()._preinstall ( err ) ->
            assert.equal err , 'missing'
            done()


describe 'package #_preinstall fetch non-version package', ->
    
    before ->
        reset()
        Package.prototype._get = ( url , cb ) ->
            cb null , null , JSON.stringify({
                ret : true 
                data : 
                    versions : 
                        '0.0.1': 
                            config: {}
            })

    it 'shoule be right' , ( done ) ->

        new Package('pkg1','0.0.2')._preinstall ( err ) ->
            assert.equal err , "'pkg1@0.0.2' is not in the fekit registry."
            done()

    


describe 'package #_preinstall fetch non-dependence package', ->
    
    before ->
        reset()
        Package.prototype._get = ( url , cb ) ->
            cb null , null , JSON.stringify({
                ret : true 
                data : 
                    versions : 
                        '0.0.1':
                            config: {}
            })

    it 'shoule be right' , ( done ) ->

        p = new Package('pkg1','0.0.1')
        p._preinstall ( err ) ->
            assert.equal err , null
            assert.equal p.children.length , 0
            done()


describe 'package #_preinstall fetch dependence package', ->
    
    before ->
        reset()
        Package.prototype._get = ( url , cb ) ->
            switch @name
                when 'pkg1'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': 
                                    config:
                                        dependencies : 
                                            'pkg2' : '0.1.x'
                    })
                when 'pkg2'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': {}
                    })

    it 'shoule be right' , ( done ) ->

        p = new Package('pkg1','0.0.1')
        p._preinstall ( err ) ->
            assert.notEqual err , null
            done()



describe 'package #_preinstall fetch dependence package 2', ->
    
    before ->
        reset()
        Package.prototype._get = ( url , cb ) ->
            switch @name
                when 'pkg1'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': 
                                    config:
                                        dependencies : 
                                            'pkg2' : '0.1.x'
                    })
                when 'pkg2'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': 
                                    config: {}
                                '0.1.1': 
                                    config: {}
                                '0.1.2': 
                                    config: {}
                                '0.1.3': 
                                    config: {}
                    })

    it 'shoule be right' , ( done ) ->

        p = new Package('pkg1','0.0.1')
        p._preinstall ( err ) ->
            assert.equal err , null
            assert.equal p.children.length , 1
            assert.equal p.children[0].version , '0.1.3'
            done()



describe 'issue #31', ->
    

    it 'section 1' , ( done ) ->
        reset()
        Package.prototype._get = ( url , cb ) ->
            switch @name
                when 'pkg1'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': 
                                    config:
                                        dependencies : 
                                            'pkg2' : '*'
                    })
                when 'pkg2'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': 
                                    config: {}
                                '0.0.2': 
                                    config: {}
                    })


        p = new Package()
        p.loadConfig( '/home/q/' , {
                dependencies : {
                    'pkg1' : '0.0.1' , 
                    'pkg2' : '0.0.2' 
                }
            })
        p._preinstall ( err ) ->
            assert.equal err , null
            assert.equal p.children.length , 2
            assert.equal p.children[0].name , 'pkg1'
            assert.equal p.children[0].version , '0.0.1'
            assert.equal p.children[1].name , 'pkg2'
            assert.equal p.children[1].version , '0.0.2'

            pkg1 = p.children[0]
            assert.equal pkg1.children.length , 0
            done()


    it 'section 2' , ( done ) ->
        reset()
        Package.prototype._get = ( url , cb ) ->
            switch @name
                when 'pkg1'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': 
                                    config:
                                        dependencies : 
                                            'pkg2' : '0.0.1'
                    })
                when 'pkg2'
                    cb null , null , JSON.stringify({
                        ret : true 
                        data : 
                            versions : 
                                '0.0.1': 
                                    config: {}
                                '0.0.2': 
                                    config: {}
                    })


        p = new Package()
        p.loadConfig( '/home/q/' , {
                dependencies : {
                    'pkg1' : '0.0.1' , 
                    'pkg2' : '0.0.2' 
                }
            })

        p._preinstall ( err ) ->
            assert.equal err , null

            assert.equal p.children.length , 2
            assert.equal p.children[0].name , 'pkg1'
            assert.equal p.children[0].version , '0.0.1'
            assert.equal p.children[1].name , 'pkg2'
            assert.equal p.children[1].version , '0.0.2'

            pkg1 = p.children[0]            
            assert.equal pkg1.children[0].name , 'pkg2'
            assert.equal pkg1.children[0].version , '0.0.1'
            assert.equal pkg1.children.length , 1
            
            done()




