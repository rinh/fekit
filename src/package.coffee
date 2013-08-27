fs = require 'fs'
_ = require 'underscore'
semver = require 'semver'
async = require 'async'
env = require './env'
utils = require './util'

class Package

    constructor: ( @name , @semverstr , @basepath ) ->
        # @schema : fekit_package_server GET /pkgname 返回结果
        @schema = null
        # @version 最终选定的版本号 
        @version = null
        # @config 最终选定版本号的 config 内容
        @version_config = null
        # @config 最终选定版本号的 config 内容(fekit.config)
        @fekit_config = null
        @semverstr = unless @semverstr then "*" else @semverstr
        @children = []
        @package_installed_path = utils.path.join @basepath , Package.FEKIT_MODULE_DIR , @name

    # 获取本地入口文件路径
    # 默认入口文件为 src/index， 如果出错则返回 null
    get_local_entry: () ->
        return null if @name is '.' or @name is '..'
        _fekit_conf_path = utils.path.join @package_installed_path , 'fekit.config'
        return null unless utils.path.exists _fekit_conf_path
        _conf = utils.file.io.readJSON _fekit_conf_path
        return utils.path.join( @package_installed_path , ( if _conf.main then _conf.main else "src/index" ) )

    report: () ->
        c = console.info
        c ""

        c "#{@name}@#{@version} #{Package.FEKIT_MODULE_DIR}/#{@name}"

        last = @children.length - 1
        for p , idx in @children
            if idx is last
                c "└── #{p.name}@#{p.version}"
            else
                c "├── #{p.name}@#{p.version}"

        c ""

    preinstall: ( done ) ->

        # 不再进行本地检查
        #return done("'#{@name}' is exists.") if @_check_local_package()

        @_preinstall done


    _preinstall: ( done ) ->

        @_fetch_remote_package_info ( err , schema ) =>

            return done( err ) if err 

            @schema = schema

            @version = semver.maxSatisfying _.keys( @schema.versions ) , @semverstr

            return done( "'#{@name}@#{@semverstr}' is not in the fekit registry." ) if !@version

            @version_config = schema.versions[@version]

            @fekit_config = schema.versions[@version].config

            @_each_dependencies_preinstall( done )


    _each_dependencies_preinstall: ( done ) ->

        _deps = @fekit_config.dependencies or {}

        return done() if _.size( _deps ) is 0

        _basepath = utils.path.join @package_installed_path 

        deps = ( new Package( _name , _ver , _basepath ) for _name , _ver of _deps )

        @children = deps

        async.eachSeries deps 
                        , ( pkg , pkg_done ) -> 
                            pkg._preinstall ( err ) ->
                                pkg_done err
                        , ( err ) ->
                            done( err )


    _each_dependencies_install: ( done ) ->

        pkgname = @name
        version = @version

        async.eachSeries @children 
                        , ( pkg , pkg_done ) ->
                            pkg.install ( err ) ->
                                pkg_done( err )
                        , ( err ) ->
                            done( err , pkgname , version )

    install: ( done ) ->

        self = @

        utils.file.rmrf self.package_installed_path , ( err ) ->

            return done( err ) if err 

            tarfile_path = self.package_installed_path + ".tgz" 

            utils.file.mkdirp utils.path.dirname( tarfile_path )        

            utils.http.get {
                            url : self.version_config.dist.tarball
                            encoding : null
                        } , ( err , res , body ) ->
                            fs.writeFileSync tarfile_path , body

                            utils.tar.unpack tarfile_path , self.package_installed_path , ( err ) ->

                                utils.file.rmrf tarfile_path
                                
                                self._each_dependencies_install done


                                            
    _fetch_remote_package_info: ( done ) ->

        url = env.getPackageUrl( @name ) 

        @_get url , ( err , res , body ) ->

            return done( err ) if err 

            try 
                json = JSON.parse( body )
            catch err 
                return done( err ) if err 

            return done( json.errmsg ) unless json.ret

            done( null , json.data )


    _get: ( url , cb ) ->

        utils.http.get url , cb 


    _check_local_package: () ->

        return false unless utils.path.exists @package_installed_path
        conf_path = utils.path.join( @package_installed_path , 'fekit.config' )
        return false unless utils.path.exists conf_path
        conf = utils.file.io.readJSON conf_path
        return false unless semver.eq conf.version , @semverstr

        return true


Package.FEKIT_MODULE_DIR = 'fekit_modules'

module.exports = Package
