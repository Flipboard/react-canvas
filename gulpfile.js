var gulp = require('gulp');
var del = require('del');
var connect = require('gulp-connect');
var webpack = require('gulp-webpack');
var webpackConfig = require('./webpack.config.js');

gulp.task('clean', function () {
  del(['build']);
});

gulp.task('build', function () {
  return gulp.src(webpackConfig.entry.timeline[0])
    .pipe(webpack(webpackConfig))
    .pipe(gulp.dest('build/'));
});

gulp.task('serve', function () {
  connect.server({
    livereload: true
  });
});

gulp.task('reload-js', function () {
  return gulp.src('./build/*.js')
    .pipe(connect.reload());
});

gulp.task('watch', function () {
  gulp.watch(['./build/*.js'], ['reload-js']);
});

gulp.task('default', ['clean', 'build', 'serve', 'watch']);
