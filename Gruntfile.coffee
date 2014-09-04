module.exports = (grunt) ->

  grunt.initConfig

    pkg: grunt.file.readJSON "package.json"

    coffeelint:
      gruntfile:
        src: ["Gruntfile.coffee"]
      app:
        src: ["src/*.coffee"]

    coffee:
      build:
        files: [
          expand: true
          cwd: "src"
          src: ["*.coffee"]
          dest: "lib"
          ext: ".js"
        ]

    mochaTest:
      test:
        options:
          reporter: "spec"
          require: "coffee-script/register"
        src: ["test/**/*.coffee"]

  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-mocha-test"

  grunt.registerTask "default", ["build"]
  grunt.registerTask "build", ["coffeelint", "coffee"]
  grunt.registerTask "test", ["mochaTest"]
