%lex

%s c

%%

"/*"                                                                                { this.begin('c'); return 'COMMENT'; }
<c>"*/"                                                                             { this.popState(); return 'COMMENT'; }
<c>(.|\n)                                                                           { return 'COMMENT'; }

"//".*                                                                              { return 'COMMENT'; }

<INITIAL>"require"[ ]*\([ ]*["](\\["]|\\\n|[^"\n])*["][ ]*\)[ ]*[;]?                { return 'REQUIRE';  }
<INITIAL>"require"[ ]*\([ ]*['](\\[']|\\\n|[^'\n])*['][ ]*\)[ ]*[;]?                { return 'REQUIRE';  }

<INITIAL>"@import"[ ]*"url"[ ]*\([ ]*[^'"]*?[ ]*\)[ ]*[;]?                          { return 'REQUIRE';  }
<INITIAL>"@import"[ ]*"url"[ ]*\([ ]*["](\\["]|\\\n|[^"\n])*["][ ]*\)[ ]*[;]?       { return 'REQUIRE';  }
<INITIAL>"@import"[ ]*"url"[ ]*\([ ]*['](\\[']|\\\n|[^'\n])*['][ ]*\)[ ]*[;]?       { return 'REQUIRE';  }


<INITIAL>["](\\["]|\\\n|[^"\n])*["]                                                 {  return 'STRING';  }
<INITIAL>['](\\[']|\\\n|[^'\n])*[']                                                 {  return 'STRING';  }

<INITIAL>(.|\n)                                                                     {  return 'CONTENT'; }

<INITIAL><<EOF>>                                                                    {  return 'EOF';  }

/lex

%%

program
    : statements EOF        { $$ = $1; return $$; }
    | EOF                   { $$ = []; }
    ;

statements
    : statements statement  { $$ = [].concat($1, $2); }
    | statement             { $$ = [$1]; }
    ;

statement
    : content               { $$ = $1; }
    | REQUIRE               { 
                                var v = $1;
                                v = v.replace( /^.*?\(/ , '' );
                                v = v.replace( /\).*$/ , '' );
                                v = v.replace( /'/g , '' );
                                v = v.replace( /"/g , '' );
                                $$ = { type : 'require' , value : v }; 
                            }
    | STRING                { $$ = $1; }
    | comment               { $$ = $1; }
    ;

content 
    : CONTENT               { $$ = $1; }
    | content CONTENT       { $$ = $1 + $2; }
    ;

comment
    : COMMENT               { $$ = $1; }
    | comment COMMENT       { $$ = $1 + $2; }
    ;

%%

//--------------------

var Compiler = function( ast ) {
    this.ast = ast;
}

Compiler.prototype = {
    
    print : function(){
        var list = []
        for( var i = 0; i < this.ast.length; i++ ) {
            var line = this.ast[i];
            if( typeof line == 'string' ) {
                list.push( line );
            } else {
                var type = line.type;
                if( this[ 'print_' + type ] ) {
                    list.push( this[ 'print_' + type ](line) );
                } else {
                    list.push( this[ 'print_'](line) );
                }
            }
        }
        return list.join('');
    } , 

    find : function( type , cb ){
        var list = []
        type = ( type || "" ).toLowerCase();
        for( var i = 0; i < this.ast.length; i++ ) {
            var line = this.ast[i];
            if( line.type == type ) {
                cb && cb( line );
                list.push( line );
            }
        }
        return list;
    } ,

    defineType : function( type , func ){
        type = ( type || "" ).toLowerCase();
        this[ 'print_' + type ] = func;
    } , 

    //-------------

    print_ : function( line ) {
        if( typeof line == "string" ) {
            return line;
        } else {
            return JSON.stringify( line );
        }
    }

};

//--------------------

exports.parseAST = function( source ){
    var ast = parser.parse.apply(parser, arguments);
    var compiler = new Compiler( ast );
    return compiler;
}





