crypto = require 'crypto' 
_ = require 'underscore'
_.str = require 'underscore.string'

###
    分析 background-image 的图片，将其分发到不同的域名中 
    多域名控制格式为
    (注释)|*@domain_mapping source.qunar.com => img1.qunarzz.com img2.qunarzz.com img3.qunarzz.com img4.qunarzz.com*|
###
exports.ddns = ( css_code , module ) ->
    
    fileconfig = module.root_module.config.config.getExportFileConfig( module.root_module.path.getFullPath() ) 

    unless fileconfig.domain_mapping

        RE_DOMAINS_CONF = /\/\*@domain_mapping(.+)\*\//

        mc = css_code.match(RE_DOMAINS_CONF)

        return css_code unless mc

        return css_code unless ~mc[1].indexOf( "=>" )

        r = mc[1]

    else 

        r = fileconfig.domain_mapping


    conf = r.split('=>')

    return css_code unless _.str.trim(conf[0])
    return css_code unless _.str.trim(conf[1])

    # 创建原多域名匹配
    _ori = _.str.trim(conf[0]).replace(/\s+/g,' ').split(' ')

    RE_DOMAIN = new RegExp "(http://)(" + _ori.join('|').replace(/\./g,'\\.') + ")(/[^\"'\\s\\)]+)" , "g";

    # 创建替换域名

    _dms = _.str.trim(conf[1]).replace(/\s+/g,' ').split(' ')

    _map = {}

    return css_code.replace RE_DOMAIN , ( $0 , http , domain , path ) ->

        if _map[$0]
            return http + _dms[_map[$0]] + path 
        else 
            _idx = pathToInt $0 , _dms.length
            _map[$0] = _idx
            return http + _dms[_idx] + path 


exports.contentType = "css"

exports.process = ( txt , path , module , cb ) ->
    cb( null , exports.ddns( txt , module ) )


#--------------------

pathToInt = ( str , number ) ->

    d = crypto.createHash("md5").update(str).digest('hex')

    arr = d.split("")
    st = 0

    arr.forEach (chr, i) ->
        c = parseInt(chr, 16)
        st = ((st * 16 + c) % number)
    
    return st







