util = require('../lib/util')
should = require('chai').should()


describe 'util.path', ->
    describe '#split_path', ->
        it 'should be right', ->
            t = util.path.split_path
            t("a/b/c",[]).join().should.equals("a,b,c")
            t("a/b/c.js",['.js']).join().should.equals("a,b,c.js")
            t("a/b/c.coffee",['.js','.coffee']).join().should.equals("a,b,c.coffee")
            t("a/b/jquery.c.coffee",['.js','.coffee']).join().should.equals("a,b,jquery.c.coffee")
            t("a",['.js','.coffee']).join().should.equals("a")
            t("./a/b/c",['.js','.coffee']).join().should.equals(".,a,b,c")
            t("../a/b/c",['.js','.coffee']).join().should.equals("..,a,b,c")
            t("..\\a\\b\\c",['.js','.coffee']).join().should.equals("..,a,b,c")
            t("a.b.c",['.js','.coffee']).join().should.equals("a,b,c")
            t("a.b.c.js",['.js','.coffee']).join().should.equals("a,b,c.js")
            t("a.b.c.m",['.js','.coffee']).join().should.equals("a,b,c,m")