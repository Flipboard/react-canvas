var webpack = require('webpack');

var hotServers = [
  'webpack-dev-server/client?http://localhost:8080',
  'webpack/hot/only-dev-server'
];

module.exports = {
  devtool: 'eval',

  entry: {
    'listview': ['./examples/listview/index'].concat(hotServers),
    'timeline': ['./examples/timeline/index'].concat(hotServers),
    'css-layout': ['./examples/css-layout/index'].concat(hotServers)
  },

  output: {
    filename: '[name].js',
    publicPath: '/build/'
  },

  module: {
    loaders: [
      { test: /\.js$/, loader: 'react-hot!jsx-loader!transform/cacheable?envify' },
    ]
  },

  plugins: [
    new webpack.HotModuleReplacementPlugin(),
    new webpack.NoErrorsPlugin()
  ],

  resolve: {
    root: __dirname,
    alias: {
      'react-canvas': 'lib/ReactCanvas.js'
    }
  }
};
