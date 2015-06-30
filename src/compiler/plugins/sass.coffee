utils = require '../../util'
css = require './css'
syspath = require 'path'
sass = require 'node-sass'
importOnce = require 'node-sass-import-once'

#=============================

MAP = {}

convertRegexp = ( str , flag ) ->
    str = str.replace(/\s/g,'').replace('{space}',' ')
    return new RegExp str , flag 

regstr = convertRegexp("""
(
    ?: [{space}]*@import\\s*\\s*'([^']+)'\\s*
    |  [{space}]*@import\\s*\\s*"([^"]+)"\\s*
)
[{space};]*
""" , "g")

grep_import = ( txt , basedir )->
    return txt.replace regstr , ( $0 , $1 , $2 )->
        p = utils.path.join basedir , $1 or $2 
        if MAP[p]
            return ""
        else
            MAP[p] = true
            return $0


#=============================

exports.contentType = "css"

exports.process = (txt, path, module, cb) ->

    dir = syspath.dirname path

    #txt = grep_import( txt , dir )

    succ = (code) -> 
        cb null, (css.ddns code, module)

    fail = (err) ->
        cb err

    try 
        sass.render {
            data: txt,
            includePaths: [dir],
            outputStyle: "expanded",
            importer: importOnce
        }, ( err, result ) ->
          if err
              fail( err )
          else
              succ( result.css.toString() )
    catch err
        fail( err )
            



