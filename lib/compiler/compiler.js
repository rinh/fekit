var LOOPS, MAX_LOOP_COUNT, Module, ModulePath, _, addPlugin, async, autoprefixer, booster, fs, getSource, pluginsDir, postcss, syspath, utils;

_ = require('underscore');

async = require('async');

autoprefixer = require('autoprefixer');

fs = require('fs');

postcss = require('postcss');

syspath = require('path');

utils = require('../util');

exports.booster = booster = require('./module/booster');

Module = require("./module/module").Module;

Module.booster = booster;

ModulePath = require('./module/path').ModulePath;

exports.path = Module.path;


/* ---------------------------
    插件系统
 */

exports.getContentType = function(url) {
  return Module.getContentType(syspath.extname(url));
};

addPlugin = function(extName, plugin) {
  return Module.addExtensionPlugin(extName, plugin);
};

pluginsDir = syspath.join(syspath.dirname(__filename), "plugins");

utils.path.each_directory(pluginsDir, (function(_this) {
  return function(filepath) {
    var extname, type;
    extname = syspath.extname(filepath);
    type = "." + syspath.basename(filepath, extname);
    return addPlugin(type, require(filepath));
  };
})(this));

ModulePath.getCompile(process.cwd(), './');


/* -----------------------
    export
 */

LOOPS = {};

MAX_LOOP_COUNT = 70;

getSource = function(module, options, callback) {
  return module.analyze(function(err) {
    var USED_MODULES, _tmp, arr, deps, i, len, ref, sub_module;
    if (err) {
      callback(err);
      return;
    }
    arr = [];
    USED_MODULES = options.use_modules;
    if (options.render_dependencies) {
      module.getSourceWithoutDependencies = options.render_dependencies;
    }
    deps = [];
    if (options.no_dependencies !== true) {
      ref = module.depends;
      for (i = 0, len = ref.length; i < len; i++) {
        sub_module = ref[i];
        _tmp = function(sub_module) {
          return (function(_this) {
            return function(seriesCallback) {
              LOOPS[sub_module.guid] = (LOOPS[sub_module.guid] || 0) + 1;
              if (LOOPS[sub_module.guid] > MAX_LOOP_COUNT) {
                seriesCallback("出现循环调用，请检查 " + sub_module.path.uri + " 的引用");
              }
              if (USED_MODULES[sub_module.guid]) {
                utils.proc.setImmediate(seriesCallback);
                return;
              }
              return getSource(sub_module, options, function(e, txt) {
                arr.push(txt);
                return utils.proc.setImmediate(function() {
                  return seriesCallback(e);
                });
              });
            };
          })(this);
        };
        deps.push(_tmp(sub_module));
      }
    }
    return async.series(deps, function(err) {
      var c, plugin, ref1, ref2, source;
      if (err) {
        callback(err);
        return null;
      }
      source = module.getSourceWithoutDependencies();
      c = (ref1 = module.config.config) != null ? (ref2 = ref1.root) != null ? ref2.autoprefixer : void 0 : void 0;
      if (_.isObject(c) && module.iscss) {
        plugin = autoprefixer(c);
        return postcss([plugin]).process(source).then(function(out) {
          arr.push(out.css);
          USED_MODULES[module.guid] = 1;
          return callback(null, arr.join(utils.file.NEWLINE));
        })['catch'](function(out) {
          console.error('\n%s %s', syspath.relative(process.cwd(), module.path.uri), out.message);
          return process.exit(1);
        });
      }
      arr.push(source);
      USED_MODULES[module.guid] = 1;
      return callback(null, arr.join(utils.file.NEWLINE));
    });
  });
};


/*
 options {
    // 依赖的文件列表(fullpath)
    dependencies_filepath_list : []
    // 使用非依赖模式
    no_dependencies : false ,
    // 非依赖模式的生成方案
    render_dependencies : function ,
    // 根模块文件路径(可有可无,如果没有则默认当前处理文件为root_module)
    root_module_path : ""
    // 开发环境
    environment : "local" / "dev" / "prd"
 }
 */

exports.compile = function(filepath, options, doneCallback) {
  var _done, _iter, _list, module, use_modules;
  LOOPS = {};
  if (arguments.length === 3) {
    options = options || {};
    doneCallback = doneCallback;
  } else if (arguments.length === 2) {
    doneCallback = options;
    options = {};
  }
  use_modules = {};
  module = Module.parse(filepath, options, null, Module.parse(options.root_module_path || filepath));
  _list = options.dependencies_filepath_list || [];
  _iter = function(dep_path, seriesCallback) {
    var parent_module;
    parent_module = new Module(dep_path, options);
    return parent_module.getDependenciesURI(function(err, module_guids) {
      if (!err) {
        _.extend(use_modules, module_guids);
      }
      return utils.proc.setImmediate(function() {
        return seriesCallback(err);
      });
    });
  };
  _done = function(err) {
    if (err) {
      doneCallback(err);
      return;
    }
    return getSource(module, {
      use_modules: use_modules,
      no_dependencies: !!options.no_dependencies,
      render_dependencies: options.render_dependencies
    }, function(err, result) {
      return doneCallback(err, result, module);
    });
  };
  return utils.async.series(_list, _iter, _done);
};
