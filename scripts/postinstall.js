var path = require('path');
var spawn = require('child_process').spawn;

var sassPath = path.resolve(__dirname, '../vendors/node-sass/');
process.chdir(sassPath);

spawn('npm', ["install", "--production"], {
    stdio: 'inherit'
});
