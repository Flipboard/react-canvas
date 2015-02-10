var gulp = require('gulp');
var clean = require('gulp-clean');
var webpack = require('webpack');
var webpackPlugin = require('gulp-webpack');
var webpackConfig = require('./webpack.config.js');
var WebpackDevServer = require('webpack-dev-server');

gulp.task('clean', function () {
  return gulp.src('build', {read: false})
    .pipe(clean());
});

gulp.task('build', function () {
  return gulp.src(webpackConfig.entry.timeline[0])
    .pipe(webpackPlugin(webpackConfig))
    .pipe(gulp.dest('build/'));
});

gulp.task('serve', function () {
  new WebpackDevServer(webpack(webpackConfig), {
    hot: true,
    publicPath: webpackConfig.output.publicPath
  }).listen(8080, 'localhost', function (err) {
    if (err) {
      return console.error(err);
    }

    console.log('Development server listening at http://localhost:8080/examples');
  });
});


gulp.task('default', ['clean', 'build', 'serve']);
