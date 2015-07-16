var npm = require('npm');
var path = require('path');

var sassPath = path.resolve(__dirname, '../vendors/node-sass/');
process.chdir(sassPath);

npm.load({}, function(err, npm) {
    if (err) {
        console.error(err);
        return null;
    }

    console.log("prefix = %s", npm.prefix);
    npm.commands.install([], function(err) {
        if (err) console.error(err);
    });
});
