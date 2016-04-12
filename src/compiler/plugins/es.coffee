utils = require '../../util'
Package = require '../../package'
syspath = require 'path'
babel = require 'babel-core'
es2015 = require('babel-preset-es2015')
react = require('babel-preset-react')

getBabelConfig = ( configPath ) ->
    return null unless utils.path.exists configPath
    config = utils.file.io.readJSON configPath
    return config

exports.contentType = "javascript"

exports.process = (txt, path, module, cb) ->
    try
        console.log('here ....');
        name = syspath.basename path, '.es'

        cwd = process.cwd()
        # 先寻找最近的fekit_modules目录 
        basepath = utils.path.closest cwd , Package.FEKIT_MODULE_DIR , true
        # 如果没有，再寻找最近的fekit.config
        basepath = utils.path.closest cwd , 'fekit.config' unless basepath 
        # 再没有，则使用当前目录
        basepath = cwd unless basepath

        babel_config_path = utils.path.join( basepath , '.babelrc' )

        babelConfig = getBabelConfig babel_config_path

        babelConfig = {presets: [es2015, react]} unless babelConfig
        console.log(babelConfig);
        txt = (babel.transform txt, babelConfig).code

        cb null, txt
    catch err
        cb err