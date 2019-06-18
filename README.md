# meyfes-front
This repository is a sorce of the web-page which is demonstrated at mayfes.

You can enjoy the web-page at [github-io](https://tomabou.github.io/meyfes-front/).



このリポジトリの
紹介記事を[qiitaに書きました](https://qiita.com/tomabou/items/6ef5add1dcbc4e9671e2)

https://github.com/tomabou/meyfes-back
が五月祭当日のサーバーのコードです


## how to build
build elm code
```
make build
```

build wasm by emscripten
```
make may3
```

js/min.js is a minified javascript file by uglifyjs.
[official documents](https://elm-lang.org/0.19.0/optimize) tell us how to minify elm code. 


