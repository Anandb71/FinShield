const exec = require('child_process').exec;
function doThing(userInput) {
    // Command Injection
    exec('ls ' + userInput);
}\n