const webpack = require('/usr/local/lib/node_modules/webpack');

module.exports = {
    entry: './Test/Browser/index.js',
    output: {
        path: './build',
        filename: 'index.js'
    },
	plugins: [
        new webpack.DefinePlugin({
            "process.env": {
                BROWSER: JSON.stringify(true)
            }
        })
    ],
    module: {
        loaders: [
            {
                test: /\.html$/,
                exclude: /node_modules/,
                loader: 'html-loader'
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/],
                loader: 'elm-webpack'
            }
        ]
    }
};
