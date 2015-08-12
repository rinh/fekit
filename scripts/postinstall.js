var path = require('path');
var spawn = require('child_process').spawn;
var npm = process.platform === "win32" ? "npm.cmd" : "npm";

var sassPath = path.resolve(__dirname, '../vendors/node-sass/');
process.chdir(sassPath);

spawn(npm, ["install", "--production", "--local"], {
    stdio: 'inherit'
});
