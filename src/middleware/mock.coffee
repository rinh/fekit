request = require 'request'
urlparser = require 'url'
vm = require 'vm'
utils = require "../util"
util = require "util"
helper_mockjson = require "./helper_mockjson"

###
启动 fekit server 时，可以通过读取配置，进行不同的mock处理
如: fekit server -m ~/myurl.conf

mock.json是一个针对域名作的代理服务配置文件,内容为

    module.exports = {
        * key 可以是正则表达式, 也可以是字符串（但仍然会转为正则表达式执行）
        * value 以不同的配置，进行不同的操作，具体见 ACTION
        * 默认的 value 是string, uri以后缀名或内容判断 ACTION
            .json -> raw
            .js   -> action
            .mockjson -> mockjson
            包含 http:// 或 https://  -> proxy_pass
    }
###
module.exports = ( options ) ->

    return noop unless options.mock or utils.file.exists options.mock
    mock_file = utils.file.io.readbymtime( options.mock )

    return ( req , res , next ) ->
        
        sandbox = 
            module :  
                exports : {}

        # 得到配置文件
        try 
            vm.runInNewContext( exjson( mock_file() ) , sandbox );
        catch err 
            sandbox.module.exports = {}

        # 检查匹配项
        url = req.url
        for key , actions of sandbox.module.exports
            n = key.split "^^^"
            key = new RegExp( n[0] , n[1] ) 
            result = url.match( key ) 
            return do_actions( result , actions , req , res , next ) if result

        next()


## 处理所有 action
do_actions = ( result , actions , req , res , next ) -> 

    actions = switch
        when typeof actions is 'string' then get_actions actions 
        when util.isArray actions then utils.extend( {} , get_actions i for i in actions ) 
        else actions

    jobs = ( { action : ACTION[action_key] , user_config : action_config } for action_key , action_config of actions when ACTION[action_key] )

    context = 
        req : req 
        res : res
        result : result
    
    utils.async.series jobs , ( item , done ) ->
                item.action( item.user_config , context , done )
            , ( err ) ->
                if err 
                    utils.logger.error err
                    res.end( err )
                else 
                    res.end()



## 所有 action 的配置解决方案
ACTION = 

    ###
        配置案例
        proxy_pass : 'http://l-hslist.corp.qunar.com'  
    ###
    "proxy_pass" : ( user_config , context , done ) ->

        conf = 
            url : '' 
            set_header : {}

        conf.url = user_config if typeof user_config is 'string'
        conf.urlObject = urlparser.parse( conf.url )

        # --- 处理 request 及 proxy_option
        proxy_option = 
            url : ''
            headers : {}
        req = context.req 

        proxy_option.url = urlparser.format( utils.extend( {} , conf.urlObject , urlparser.parse(req.url) ) )
        proxy_option.headers = utils._.extend( {} , req.headers , {
                host : conf.urlObject.host 
            } , conf.set_header )

        # --- 针对不同请求，进行不同处理
        switch req.method
            when 'GET'
                r = request.get(proxy_option).pipe(context.res)
            when 'POST'
                r = request.post(proxy_option).pipe(context.res)
                
        r.on 'end' , () ->    
            done()


    ###
        配置案例
        "raw" : "./url.json"
    ###
    "raw" : ( user_config , context , done ) ->

        context.res.setHeader "Content-Type", "application/json"

        context.res.write( utils.file.io.read( user_config ) )

        done()

    ###
        配置案例
        "action" : "./url.js"

        在 url.js 中，必须存在 
        module.exports = function( req , res , user_config , context ) {
            // res.write("hello");
        }
    ###
    "action" : ( user_config , context , done ) ->

        act_file = utils.file.io.read( user_config )

        #执行该文件
        sandbox = 
            module : 
                exports : noop

        vm.runInNewContext( act_file , sandbox )

        sandbox.module.exports?( context.req , context.res , user_config , context ) 

        done()

    ###
        配置案例
        "mockjson" : "./a.mockjson"

        使用方式见：https://github.com/mennovanslooten/mockJSON
    ###
    "mockjson" : ( user_config , context , done ) ->

        json = utils.file.io.readJSON( user_config )

        context.res.setHeader "Content-Type", "application/json"

        context.res.write( JSON.stringify helper_mockjson.mockJSON.generateFromTemplate( json ) )

        done()

# ============================


noop = ( req , res , next ) ->
    next()

exjson = ( txt ) ->
    def = ""
    count = 0
    return txt.replace new RegExp( "/(\\\\/|.*?)/([ig]*)(.*?:)" , "ig") , ( $0 , $1 , $2 , $3 ) ->
            return util.inspect( $1 + "^^^" + $2 ) + $3

get_actions = ( actions ) ->
    return switch
            when actions.indexOf('http://') > -1 or actions.indexOf('https://') > -1 then { proxy_pass : actions }
            when utils.path.extname( actions ) is ".mockjson" then { mockjson : actions } 
            when utils.path.extname( actions ) is ".json" then { raw : actions }
            when utils.path.extname( actions ) is ".js" then { action : actions }