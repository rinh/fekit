slice = ( arry , pos ) ->
	return Array.prototype.slice.call arry , pos

exports.add = ( num1 , num2 ) ->
	v = 0
	for tmp in arguments
		v += parseFloat(tmp)
	return v

exports.sub = ( num1 , num2 ) ->
	v = parseFloat( num1 )
	for tmp in slice( arguments , 1)
		v -= parseFloat(tmp)
	return v

exports.mul = ( num1 , num2 ) ->
	v = 1
	for tmp in arguments
		v *= parseFloat(~~tmp)
	return v

exports.div = ( num1 , num2 ) ->
	v = parseFloat(num1)
	for tmp in slice( arguments , 1)
		tmp = parseFloat(tmp)
		if tmp is 0
			return null
		v /= tmp
	return v

exports.max = ( num1 , num2 ) ->
	v = parseFloat(num1)
	for tmp in slice( arguments , 1 )
		tmp = parseFloat(tmp) 
		v < tmp and (v = tmp)
	return v

exports.min = ( num1 , num2 ) ->
	v = parseFloat(num1)
	for tmp in slice( arguments , 1 )
		tmp = parseFloat(tmp) 
		v > tmp and (v = tmp)
	return v

exports.pow = ( num1 , num2 ) ->
	if not num1 or not num2
		return null
	return num1 ** num2 

exports.floor = ( num1 , num2 ) ->
	if not num1 or not num2
		return null
	return num1 // num2 

exports.idiv = ( num1 , num2 ) ->
	if not num1 or not num2 or ~~num2 is 0
		return null
	return ~~( ~~num1 / ~~num2 )

exports.mod = ( num1 , num2 ) ->
	if not num1 or not num2 or ~~num2 is 0
		return null
	return ~~( ~~num1 % ~~num2 )

exports.abs = ( num ) ->
	if not num
		return null
	return Math.abs( parseFloat( num ) )

exports.ceil = ( num ) ->
	if not num
		return null
	return ~~Math.ceil( parseFloat( num ) )

exports.random = () ->
	return Math.random()