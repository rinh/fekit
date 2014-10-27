syspath = require 'path'

exports.contentType = "javascript"

exports.process = (ori_txt, path, module, cb) ->
    s = JSON.stringify

    scope = path.replace (syspath.join module.config.config.fekit_root_dirname, 'src/'), ''
    scope = scope.replace syspath.extname(scope) , ''
    scope = scope.split syspath.sep

    code = "module.exports = #{s(ori_txt)};"

    cb null, code
