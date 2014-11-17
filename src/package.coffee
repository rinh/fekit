fs = require 'fs'
_ = require 'underscore'
semver = require 'semver'
async = require 'async'
env = require './env'
utils = require './util'
syspath = require 'path'

class Package

    constructor: ( @name , @semverstr , @basepath ) ->
        # 如果没有参数，则认为是本地包模式，需要使用 loadConfig 进行配置加载
        if arguments.length is 0
            @is_root = true
            return

        # @schema : fekit_package_server GET /pkgname 返回结果
        @schema = null
        # @version 最终选定的版本号
        @version = null
        # @config 最终选定版本号的 config 内容
        @version_config = null
        # @config 最终选定版本号的 config 内容(fekit.config)
        @fekit_config = null

        @semverstr = unless @semverstr then "*" else @semverstr
        @parent = null
        @children = []
        @package_installed_path = utils.path.join @basepath , Package.FEKIT_MODULE_DIR , @name

    # config 包含 dependencies , 基本上就是 fekit.config
    loadConfig: ( @basepath , config ) ->
        @package_installed_path = @basepath
        @_get = ( url , cb ) ->
            obj =
                ret : true
                data :
                    versions :
                        '0.0.0':
                            config: config
            cb( null , null , obj )

    # 获取本地入口文件路径
    # 默认入口文件为 src/index， 如果出错则返回 null
    get_local_entry: () ->
        return null if @name is '.' or @name is '..'
        p = @basepath
        # 不断向上寻找组件
        while _fekit_conf_path = @get_fekitconfig_path( p )
            return null if utils.path.is_root( p )
            break if utils.path.exists _fekit_conf_path
            p = utils.path.dirname p

        return null unless utils.path.exists _fekit_conf_path
        _conf = utils.file.io.readJSON _fekit_conf_path
        _base = utils.path.join p , Package.FEKIT_MODULE_DIR , @name
        return utils.path.join( _base , ( if _conf.main then _conf.main else "src/index" ) )

    get_fekitconfig_path : ( base ) ->
        utils.path.join base , Package.FEKIT_MODULE_DIR , @name , 'fekit.config'

    report: () ->
        c = console.info
        c ""

        unless @is_root
            c "----#{@name}"
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


    # 递归检查父级是否包含该组件（版本号包含）
    _contain: ( name , semverstr ) ->
        return false unless @parent
        for pkg in @parent.children
            if name is pkg.name
                if semver.satisfies( pkg.version || pkg.semverstr , semverstr )
                    return true
        return @parent._contain( name , semverstr )

    _each_dependencies_preinstall: ( done ) ->

        self = this

        _deps = @fekit_config.dependencies or {}

        return done() if _.size( _deps ) is 0

        _basepath = utils.path.join @package_installed_path
        deps = []
        for _name , _ver of _deps
            unless @_contain( _name , _ver )
                _p = new Package( _name , _ver , _basepath )
                _p.parent = self
                deps.push _p

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

        return self._each_dependencies_install done if @is_root

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

                                # install hook
                                self_config = utils.file.io.readJSON syspath.join( self.package_installed_path, 'fekit.config' )

                                if self_config.scripts?.postinstall and utils.path.exists syspath.join( self.package_installed_path, self_config.scripts.postinstall )
                                    parent_config_path = syspath.join( self.package_installed_path, '../../fekit.config' )
                                    parent_config = {};
                                    try
                                        parent_config = utils.file.io.readJSON parent_config_path
                                    catch error

                                    utils.proc.requireScript syspath.join( self.package_installed_path, self_config.scripts.postinstall ), {
                                        config: parent_config.module_options?[self.name] || {},
                                        process_end: () ->
                                            self._each_dependencies_install done
                                    }
                                else
                                    self._each_dependencies_install done


    _fetch_remote_package_info: ( done ) ->

        url = env.getPackageUrl( @name )

        @_get url , ( err , res , body ) ->

            return done( err ) if err

            switch typeof body
                when 'string'
                    try
                        json = JSON.parse( body )
                    catch err
                        return done( err ) if err
                when 'object'
                    json = body

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
