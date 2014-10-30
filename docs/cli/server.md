server
========

###usage

    fekit server  -p <portNo>, --port        服务端口号, 一般无法使用 80 时设置, 并且需要自己做端口转发                     
    fekit server  -r <原路径名><路由后的物理路径>, --route       路由,将指定路径路由到其它地址, 物理地址需要均在当前执行目录下。转换旧项目(qzz)的url，方便开发
    fekit server  -c, --combine     指定所有文件以合并方式进行加载, 启动该参数则请求文件不会将依赖展开                    
    fekit server  -n, --noexport    默认情况下，/prd/的请求需要加入export中才可以识别。 指定此选项则可以无视export属性    
    fekit server  -t, --transfer    当指定该选项后，会识别以前的 qzz 项目 url                             
    fekit server  -b <目录名>, --boost       可以指定目录进行编译加速。                               
    fekit server  -s <ssl证书>, --ssl         指定ssl证书文件，后缀为.crt                                     
    fekit server  -m <mock文件>, --mock        指定mock配置文件                                            
    fekit server  -l, --livereload  是否启用livereload                                        
    fekit server  -h, --help        查看帮助         
       
       
###description
mock文件,是一个针对域名作的代理服务配置文件

    module.exports = {
        "/exact/match/1": "exact.json",
        "/exact/match/2": "exact.mockjson",
        "/exact/match/3": "https://raw.githubusercontent.com/rinh/fekit/master/docs/mock/exact.json",
        "/exact/match/4": "exact.js",
        rules: [{
            pattern: "/exact/match/5",
            respondwith: "exact.json"
        }, {
            pattern: /^\/regex\/match\/a\/\d+/,
            respondwith: "regex.json",
            jsonp: "__jscallback"
        }, {
            pattern: /^\/regex\/match\/b\/\d+/,
            respondwith: function(req, res, context) {
                res.end(JSON.stringify(Object.keys(context)));
            }
        }]
    };

* key 可以是正则表达式, 也可以是字符串
        * 默认的 value 是string, uri以后缀名或内容判断 ACTION
        有四种类型
            .json -> raw
            .js   -> action
            .mockjson -> mockjson
            http:// 或 https://  -> proxy_pass
* 配置文件定义一个 node 模块
* key 或 `pattern` 属性是字符串，准确匹配 url（包括 query）
* `pattern` 属性是正则表达式，正则匹配 url
* `jsonp` 属性指定 jsonp 请求的回调函数名，默认为 `"callback"`
* value 或 `respondwith` 属性给定文件均为配置文件相对路径
* value 或 `respondwith` 属性有如下方案：


### raw
    ###
        配置案例
        "raw" : "./url.json"
    ###
如 `"/exact/match/1"`，`"/exact/match/5"`，`/^\/regex\/match\/a\/\d+/`，指定文件是 .json 文件，.json 文件内容原样返回


### mockjson
    ###
        配置案例
        "mockjson" : "./a.mockjson"

        使用方式见：https://github.com/mennovanslooten/mockJSON
    ###
如 `"/exact/match/2"`，指定文件是 .mockjson 文件，如下：

    {
        "fathers|5-10": [{
            "id|+1": 0,
            "married|0-1": true,
            "name": "@MALE_FIRST_NAME @LAST_NAME",
            "sons": null,
            "daughters|0-3": [{
                "age|0-31": 0,
                "name": "@FEMALE_FIRST_NAME"
            }]
        }]
    }

遵循 [mockJSON](http://experiments.mennovanslooten.nl/2010/mockjson/) 的写法，生成随机数据返回


### proxy_pass
    ###
        配置案例
        proxy_pass : 'http://l-hslist.corp.qunar.com'
    ###
如 `"/exact/match/3"`，代理请求指定地址，并将请求结果返回

### action
    ###
        配置案例
        "action" : "./url.js"

        在 url.js 中，必须存在
        module.exports = function( req , res , user_config , context ) {
            // res.write("hello");
        }
    ###
如 `"/exact/match/4"`，自定义请求处理函数，给定 js 文件代码如下：

    module.exports = function(req, res, context) {
        res.end(JSON.stringify({
            "exact": true
        }));
    };

或如 `/^\/regex\/match\/b\/\d+/` 直接写在配置文件中
