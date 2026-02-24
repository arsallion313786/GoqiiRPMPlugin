var exec = require('cordova/exec');

var GoqiiPlugin = {
    initialize: function(success, error) {
        exec(success, error, "GoqiiPlugin", "initialize", []);
    },
    getData: function(params, success, error) {
        exec(success, error, "GoqiiPlugin", "getData", [params]);
    }
};

module.exports = GoqiiPlugin;
