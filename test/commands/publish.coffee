path = require 'path'
utils = require('../../lib/util')
publish = require('../../lib/commands/publish')
assert = require('chai').assert

describe '#tar_package', ->

    it 'tar1 should throw exception.' , () ->

        t = () ->
            publish.tar_package {} , ( err ) ->

        assert.throw t 

    it 'tar1 should be right.' , ( done ) ->

        opt = { cwd : path.join( path.dirname(__filename) , 'publish/tar1' ) }

        publish.tar_package opt , ( err ) ->

            assert.equal err , null

            assert.ok !!opt.tar_path

            assert.ok utils.path.exists opt.tar_path

            done()