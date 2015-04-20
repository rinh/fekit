utils = require '../util'
prompt = require 'prompt'

exports.usage = "初始化目录为标准[fekit项目]"

exports.set_options = ( optimist ) ->
    optimist.usage('init [新建目录名]')
    optimist

exports.run = ( options ) ->
    start( options )


#=====================

schema = 
    properties : 
        name : 
            pattern : /^[0-9a-z\-_]+$/i 
            message : '只允许输入字母、连接符、下划线'
            required: true
            description: 'Enter project name'
        version : 
            pattern : /^\d{1,2}\.\d{1,2}\.\d{1,2}$/
            message : '只允许输入如 1.2.3'
            required: true
            description: 'Enter project version'
            default: '0.0.0'


start = ( opts ) ->
    
    base = opts.cwd
    base = utils.path.join( opts.cwd , opts._[1] ) if opts._[1]

    config_path = utils.path.join base , 'fekit.config'

    return utils.logger.error('初始化失败, 已经存在 fekit.config 文件') if utils.path.exists config_path

    #-------

    name = utils.path.basename( base )

    schema.properties.name.default = name

    prompt.start()

    prompt.get schema , ( err , result ) ->

        return if err 

        config = utils.config.createEmptySchema()

        config.name = result.name

        config.version = result.version

        utils.file.mkdirp utils.path.join( base , 'src' )

        utils.file.io.write utils.path.join( base , 'README.md' ) , ""

        environment = """
local:
    DEBUG: true

dev:
    DEBUG: true

beta:
    DEBUG: false

prd:
    DEBUG: false
        """

        utils.file.io.write utils.path.join( base , 'environment.yaml' ) , environment

        utils.file.io.write config_path , JSON.stringify( config , {} , 4 )

        utils.logger.log("初始化成功.")



