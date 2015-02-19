var gulp = require('gulp');
var del = require('del');
var rename = require('gulp-rename');
var connect = require('gulp-connect');
var webpack = require('gulp-webpack');
var webpackConfig = require('./webpack.config.js');

var port = process.env.PORT || 8080;
var reloadPort = process.env.RELOAD_PORT || 35729;

gulp.task('clean', function () {
  del(['build', 'examples/ejecta/iOS/App']);
});

gulp.task('build', function () {
  return gulp.src(webpackConfig.entry.timeline[0])
    .pipe(webpack(webpackConfig))
    .pipe(gulp.dest('build/'));
});

gulp.task('serve', function () {
  connect.server({
    port: port,
    livereload: {
      port: reloadPort
    }
  });
});

gulp.task('reload-js', function () {
  return gulp.src('./build/*.js')
    .pipe(connect.reload());
});

gulp.task('watch', function () {
  gulp.watch(['./build/*.js'], ['copyEjecta', 'reload-js']);
});

gulp.task('copyEjecta', function () {
  gulp.src('./build/ejecta.js')
    .pipe(rename('index.js'))
    .pipe(gulp.dest('./examples/ejecta/iOS/App'));
});

gulp.task('default', ['clean', 'watch', 'build', 'serve']);
