module.exports = (grunt) ->

   grunt.loadNpmTasks 'grunt-contrib-coffee'
   grunt.loadNpmTasks 'grunt-contrib-watch'
   grunt.loadNpmTasks 'grunt-mocha-cli'
   grunt.loadNpmTasks 'grunt-stubby'

   grunt.initConfig
      pkg: grunt.file.readJSON 'package.json'

      mochacli:
        options:
          timeout: 50000
          compilers: ['coffee:coffee-script']
        all: 'test/**/*.coffee'

      stubby: 
        bintray: 
          files: [{
            src: [ 'test/mocks/*.json' ]
          }]      

      coffee:
        src:
          options:
            base: false
          expand: true
          cwd: 'src'
          src: ['**/*.coffee']
          dest: 'lib'
          ext: '.js'

      watch:
        src:
          files: 'src/**/*.coffee'
          tasks: [ 'coffee:src', 'test' ]

   grunt.registerTask 'default', ['coffee', 'mochacli']
   grunt.registerTask 'test', ['stubby', 'mochacli']
   grunt.registerTask 'compile', ['coffee']