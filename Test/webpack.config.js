module.exports = {
    entry: './Test/index.js',
    output: {
        path: './build',
        filename: 'index.js'
    },
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
