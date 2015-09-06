exports.contentType = "javascript"
exports.process = (txt, path, module, cb) ->
    cb null, "module.exports=#{txt}"
