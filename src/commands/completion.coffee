exports.usage = "TAB 自动补全"
exports.run = (options) ->
    if process.platform is "darwin" # "win32"
        console.error "fekit completion 不支持 windows"
        return null

