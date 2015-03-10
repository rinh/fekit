syspath = require 'path'
compiler = require "../compiler/compiler"
utils = require "../util"
uglifycss = require("uglifycss")
ujs = require("uglify-js")


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
                toplevel = ujs.parse( source )
                toplevel.figure_out_scope()

                CompressorOptions = fekitconfig?.min?.config?.uglifyjs?.compressor or {
                    drop_console : true
                    drop_debugger : true
                    warnings : false
                }
                compressor = ujs.Compressor( CompressorOptions )
                compressed_ast = toplevel.transform(compressor)
                compressed_ast.figure_out_scope()
                compressed_ast.compute_char_frequency()
                compressed_ast.mangle_names()

                BeautifierOptions = fekitconfig?.min?.config?.uglifyjs?.beautifier or {}

                stream = ujs.OutputStream(BeautifierOptions)
                compressed_ast.print(stream);

                final_code = stream.toString()


    return final_code