utils = require '../../util'
css = require './css'
fs = require 'fs'
syspath = require 'path'

sass = require 'node-sass-china'

#=============================

# sass 扩展名
extNames = ['.sass', '.scss'];
# 行号显示位数
digits = 6;

# 修正行号
fixLineNum = (lineNum) ->
  blankNum = digits - (lineNum + '').length;
  for $0 in [1..blankNum]
    lineNum = ' ' + lineNum
  lineNum

# 显示错误上下问
displayErrorContext = (txt, lineNum) ->
  start = lineNum - 5
  lines = txt.split( '\n' ).splice start, 10
  lines = lines.map (line, index) ->
    ln = start + index + 1;
    content = "#{ fixLineNum ln }:#{ if ln is lineNum then '->' else '  '} #{line}";
    content
  lines.join '\n'

# 修正文件路径，自动查找 _前缀 .scss和.sass后缀的文件
fixFilePath = (filePath) ->
  extName = syspath.extname filePath
  baseName = syspath.basename filePath
  dirName = syspath.dirname filePath
  if extName && fs.existsSync filePath
    return filePath

  if !extName
    for eName in extNames
      if fs.existsSync filePath + eName
        return filePath + eName;
      privatePath = syspath.join dirName, '_' + baseName + eName
      if fs.existsSync privatePath
        return privatePath
  else
    privatePath = syspath.join dirName, '_' + baseName
    if fs.existsSync privatePath
      return privatePath

  throw new Error '找不到import文件: ' + filePath

# 修复 window 上 path 的 seq
fixPathSeq = if process.platform is "win32" then (path) ->
  return path.replace /\\/g, '/'
else (path) ->
  return path

# 获得文件拼接后的内容
getWholeScssFile = (filePath, dir, imports) ->
  imports = imports or {}
#  filePath = fixFilePath filePath
  if imports[filePath] isnt true
    imports[filePath] = true
    data = '\n' + new utils.file.reader().read filePath

    # 删除注释
    data = data.replace(/\/\*(.|\s)*?\*\//gm, '').replace(/\n\s*\/\/.*(?=[\n\r])/g, '')
    # 删除多余空行
    data = data.replace /\n+/g, '\n'
    # 分析 import
    data = data.replace /@import(.*);/g, ( $1, $2 ) ->
      ret = ''
      # 匹配 @import url("xxxx");
      content = $2.replace /url\(.*[\'\"]([^\'^\"]+)[\'\"].*\)/g, ( $3, $4 ) ->
        if $4.indexOf('://') > -1
          # http:// 直接忽略，用 node-sass 解析
          ret += "@import url(\"#{$4}\");\n";
        else
          importPath = fixFilePath syspath.join syspath.dirname(filePath), $4
          # 如果是 sass 和 scss 则先编译，再将内容拼接
          if syspath.extname(importPath) in extNames
            try
              txt = getWholeScssFile importPath, dir
              ret += sass.renderSync({
                data: txt,
                includePaths: [dir],
                outputStyle: "expanded"
              }).css.toString() + '\n';
            catch err
              throw new Error "文件 #{filePath} 编译错误: at line #{err.line}  column #{err.column}: #{err.message}\n#{displayErrorContext txt, err.line }"
           else
            # 其他 例如 .css 转换相对路径后，由 node-sass 解析
            relativePath = fixPathSeq syspath.relative dir, importPath
            ret += "@import url(\"#{relativePath}\");\n";
        return ''

      # 匹配 @import "xxxx";
      content.replace /[\'\"]([^\'^\"]+)[\'\"]/g, ( $5, $6 ) ->
        if $6.indexOf('://') > -1
          # http:// 直接忽略，用 node-sass 解析
          ret += "@import \"#{$6}\";\n";
        else
          importPath = fixFilePath syspath.join syspath.dirname(filePath), $6
          # 如果是 sass 和 scss 直接将内容拼接
          if syspath.extname(importPath) in extNames
            ret += getWholeScssFile(importPath, dir, imports) + '\n'
          else
            # 其他 例如 .css 转换相对路径后，由 node-sass 解析
            relativePath = fixPathSeq syspath.relative dir, importPath
            ret += "@import \"#{relativePath}\";\n";
      return ret;

  else
    return ''

#=============================

exports.contentType = "css"

exports.process = (txt, path, module, cb) ->

    dir = syspath.dirname path

    succ = (code) ->
        cb null, (css.ddns code, module)

    fail = (err) ->
        cb err

    try

        txt = getWholeScssFile path, dir

        sass.render {
            data: txt,
            includePaths: [dir],
            outputStyle: "expanded"
        }, ( err, result ) ->
          if err
              fail( "文件#{err.file}编译错误: at line #{err.line} column #{err.column}: #{err.message}\n#{displayErrorContext txt, err.line }" )
          else
              succ( result.css.toString() )
    catch err
        fail( err )




