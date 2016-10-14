elm make Test/App.elm --output elm.js
if [ $? -eq 0 ]
then
	webpack --config Test/webpack.config.js --display-error-details
fi
