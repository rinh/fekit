fs = require 'fs'

getVal = ( regexpResult ) ->
    for r , idx in regexpResult 
        if idx is 0 then continue
        return r if r 


convertRegexp = ( str , flag ) ->
    str = str.replace(/\s/g,'').replace('{space}',' ')
    return new RegExp str , flag 

_is_break = ( str , idx ) ->
    return true if idx < 0
    return true if idx > str.length
    return true if str.charAt(idx) is '\n'
    return false

exports.find_line_from_str = find_line_from_str = ( str , index , is_fullline ) ->
    start = index 
    end = index 
    while !_is_break( str , start )
        start--
    if is_fullline
        while !_is_break( str , end )
            end++
        return str.substring( start , end ).replace(/\n/g,'')
    else 
        return str.substring( start , index ).replace(/\n/g,'')

exports.is_line_end = is_line_end = ( str , index ) ->
    s = ""
    while !_is_break( str , index ) 
        s += str[index]
        index++
    return s.replace(/\s*/g,'') is ""

parse = ( str ) -> 
    
    result = []

    regstr = convertRegexp("""
    (
        ?: [{space}]*require\\s*\\(\\s*'([^']+)'\\s*\\)
        |  [{space}]*require\\s*\\(\\s*"([^"]+)"\\s*\\)
        |  [{space}]*@import\\s+url\\s*\\(\\s*'([^']+)'\\s*\\)
        |  [{space}]*@import\\s+url\\s*\\(\\s*"([^"]+)"\\s*\\)
        |  [{space}]*@import\\s+url\\s*\\(\\s*([^\\)]+)\\s*\\)
    )
    [{space};]*
    """ , "g")

    prefix_comment = convertRegexp("""
        ^\\s*\\/\\/
    """)

    start = end = 0
    while( ( r = regstr.exec(str) ) isnt null )
        end = regstr.lastIndex - r[0].length;

        # 添加匹配内容前面的内容
        result.push( str.substring( start , end ) )

        # 判断require之前的字符是否符合规则
        # 不符合则不认为该匹配为正确的 require 
        _line = find_line_from_str( str , end , false )
        if prefix_comment.test( _line ) or _line.charAt( _line.length - 1 ) is '.'
            result.push( r[0] )
        else
            result.push({
                type : 'require' , 
                value : getVal(r) , 
                # 确认 require 后是否没有任何内容
                is_line_end : is_line_end( str , regstr.lastIndex )
            })
            
        start = regstr.lastIndex

    result.push( str.substring( start ) )

    return result


#--------------------
class Compiler
    
    constructor: (@ast) ->

    print: ->
        list = []
        i = 0
        while i < @ast.length
            line = @ast[i]
            if typeof line is "string"
                list.push line
            else
                type = line.type
                if this["print_" + type]
                    list.push this["print_" + type](line)
                else
                    list.push this["print_"](line)
            i++
        list.join ""

    find: (type, cb) ->
        list = []
        type = (type or "").toLowerCase()
        i = 0

        while i < @ast.length
            line = @ast[i]
            if line.type is type
                cb and cb(line)
                list.push line
            i++
        list

    defineType: (type, func) ->
        type = (type or "").toLowerCase()
        this["print_" + type] = func

    
    #-------------

    print_: (line) ->
        if typeof line is "string"
            line
        else
            JSON.stringify line


#--------------------

exports.parseAST = (source) ->
    ast = parse(source)
    compiler = new Compiler(ast)
    compiler

