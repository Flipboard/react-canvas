module.exports = {
  cache: true,

  watch: true,

  entry: {
    'listview': ['./examples/listview/app.js'],
    'timeline': ['./examples/timeline/app.js'],
    'css-layout': ['./examples/css-layout/app.js']
  },

  output: {
    filename: '[name].js'
  },

  module: {
    loaders: [{
      test: /\.jsx?$/, // 扩展名
      exclude: /(node_modules|bower_components)/, // 排除目录
      loader: 'babel', // 加载器
      query: {
        presets: ['react', 'es2015'] // 包含的预置处理器
      }
    }]
  },

  resolve: {
    root: __dirname,
    alias: {
      'react-canvas': 'lib/ReactCanvas.js'
    }
  }
};
