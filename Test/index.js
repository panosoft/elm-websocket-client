require('./index.html');
var Elm = require('./App.elm');
var elmNode = document.getElementById('elm');
var app = Elm.Test.App.embed(elmNode);
