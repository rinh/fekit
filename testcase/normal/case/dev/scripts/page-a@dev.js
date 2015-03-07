// this is core.dom.helper.js

// this is core.widget.widget
if(typeof window.QTMPL === "undefined"){ window.QTMPL={}; }
window.QTMPL.dialog = new window.Hogan.Template(function(c,p,i){var _=this;_.b(i=i||"");_.b("// this is dialog.mustache");return _.fl();;});



// this is core.widget.dialog.dialog.js
(function() {
  var list, num;

  list = (function() {
    var _i, _results;
    _results = [];
    for (num = _i = 10; _i >= 0; num = --_i) {
      _results.push(num);
    }
    return _results;
  })();

}).call(this);




// this is page-b.js
