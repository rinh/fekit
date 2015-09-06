# 增加 fekit.hosts 文件
###
# 指定 http 代理端口 (--proxy 配置)
http_port 10180
# 指定 https 代理端口(--proxy 配置)
https_port 10430
# 指定 host(--proxy 配置)
127.0.0.1 qunarzz.com
# rewrite host 目录(--proxy 配置)
proxy_pass http://qunarzz.com/home/(.*)   http://119.254.124.13/$1
# reverse host 反向代理域名(--reverse 配置) ip 不写，则从 dns 获取
reverse_host qunarzz.com 119.254.124.12
###

utils = require '../util'
sysurl = require 'url'

class Rule
    constructor:( @_list ) ->
        @config = {}
        @proxy_pass_hosts = {}
        @ip_hosts = {}
        @reverse_hosts = {}
        for line in @_list
            line = line.trim()
            continue if line.charAt(0) is "#"
            line = line.replace(/\s+/g,' ').split(' ')
            switch line[0]
                when "https_port" or "http_port"
                    @config[line[0]] = line[1]
                when "proxy_pass"
                    @proxy_pass_hosts[line[1]] = line[2]
                when "reverse_host"
                    @reverse_hosts[line[1]] = line[2] or ''
                else
                    ip = line.shift()
                    for h in line
                        @ip_hosts[h] = @ip_hosts[h] or []
                        @ip_hosts[h] = ip

    match: ( uri ) ->
        _m = new Matcher( uri )
        _m.to = "http://" + @ip_hosts[uri.host]

        for reg_host , rep_host of @proxy_pass_hosts
            m = uri.href.match reg_host
            if m
                _m.regmatcher = m
                _m.ret = rep_host
                _u = sysurl.parse( rep_host )
                _m.to = _u.protocol + "//" + _u.host
                break

        return null if not m and not @ip_hosts[uri.host]

        return _m


Rule.load = ( path ) ->
    host_config_path = utils.path.join utils.path.get_user_home() , "fekit.hosts"
    if utils.path.exists path
        return new Rule( utils.file.io.readlines(path) )
    else if utils.path.exists host_config_path
        return new Rule( utils.file.io.readlines(host_config_path) )
    else
        utils.logger.error "找不到 fekit.hosts 配置文件, 它应该存在于 #{host_config_path}"
        return null

# ---------

class Matcher

    constructor: ( @uri ) ->

    getURL:()->
        ret = null
        if @regmatcher and @ret
            $ = @regmatcher.slice(1)
            ret = @ret
            for val , idx in $
                ret = ret.replace new RegExp("\\$" + (idx+1)) , val
        return ret

    getFullHost:() ->
        return @to

module.exports = Rule
