module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    md: {
      options: {
        wrapper: "views/markdown.html",
        mm: {
          postCompile: function(html) {
            return html.replace("BASE_URL", process.env.BASE_URL)
          }
        }
      },
      all: {
        files: {
          'public/index.html': 'src/crpaste.md'
        }
      },
    },
    bower_concat: {
      all: {
        mainFiles: {
          'highlightjs-line-numbers.js': ['dist/highlightjs-line-numbers.min.js'],
          'ago': ['ago.js', 'en.js'],
          'highlightjs': ['highlight.pack.js', 'styles/github.css']
        },
        dest: {
          js: 'tmp/bower.js',
          css: 'tmp/bower.scss'
        }
      }
    },
    sass: {
      dist: {
        files: {
          'tmp/<%= pkg.name %>.css': 'src/<%= pkg.name %>.scss',
        }
      }
    },
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      },
      build: {
        src: ['tmp/bower.js', 'src/<%= pkg.name %>.js'],
        dest: 'public/<%= pkg.name %>.min.js'
      }
    },
    cssmin: {
      target: {
        files: {
          'public/<%= pkg.name %>.min.css': ['tmp/bower.css', 'tmp/<%= pkg.name %>.css']
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-md');
  grunt.loadNpmTasks('grunt-contrib-sass');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-bower-concat');

  grunt.registerTask('default', ['md', 'bower_concat', 'sass', 'uglify', 'cssmin']);

};
