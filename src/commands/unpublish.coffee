prompt = require 'prompt'
env = require '../env'
request = require 'request'
utils = require '../util'
_ = require 'underscore'
async = require 'async'
semver = require 'semver'

exports.usage = "取消发布特定的组件包"


exports.set_options = ( optimist ) ->
    
    optimist.usage 'unpublish name[@version]'

    optimist


exports.run = ( options ) ->

    spec_pkg = options['_'][1]

    return utils.logger.error('请指定要取消发布的包及版本号.') unless spec_pkg

    name = spec_pkg.split('@')[0]
    version = spec_pkg.split('@')[1]

    if ~spec_pkg.indexOf('@')
        return utils.logger.error('请指定正确的版本号.') unless semver.valid(version)

    # ----- 

    prompt.start()

    prop = 
        properties:
            ensure:
                description: 'are you sure? '
                pattern: /^(y|n|yes|no)$/i
                default: 'no'

    prompt.get prop , ( err , result ) ->

        return if /^(n|no)$/i.test( result.ensure )

        # ----- 

        url = env.getPackageUrl( name , version )

        env.authenticate ( err ) ->

            if err then return utils.logger.error err

            utils.http.del url , {
                    username : env.get('user') 
                    password_md5 : env.getUserPasspharse()
                } , ( err , res , body ) ->

                    data = JSON.parse( body )

                    return utils.logger.error( data.errmsg ) unless data.ret

                    utils.logger.log "#{name} @ #{version or "all"} 删除成功"

