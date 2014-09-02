启动 fekit server 时，可以通过读取配置，进行不同的 mock 处理    
如: fekit server -m [mock.js](https://raw.githubusercontent.com/rinh/fekit/master/docs/mock/sample.js)

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

* 配置文件定义一个 node 模块
* key 或 `pattern` 属性是字符串，准确匹配 url（包括 query）
* `pattern` 属性是正则表达式，正则匹配 url
* `jsonp` 属性指定 jsonp 请求的回调函数名，默认为 `"callback"`
* value 或 `respondwith` 属性给定文件均为配置文件相对路径
* value 或 `respondwith` 属性有如下方案：


### raw
如 `"/exact/match/1"`，`"/exact/match/5"`，`/^\/regex\/match\/a\/\d+/`，指定文件是 .json 文件，.json 文件内容原样返回


### mockjson
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
如 `"/exact/match/3"`，代理请求指定地址，并将请求结果返回

### action
如 `"/exact/match/4"`，自定义请求处理函数，给定 js 文件代码如下：

    module.exports = function(req, res, context) {
        res.end(JSON.stringify({
            "exact": true
        }));
    };

或如 `/^\/regex\/match\/b\/\d+/` 直接写在配置文件中
