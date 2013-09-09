var Bintray = require('./lib/bintray');

var bintray = new Bintray('h2non', '65deba60e9e5aa196daac3edada58e2cacd6de4694143053d28d70bca9e52eba', 'frontstack', 'stable');

bintray.searchPackage('test')
  .then(function () {
    console.log('done!') 
  }, function (error) {
    console.log(error.code)
  });