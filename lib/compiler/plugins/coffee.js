var coffee;

coffee = require('coffee-script');

exports.contentType = "javascript";

exports.process = function(txt, path, module, cb) {
  var err, error;
  try {
    return cb(null, coffee.compile(txt));
  } catch (error) {
    err = error;
    return cb(err);
  }
};
