path = require 'path'
fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'
{exec} = require 'child_process'

_exec = ( cmd , callback ) ->
    console.info("[EXEC] #{cmd}")
    n = cmd.split(' ')
    n1 = n[0]
    n2 = ( i.replace(/\t/g,' ') for i in n.slice(1) )
    c = spawn( n1 , n2 , {
            cwd : process.cwd() ,
            env : process.env
        })

    console.info("---------------------------")
    c.stderr.pipe process.stderr, end: false
    c.stdout.pipe process.stdout, end: false
    c.on 'exit' , ( code ) ->
        console.info("")
        callback()


_spawn = ( cmd , args = [] , options = {} ) ->
    cmd = if process.platform is "win32" then cmd + ".cmd" else cmd
    spawn cmd , args , options

fetch_vendors = () ->

    ###
    console.info('fetch vendors...')

    # vendors npm install
    n = _spawn 'npm' , ['install'] , {
        cwd : path.resolve( process.cwd() , './vendors/tar/' )
        env : process.env
    }

    process_stdio n , () ->
        console.info('fetch vendors done.')
    ###

process_stdio = (proc,callback) ->
    proc.stderr.pipe process.stderr, end: false
    proc.stdout.pipe process.stdout, end: false
    proc.on 'exit', (code) ->
        callback?() if code is 0

build = (option,callback) ->

    fetch_vendors()

    coffee = _spawn path.join('.', 'node_modules', '.bin', 'coffee'), option
    process_stdio coffee , callback

test = () ->
    mocha = _spawn path.join('.', 'node_modules', '.bin', 'mocha') , [ '--colors', '--recursive', '--compilers', 'coffee:coffee-script' ]
    process_stdio mocha


echo = (child) ->
  child.stdout.on "data", (data) -> print data.toString()
  child.stderr.on "data", (data) -> print data.toString()
  child

install = (cb) ->
    console.log "Building..."

    fetch_vendors()

    echo child = _spawn path.join(".", "node_modules", ".bin", "coffee"), ["-c", "-o", "lib", "src"]
    child.on "exit", (status) -> cb?() if status is 0

#-------------------

task "bump", 'bump version' , ->
    semver = require('semver')
    pkg = JSON.parse( fs.readFileSync('./package.json').toString() )
    lasest_version = fs.readFileSync('./CHANGELOG.md').toString().split('\n')[0].replace("#","").replace(/\s/g,'')

    return console.error("[ERROR] #{lasest_version} is invalid.") if semver.lt lasest_version , pkg.version

    pkg.version = lasest_version
    fs.writeFileSync('./package.json', JSON.stringify( pkg , null , 4 ) )

    _exec 'git add . ' , ->
        _exec "git commit -m 'bump\tversion\tv#{pkg.version}'" , ->
            _exec "git tag v#{pkg.version}" , ->
                _exec 'git push origin master' , ->
                    _exec "git push origin --tags" , ->
                        _exec 'npm publish' , ->
                            console.info "[success] BUMP done."


task 'watch', 'Watch src/ for changes', ->
    build ['-w','-c','-o','lib','src']

task 'build', 'Build lib/ from src/', ->
    build ['-c','-o','lib','src']

task 'test', 'Test all case', ->
    test();

task "install", "Install, build, and test repo", install
