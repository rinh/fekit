ModulePath = require('../../lib/compiler/module/path').ModulePath
assert = require('chai').assert

describe '#parsePath1', ->
    it 'should be right', ->

        ModulePath.EXTLIST = ['.js','.css']

        fakeParent =
            config :
                getPackage : ( name ) ->
                    return null
                isUseAlias : ( name ) ->

                parseAlias : ( name ) ->

            path :
                dirname : () ->
                    '/home/test/'

        assert.equal ModulePath.parsePath('./core.js',fakeParent) , '/home/test/core.js'
        assert.equal ModulePath.parsePath('./core',fakeParent) , '/home/test/core'
        assert.equal ModulePath.parsePath('./core/abc',fakeParent) , '/home/test/core/abc'
        assert.equal ModulePath.parsePath('core.js',fakeParent) , '/home/test/core.js'
        assert.equal ModulePath.parsePath('core',fakeParent) , '/home/test/core'




describe '#parsePath2', ->
    it 'should be right', ->

        ModulePath.EXTLIST = ['.js','.css']

        fakeParent =
            config :
                getPackage : ( name ) ->
                    if name is 'core' or name is 'base-js'
                        return "/home/packages/#{name}/index"
                    else
                        return null
                isUseAlias : ( name ) ->

                parseAlias : ( name ) ->

            path :
                dirname : () ->
                    '/home/test/'

        assert.equal ModulePath.parsePath('./core.js',fakeParent) , '/home/test/core.js'
        assert.equal ModulePath.parsePath('./core',fakeParent) , '/home/test/core'
        assert.equal ModulePath.parsePath('core-js',fakeParent) , '/home/test/core-js'
        assert.equal ModulePath.parsePath('core',fakeParent) , '/home/packages/core/index'
        assert.equal ModulePath.parsePath('base-js',fakeParent) , '/home/packages/base-js/index'


describe '#parsePath3', ->
    it 'should be right', ->

        ModulePath.EXTLIST = ['.js','.css']

        fakeParent =
            config :
                getPackage : ( name ) ->
                    return null
                isUseAlias : ( name ) ->
                    name is "core"
                parseAlias : ( name ) ->
                    return "/home/lib/#{name}-base/"
            path :
                dirname : () ->
                    '/home/test/'

        assert.equal ModulePath.parsePath('./core.js',fakeParent) , '/home/test/core.js'
        assert.equal ModulePath.parsePath('./core',fakeParent) , '/home/test/core'
        assert.equal ModulePath.parsePath('core/index',fakeParent) , '/home/lib/core-base/index'






