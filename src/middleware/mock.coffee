request = require 'request'
urlparser = require 'url'
vm = require 'vm'
utils = require "../util"
util = require "util"
helper_mockjson = require "./helper_mockjson"
qs = require "querystring"

###
启动 fekit server 时，可以通过读取配置，进行不同的mock处理
如: fekit server -m ~/myurl.conf

mock.json是一个针对域名作的代理服务配置文件,内容为
    module.exports = {
        * key 可以是正则表达式, 也可以是字符串
        * value 以不同的配置，进行不同的操作，具体见 ACTION
        * 默认的 value 是string, uri以后缀名或内容判断 ACTION
            .json -> raw
            .js   -> action
            .mockjson -> mockjson
            包含 http:// 或 https://  -> proxy_pass
    }
###
module.exports = (options) ->
    return noop unless options.mock and utils.path.exists options.mock

    utils.logger.log "成功加载 mock 配置 #{options.mock}"
    mock_file = utils.file.io.readbymtime(options.mock)

    return (req, res, next) ->
        sandbox =
            module :
                exports : {}

        # 得到配置文件
        try
            vm.runInNewContext(exjson(mock_file()), sandbox)
        catch err
            sandbox.module.exports = {}
            utils.logger.error "mock 配置文件出错 #{err.toString()}"

        # 检查匹配项
        rules = sandbox.module.exports.rules or []
        delete sandbox.module.exports.rules

        for key, action of sandbox.module.exports
            pieces = key.split "^^^"
            pattern = if pieces.length is 2 then RegExp pieces... else key
            rules.push
                pattern: pattern,
                respondwith: action

        url = req.url
        for rule in rules
            if util.isRegExp rule.pattern
                result = url.match rule.pattern
            else
                result = url.indexOf(rule.pattern) is 0
            return do_actions(result, rule, req, res, options) if result

        next()

## 处理所有 action
do_actions = (result, rule, req, res, options) ->
    actions = rule.respondwith
    actions = switch
        when typeof actions is 'string'
            get_actions actions
        when typeof actions is 'function'
            action:
                actions
        # 多种 action
        # when util.isArray actions
        #     a = {}
        #     for k in (get_actions i for i in actions)
        #         a = utils.extend(a, k)
        #     a
        else
            {}

    jobs = ({
            action: ACTION[action_key],
            user_config: action_config
        } for action_key, action_config of actions when ACTION[action_key])

    context =
        req     : req
        res     : res
        result  : result
        rule    : rule
        options : options

    utils.async.series jobs, (item ,done) ->
            item.action(item.user_config, context, done)
        , (err) ->
            if err
                utils.logger.error err
                res.end err
            else
                res.end()


## 所有 action 的配置解决方案
ACTION =
    ###
        配置案例
        proxy_pass : 'http://l-hslist.corp.qunar.com'
    ###
    "proxy_pass": (user_config, context, done) ->
        conf =
            url: ''
            set_header: {}

        conf.url = user_config if typeof user_config is 'string'
        conf.urlObject = urlparser.parse(conf.url)
        conf.qsObject = qs.parse conf.urlObject.query

        # --- 处理 request 及 proxy_option
        proxy_option =
            url: ''
            headers: {}
        req = context.req

        urlObject = urlparser.parse req.url
        qsObject = qs.parse urlObject.query

        conf.urlObject.query = qs.stringify(utils.extend({}, conf.qsObject, qsObject))
        conf.urlObject.search = "?#{conf.urlObject.query}"
        proxy_option.url = urlparser.format(conf.urlObject)
        proxy_option.headers = utils._.extend({}, req.headers, {
                host: conf.urlObject.host
            } , conf.set_header)

        # --- 针对不同请求，进行不同处理
        switch req.method
            when 'GET'
                r = request.get(proxy_option).pipe(context.res)
            when 'POST'
                proxy_option.form = req.body 
                r = request.post(proxy_option).pipe(context.res)

        r.on 'end', () ->
            done()


    ###
        配置案例
        "raw" : "./url.json"
    ###
    "raw": (user_config, context, done) ->
        jsonp = context.rule.jsonp or 'callback'
        callback = val for key, val of context.req.query when (key is jsonp)
        jsonstr = read(context, user_config)
        context.res.setHeader "Content-Type", "application/json"

        if callback
            context.res.setHeader "Content-Type", "application/x-javascript"
            jsonstr = "#{callback}(#{jsonstr.trim()})" if callback

        context.res.write(jsonstr)
        done()

    ###
        配置案例
        "action" : "./url.js"

        在 url.js 中，必须存在
        module.exports = function( req , res , user_config , context ) {
            // res.write("hello");
        }
    ###
    "action": (user_config, context, done) ->
        unless typeof user_config is 'function'
            act_file = read(context, user_config)
            #执行该文件
            sandbox =
                module:
                    exports: noop
            vm.runInNewContext(act_file, sandbox)
            sandbox.module.exports?(context.req, context.res, context)
        else
            user_config context.req, context.res, context
        done()

    ###
        配置案例
        "mockjson" : "./a.mockjson"

        使用方式见：https://github.com/mennovanslooten/mockJSON
    ###
    "mockjson": (user_config, context, done) ->
        jsonp = context.rule.jsonp or 'callback'
        callback = val for key, val of context.req.query when (key is jsonp)
        dir = utils.path.dirname context.options.mock
        json = utils.file.io.readJSON(utils.path.join(dir, user_config))
        jsonstr = JSON.stringify helper_mockjson.mockJSON.generateFromTemplate(json)
        context.res.setHeader "Content-Type", "application/json"

        if callback
            context.res.setHeader "Content-Type", "application/x-javascript"
            jsonstr = "#{callback}(#{jsonstr})" if callback

        context.res.write(jsonstr)
        done()


noop = (req, res, next) ->
    next()

exjson = module.exports.exjson = (txt) ->
    return txt.replace new RegExp("\/(.+)\/([i]*)(\\s*:\\s*)(.+)", "ig"), ($0, $1, $2, $3, $4) ->
        return util.inspect($1 + "^^^" + $2) + $3 + $4

get_actions = (actions) ->
    return switch
        when (actions.indexOf 'http://') is 0 or (actions.indexOf 'https://') is 0
            {proxy_pass: actions}
        when (utils.path.extname actions) is ".mockjson"
            {mockjson: actions}
        when (utils.path.extname actions) is ".json"
            {raw: actions}
        when (utils.path.extname actions) is ".js"
            {action: actions}

read = (context, partial_path) ->
    dir = utils.path.dirname context.options.mock
    return utils.file.io.read(utils.path.join(dir, partial_path))
