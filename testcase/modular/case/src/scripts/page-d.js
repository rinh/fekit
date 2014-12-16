require("jade-web")

var d = require("./pageD.jade");

console.info(d({
    pageTitle: "hello world",
    youAreUsingJade: false
}));