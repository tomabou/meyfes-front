require('../css/style.css');
const { Elm } = require('../app/meyfes.elm');

var app = Elm.Main.init({
    node: document.getElementById('elm')
});