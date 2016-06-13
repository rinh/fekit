var ModulePath, fs, syspath, utils;

syspath = require('path');

fs = require('fs');

utils = require('../../util');


/* ---------------------------
    模块路径
 */

ModulePath = (function() {
  function ModulePath(uri1) {
    this.uri = uri1;
  }

  ModulePath.prototype.parseify = function(path_without_extname) {
    var ext_list, extname, p, result;
    extname = this.extname();
    if (~ModulePath.EXTLIST.indexOf(extname)) {
      ext_list = ModulePath.getContentTypeList(extname);
      result = utils.file.findify(path_without_extname, ext_list);
      if (result === null && utils.path.exists(path_without_extname) && utils.path.is_directory(path_without_extname)) {
        p = utils.path.join(path_without_extname, "index");
        result = utils.file.findify(p, ModulePath.EXTLIST);
      }
    }
    if (result) {
      return result;
    } else {
      throw "找不到文件或对应的编译方案 [" + path_without_extname + "] 后缀检查列表为[" + ModulePath.EXTLIST + "]";
    }
  };

  ModulePath.prototype.extname = function() {
    return syspath.extname(this.uri);
  };

  ModulePath.prototype.dirname = function() {
    return syspath.dirname(this.uri);
  };

  ModulePath.prototype.getFullPath = function() {
    return this.uri;
  };

  ModulePath.prototype.getContentType = function() {
    return ModulePath.getContentType(this.extname());
  };

  return ModulePath;

})();


/*
    解析子模块真实路径

    子模块路径表现形式可以是
        省略后缀名方式, 该方式会认为子模块后缀名默认与parentModule相同
            a/b/c
            a.b.c

            后缀名默认匹配顺序为, 如果都找不到就会报错
            [javascript]
            .js / .coffee / .mustache
            [css]
            .css / .less

    子模块的

    子模块路径分2种
    1, 相对路径, 相对于父模块的dirname. 如 a/b/c
    2, 别名引用路径, 别名是由配置指定的路径. 如 core/a/b/c , core是在配置文件中进行配置的
 */

ModulePath.resolvePath = function(path, parentModule) {
  var path_without_extname, truelypath;
  path_without_extname = ModulePath.parsePath(path, parentModule);
  truelypath = parentModule.path.parseify(path_without_extname);
  utils.logger.trace("[COMPILE] 解析子模块真实路径 " + path + " >>>> " + truelypath);
  return truelypath;
};

ModulePath.parsePath = function(path, parentModule) {
  var i, j, len, package_path, part, parts, result;
  parts = utils.path.split_path(path, ModulePath.EXTLIST);
  result = [];
  for (i = j = 0, len = parts.length; j < len; i = ++j) {
    part = parts[i];
    if (i === 0 && parts.length === 1) {

      /*
          处理组件名或只写一个当前目录文件且没有扩展名的情况
          优先取文件，再取组件
       */
      package_path = parentModule.config.getPackage(part);
      if (package_path) {
        result.push(package_path);
      } else {
        result.push(parentModule.path.dirname());
        result.push(part);
      }
    } else if (i === 0) {

      /*
          大于1个以上的引用名的情况
       */
      if (parentModule.config.isUseAlias(part)) {
        result.push(parentModule.config.parseAlias(part));
      } else {
        result.push(parentModule.path.dirname());
        result.push(part);
      }
    } else {
      result.push(part);
    }
  }
  return syspath.join.apply(syspath, result);
};

ModulePath.getContentType = function(extname) {
  var ref;
  return (ref = ModulePath.EXTTABLE[extname]) != null ? ref.contentType : void 0;
};

ModulePath.addExtensionPlugin = function(extName, plugin) {
  ModulePath.EXTLIST.push(extName);
  return ModulePath.EXTTABLE[extName] = plugin;
};

ModulePath.getPlugin = function(extName, path) {
  var firstMatch;
  firstMatch = syspath.join(path, extName);
  return ModulePath.EXTTABLE[firstMatch] || ModulePath.EXTTABLE[extName];
};

ModulePath.getContentTypeList = function(extName) {
  var k, type, v;
  type = ModulePath.EXTTABLE[extName].contentType;
  return (function() {
    var ref, results;
    ref = ModulePath.EXTTABLE;
    results = [];
    for (k in ref) {
      v = ref[k];
      if (v.contentType === type) {
        results.push(k);
      }
    }
    return results;
  })();
};

ModulePath.findFileWithoutExtname = function(uri) {
  var ext, extname, j, len, list, n, p;
  if (utils.path.exists(uri)) {
    return uri;
  }
  ext = syspath.extname(uri);
  p = uri.replace(ext, '');
  list = ModulePath.getContentTypeList(ext);
  for (j = 0, len = list.length; j < len; j++) {
    extname = list[j];
    n = p + extname;
    if (utils.path.exists(n)) {
      return n;
    }
  }
  return null;
};

ModulePath.getCompile = function(cwd, folder) {
  var build, buildName, buildPath, config, e, error, extName, fekitconfig, plugin, projectFolder, results;
  fekitconfig = syspath.join(cwd, folder, 'fekit.config');
  projectFolder = syspath.join(cwd, folder);
  if (fs.existsSync(fekitconfig)) {
    try {
      config = utils.file.io.readJSON(fekitconfig);
    } catch (error) {
      e = error;
      return;
    }
    build = config.build;
    if (build) {
      results = [];
      for (extName in build) {
        plugin = build[extName];
        buildPath = syspath.join(projectFolder, plugin.path);
        if (fs.statSync(buildPath).isDirectory()) {
          buildPath = syspath.join(buildPath, 'index');
        }
        buildName = syspath.join(projectFolder, extName);
        results.push(ModulePath.addExtensionPlugin(buildName, require(buildPath)));
      }
      return results;
    }
  }
};

ModulePath.EXTLIST = [];

ModulePath.EXTTABLE = {};

exports.ModulePath = ModulePath;
