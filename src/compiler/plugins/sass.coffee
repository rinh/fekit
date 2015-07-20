utils = require '../../util'
css = require './css'
fs = require 'fs'
syspath = require 'path'
try
    sass = require '../../../vendors/node-sass'
catch err
    sass = require 'node-sass'

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


extNames = ['sass', 'scss', 'css'];

fixFilePath = (filePath) ->
  extName = syspath.extname filePath
  baseName = syspath.basename filePath
  dirName = syspath.dirname filePath
  if extName && fs.existsSync filePath
    return filePath

  if !extName
    for eName in extNames
      if fs.existsSync filePath + '.' + eName
        return filePath + '.' + eName;
      privatePath = syspath.join dirName, '_' + baseName + '.' + eName
      if fs.existsSync privatePath
        return privatePath
  else
    privatePath = syspath.join dirName, '_' + baseName
    if fs.existsSync privatePath
      return privatePath

  throw new Error '找不到import文件: ' + filePath

getWholeScssFile = (filePath, imports) ->
  imports = imports or {}
  filePath = fixFilePath filePath
  if imports[filePath] isnt true
    imports[filePath] = true
    data = '\n' + new utils.file.reader().read filePath
    # 删除注释
    if data
      data = data.replace /\/\*.+?\*\/|\n\s*\/\/.*(?=[\n\r])/gm, ''
    return data.replace /@import.*[\'\"](.+)[\'\"].*/g, (a, b) ->
      return getWholeScssFile(syspath.join(syspath.dirname(filePath), b), imports) + '\n'
  else
    return ''

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

        txt = getWholeScssFile path

        sass.render {
            data: txt,
            includePaths: [dir],
            outputStyle: "expanded"
        }, ( err, result ) ->
          if err
              fail( err.file + ' at line ' + err.line + ' column ' + err.column + '\n' + err.message )
          else
              succ( result.css.toString() )
    catch err
        fail( err )




