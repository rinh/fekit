syspath = require 'path'
compiler = require "../compiler/compiler"
utils = require "../util"
uglifycss = require("uglifycss")
jsp = require("uglify-js").parser;
pro = require("uglify-js").uglify;


exports.get_dist_filename = ( srcpath ) ->
        t = compiler.getContentType( srcpath )
        switch t.toLowerCase()
            when "javascript"
                ext = ".js"
            when "css"
                ext = ".css"
        _extname = utils.path.extname( srcpath )
        _basename = utils.path.basename( srcpath , _extname )
        return _basename + ext


exports.minCode = minCode = ( extname , source , options = {} , fekitconfig = {} ) ->

    if options.nopack then return source

    switch extname
        when ".css"
            if options.noSplitCSS
                final_code = uglifycss.processString( source , fekitconfig?.min?.config?.uglifycss )
            else
                final_code = uglifycss.processString( source , fekitconfig?.min?.config?.uglifycss ).replace( /}/g , "}\n" )
        when ".js"
            try
                ast = jsp.parse( source )
                ast = pro.ast_mangle( ast , fekitconfig?.min?.config?.uglifyjs?.ast_mangle )
                ast = pro.ast_squeeze( ast , fekitconfig?.min?.config?.uglifyjs?.ast_squeeze ) if fekitconfig?.minconfig?.uglifyjs?.ast_squeeze
                final_code = pro.gen_code( ast , fekitconfig?.min?.config?.uglifyjs?.gen_code )
            catch err
                console.info( err )
                return null


    return final_code
