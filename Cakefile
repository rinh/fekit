path = require 'path'
fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

_spawn = ( cmd , args = [] , options = {} ) ->
    cmd = if process.platform is "win32" then cmd + ".cmd" else cmd
    spawn cmd , args , options

fetch_vendors = () ->
    
    console.info('fetch vendors...')

    # vendors npm install 
    n = _spawn 'npm' , ['install'] , {
        cwd : path.resolve( process.cwd() , './vendors/tar/' )
        env : process.env
    }

    process_stdio n , () ->
        console.info('fetch vendors done.')

process_stdio = (proc,callback) ->
    proc.stderr.pipe process.stderr, end: false 
    proc.stdout.pipe process.stdout, end: false 
    proc.on 'exit', (code) ->
        callback?() if code is 0

build = (option,callback) ->

    fetch_vendors()

    coffee = _spawn './node_modules/.bin/coffee', option
    process_stdio coffee , callback

test = () ->
    mocha = _spawn './node_modules/.bin/mocha' , [ '--colors', '--recursive', '--compilers', 'coffee:coffee-script' ]
    process_stdio mocha


echo = (child) ->
  child.stdout.on "data", (data) -> print data.toString()
  child.stderr.on "data", (data) -> print data.toString()
  child

install = (cb) ->
    console.log "Building..."

    fetch_vendors()

    echo child = _spawn "./node_modules/.bin/coffee", ["-c", "-o", "lib", "src"]
    child.on "exit", (status) -> cb?() if status is 0

#-------------------

task 'watch', 'Watch src/ for changes', ->
    build ['-w','-c','-o','lib','src']

task 'build', 'Build lib/ from src/', ->
    build ['-c','-o','lib','src']

task 'test', 'Test all case', ->
    test();

task "install", "Install, build, and test repo", install
