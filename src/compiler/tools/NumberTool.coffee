exports.interger = ( v ) ->
	return ~~v 

exports.currency = ( v ) ->
	return '$' + v

exports.percent = ( v ) ->
	return v * 100 + '%'

exports.format = ( v ) ->
	reuturn Math.round( v * 10 ) / 10