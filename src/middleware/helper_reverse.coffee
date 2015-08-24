http = require 'http'
dns = require 'dns'
utils = require "../util"

domains = {}

mime_config =
    ".js" : "application/javascript"
    ".css" : "text/css"

charset = ";charset=UTF-8"

writeHeader = ( res, code, type , domain) ->
    res.writeHead code, {
        'Content-Type': mime_config[type] + charset,
        'Server': "Fekit - Remote File From #{domain.address} (" + (if domain.custom then 'Custom' else 'Online') + ")"
    }

module.exports = {
    load: ( options ) ->
        return unless options.reverse

        for domain,address of options.rule.reverse_hosts
            if address
                domains[domain] = {
                    custom: true,
                    address: address
                }
            else
                closure = (domain) ->
                    dns.resolve4 domain, (err, addresses) ->
                        if !err
                            domains[domain] =
                                custom: false,
                                address: addresses[0]
                closure(domain)

    exists: ( domain ) ->
        return !!domains[domain]

    get: ( domain ) ->
        domains[domain]

    request: ( headers , protocol, host , port , pathname , response , type ) ->

        req = http.request  {
            host: domains[host].address,
            port: port?.substring(1) or 80,
            headers: {
                host: headers.host,
                "user-agent": headers["user-agent"]
            },
            path: "#{protocol}://#{host}#{port}#{pathname}"
        }, ( res ) ->
            data = ''

            res.setEncoding 'utf8'

            res.on 'data' , ( chunk ) ->
                data += chunk

            res.on 'end' , () ->
                writeHeader response , 200 , type , domains[host]
                response.end( data )

            res.on 'error', ( err ) ->
                writeHeader response , 500 , type, domains[host]
                utils.logger.error err
                response.end err

        req.on 'error', ( err ) ->
            writeHeader response , 500 , type, domains[host]
            utils.logger.error err
            response.end err

        req.end()
}
