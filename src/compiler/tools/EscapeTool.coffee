exports.html = ( str ) ->
	return String( str ).replace( /&(?!\w+;)/g , '&amp;' )
						.replace( /</g , '&lt;' )
						.replace( />/g , '&gt;' )
						.replace( /"/g , '&quot;' )

exports.javascript = ( str ) ->
	return String( str ).replace( /\\/g , '\\\\' )
						.replace( /'/g , '\\\'' )
						.replace( /"/g , '\\\"' )
						.replace( /\//g , '//' )

exports.url = ( str ) ->
	return encodeURIComponent( str )

exports.java = ( str ) ->
	return String( str ).replace( /\\/g , '\\\\' )
						.replace( /\"/g , '\\\"' )

exports.json = ( str ) ->
	return String( str ).replace( /\\/g , '\\\\' )
						.replace( /\"/g , '\\\"' )
						.replace( /\//g , '//' )
