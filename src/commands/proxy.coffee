proxy = require "mitm-proxy"

exports.usage = "创建http代理服务器 , 默认端口10086"

exports.set_options = ( optimist ) ->

    optimist.alias 'p' , 'port'
    optimist.describe 'p' , '自定义代理服务的服务端口号'


exports.run = ( options ) ->
        proxyPort = options.port||10086

        new proxy({proxy_port: proxyPort, mitm_port: "10012" , verbose: true});
        console.log "[LOG]: fekit proxy 运行成功, 端口为 #{proxyPort}."
        console.log "[LOG]: 按 Ctrl + C 结束进程." 
