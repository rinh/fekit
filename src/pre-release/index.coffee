
###
 type: dev | prd
 options: 命令行参数
###
exports.exec = ( type , options , done ) ->
    
    require('./css-md5').exec type , options , () ->
        require('./css-replace-domain').exec type , options , () ->
            require('./css-domain-mapping').exec type , options , () ->
                done()