utils = require "../util"
sysurl = require('url')
http = require 'http'
httpProxy = require 'http-proxy'

exports.run = (options) ->

    return unless options.proxy

    rule = options.rule

    return unless rule

    # ----------------

    port = rule.http_port || 10180

    proxy = httpProxy.createProxyServer({});

    proxy.on 'error', (err, req, res) ->
        res.writeHead 500,
            'Content-Type': 'text/plain'
        res.end '[HTTP PROXY ERROR]' + err.toString()

    server = http.createServer (req, res) ->
        u = sysurl.parse( req.url )
        r = rule.match u
        if r
            req.url = r.getURL() if r.getURL()
            proxy.web req, res, { target: r.getFullHost() }
        else
            proxy.web req, res, { target: u.protocol + "//" + u.host }

    utils.logger.log "fekit proxy server 运行成功, 端口为 #{port}."
    server.listen port
