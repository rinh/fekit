util = require('../lib/util')
exec = require('child_process').exec
assert = require('chai').assert

testcase_dir = util.path.join( __dirname , '../testcase' )

do_case = ( cmd , case_name , cb ) ->
    command = "node #{util.path.join(testcase_dir,'../bin/fekit')} #{cmd}"
    cwd = util.path.join( testcase_dir , case_name , "case" )

    exec( command , {
        cwd : cwd 
    }, (error, stdout, stderr) ->
        if error
            console.error(error)
            assert.fail()
        switch cmd
            when "pack"  
                compare case_name , "dev"
            when "min"  
                compare case_name , "prd"
        if cb then cb( error )
    )

compare = ( case_name , compare_path ) ->
    basepath = util.path.join( testcase_dir , case_name , 'except' , compare_path )
    util.path.each_directory( basepath , ( path ) ->
        compare_file path
    , true )


compare_file = ( except_file_path ) ->
    except = util.file.io.read( except_file_path )
    actual = util.file.io.read( except_file_path.replace('/except/','/case/') )
    assert.equal actual , except 



describe 'testcase case', ->

    this.timeout( 3 * 60 * 1000 )

    describe 'simple 普通编译模式', ->

        it '使用不同路径写法合并js/css文件', (done) ->

            do_case 'pack', 'simple' , () ->
                done()


    describe 'export multi type', ->

        it '测试根文件为非js,css的编译', (done) ->

            do_case 'pack', 'export_multi_type' , () ->
                done()



