exports.getSystemDate = () ->
	return new Date()

exports.getYear = () ->
	return new Date().getFullYear()

exports.getMonth = () ->
	return new Date().getMonth() + 1

exports.getDay = () ->
	return new Date().getDate()
	