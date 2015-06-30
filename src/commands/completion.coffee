exports.usage = "TAB 自动补全"


dumpScript = () ->
    console.log "kkk"

exports.run = (options) ->
    if process.platform is "win32"
        console.error "fekit completion 不支持 windows"
        return null

    # if the COMP_* isn't in the env, then just dump the script.
    if undefined in [process.env.COMP_CWORD, process.env.COMP_LINE, process.env.COMP_POINT]
        return dumpScript()

    console.error(process.env.COMP_CWORD)
    console.error(process.env.COMP_LINE)
    console.error(process.env.COMP_POINT)

