fs = require 'fs'

getVal = ( regexpResult ) ->
    for r , idx in regexpResult 
        if idx is 0 then continue
        return r if r 


convertRegexp = ( str ) ->
    str.replace(/\s/g,'').replace('{space}',' ')


parse = ( str ) -> 
    
    result = []

    regstr = convertRegexp("""
    (
        ?: require\\s*\\(\\s*'([^']+)'\\s*\\)
        |  require\\s*\\(\\s*"([^"]+)"\\s*\\)
        |  @import\\s+url\\s*\\(\\s*'([^']+)'\\s*\\)
        |  @import\\s+url\\s*\\(\\s*"([^"]+)"\\s*\\)
        |  @import\\s+url\\s*\\(\\s*([^\\)]+)\\s*\\)
    )
    [{space};]*
    """)

    REG = new RegExp regstr , "g"

    start = end = 0
    while( ( r = REG.exec(str) ) isnt null )
        end = REG.lastIndex - r[0].length;
        result.push( str.substring( start , end ) )
        result.push({
            type : 'require' , 
            value : getVal(r)
        })
        start = REG.lastIndex

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

