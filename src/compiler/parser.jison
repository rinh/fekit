%lex

%s l_comment req

%%

"/*"                        {  this.begin('l_comment'); return 'L_COMMENT_START';  }
<l_comment>"*/"             {  this.popState(); return 'L_COMMENT_END';  }
<l_comment>(.|\n)           {  return 'L_COMMENT_CHR';  }

^[ ]*"//".*                 {  return 'S_COMMENT';  }

(require|\@import\s+url)\s* {  this.begin('req'); return 'REQUIRE_START'; }
<req>"("\s*                 {  return 'REQUIRE_LOP'; }
<req>\s*")"                 {  this.popState(); return 'REQUIRE_ROP'; }
<req>\'.*\'                 {  return 'REQUIRE_CHR'; }
<req>\".*\"                 {  return 'REQUIRE_CHR'; }

(.|\n)                      {  return 'CONTENT';  }

<<EOF>>                     {  return 'EOF';  }

/lex

%%

program
    : statements EOF        { $$ = o('PROGRAM',$1); return $$; }
    | EOF                   { }
    ;

statements
    : statements statement  { $$ = o('STATEMENTS',[].concat( $1 , $2 )); }
    | statement             { $$ = o('STATEMENTS',[ $1 ]); }
    ;

statement
    : comment               { $$ = o('COMMENT_STATEMENT', $1 ); }
    | S_COMMENT             { $$ = o('LINE_COMMENT_STATEMENT' , $1 ); }
    | CONTENT               { $$ = o('CONTENT_STATEMENT', $1 ); }
    | require               { $$ = o('REQUIRE_STATEMENT', $1 ); }
    ;

require
    : REQUIRE_START REQUIRE_LOP require_chr REQUIRE_ROP   { $$ = o('REQUIRE', $1, $2, $3, $4 ); }
    ;


require_chr
    : require_chr REQUIRE_CHR       { $$ = o('REQUIRE_CHR', $1 , $2); }
    | REQUIRE_CHR               { $$ = o('REQUIRE_CHR', $1); }
    ;


comment 
    : L_COMMENT_START comment_chr L_COMMENT_END  {  $$ = o('COMMENT', $1 , $2 , $3);  } 
    ;

comment_chr
    : comment_chr L_COMMENT_CHR     { $$ = o('COMMENT_CHR', $1 , $2); }
    | L_COMMENT_CHR                 { $$ = o('COMMENT_CHR', $1 ); }
    ;

%%

// -------------  common -------------

var _ = require("underscore");
var util = require("util");
var EventEmitter = require('events').EventEmitter;

function AstNode() {};

util.inherits(AstNode, EventEmitter);

_.extend( AstNode.prototype , {

    setParam : function( param ) {
        this.params.push( param );
        this["$"+this.params.length] = param;
    } , 

    print : function(){
        var r = [];
        this.params.forEach(function(i){
            r.push( typeof i.print != 'undefined' ? i.print() : i );
        });
        var obj = {
            target : this ,
            source : r.join('')
        };
        this.emit('printing',obj)
        return obj.source;
    },

    find : function( name , cb ) {
        var r = [];
        this.params.forEach(function(i){
            if( i.name == name ) {
                r.push(i);
                if( cb ) { cb(i); }    
            } else if( i.find ) {
                r = r.concat( i.find( name , cb ) );
            }
        });
        return r;
    }
});



function defineNode( name , prop ) {
    var CLS_NAME = name + "_AstNode";
    var CLS = parser.yy[ CLS_NAME ];
    if( !CLS ) {
        parser.yy[ CLS_NAME ] = CLS = function( name ) {
            this.name = name;
            this.params = [];
        };
    }
    _.extend( CLS.prototype , AstNode.prototype );
    _.extend( CLS.prototype , prop );
};

function o( name ) {
    var CLS = parser.yy[ name + "_AstNode" ];
    if( !CLS ) {
        defineNode( name );
        CLS = parser.yy[ name + "_AstNode" ];
    }
    var n = new CLS( name );
    for( var i = 1; i < arguments.length; i++ ) {
        var param = arguments[i];
        n.setParam( param );
    }
    return n;
}

// --------------

defineNode('STATEMENTS',{
    print : function(){
        var lines = []
        this.$1.forEach(function(i){
            lines.push( i.print() );
        });
        var obj = {
            target : this ,
            source : lines.join('')
        }
        this.emit('printing',obj)
        return obj.source;
    } , 
    find : function( name , cb ){
        var r = [];
        this.$1.forEach(function(i){
            if( i.name ) {
                if( i.name == name + '_AstNode' ) {
                    r.push(i);
                    if( cb ) { cb(i); }    
                } else if( i.find ) {
                    r = r.concat( i.find( name , cb ) );
                }
            }
        });
        return r;   
    }
});

defineNode('REQUIRE',{
    getPath : function(){
        return this.$3.$1.replace(/("|')/g,"");
    }
});


// --------------

exports.defineNode = defineNode;
